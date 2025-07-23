#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_changelog=$(cat changelog_release.md 2>/dev/null || echo "")
initial_version=$(cat version.json 2>/dev/null || echo "")

# Operation history for robust cleanup
operation_history=()
commit_pushed=0
pr_url=""
pr_number=""

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        for (( idx=${#operation_history[@]}-1 ; idx>=0 ; idx-- )) ; do
            op="${operation_history[$idx]}"
            case $op in
                restore_changelog)
                    if [ -f changelog_release.md ]; then
                        echo "$initial_changelog" > changelog_release.md
                        echo "Changelog restored."
                    fi
                    ;;
                restore_version)
                    if [ -f version.json ]; then
                        echo "$initial_version" > version.json
                        echo "Version file restored."
                    fi
                    ;;
                checkout_original_branch)
                    if [ "$(git branch --show-current)" != "$initial_branch" ]; then
                        git checkout $initial_branch
                        echo "Checked out original branch: $initial_branch."
                    fi
                    ;;
                reset_commit)
                    # Check if we've already undone this through warn_push
                    if [ $commit_pushed -eq 1 ]; then
                        echo "Skipping reset as commit will be handled by warn_push operation."
                        continue
                    fi
                    git reset --hard HEAD^ 2>/dev/null || true
                    echo "Last commit reset."
                    ;;
                warn_push)
                    if [ $commit_pushed -eq 1 ]; then
                        echo "Reverting to the commit before the push..."
                        git reset --hard HEAD^
                        git push --force-with-lease || echo "Warning: force-push failed. Manual intervention may be required."
                        echo "Force-pushed branch to remove last commit from remote."
                    else
                        echo "Warning: git push was performed. Manual intervention may be required to undo remote changes."
                    fi
                    ;;
                warn_pr_main)
                    echo "Warning: Pull request was created for main. Please close it manually if not needed."
                    ;;
                warn_pr_develop)
                    echo "Warning: Pull request was created for develop. Please close it manually if not needed."
                    ;;
            esac
        done
        exit 1
    fi
}

trap cleanup EXIT

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Check if we are on a hotfix branch, if not ask the user for the name of the hotfix branch
current_branch=$(git branch --show-current)
if [[ $current_branch != "hotfix/"* ]]; then
    read -p "Not on a hotfix branch, enter the name of the hotfix branch to complete: " hotfix_name
    branch_name="hotfix/$hotfix_name"
    # Check that the hotfix branch exists
    if ! git branch --list $branch_name; then
        echo "Error: Hotfix branch '$branch_name' does not exist."
        exit 1
    fi
    git checkout $branch_name || exit 1
    operation_history+=(checkout_original_branch)
else
    hotfix_name=${current_branch#hotfix/}
    branch_name=$current_branch
fi

# Rebase the hotfix branch from the latest main
echo "Rebasing hotfix branch from latest main..."
git checkout main || exit 1
git pull || exit 1
git checkout $branch_name || exit 1

beforeRebaseHash=$(git rev-parse HEAD)
git rebase main || {
    echo "Merge conflicts detected during rebase. Please resolve them manually."
    while true; do
        echo "Press Enter when you have resolved all conflicts and completed the rebase."
        read -p ""
        # Check if rebase is still in progress
        if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
            echo "Rebase is still in progress. Please complete it before continuing."
        else
            break
        fi
    done
}
afterRebaseHash=$(git rev-parse HEAD)

rebased=false
if [ "$beforeRebaseHash" != "$afterRebaseHash" ]; then
    rebased=true
fi

operation_history+=(checkout_original_branch)

# Read the version number from the file as integers
version_major=$(jq '.major' version.json)
version_minor=$(jq '.minor' version.json)
version_patch=$(jq '.patch' version.json)

# Increment the patch version number
version_patch=$((version_patch + 1))

# Write the new version number to the file
cat > version.json << EOF
{
    "major": $version_major,
    "minor": $version_minor,
    "patch": $version_patch
}
EOF
operation_history+=(restore_version)

# Get the description of the hotfix from the user
read -p "Enter a description of the hotfix to be added to the changelog: " hotfix_description

# Add the hotfix description to the end of the changelog
cat >> changelog_release.md << EOF
## v$version_major.$version_minor.$version_patch
- $hotfix_description
EOF
operation_history+=(restore_changelog)

# Commit the changelog and version.json file
git add changelog_release.md version.json || exit 1
git commit -m "Update changelog and version number for hotfix $hotfix_name" || exit 1
operation_history+=(reset_commit)

if [ $rebased = true ]; then
    git push --force-with-lease || exit 1
else
    git push || exit 1
fi
operation_history+=(warn_push)
commit_pushed=1

# Create a pull request from the hotfix branch to main
gh pr create --base main --head $branch_name --title "Merge hotfix $hotfix_name into main" --body "Automated PR for hotfix $hotfix_name" || exit 1
operation_history+=(warn_pr_main)

# Create a pull request from the hotfix branch to develop
gh pr create --base develop --head $branch_name --title "Merge hotfix $hotfix_name into develop" --body "Automated PR for hotfix $hotfix_name" || exit 1
operation_history+=(warn_pr_develop)

# Inform the user
echo "Pull requests created for hotfix: $hotfix_name. Please complete the PR merges and branch deletions via the GitHub UI or your automation system."
echo "Successfully completed hotfix: $hotfix_name (PRs created)"
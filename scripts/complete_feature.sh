#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_changelog=$(cat changelog_develop.md 2>/dev/null || echo "")

# Operation history for robust cleanup
operation_history=()
commit_pushed=0

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        for (( idx=${#operation_history[@]}-1 ; idx>=0 ; idx-- )) ; do
            op="${operation_history[$idx]}"
            case $op in
                restore_changelog)
                    if [ -f changelog_develop.md ]; then
                        echo "$initial_changelog" > changelog_develop.md
                        echo "Changelog restored."
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
                    # If a commit was pushed, force-push after reset
                    if [ $commit_pushed -eq 1 ]; then
                        # Revert to the commit before the push
                        echo "Reverting to the commit before the push..."
                        git reset --hard HEAD^
                        git push --force-with-lease || echo "Warning: force-push failed. Manual intervention may be required."
                        echo "Force-pushed branch to remove last commit from remote."
                    else
                        echo "Warning: git push was performed. Manual intervention may be required to undo remote changes."
                    fi
                    ;;
            esac
        done
        exit 1
    fi
}

# Set up error handling
trap cleanup EXIT

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Check if we are on a feature branch, if not ask the user for the name of the feature branch
current_branch=$(git branch --show-current)
if [[ $current_branch != "feature/"* ]]; then
    read -p "Not on a feature branch, enter the name of the feature branch to complete without the 'feature/' prefix: " feature_name
    branch_name="feature/$feature_name"
    # Check that the feature branch exists
    if ! git branch --list $branch_name; then
        echo "Error: Feature branch '$branch_name' does not exist."
        exit 1
    fi
    git checkout $branch_name || exit 1
    operation_history+=(checkout_original_branch)
else
    feature_name=${current_branch#feature/}
    branch_name=$current_branch
fi

# Rebase the feature branch from the latest develop
echo "Rebasing feature branch from latest develop..."
git checkout develop || exit 1
git pull || exit 1
git checkout $branch_name || exit 1
rebased=false
git rebase develop || {
    echo "Merge conflicts detected during rebase. Please resolve them manually."
    while true; do
        echo "Press Enter when you have resolved all conflicts and completed the rebase."
        read -p ""
        # Check if rebase is still in progress
        if [ -d ".git/rebase-merge" ] || [ -d ".git/rebase-apply" ]; then
            echo "Rebase is still in progress. Please complete it before continuing."
        else
            rebased=true
            break
        fi
    done
}
operation_history+=(checkout_original_branch)

# Get description of the feature from the user
read -p "Enter a description of the feature to be added to the changelog: " feature_description

# Add the feature description to the end of the changelog
cat >> changelog_develop.md << EOF
- $feature_description
EOF
operation_history+=(restore_changelog)

# Commit the changelog file
git add changelog_develop.md || exit 1
git commit -m "Update changelog for feature $feature_name" || exit 1
operation_history+=(reset_commit)

# Push the branch and mark that a commit was pushed
if [ $rebased = true ]; then
    git push --force-with-lease || exit 1
else
    git push || exit 1
fi
operation_history+=(warn_push)
commit_pushed=1

# Create a pull request from the feature branch to develop
gh pr create --base develop --head $branch_name --title "Merge feature $feature_name into develop" --body "Automated PR for feature $feature_name" || exit 1

# Inform the user
echo "Pull request created for feature: $feature_name. Please complete the PR merge and branch deletion via the GitHub UI or your automation system."

# If we get here, everything succeeded
echo "Successfully completed feature: $feature_name (PR created)"

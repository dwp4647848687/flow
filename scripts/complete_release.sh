#! /bin/bash

# Exit on any error
set -e

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

# Get the current branch
current_branch=$(git branch --show-current)

# Verify we're on a release branch
if [[ ! $current_branch =~ ^release/[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: Must be on a release branch to complete a release"
    exit 1
fi

# Extract version from branch name
version_parts=(${current_branch//[.\/]/ })
version_major=${version_parts[1]}
version_minor=${version_parts[2]}
version_patch=${version_parts[3]}

# Verify version numbers
if ! [[ "$version_major" =~ ^[0-9]+$ ]] || ! [[ "$version_minor" =~ ^[0-9]+$ ]] || ! [[ "$version_patch" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid version numbers in branch name"
    exit 1
fi

# Push the release branch
# (Assume any changes have already been committed)
git push || exit 1
operation_history+=(warn_push)
commit_pushed=1

# Create a pull request from the release branch to main
pr_title="Release v$version_major.$version_minor.$version_patch"
pr_body="Automated PR for release v$version_major.$version_minor.$version_patch"
gh pr create --base main --head $current_branch --title "$pr_title" --body "$pr_body" || exit 1
operation_history+=(warn_pr_main)

# Inform the user

echo "Pull request created for release: v$version_major.$version_minor.$version_patch."
echo "After the PR is merged into main, create the tag and delete the release branch as appropriate."
echo "Successfully completed release: v$version_major.$version_minor.$version_patch (PR created)" 
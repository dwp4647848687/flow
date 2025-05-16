#! /bin/bash

# Exit on any error
set -e

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        
        # Abort any in-progress merge
        git merge --abort 2>/dev/null || true
        
        # If we created a tag, delete it
        if [ -n "$version_major" ] && [ -n "$version_minor" ] && [ -n "$version_patch" ]; then
            git tag -d "v$version_major.$version_minor.$version_patch" 2>/dev/null || true
            git push origin --delete "v$version_major.$version_minor.$version_patch" 2>/dev/null || true
        fi
        
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

# Merge the release branch into the main branch
git checkout main || exit 1
git pull || exit 1
git merge --no-ff $current_branch -m "Merge release $version_major.$version_minor.$version_patch into main" || exit 1
git push || exit 1

# Create and push a tag for the release
git tag -a "v$version_major.$version_minor.$version_patch" -m "Release v$version_major.$version_minor.$version_patch" || exit 1
git push origin "v$version_major.$version_minor.$version_patch" || exit 1

# Merge the release branch into the develop branch
git checkout develop || exit 1
git pull || exit 1
git merge --no-ff $current_branch -m "Merge release $version_major.$version_minor.$version_patch into develop" || exit 1
git push || exit 1

# Delete the release branch
git branch -d $current_branch || exit 1
git push origin --delete $current_branch || exit 1

echo "Successfully completed release: v$version_major.$version_minor.$version_patch" 
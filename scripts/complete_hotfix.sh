#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_changelog=$(cat changelog_release.md 2>/dev/null || echo "")
initial_version=$(cat version.json 2>/dev/null || echo "")

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        
        # Restore changelog if it was modified
        if [ -f changelog_release.md ]; then
            echo "$initial_changelog" > changelog_release.md
        fi
        
        # Restore version file if it was modified
        if [ -f version.json ]; then
            echo "$initial_version" > version.json
        fi
        
        # Abort any in-progress merge
        git merge --abort 2>/dev/null || true
        
        # If we switched branches, go back to the original
        if [ "$(git branch --show-current)" != "$initial_branch" ]; then
            git checkout $initial_branch
        fi
        
        # If we created a commit, try to reset it
        if [ -n "$hotfix_name" ]; then
            git reset --hard HEAD^ 2>/dev/null || true
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
else
    hotfix_name=${current_branch#hotfix/}
    branch_name=$current_branch
fi

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

# Get the description of the hotfix from the user
read -p "Enter a description of the hotfix to be added to the changelog: " hotfix_description

# Add the hotfix description to the end of the changelog
cat >> changelog_release.md << EOF
## v$version_major.$version_minor.$version_patch
- $hotfix_description
EOF

# Commit the changelog and version.json file
git add changelog_release.md version.json || exit 1
git commit -m "Update changelog and version number for hotfix $hotfix_name" || exit 1
git push || exit 1

# Merge the hotfix branch into the main branch
git checkout main || exit 1
git pull || exit 1
git merge --no-ff $branch_name -m "Merge hotfix $hotfix_name into main" || exit 1
git push || exit 1

# Merge the hotfix branch into the develop branch
git checkout develop || exit 1
git pull || exit 1
git merge --no-ff $branch_name -m "Merge hotfix $hotfix_name into develop" || exit 1
git push || exit 1

# Delete the hotfix branch
git branch -d $branch_name || exit 1
git push origin --delete $branch_name || exit 1

# If we get here, everything succeeded
echo "Successfully completed hotfix: $hotfix_name"
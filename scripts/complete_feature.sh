#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_changelog=$(cat changelog_develop.md 2>/dev/null || echo "")

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        
        # Restore changelog if it was modified
        if [ -f changelog_develop.md ]; then
            echo "$initial_changelog" > changelog_develop.md
        fi
        
        # Abort any in-progress merge
        git merge --abort 2>/dev/null || true
        
        # If we switched branches, go back to the original
        if [ "$(git branch --show-current)" != "$initial_branch" ]; then
            git checkout $initial_branch
        fi
        
        # If we created a commit, try to reset it
        if [ -n "$feature_name" ]; then
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
else
    feature_name=${current_branch#feature/}
    branch_name=$current_branch
fi


# Get description of the feature from the user
read -p "Enter a description of the feature to be added to the changelog: " feature_description

# Add the feature description to the end of the changelog
cat >> changelog_develop.md << EOF
- $feature_description
EOF

# Commit the changelog file
git add changelog_develop.md || exit 1
git commit -m "Update changelog for feature $feature_name" || exit 1
git push || exit 1

# Merge the feature branch into the develop branch
git checkout develop || exit 1
git pull || exit 1
git merge --no-ff $branch_name -m "Merge feature $feature_name into develop" || exit 1
git push || exit 1

# Delete the feature branch
git branch -d $branch_name || exit 1
git push origin --delete $branch_name || exit 1

# If we get here, everything succeeded
echo "Successfully completed feature: $feature_name"

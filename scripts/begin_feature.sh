#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        # If we created a feature branch, delete it
        if git branch | grep -q "$branch_name"; then
            git checkout $initial_branch
            git branch -D $branch_name
            # Try to delete remote branch if it exists
            git push origin --delete $branch_name 2>/dev/null || true
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

# Get the name of the new feature from the user
read -p "Enter the name of the new feature: " feature_name

# Check that the feature name is valid
if ![[ "$feature_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Feature name must contain only alphanumeric characters, underscores, or hyphens."
    exit 1
fi

branch_name="feature/$feature_name"

# Switch to the develop branch
git checkout develop || exit 1
git pull || exit 1

# Create a new feature branch
git checkout -b $branch_name || exit 1
git push --set-upstream origin $branch_name || exit 1

# If we get here, everything succeeded
echo "Successfully created and pushed feature branch: $branch_name"

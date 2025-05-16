#! /bin/bash

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Get the name of the new feature from the user
read -p "Enter the name of the new feature: " feature_name

# Switch to the develop branch
git checkout develop
git pull

# Create a new feature branch
git checkout -b feature/$feature_name
git push --set-upstream origin feature/$feature_name
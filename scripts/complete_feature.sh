#! /bin/bash

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Check if we are on a feature branch, if not ask the user for the name of the feature branch
current_branch=$(git branch --show-current)
if [[ $current_branch != "feature/"* ]]; then
    read -p "Not on a feature branch, enter the name of the feature branch to complete: " feature_name
    git checkout feature/$feature_name
else
    feature_name=$(basename $current_branch)
fi

# Get description of the feature from the user
read -p "Enter a description of the feature to be added to the changelog: " feature_description

# Add the feature description to the end of the changelog
cat >> changelog_develop.md << EOF
- $feature_description
EOF

# Commit the changelog file
git add changelog_develop.md
git commit -m "Update changelog for feature $feature_name"
git push

# Merge the feature branch into the develop branch
git checkout develop
git pull
git merge --no-ff feature/$feature_name -m "Merge feature $feature_name into develop"
git push

# Delete the feature branch
git branch -d feature/$feature_name
git push origin --delete feature/$feature_name

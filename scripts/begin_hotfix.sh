#! /bin/bash

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Get the name of the new hotfix from the user
read -p "Enter the name of the new hotfix: " hotfix_name

# Switch to the main branch
git checkout main
git pull

# Create a new hotfix branch
git checkout -b hotfix/$hotfix_name
git push --set-upstream origin hotfix/$hotfix_name

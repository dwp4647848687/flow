#! /bin/bash

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Check if we are on a hotfix branch, if not ask the user for the name of the hotfix branch
current_branch=$(git branch --show-current)
if [[ $current_branch != "hotfix/"* ]]; then
    read -p "Not on a hotfix branch, enter the name of the hotfix branch to complete: " hotfix_name
    git checkout hotfix/$hotfix_name
else
    hotfix_name=$(basename $current_branch)
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
git add changelog_release.md version.json
git commit -m "Update changelog and version number for hotfix $hotfix_name"
git push

# Merge the hotfix branch into the main branch
git checkout main
git pull
git merge --no-ff hotfix/$hotfix_name -m "Merge hotfix $hotfix_name into main"
git push

# Merge the hotfix branch into the develop branch
git checkout develop
git pull
git merge --no-ff hotfix/$hotfix_name -m "Merge hotfix $hotfix_name into develop"
git push

# Delete the hotfix branch
git branch -d hotfix/$hotfix_name
git push origin --delete hotfix/$hotfix_name
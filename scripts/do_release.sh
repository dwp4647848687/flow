#! /bin/bash

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Move to the develop branch
git checkout develop
git pull

# Ask the user if this is a major or minor release
while true; do
    read -p "Is this a major or minor release? (m for minor, M for major): " release_type
    if [ "$release_type" = "m" ] ; then
        release_type="minor"
        break
    elif [ "$release_type" = "M" ] ; then
        release_type="major"
        break
    else
        echo "Invalid input, please enter m for minor or M for major"
    fi
done

# Read the version number from the file as integers
version_major=$(jq '.major' version.json)
version_minor=$(jq '.minor' version.json)
version_patch=$(jq '.patch' version.json)

# Increment the version number based on the release type
if [ "$release_type" = "major" ]; then
    version_major=$((version_major + 1))
    version_minor=0
    version_patch=0
elif [ "$release_type" = "minor" ]; then
    version_minor=$((version_minor + 1))
    version_patch=0
fi

echo "This will be version $version_major.$version_minor.$version_patch"

# Create a temporary release branch
git checkout -b release/$version_major.$version_minor.$version_patch
git push --set-upstream origin release/$version_major.$version_minor.$version_patch

# Write the new version numbers to the file
cat > version.json << EOF
{
    "major": $version_major,
    "minor": $version_minor,
    "patch": $version_patch
}
EOF

# Add all the changes from the develop changelog to the release changelog
cat >> changelog_release.md << EOF
## v$version_major.$version_minor.$version_patch
EOF

# Add all the changes from the develop changelog to the release changelog
cat changelog_develop.md >> changelog_release.md

# Clear the develop changelog
cat > changelog_develop.md << EOF
EOF

# Commit the changelog and version.json file
git add changelog_release.md changelog_develop.md version.json
git commit -m "Update changelog and version number for release $version_major.$version_minor.$version_patch"
git push

# Merge the release branch into the main branch
git checkout main
git pull
git merge --no-ff release/$version_major.$version_minor.$version_patch -m "Merge release $version_major.$version_minor.$version_patch into main"
git push

# Create and push a tag for the release
git tag -a "v$version_major.$version_minor.$version_patch" -m "Release v$version_major.$version_minor.$version_patch"
git push origin "v$version_major.$version_minor.$version_patch"

# Merge the release branch into the develop branch
git checkout develop
git pull
git merge --no-ff release/$version_major.$version_minor.$version_patch -m "Merge release $version_major.$version_minor.$version_patch into develop"
git push

# Delete the release branch
git branch -d release/$version_major.$version_minor.$version_patch
git push origin --delete release/$version_major.$version_minor.$version_patch

#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_version=$(cat version.json 2>/dev/null || echo "")
initial_release_changelog=$(cat changelog_release.md 2>/dev/null || echo "")
initial_develop_changelog=$(cat changelog_develop.md 2>/dev/null || echo "")

# Function to clean up on error
cleanup() {
    if [ $? -ne 0 ]; then
        echo "Error occurred. Cleaning up..."
        
        # Restore version file if it was modified
        if [ -f version.json ]; then
            echo "$initial_version" > version.json
        fi
        
        # Restore changelogs if they were modified
        if [ -f changelog_release.md ]; then
            echo "$initial_release_changelog" > changelog_release.md
        fi
        if [ -f changelog_develop.md ]; then
            echo "$initial_develop_changelog" > changelog_develop.md
        fi
        
        # Abort any in-progress merge
        git merge --abort 2>/dev/null || true
        
        # If we switched branches, go back to the original
        if [ "$(git branch --show-current)" != "$initial_branch" ]; then
            git checkout $initial_branch
        fi
        
        # If we created a release branch, delete it
        if [ -n "$release_branch" ]; then
            git branch -D $release_branch 2>/dev/null || true
            git push origin --delete $release_branch 2>/dev/null || true
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

# Move to the develop branch
git checkout develop || exit 1
git pull || exit 1

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

# Validate version numbers
if ! [[ "$version_major" =~ ^[0-9]+$ ]] || ! [[ "$version_minor" =~ ^[0-9]+$ ]] || ! [[ "$version_patch" =~ ^[0-9]+$ ]]; then
    echo "Error: Invalid version numbers in version.json"
    exit 1
fi

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
release_branch="release/$version_major.$version_minor.$version_patch"
git checkout -b $release_branch || exit 1
git push --set-upstream origin $release_branch || exit 1

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
cat changelog_develop.md >> changelog_release.md || exit 1

# Clear the develop changelog
cat > changelog_develop.md << EOF
EOF

# Commit the changelog and version.json file
git add changelog_release.md changelog_develop.md version.json || exit 1
git commit -m "Update changelog and version number for release $version_major.$version_minor.$version_patch" || exit 1
git push || exit 1

echo "Successfully began release: v$version_major.$version_minor.$version_patch"
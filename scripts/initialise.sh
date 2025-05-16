#! /bin/bash

# Exit on any error
set -e

# Store the initial state
initial_branch=$(git branch --show-current)
initial_git_hooks=$(git config --get core.hooksPath 2>/dev/null || echo "")
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
        
        # Restore git hooks path if it was modified
        if [ -n "$initial_git_hooks" ]; then
            git config core.hooksPath "$initial_git_hooks"
        else
            git config --unset core.hooksPath
        fi
        
        # Remove created hook directory if it exists
        if [ -d ".githooks" ]; then
            rm -rf .githooks
        fi
        
        # If we switched branches, go back to the original
        if [ "$(git branch --show-current)" != "$initial_branch" ]; then
            git checkout $initial_branch
        fi
        
        # If we created the develop branch, delete it
        if git branch --list develop >/dev/null 2>&1; then
            git branch -D develop 2>/dev/null || true
            git push origin --delete develop 2>/dev/null || true
        fi
        
        exit 1
    fi
}

# Set up error handling
trap cleanup EXIT

# Make sure we are in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: This is not a git repository."
    exit 1
fi

# Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# Switch to the main branch
git checkout main || exit 1
git pull || exit 1

# Create a new version.json file in the root of the repository if one doesn't exist
if [ ! -f version.json ]; then
    cat > version.json << EOF
{
	"major": 0,
	"minor": 0,
	"patch": 0
}
EOF
else
    # If the file exists, check if has the expected fields
    if ! jq '.major' version.json >/dev/null 2>&1; then
        echo "Error: version.json is missing the \"major\" field."
        exit 1
    fi
    if ! jq '.minor' version.json >/dev/null 2>&1; then
        echo "Error: version.json is missing the \"minor\" field."
        exit 1
    fi
    if ! jq '.patch' version.json >/dev/null 2>&1; then
        echo "Error: version.json is missing the \"patch\" field."
        exit 1
    fi
    # Check there are no extra fields
    if [ "$(jq '. | keys | length' version.json)" -ne 3 ]; then
        echo "Error: version.json has extra fields. Only \"major\", \"minor\" and \"patch\" are allowed."
        exit 1
    fi
fi

# Create a new changelog file for tracking releases
cat > changelog_release.md << EOF
# Changelog
EOF

# Create a develop changelog file for tracking unreleased changes
cat > changelog_develop.md << EOF
EOF

# Create the custom commit hook
mkdir -p .githooks || exit 1
cat > .githooks/pre-commit << EOF
#!/bin/bash

# List of protected branches
protected_branches=("main" "develop")

# Get the current branch
current_branch=\$(git symbolic-ref --short HEAD)

# Check if current branch is in the list
for branch in "\${protected_branches[@]}"; do
  if [[ "\${current_branch}" == "\${branch}" ]]; then
    echo "❌ You cannot commit directly to '\${current_branch}'. Switch to a feature or hotfix branch."
    exit 1
  fi
done

exit 0
EOF

# Make the script executable
chmod +x .githooks/pre-commit || exit 1

# Make sure we are able to commit to main
git config core.hooksPath .git/hooks || exit 1

# Commit the changes, this needs to be done before we enable the hook
git add version.json changelog_release.md changelog_develop.md || exit 1
git add .githooks/pre-commit || exit 1
git commit -m "Initialise the repository for use with flow" || exit 1
git push || exit 1

# Tell git to use the custom hook
git config core.hooksPath .githooks || exit 1

# Create the develop branch
git checkout -b develop || exit 1
git push --set-upstream origin develop || exit 1

# If we get here, everything succeeded
echo "Successfully initialized repository for use with flow"

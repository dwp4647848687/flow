#! /bin/bash

# Make sure we are in a git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: This is not a git repository."
    exit 1
fi

# # Check that there are no uncommitted changes
if ! git diff --quiet; then
    echo "Error: There are uncommitted changes in the repository."
    exit 1
fi

# # Switch to the main branch
git checkout main
git pull

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
    if ! jq '.major' version.json; then
        echo "Error: version.json is missing the \"major\" field."
        exit 1
    fi
    if ! jq '.minor' version.json; then
        echo "Error: version.json is missing the \"minor\" field."
        exit 1
    fi
    if ! jq '.patch' version.json; then
        echo "Error: version.json is missing the \"patch\" field."
        exit 1
    fi
    # Check there are no extra fields
    if jq '. | keys' version.json | grep -q 'major' || jq '. | keys' version.json | grep -q 'minor' || jq '. | keys' version.json | grep -q 'patch'; then
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
mkdir .githooks
cat > .githooks/pre-commit << EOF
#!/bin/bash

# List of protected branches
protected_branches=("main" "develop")

# Get the current branch
current_branch=$(git symbolic-ref --short HEAD)

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
chmod +x .githooks/pre-commit

# Commit the changes, this needs to be done before we enable the hook
git add version.json changelog_release.md changelog_develop.md
git add .githooks/pre-commit
git commit -m "Initialise the repository for use with flow"
git push

# Tell git to use the custom hook
git config core.hooksPath .githooks

# # Create the develop branch
git checkout -b develop
git push --set-upstream origin develop

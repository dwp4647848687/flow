#!/bin/bash

# ------------------------------------------------------------
# Setup and teardown functions
# ------------------------------------------------------------
setup_test_env()
{
    # Create temporary directory
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    
    # Initialize git repository
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    
    # Create initial commit
    echo "Initial commit" > README.md
    git add README.md
    git commit -m "Initial commit"
    git branch -M main
}

teardown_test_env()
{
    cd - > /dev/null
    rm -rf "$TEST_DIR"
}

# ------------------------------------------------------------
# Assertion functions
# ------------------------------------------------------------
assert_branch_exists()
{
    local branch_name=$1
    if ! git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        echo "❌ Test failed: Branch '$branch_name' does not exist"
        exit 1
    fi
    echo "✅ Branch '$branch_name' exists"
}

assert_branch_not_exists()
{
    local branch_name=$1
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        echo "❌ Test failed: Branch '$branch_name' exists when it shouldn't"
        exit 1
    fi
    echo "✅ Branch '$branch_name' does not exist"
}

assert_version_is()
{
    local major=$1
    local minor=$2
    local patch=$3
    local current_major=$(jq '.major' version.json)
    local current_minor=$(jq '.minor' version.json)
    local current_patch=$(jq '.patch' version.json)
    
    if [ "$current_major" != "$major" ] || [ "$current_minor" != "$minor" ] || [ "$current_patch" != "$patch" ]; then
        echo "❌ Test failed: Version mismatch. Expected $major.$minor.$patch, got $current_major.$current_minor.$current_patch"
        exit 1
    fi
    echo "✅ Version is $major.$minor.$patch"
}

assert_file_exists()
{
    local file_path=$1
    if [ ! -f "$file_path" ]; then
        echo "❌ Test failed: File '$file_path' does not exist"
        exit 1
    fi
    echo "✅ File '$file_path' exists"
}

# ------------------------------------------------------------
# Getter functions
# ------------------------------------------------------------
get_current_branch_name()
{
    return $(git branch --show-current)
}

get_latest_commit_hash()
{
    return $(git rev-parse HEAD)
}

get_latest_commit_message()
{
    return $(git log -1 --pretty=%B)
}

get_commit_hash_n_back()
{
    local n=$1
    return $(git rev-parse HEAD~$n)
}

get_commit_message_for_hash()
{
    local hash=$1
    return $(git log -1 --pretty=%B $hash)
}


#!/bin/bash

# Flow - A Git Flow automation tool
# Version: 1.0.0

# Function to display help message
show_help() {
    echo "Flow - Git Flow automation tool"
    echo
    echo "Usage: flow <command> [options]"
    echo
    echo "Commands:"
    echo "  init                  Initialize repository for Git Flow"
    echo "  feature begin         Start a new feature"
    echo "  feature complete      Complete a feature"
    echo "  hotfix begin          Start a new hotfix"
    echo "  hotfix complete       Complete a hotfix"
    echo "  release begin         Start a new release"
    echo "  release complete      Complete a release"
    echo
    echo "For more information about a command, use: flow help <command>"
}

# Function to display command-specific help
show_command_help() {
    case "$1" in
        "init")
            echo "flow init"
            echo "Initializes your repository for Git Flow:"
            echo "- Creates the develop branch"
            echo "- Sets up changelog and version tracking"
            echo "- Configures Git hooks to protect main and develop branches"
            ;;
        "feature")
            echo "flow feature begin"
            echo "Starts a new feature:"
            echo "- Creates a new feature branch from develop"
            echo "- Prompts for feature name"
            echo
            echo "flow feature complete"
            echo "Completes a feature:"
            echo "- Rebases the feature branch onto develop"
            echo "- Updates the development changelog"
            echo "- Pushes the branch and changelog"
            echo "- Creates a pull request (PR) to merge the feature into develop"
            echo "- You must complete the PR merge and branch deletion via the GitHub UI or automation"
            ;;
        "hotfix")
            echo "flow hotfix begin"
            echo "Starts a new hotfix:"
            echo "- Creates a new hotfix branch from main"
            echo "- Prompts for hotfix name"
            echo
            echo "flow hotfix complete"
            echo "Completes a hotfix:"
            echo "- Rebases the hotfix branch onto main"
            echo "- Updates the release changelog and version"
            echo "- Pushes the branch and changelog/version"
            echo "- Creates pull requests (PRs) to merge the hotfix into main and develop"
            echo "- You must complete the PR merges and branch deletion via the GitHub UI or automation"
            ;;
        "release")
            echo "flow release begin"
            echo "Starts a new release:"
            echo "- Creates a new release branch"
            echo "- Prompts for version increment type"
            echo "- Updates changelogs"
            echo
            echo "flow release complete"
            echo "Completes a release:"
            echo "- Pushes the release branch"
            echo "- Creates a pull request (PR) to merge the release into main"
            echo "- You must complete the PR merge, create the release tag, and delete the branch via the GitHub UI or automation"
            ;;
        *)
            show_help
            ;;
    esac
}

print_version() {
    version_major=$(jq -r '.major' "$INSTALL_DIR/version.json")
    version_minor=$(jq -r '.minor' "$INSTALL_DIR/version.json")
    version_patch=$(jq -r '.patch' "$INSTALL_DIR/version.json")
    echo "Flow v$version_major.$version_minor.$version_patch"
}

# Check that git is installed
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed. Please install it using your package manager."
    exit 1
fi

# Check that jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed. Please install it using your package manager."
    exit 1
fi

# Check that the Github CLI is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed. Please install it using your package manager."
    exit 1
fi

# Get the directory where the script is located
if [ -L "$0" ]; then
    # If the script is a symlink, resolve it
    INSTALL_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" &> /dev/null && pwd )"
else
    # If the script is not a symlink
    INSTALL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

# Set working directory to repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ $? -ne 0 ]; then
    echo "Error: Not in a Git repository"
    exit 1
fi
cd "$REPO_ROOT"

# Main command processing
case "$1" in
    "init")
        "$INSTALL_DIR/scripts/initialise.sh"
        ;;
    "feature")
        case "$2" in
            "begin")
                "$INSTALL_DIR/scripts/begin_feature.sh"
                ;;
            "complete")
                "$INSTALL_DIR/scripts/complete_feature.sh"
                ;;
            *)
                echo "Error: Unknown feature command. Use 'flow help feature' for usage information."
                exit 1
                ;;
        esac
        ;;
    "hotfix")
        case "$2" in
            "begin")
                "$INSTALL_DIR/scripts/begin_hotfix.sh"
                ;;
            "complete")
                "$INSTALL_DIR/scripts/complete_hotfix.sh"
                ;;
            *)
                echo "Error: Unknown hotfix command. Use 'flow help hotfix' for usage information."
                exit 1
                ;;
        esac
        ;;
    "release")
        case "$2" in
            "begin")
                "$INSTALL_DIR/scripts/begin_release.sh"
                ;;
            "complete")
                "$INSTALL_DIR/scripts/complete_release.sh"
                ;;
        esac
        ;;
    "help")
        if [ -z "$2" ]; then
            show_help
        else
            show_command_help "$2"
        fi
        ;;
    "--version")
        print_version
        ;;
    *)
        echo "Error: Unknown command: $1"
        echo
        show_help
        exit 1
        ;;
esac

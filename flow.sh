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
            echo "- Merges the feature branch into develop"
            echo "- Updates the development changelog"
            ;;
        "hotfix")
            echo "flow hotfix begin"
            echo "Starts a new hotfix:"
            echo "- Creates a new hotfix branch from main"
            echo "- Prompts for hotfix name"
            echo
            echo "flow hotfix complete"
            echo "Completes a hotfix:"
            echo "- Merges the hotfix branch into main and develop"
            echo "- Updates the release changelog"
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
            echo "- Merges the release branch into main and develop"
            echo "- Creates a new tag"
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
        show_help
        exit 1
        ;;
esac

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
    echo "  release               Create a new release"
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
            echo "flow release"
            echo "Creates a new release:"
            echo "- Merges changes from develop into main"
            echo "- Prompts for version increment type"
            echo "- Updates changelogs"
            ;;
        *)
            show_help
            ;;
    esac
}

# Get the directory where the script is located
if [ -L "$0" ]; then
    # If the script is a symlink, resolve it
    SCRIPT_DIR="$( cd "$( dirname "$(readlink -f "$0")" )" &> /dev/null && pwd )"
else
    # If the script is not a symlink
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
fi

# Main command processing
case "$1" in
    "init")
        "$SCRIPT_DIR/scripts/initialise.sh"
        ;;
    "feature")
        case "$2" in
            "begin")
                "$SCRIPT_DIR/scripts/begin_feature.sh"
                ;;
            "complete")
                "$SCRIPT_DIR/scripts/complete_feature.sh"
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
                "$SCRIPT_DIR/scripts/begin_hotfix.sh"
                ;;
            "complete")
                "$SCRIPT_DIR/scripts/complete_hotfix.sh"
                ;;
            *)
                echo "Error: Unknown hotfix command. Use 'flow help hotfix' for usage information."
                exit 1
                ;;
        esac
        ;;
    "release")
        "$SCRIPT_DIR/scripts/do_release.sh"
        ;;
    "help")
        if [ -z "$2" ]; then
            show_help
        else
            show_command_help "$2"
        fi
        ;;
    *)
        show_help
        exit 1
        ;;
esac

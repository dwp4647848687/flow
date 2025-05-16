# Flow

A command-line tool that simplifies following the Git Flow branching model. Flow helps teams maintain a clean and organized Git workflow by automating common branching operations and enforcing best practices.

## Overview

Flow provides a simple interface for managing Git Flow operations, ensuring consistent branching patterns across your team. It automatically handles branch creation, merging, and changelog management while preventing direct commits to protected branches.

## Prerequisites

- Git 2.0 or higher
- Unix-like operating system (macOS, Linux)

## Installation

### Prerequisites
- Git 2.0 or higher
- Unix-like operating system (macOS, Linux)
- Root/sudo access for system-wide installation

### Quick Install
```bash
# Clone the repository
git clone https://github.com/yourusername/flow.git
cd flow

# Run the installation script
sudo ./install.sh
```

### What Gets Installed
The installation script will:
- Install Flow to `/usr/local/lib/flow`
- Create a symlink in `/usr/local/bin` for global access
- Set up all required scripts with proper permissions

### Verification
After installation, verify it works by running:
```bash
flow --help
```

### Git Hooks Configuration
When cloning an existing repository that uses Flow, you need to manually configure Git hooks to prevent direct commits to protected branches:
```bash
git config core.hooksPath .githooks
```
This ensures that the pre-commit hook is properly set up to protect the `main` and `develop` branches from direct commits.

### Uninstallation
To remove Flow from your system:
```bash
sudo rm -rf /usr/local/lib/flow /usr/local/bin/flow
```

### Troubleshooting
If you encounter permission issues:
1. Ensure you're using `sudo` for installation
2. Verify you have write permissions to `/usr/local`
3. Check that the installation script is executable (`chmod +x install.sh`)

## Usage

All commands are executed using the `flow` command followed by the operation:

```bash
flow <command> [options]
```

### Available Commands

#### Initialize Repository
```bash
flow init
```
Initializes your repository for Git Flow:
- Creates the `develop` branch
- Sets up changelog and version tracking
- Configures Git hooks to protect `main` and `develop` branches

#### Feature Management
```bash
flow feature begin    # Start a new feature
flow feature complete # Finish a feature
```

**Starting a Feature:**
- Creates a new feature branch from `develop`
- Prompts for feature name. Note a prefix of `feature/` will be added to the provided name.
- Automatically switches to the new branch

**Completing a Feature:**
- Merges the feature branch into `develop`
- Prompts for feature description
- Updates the development changelog
- Cleans up the feature branch

#### Hotfix Management
```bash
flow hotfix begin    # Start a new hotfix
flow hotfix complete # Finish a hotfix
```

**Starting a Hotfix**
- Creates a new hotfix branch from `main`
- Prompts for hotfix name. Note a prefix of `hotfix/` will be added to the provided name.
- Automatically switches to the new branch

**Completing a Hotfix**
- Merges the hotfix branch into both `main` and `develop`
- Prompts for hotfix description
- Increments the version patch number
- Updates the release changelog
- Cleans up the hotfix branch

#### Release Management
```bash
flow release begin    # Start a new release
flow release complete # Finish a release
```

**Starting a Release:**
- Creates a new release branch from `develop`
- Prompts for whether this is a major or minor release
- Increments the appropriate version number
- Moves changes from the development changelog to the release changelog
- Creates an initial commit with version and changelog updates

**Completing a Release:**
- Merges the release branch into both `main` and `develop`
- Creates and pushes a version tag
- Cleans up the release branch

The two-step release process allows for:
- Review of changelog changes before finalizing
- Additional commits to the release branch if needed

### Branch Naming

All branches follow a consistent naming pattern:

- Feature branches: `feature/<name>`
- Hotfix branches: `hotfix/<name>`
- Release branches: `release/<version>`

Branch names should:
- Use only alphanumeric characters, underscores, and hyphens
- Be descriptive but concise
- Not contain spaces or special characters

Examples:
```bash
feature/user-authentication
hotfix/login-crash
release/1.2.0
```
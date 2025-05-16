# Flow

A command-line tool that simplifies following the Git Flow branching model. Flow helps teams maintain a clean and organized Git workflow by automating common branching operations and enforcing best practices.

## Overview

Flow provides a simple interface for managing Git Flow operations, ensuring consistent branching patterns across your team. It automatically handles branch creation, merging, and changelog management while preventing direct commits to protected branches.

## Prerequisites

- Git 2.0 or higher
- Unix-like operating system (macOS, Linux)

## Installation

```bash
# Installation instructions will be added here
```

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
flow release
```
- Creates a temporary release branch from `develop`
- Prompts for whether this is a major or minor release, incrementing the appropriate version number
- Inserts changes in the active development changelog into release changelog
- Merges changes into `main`
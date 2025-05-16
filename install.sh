#!/bin/bash

# Flow installation script
# This script installs the Flow Git automation tool and its dependencies

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

# Define installation directories
INSTALL_DIR="/usr/local/lib/flow"
BIN_DIR="/usr/local/bin"
SCRIPTS_DIR="$INSTALL_DIR/scripts"

# Create necessary directories
echo "Creating installation directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$SCRIPTS_DIR"

# Copy the main script
echo "Installing main script..."
cp flow.sh "$INSTALL_DIR/flow.sh"
chmod 755 "$INSTALL_DIR/flow.sh"

# Create symlink in bin directory
echo "Creating symlink..."
ln -sf "$INSTALL_DIR/flow.sh" "$BIN_DIR/flow"

# Copy scripts directory
echo "Installing supporting scripts..."
cp -r scripts/* "$SCRIPTS_DIR/"
chmod -R 755 "$SCRIPTS_DIR"

echo "Installation complete!"
echo "You can now use the 'flow' command from anywhere."
echo "To uninstall, run: sudo rm -rf $INSTALL_DIR $BIN_DIR/flow" 
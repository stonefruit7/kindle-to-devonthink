#!/bin/bash
#
# Kindle to DEVONthink - Installer
#
# Sets up automatic highlight syncing when you plug in your Kindle.
# Highlights are imported directly into DEVONthink.
#

set -e

echo "Kindle to DEVONthink - Installer"
echo "================================"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
INSTALL_DIR="$HOME/.kindle-sync"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_NAME="com.user.kindle-sync.plist"

echo "This will install:"
echo "  Script:      $INSTALL_DIR/sync_highlights.py"
echo "  LaunchAgent: $LAUNCH_AGENTS_DIR/$PLIST_NAME"
echo ""
echo "Highlights will be imported into DEVONthink's inbox"
echo "in a group called 'Kindle Highlights'."
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "Creating directories..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$LAUNCH_AGENTS_DIR"

echo "Installing script..."
cp "$SCRIPT_DIR/sync_highlights.py" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/sync_highlights.py"

echo "Creating LaunchAgent..."
cat > "$LAUNCH_AGENTS_DIR/$PLIST_NAME" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.user.kindle-sync</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/python3</string>
        <string>$INSTALL_DIR/sync_highlights.py</string>
    </array>

    <key>StartOnMount</key>
    <true/>

    <key>WorkingDirectory</key>
    <string>$HOME</string>

    <key>StandardOutPath</key>
    <string>$HOME/.kindle-sync.log</string>

    <key>StandardErrorPath</key>
    <string>$HOME/.kindle-sync.log</string>
</dict>
</plist>
PLIST

echo "Loading LaunchAgent..."
launchctl unload "$LAUNCH_AGENTS_DIR/$PLIST_NAME" 2>/dev/null || true
launchctl load "$LAUNCH_AGENTS_DIR/$PLIST_NAME"

echo "Adding 'kindle-sync' shortcut..."
ALIAS_LINE='alias kindle-sync="python3 ~/.kindle-sync/sync_highlights.py"'
SHELL_RC="$HOME/.zshrc"

# Use .bashrc if zsh config doesn't exist
if [[ ! -f "$SHELL_RC" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

# Add alias if not already present
if ! grep -q "alias kindle-sync=" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# Kindle to DEVONthink" >> "$SHELL_RC"
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    echo "Added 'kindle-sync' alias to $SHELL_RC"
else
    echo "'kindle-sync' alias already exists in $SHELL_RC"
fi

echo ""
echo "Done!"
echo ""
echo "Now just plug in your Kindle - highlights will import"
echo "into DEVONthink automatically."
echo ""
echo "Manual sync:  kindle-sync  (restart Terminal first)"
echo "View log:     cat ~/.kindle-sync.log"
echo ""
echo "Uninstall:"
echo "  launchctl unload $LAUNCH_AGENTS_DIR/$PLIST_NAME"
echo "  rm -rf $INSTALL_DIR $LAUNCH_AGENTS_DIR/$PLIST_NAME"

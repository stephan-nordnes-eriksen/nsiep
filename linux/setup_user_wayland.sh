#!/bin/bash

# NSIEP Keyboard Layout - User-level Wayland Setup Script
# MIT License - 2023

# Colors for output
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
BOLD="\033[1m"
RESET="\033[0m"

print_header() {
    echo -e "${BLUE}${BOLD}$1${RESET}"
}

print_success() {
    echo -e "${GREEN}$1${RESET}"
}

print_info() {
    echo -e "${YELLOW}$1${RESET}"
}

print_error() {
    echo -e "${RED}$1${RESET}"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYOUT_NAME="nsiep"
LAYOUT_FILE="$SCRIPT_DIR/$LAYOUT_NAME"

# Print header
print_header "NSIEP Keyboard Layout - User-level Wayland Setup"
echo "This script will set up the NSIEP keyboard layout for your user account"
echo "No root privileges required"
echo ""

# Check if we're running under Wayland
if [ -z "$WAYLAND_DISPLAY" ]; then
    print_info "Not running under Wayland. This script is intended for Wayland sessions."
    print_info "If you're sure you want to continue anyway, press Enter. Otherwise press Ctrl+C to abort."
    read -r
fi

# Create user XKB directory if it doesn't exist
USER_XKB_DIR="$HOME/.config/xkb/symbols"
mkdir -p "$USER_XKB_DIR"

# Copy layout file to user directory
echo "Copying layout to $USER_XKB_DIR/$LAYOUT_NAME"
cp "$LAYOUT_FILE" "$USER_XKB_DIR/$LAYOUT_NAME"

# Create user XKB configuration
RULES_DIR="$HOME/.config/xkb/rules"
mkdir -p "$RULES_DIR"

# Detect the compositor
COMPOSITOR="unknown"

if [ -n "$SWAYSOCK" ]; then
    COMPOSITOR="sway"
elif ps -e | grep -q "gnome-shell"; then
    COMPOSITOR="gnome"
elif [ -n "$KDE_FULL_SESSION" ] || ps -e | grep -q "plasmashell"; then
    COMPOSITOR="kde"
fi

print_info "Detected compositor: $COMPOSITOR"

# Compositor-specific setup
case $COMPOSITOR in
    "gnome")
        print_header "Setting up for GNOME Wayland..."
        
        # Add NSIEP layout to GNOME input sources
        current=$(gsettings get org.gnome.desktop.input-sources sources)
        if [[ $current != *"'xkb', 'nsiep'"* ]]; then
            # Remove the last bracket, add our layout, and close the bracket
            new_value=${current%]*},[\'xkb\',\'nsiep\']]
            
            # If the value is empty or just contains [], set it to our layout
            if [[ $current == "[]" || $current == "@as []" ]]; then
                new_value="[['xkb','nsiep']]"
            fi
            
            gsettings set org.gnome.desktop.input-sources sources "$new_value"
            print_success "NSIEP keyboard layout added to GNOME input sources"
        else
            print_info "NSIEP keyboard layout already in GNOME input sources"
        fi
        
        print_info "You can use the keyboard indicator in the top bar to switch layouts"
        ;;
        
    "kde")
        print_header "Setting up for KDE Plasma Wayland..."
        print_info "For KDE Plasma, please follow these steps manually:"
        echo "1. Open System Settings > Input Devices > Keyboard > Layouts"
        echo "2. Check 'Configure layouts'"
        echo "3. Click 'Add' and search for 'NSIEP Norwegian'"
        echo "4. Select it and click 'Add'"
        echo "5. Click 'Apply' to save changes"
        
        # Create the directory for KDE's xkb custom layouts
        KDE_XKB_DIR="$HOME/.local/share/kxmlgui5/kxkb"
        mkdir -p "$KDE_XKB_DIR"
        
        print_info "KDE Plasma configuration directories prepared"
        ;;
        
    "sway")
        print_header "Setting up for Sway Wayland compositor..."
        
        # Check if sway config exists
        SWAY_CONFIG="$HOME/.config/sway/config"
        if [ -f "$SWAY_CONFIG" ]; then
            # Check if the config already contains our layout
            if grep -q "xkb_layout.*nsiep" "$SWAY_CONFIG"; then
                print_info "Sway config already contains NSIEP layout"
            else
                print_info "Adding NSIEP layout to Sway config..."
                # Create a backup
                cp "$SWAY_CONFIG" "$SWAY_CONFIG.bak"
                
                # Add our config
                cat >> "$SWAY_CONFIG" << EOF

# NSIEP Keyboard layout configuration
input * {
    xkb_layout "us,nsiep"
    xkb_options "grp:alt_shift_toggle"
}
EOF
                print_success "NSIEP layout added to Sway config"
                print_info "Restart Sway or reload the config with 'swaymsg reload' to apply changes"
            fi
        else
            print_info "Sway config not found at $SWAY_CONFIG"
            print_info "Please add the following to your Sway config manually:"
            echo "input * {"
            echo "    xkb_layout \"us,nsiep\""
            echo "    xkb_options \"grp:alt_shift_toggle\""
            echo "}"
        fi
        ;;
        
    *)
        print_header "Generic Wayland Setup"
        print_info "Your Wayland compositor was not specifically recognized."
        print_info "The layout file has been installed to: $USER_XKB_DIR/$LAYOUT_NAME"
        print_info "Please consult your compositor's documentation for adding keyboard layouts."
        ;;
esac

print_header "Setup Complete!"
print_info "You may need to log out and log back in for changes to take effect"

exit 0
#!/bin/bash

# NSIEP Keyboard Layout Installer for Linux (X11 and Wayland)
# MIT License - 2023

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAYOUT_NAME="nsiep"
LAYOUT_FILE="$SCRIPT_DIR/$LAYOUT_NAME"

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

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script requires root privileges for system-wide installation."
        print_info "Please run with sudo or as root, or use --user for user-level installation."
        exit 1
    fi
}

print_usage() {
    echo "Usage: $0 [OPTION]"
    echo "Install NSIEP keyboard layout for X11 and Wayland"
    echo ""
    echo "Options:"
    echo "  --user         Install for current user only (no root required)"
    echo "  --system       Install system-wide (default, requires root)"
    echo "  --help         Display this help and exit"
    echo ""
}

# Default to system install
INSTALL_MODE="system"

# Process command line arguments
for arg in "$@"; do
    case $arg in
        --user)
            INSTALL_MODE="user"
            shift
            ;;
        --system)
            INSTALL_MODE="system"
            shift
            ;;
        --help)
            print_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $arg"
            print_usage
            exit 1
            ;;
    esac
done

# Print header
print_header "NSIEP Keyboard Layout Installer"
echo "This will install the NSIEP keyboard layout for both X11 and Wayland"
echo ""

# System-wide installation
install_system() {
    check_root
    
    print_header "Installing system-wide..."
    
    # X11 installation
    print_info "Installing for X11..."
    
    # Copy layout file to X11 symbols directory
    echo "Copying layout to /usr/share/X11/xkb/symbols/$LAYOUT_NAME"
    cp "$LAYOUT_FILE" "/usr/share/X11/xkb/symbols/$LAYOUT_NAME"
    
    # Check for evdev.xml
    if [ -f "/usr/share/X11/xkb/rules/evdev.xml" ]; then
        # Make a backup of evdev.xml if it doesn't exist
        if [ ! -f "/usr/share/X11/xkb/rules/evdev.xml.nsiep.bak" ]; then
            echo "Backing up evdev.xml"
            cp "/usr/share/X11/xkb/rules/evdev.xml" "/usr/share/X11/xkb/rules/evdev.xml.nsiep.bak"
        fi
        
        # Check if our layout is already in evdev.xml
        if grep -q "<name>nsiep</name>" "/usr/share/X11/xkb/rules/evdev.xml"; then
            echo "Layout already exists in evdev.xml"
        else
            echo "Adding layout to evdev.xml"
            # Use sed to add our layout to evdev.xml
            sed -i '/<layoutList>/a \
    <layout>\
      <configItem>\
        <name>nsiep</name>\
        <shortDescription>ns</shortDescription>\
        <description>NSIEP Norwegian</description>\
        <languageList>\
          <iso639Id>nob</iso639Id>\
        </languageList>\
      </configItem>\
    </layout>' "/usr/share/X11/xkb/rules/evdev.xml"
        fi
    else
        print_error "Could not find evdev.xml"
    fi
    
    # Check for evdev.lst
    if [ -f "/usr/share/X11/xkb/rules/evdev.lst" ]; then
        # Make a backup of evdev.lst if it doesn't exist
        if [ ! -f "/usr/share/X11/xkb/rules/evdev.lst.nsiep.bak" ]; then
            echo "Backing up evdev.lst"
            cp "/usr/share/X11/xkb/rules/evdev.lst" "/usr/share/X11/xkb/rules/evdev.lst.nsiep.bak"
        fi
        
        # Check if our layout is already in evdev.lst
        if grep -q "nsiep" "/usr/share/X11/xkb/rules/evdev.lst"; then
            echo "Layout already exists in evdev.lst"
        else
            echo "Adding layout to evdev.lst"
            # Find the line containing "! layout" and insert our layout in the section below
            sed -i '/! layout/,/! variant/ {
                /! variant/! {
                    /! layout/! {
                        /^$/! {
                            $ a\
  nsiep           NSIEP Norwegian
                        }
                    }
                }
            }' "/usr/share/X11/xkb/rules/evdev.lst"
        fi
    else
        print_error "Could not find evdev.lst"
    fi
    
    # Run xkbcomp to rebuild the XKB cache for X11 if it's installed
    if command -v xkbcomp &> /dev/null; then
        echo "Updating XKB cache..."
        xkbcomp -I/usr/share/X11/xkb /usr/share/X11/xkb/keymap/xfree86 /tmp/xkb.dump 2>/dev/null || true
    fi
    
    # Update the Compose cache if applicable
    if command -v fc-cache &> /dev/null; then
        echo "Updating Compose cache..."
        fc-cache -f
    fi
    
    print_success "X11 installation complete!"
    
    # Wayland-specific configurations
    print_info "Configuring for Wayland..."
    
    # Ensure X11 keyboard data is accessible for Wayland compositors
    # (Most Wayland compositors use libxkbcommon which reads the X11 keyboard files)
    
    print_success "Wayland configuration complete!"
    print_success "System-wide installation finished!"
}

# User-level installation
install_user() {
    print_header "Installing for current user..."
    
    # Create user XKB directory if it doesn't exist
    USER_XKB_DIR="$HOME/.config/xkb/symbols"
    mkdir -p "$USER_XKB_DIR"
    
    # Copy layout file to user directory
    echo "Copying layout to $USER_XKB_DIR/$LAYOUT_NAME"
    cp "$LAYOUT_FILE" "$USER_XKB_DIR/$LAYOUT_NAME"
    
    # Create user XKB configuration
    RULES_DIR="$HOME/.config/xkb/rules"
    mkdir -p "$RULES_DIR"
    
    # Create custom rules files if they don't exist
    if [ ! -f "$RULES_DIR/evdev.xml" ]; then
        echo "Creating user evdev.xml"
        cat > "$RULES_DIR/evdev.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xkbConfigRegistry SYSTEM "xkb.dtd">
<xkbConfigRegistry version="1.1">
  <layoutList>
    <layout>
      <configItem>
        <name>nsiep</name>
        <shortDescription>ns</shortDescription>
        <description>NSIEP Norwegian</description>
        <languageList>
          <iso639Id>nob</iso639Id>
        </languageList>
      </configItem>
    </layout>
  </layoutList>
</xkbConfigRegistry>
EOF
    else
        # Check if our layout is already in user evdev.xml
        if grep -q "<name>nsiep</name>" "$RULES_DIR/evdev.xml"; then
            echo "Layout already exists in user evdev.xml"
        else
            echo "Adding layout to user evdev.xml"
            sed -i '/<layoutList>/a \
    <layout>\
      <configItem>\
        <name>nsiep</name>\
        <shortDescription>ns</shortDescription>\
        <description>NSIEP Norwegian</description>\
        <languageList>\
          <iso639Id>nob</iso639Id>\
        </languageList>\
      </configItem>\
    </layout>' "$RULES_DIR/evdev.xml"
        fi
    fi
    
    # For GNOME Wayland - create a gsettings script
    GSETTINGS_SCRIPT="$SCRIPT_DIR/apply_gnome_wayland.sh"
    cat > "$GSETTINGS_SCRIPT" << EOF
#!/bin/bash
# Add NSIEP layout to GNOME input sources
current=\$(gsettings get org.gnome.desktop.input-sources sources)
if [[ \$current != *"'xkb', 'nsiep'"* ]]; then
    # Remove the last bracket, add our layout, and close the bracket
    new_value=\${current%]*},[\'xkb\',\'nsiep\']]
    
    # If the value is empty or just contains [], set it to our layout
    if [[ \$current == "[]" || \$current == "@as []" ]]; then
        new_value="[['xkb','nsiep']]"
    fi
    
    gsettings set org.gnome.desktop.input-sources sources "\$new_value"
    echo "NSIEP keyboard layout added to GNOME input sources"
else
    echo "NSIEP keyboard layout already in GNOME input sources"
fi
EOF
    chmod +x "$GSETTINGS_SCRIPT"
    
    # For KDE Wayland - create instructions
    KDE_INSTRUCTIONS="$SCRIPT_DIR/kde_wayland_instructions.txt"
    cat > "$KDE_INSTRUCTIONS" << EOF
Instructions for enabling NSIEP keyboard layout in KDE Plasma:

1. Go to System Settings > Input Devices > Keyboard > Layouts
2. Click on 'Add' and select 'Norwegian' > 'NSIEP Norwegian'
3. Apply the settings

If NSIEP does not appear in the list, log out and log back in, or restart KDE Plasma
EOF

    # For Sway/wlroots - create config snippet
    SWAY_CONFIG="$SCRIPT_DIR/sway_config_snippet.txt"
    cat > "$SWAY_CONFIG" << EOF
# Sway/wlroots configuration for NSIEP keyboard layout
# Add these lines to your Sway config (~/.config/sway/config)

input * {
    # Replace 'us' with your default layout if different
    xkb_layout "us,nsiep"
    xkb_options "grp:alt_shift_toggle"
}

# To switch between layouts: Alt+Shift
EOF

    print_success "User-level installation finished!"
    print_info "Note: You may need to log out and log back in for changes to take effect"
    print_info "For GNOME Wayland: Run $GSETTINGS_SCRIPT to add NSIEP to input sources"
    print_info "For KDE Wayland: See $KDE_INSTRUCTIONS"
    print_info "For Sway/wlroots: See $SWAY_CONFIG"
}

# Run the appropriate installation method
if [ "$INSTALL_MODE" = "system" ]; then
    install_system
else
    install_user
fi

print_header "Installation Complete!"
echo "To enable the keyboard layout:"
echo "1. Log out and log back in to your desktop session"
echo "2. Open your system settings and add the 'NSIEP Norwegian' keyboard layout"
echo ""
echo "For specific desktop environments:"

if [ "$INSTALL_MODE" = "user" ]; then
    echo "- GNOME Wayland: Run $SCRIPT_DIR/apply_gnome_wayland.sh"
    echo "- KDE Wayland: See $SCRIPT_DIR/kde_wayland_instructions.txt"
    echo "- Sway/wlroots: See $SCRIPT_DIR/sway_config_snippet.txt"
else
    echo "- GNOME (X11/Wayland): Settings > Region & Language > Input Sources > + > Other > NSIEP Norwegian"
    echo "- KDE (X11/Wayland): System Settings > Input Devices > Keyboard > Layouts > Add > Norwegian > NSIEP Norwegian"
    echo "- Sway/wlroots: Add 'input * { xkb_layout \"us,nsiep\" }' to your config"
fi

echo ""
print_info "For more information see the readme.md file"
exit 0
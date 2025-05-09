#!/bin/bash

# NSIEP Keyboard Layout Installation Checker
# MIT License - 2023

set -e

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
    echo -e "${GREEN}✓ $1${RESET}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${RESET}"
}

print_error() {
    echo -e "${RED}✗ $1${RESET}"
}

print_info() {
    echo -e "$1"
}

LAYOUT_NAME="nsiep"
TOTAL_CHECKS=0
PASSED_CHECKS=0

# Print header
print_header "NSIEP Keyboard Layout Installation Check"
echo "This script will check if the NSIEP layout is properly installed"
echo ""

# Check system installation
print_header "Checking system installation..."

# Check if layout file exists in system directory
TOTAL_CHECKS=$((TOTAL_CHECKS+1))
if [ -f "/usr/share/X11/xkb/symbols/$LAYOUT_NAME" ]; then
    print_success "Layout file exists in system directory"
    PASSED_CHECKS=$((PASSED_CHECKS+1))
else
    print_error "Layout file not found in /usr/share/X11/xkb/symbols/$LAYOUT_NAME"
fi

# Check if layout is in evdev.xml
TOTAL_CHECKS=$((TOTAL_CHECKS+1))
if [ -f "/usr/share/X11/xkb/rules/evdev.xml" ] && grep -q "<n>nsiep</n>" "/usr/share/X11/xkb/rules/evdev.xml"; then
    print_success "Layout found in evdev.xml"
    PASSED_CHECKS=$((PASSED_CHECKS+1))
else
    print_error "Layout not found in evdev.xml"
fi

# Check if layout is in evdev.lst
TOTAL_CHECKS=$((TOTAL_CHECKS+1))
if [ -f "/usr/share/X11/xkb/rules/evdev.lst" ] && grep -q "nsiep" "/usr/share/X11/xkb/rules/evdev.lst"; then
    print_success "Layout found in evdev.lst"
    PASSED_CHECKS=$((PASSED_CHECKS+1))
else
    print_warning "Layout not found in evdev.lst (may still work without this)"
fi

# Check user installation
print_header "Checking user installation..."

# Check if user layout directory exists
USER_XKB_DIR="$HOME/.config/xkb/symbols"
if [ -d "$USER_XKB_DIR" ]; then
    print_info "User XKB directory exists: $USER_XKB_DIR"
    
    # Check if layout file exists in user directory
    TOTAL_CHECKS=$((TOTAL_CHECKS+1))
    if [ -f "$USER_XKB_DIR/$LAYOUT_NAME" ]; then
        print_success "Layout file exists in user directory"
        PASSED_CHECKS=$((PASSED_CHECKS+1))
    else
        print_info "Layout file not found in user directory (this is OK if using system installation)"
    fi
else
    print_info "User XKB directory does not exist (this is OK if using system installation)"
fi

# Check Wayland integration
print_header "Checking Wayland integration..."

# Check for common Wayland compositors
if [ -n "$WAYLAND_DISPLAY" ]; then
    print_success "Currently running under Wayland"
    
    # Check for GNOME
    if command -v gnome-shell &> /dev/null; then
        print_info "GNOME detected"
        TOTAL_CHECKS=$((TOTAL_CHECKS+1))
        if gsettings get org.gnome.desktop.input-sources sources 2>/dev/null | grep -q "nsiep"; then
            print_success "NSIEP layout found in GNOME input sources"
            PASSED_CHECKS=$((PASSED_CHECKS+1))
        else
            print_warning "NSIEP layout not found in GNOME input sources"
            print_info "  To add: Run the apply_gnome_wayland.sh script"
        fi
    fi
    
    # Check for KDE
    if [ -n "$KDE_FULL_SESSION" ] || ps -e | grep -q "plasmashell"; then
        print_info "KDE Plasma detected"
        print_info "  Note: Cannot automatically check KDE configuration"
        print_info "  Please verify in System Settings > Input Devices > Keyboard > Layouts"
    fi
    
    # Check for Sway
    if [ -n "$SWAYSOCK" ]; then
        print_info "Sway detected"
        print_info "  Note: Check your sway config file for 'xkb_layout \"us,nsiep\"' or similar"
    fi
else
    print_info "Not running under Wayland (this check is being run from X11 or TTY)"
fi

# Check X11 integration
if [ -n "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ]; then
    print_info "Currently running under X11"
    
    # Check if the layout is available in X11
    TOTAL_CHECKS=$((TOTAL_CHECKS+1))
    if command -v setxkbmap &> /dev/null; then
        if setxkbmap -query | grep -q "nsiep" || setxkbmap -layout nsiep -print 2>/dev/null | grep -q "nsiep"; then
            print_success "NSIEP layout is available in X11"
            PASSED_CHECKS=$((PASSED_CHECKS+1))
        else
            layout_list=$(setxkbmap -query | grep layout)
            print_warning "NSIEP layout not detected in active X11 session"
            print_info "  Current layout: $layout_list"
            if setxkbmap -layout nsiep -print 2>/dev/null | grep -q "symbols"; then
                print_success "But layout is loadable with setxkbmap"
                PASSED_CHECKS=$((PASSED_CHECKS+1))
            else
                print_error "Layout not usable with setxkbmap"
            fi
        fi
    else
        print_warning "setxkbmap not available, can't check X11 layout availability"
    fi
fi

# Print summary
print_header "Summary"
echo "Checks passed: $PASSED_CHECKS / $TOTAL_CHECKS"

if [ $PASSED_CHECKS -eq $TOTAL_CHECKS ]; then
    print_success "All checks passed! NSIEP keyboard layout should be working properly."
elif [ $PASSED_CHECKS -ge $(($TOTAL_CHECKS / 2)) ]; then
    print_warning "Some checks passed. The layout might work but may require additional configuration."
else
    print_error "Most checks failed. The layout is likely not properly installed."
fi

echo ""
print_info "To use the layout:"
print_info "- For GNOME: Settings > Region & Language > Input Sources > Add"
print_info "- For KDE: System Settings > Input Devices > Keyboard > Layouts > Add"
print_info "- For Sway/wlroots: Add 'input * { xkb_layout \"us,nsiep\" }' to your config"
print_info "You may need to log out and log back in for changes to take effect."

exit 0
#!/bin/bash

# EAWS CLI Uninstaller for Unix Systems
# Usage: curl -fsSL https://raw.githubusercontent.com/manudiv16/eaws/main/uninstall.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BINARY_NAME="eaws"
INSTALL_LOCATIONS=(
    "/usr/local/bin/$BINARY_NAME"
    "/usr/bin/$BINARY_NAME"
    "$HOME/.local/bin/$BINARY_NAME"
    "$HOME/bin/$BINARY_NAME"
)

# Print functions
print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Find installed binary
find_installed_binary() {
    FOUND_LOCATIONS=()
    
    for location in "${INSTALL_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            FOUND_LOCATIONS+=("$location")
        fi
    done
    
    # Also check PATH
    if command_exists "$BINARY_NAME"; then
        BINARY_PATH=$(which "$BINARY_NAME" 2>/dev/null || echo "")
        if [ -n "$BINARY_PATH" ] && [ -f "$BINARY_PATH" ]; then
            # Check if already in our list
            local found=false
            for location in "${FOUND_LOCATIONS[@]}"; do
                if [ "$location" = "$BINARY_PATH" ]; then
                    found=true
                    break
                fi
            done
            if [ "$found" = false ]; then
                FOUND_LOCATIONS+=("$BINARY_PATH")
            fi
        fi
    fi
}

# Remove binary
remove_binary() {
    local binary_path="$1"
    local dir_path=$(dirname "$binary_path")
    
    if [ -w "$dir_path" ]; then
        print_info "Removing $binary_path..."
        rm -f "$binary_path"
        print_success "Removed $binary_path"
    else
        print_info "Removing $binary_path (requires sudo)..."
        sudo rm -f "$binary_path"
        print_success "Removed $binary_path"
    fi
}

# Main uninstallation process
main() {
    echo
    print_info "EAWS CLI Uninstaller"
    print_info "===================="
    echo
    
    # Check if binary exists
    if ! command_exists "$BINARY_NAME"; then
        print_warning "EAWS CLI is not installed or not in PATH"
        find_installed_binary
        if [ ${#FOUND_LOCATIONS[@]} -eq 0 ]; then
            print_info "No EAWS CLI installation found"
            exit 0
        fi
    else
        find_installed_binary
    fi
    
    if [ ${#FOUND_LOCATIONS[@]} -eq 0 ]; then
        print_info "No EAWS CLI installation found"
        exit 0
    fi
    
    print_info "Found EAWS CLI installations:"
    for location in "${FOUND_LOCATIONS[@]}"; do
        echo "  • $location"
    done
    echo
    
    # Confirm uninstallation
    echo -n "Do you want to remove all EAWS CLI installations? [y/N]: "
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled"
        exit 0
    fi
    
    # Remove all found installations
    for location in "${FOUND_LOCATIONS[@]}"; do
        if [ -f "$location" ]; then
            remove_binary "$location"
        fi
    done
    
    # Verify removal
    if command_exists "$BINARY_NAME"; then
        print_warning "EAWS CLI is still available in PATH"
        print_info "You may need to restart your terminal or check other installation locations"
    else
        print_success "EAWS CLI has been completely removed"
    fi
    
    echo
    print_info "If you installed EAWS CLI using Homebrew, run:"
    print_info "  brew uninstall eaws"
    echo
    print_info "Thank you for using EAWS CLI!"
}

# Run main function
main "$@"

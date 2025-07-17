#!/bin/bash

# EAWS CLI Installer for Unix Systems (macOS and Linux)
# Usage: curl -fsSL https://raw.githubusercontent.com/manudiv16/eaws-go/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_OWNER="manudiv16"
REPO_NAME="eaws-go"
BINARY_NAME="eaws"
INSTALL_DIR="/usr/local/bin"
GITHUB_RELEASES_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"

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

# Detect OS and architecture
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OS="darwin"
            ;;
        Linux)
            OS="linux"
            ;;
        *)
            print_error "Unsupported operating system: $(uname -s)"
            exit 1
            ;;
    esac
}

detect_arch() {
    case "$(uname -m)" in
        x86_64 | amd64)
            ARCH="amd64"
            ;;
        arm64 | aarch64)
            ARCH="arm64"
            ;;
        *)
            print_error "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command_exists curl; then
        print_error "curl is required but not installed. Please install curl and try again."
        exit 1
    fi
    
    if ! command_exists tar; then
        print_error "tar is required but not installed. Please install tar and try again."
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Get latest release version
get_latest_version() {
    print_info "Fetching latest release version..."
    
    if command_exists jq; then
        VERSION=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | jq -r '.tag_name')
    else
        VERSION=$(curl -s "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    fi
    
    if [ -z "$VERSION" ] || [ "$VERSION" = "null" ]; then
        print_error "Failed to get latest version"
        exit 1
    fi
    
    print_success "Latest version: $VERSION"
}

# Download and install binary
download_and_install() {
    BINARY_FILE="${BINARY_NAME}-${OS}-${ARCH}"
    if [ "$OS" = "darwin" ] && [ "$ARCH" = "amd64" ]; then
        BINARY_FILE="${BINARY_NAME}-darwin-amd64"
    elif [ "$OS" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
        BINARY_FILE="${BINARY_NAME}-darwin-arm64"
    elif [ "$OS" = "linux" ] && [ "$ARCH" = "amd64" ]; then
        BINARY_FILE="${BINARY_NAME}-linux-amd64"
    fi
    
    DOWNLOAD_URL="${GITHUB_RELEASES_URL}/download/${VERSION}/${BINARY_FILE}"
    
    print_info "Downloading ${BINARY_FILE}..."
    print_info "URL: $DOWNLOAD_URL"
    
    # Create temporary directory
    TMP_DIR=$(mktemp -d)
    cd "$TMP_DIR"
    
    # Download binary
    if ! curl -fsSL "$DOWNLOAD_URL" -o "$BINARY_FILE"; then
        print_error "Failed to download binary from $DOWNLOAD_URL"
        print_info "Available releases: $GITHUB_RELEASES_URL"
        exit 1
    fi
    
    # Make binary executable
    chmod +x "$BINARY_FILE"
    
    # Check if we need sudo for installation
    if [ -w "$INSTALL_DIR" ]; then
        print_info "Installing to $INSTALL_DIR..."
        mv "$BINARY_FILE" "$INSTALL_DIR/$BINARY_NAME"
    else
        print_info "Installing to $INSTALL_DIR (requires sudo)..."
        sudo mv "$BINARY_FILE" "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    # Clean up
    cd - > /dev/null
    rm -rf "$TMP_DIR"
    
    print_success "Binary installed to $INSTALL_DIR/$BINARY_NAME"
}

# Verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if command_exists "$BINARY_NAME"; then
        VERSION_OUTPUT=$("$BINARY_NAME" --version 2>/dev/null || echo "version check failed")
        print_success "Installation successful!"
        print_info "Version: $VERSION_OUTPUT"
        print_info "Location: $(which $BINARY_NAME)"
    else
        print_error "Installation failed. Binary not found in PATH."
        print_info "Make sure $INSTALL_DIR is in your PATH"
        exit 1
    fi
}

# Print usage information
print_usage() {
    echo
    print_info "EAWS CLI has been installed successfully!"
    echo
    echo "Usage examples:"
    echo "  $BINARY_NAME --help                 # Show help"
    echo "  $BINARY_NAME container list         # List ECS containers"
    echo "  $BINARY_NAME container connect      # Connect to container"
    echo "  $BINARY_NAME logs query             # Query CloudWatch logs"
    echo "  $BINARY_NAME pipeline               # Show pipeline status"
    echo
    echo "For more information, visit: https://github.com/${REPO_OWNER}/${REPO_NAME}"
}

# Main installation process
main() {
    echo
    print_info "EAWS CLI Installer"
    print_info "===================="
    echo
    
    # Check if already installed
    if command_exists "$BINARY_NAME"; then
        CURRENT_VERSION=$("$BINARY_NAME" --version 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n1 || echo "unknown")
        print_warning "EAWS CLI is already installed (version: $CURRENT_VERSION)"
        echo -n "Do you want to update it? [y/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled"
            exit 0
        fi
    fi
    
    detect_os
    detect_arch
    check_dependencies
    get_latest_version
    download_and_install
    verify_installation
    print_usage
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"

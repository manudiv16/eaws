#!/bin/bash

# Local development installer for EAWS CLI
# This script builds and installs EAWS CLI locally for development

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BINARY_NAME="eaws"
INSTALL_DIR="/usr/local/bin"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command_exists go; then
        print_error "Go is required but not installed. Please install Go and try again."
        print_info "Visit: https://golang.org/doc/install"
        exit 1
    fi
    
    if ! command_exists make; then
        print_error "make is required but not installed. Please install make and try again."
        exit 1
    fi
    
    print_success "All dependencies are available"
}

# Build binary
build_binary() {
    print_info "Building EAWS CLI..."
    
    cd "$PROJECT_DIR"
    
    # Clean previous builds
    make clean
    
    # Build binary
    if ! make build; then
        print_error "Failed to build EAWS CLI"
        exit 1
    fi
    
    print_success "Build completed successfully"
}

# Install binary
install_binary() {
    print_info "Installing EAWS CLI..."
    
    cd "$PROJECT_DIR"
    
    # Check if we can write to install directory
    if [ -w "$INSTALL_DIR" ]; then
        cp "$BINARY_NAME" "$INSTALL_DIR/"
    else
        print_info "Installing to $INSTALL_DIR (requires sudo)..."
        sudo cp "$BINARY_NAME" "$INSTALL_DIR/"
    fi
    
    # Make sure it's executable
    if [ -w "$INSTALL_DIR" ]; then
        chmod +x "$INSTALL_DIR/$BINARY_NAME"
    else
        sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    print_success "EAWS CLI installed to $INSTALL_DIR/$BINARY_NAME"
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

# Setup development environment
setup_dev_environment() {
    print_info "Setting up development environment..."
    
    cd "$PROJECT_DIR"
    
    # Install Go dependencies
    print_info "Installing Go dependencies..."
    go mod download
    go mod tidy
    
    # Run tests if available
    if [ -f "go.mod" ]; then
        print_info "Running tests..."
        go test ./... || print_warning "Some tests failed"
    fi
    
    print_success "Development environment ready"
}

# Create development symlink
create_dev_symlink() {
    print_info "Creating development symlink..."
    
    DEV_BINARY="$PROJECT_DIR/$BINARY_NAME"
    
    if [ ! -f "$DEV_BINARY" ]; then
        print_error "Binary not found at $DEV_BINARY"
        exit 1
    fi
    
    # Remove existing installation if any
    if [ -f "$INSTALL_DIR/$BINARY_NAME" ]; then
        if [ -w "$INSTALL_DIR" ]; then
            rm -f "$INSTALL_DIR/$BINARY_NAME"
        else
            sudo rm -f "$INSTALL_DIR/$BINARY_NAME"
        fi
    fi
    
    # Create symlink
    if [ -w "$INSTALL_DIR" ]; then
        ln -sf "$DEV_BINARY" "$INSTALL_DIR/$BINARY_NAME"
    else
        sudo ln -sf "$DEV_BINARY" "$INSTALL_DIR/$BINARY_NAME"
    fi
    
    print_success "Development symlink created: $INSTALL_DIR/$BINARY_NAME -> $DEV_BINARY"
}

# Print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --dev-symlink    Create a symlink for development (auto-updates)"
    echo "  --build-only     Only build, don't install"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0                    # Build and install"
    echo "  $0 --dev-symlink      # Build and create development symlink"
    echo "  $0 --build-only       # Only build the binary"
}

# Main installation process
main() {
    local dev_symlink=false
    local build_only=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dev-symlink)
                dev_symlink=true
                shift
                ;;
            --build-only)
                build_only=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    echo
    print_info "EAWS CLI Local Installer"
    print_info "========================"
    echo
    
    check_dependencies
    setup_dev_environment
    build_binary
    
    if [ "$build_only" = true ]; then
        print_success "Build completed. Binary available at: $PROJECT_DIR/$BINARY_NAME"
        exit 0
    fi
    
    if [ "$dev_symlink" = true ]; then
        create_dev_symlink
    else
        install_binary
    fi
    
    verify_installation
    
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
    
    if [ "$dev_symlink" = true ]; then
        print_info "Development mode: The binary will auto-update when you rebuild"
        print_info "To rebuild: cd $PROJECT_DIR && make build"
    fi
    
    print_success "Installation completed successfully!"
}

# Run main function
main "$@"

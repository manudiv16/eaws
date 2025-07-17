#!/bin/bash

# EAWS CLI Completion Setup Script
# This script helps set up shell completion for the EAWS CLI

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Detect shell
detect_shell() {
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_TYPE="zsh"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_TYPE="bash"
    else
        SHELL_TYPE=$(basename "$SHELL")
    fi
}

# Setup completion for zsh
setup_zsh_completion() {
    print_info "Setting up zsh completion..."
    
    # Find zsh functions directory
    local zsh_functions_dir=""
    for dir in "/opt/homebrew/share/zsh/site-functions" "/usr/local/share/zsh/site-functions" "/usr/share/zsh/site-functions"; do
        if [ -d "$dir" ]; then
            zsh_functions_dir="$dir"
            break
        fi
    done
    
    if [ -z "$zsh_functions_dir" ]; then
        print_warning "System zsh functions directory not found, using user directory"
        zsh_functions_dir="$HOME/.zsh/completions"
        mkdir -p "$zsh_functions_dir"
        
        # Add to fpath if not already there
        if [ -f "$HOME/.zshrc" ]; then
            if ! grep -q "fpath=(.*$zsh_functions_dir" "$HOME/.zshrc"; then
                echo "" >> "$HOME/.zshrc"
                echo "# EAWS CLI completion" >> "$HOME/.zshrc"
                echo "fpath=(~/.zsh/completions \$fpath)" >> "$HOME/.zshrc"
                echo "autoload -U compinit && compinit" >> "$HOME/.zshrc"
                print_info "Added completion setup to .zshrc"
            fi
        fi
    fi
    
    # Generate and install completion
    if command -v eaws >/dev/null 2>&1; then
        print_info "Generating completion script..."
        eaws completion zsh > "$zsh_functions_dir/_eaws"
        print_success "Completion installed to $zsh_functions_dir/_eaws"
    else
        print_error "eaws command not found. Please install eaws first."
        return 1
    fi
    
    # Check if completion is already configured
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "autoload -U compinit" "$HOME/.zshrc"; then
            echo "" >> "$HOME/.zshrc"
            echo "# Enable completion system" >> "$HOME/.zshrc"
            echo "autoload -U compinit && compinit" >> "$HOME/.zshrc"
            print_info "Added compinit to .zshrc"
        fi
    fi
    
    print_success "Zsh completion setup complete!"
    print_info "Please restart your terminal or run: source ~/.zshrc"
}

# Setup completion for bash
setup_bash_completion() {
    print_info "Setting up bash completion..."
    
    # Find bash completion directory
    local bash_completion_dir=""
    for dir in "/opt/homebrew/etc/bash_completion.d" "/usr/local/etc/bash_completion.d" "/etc/bash_completion.d"; do
        if [ -d "$dir" ]; then
            bash_completion_dir="$dir"
            break
        fi
    done
    
    if [ -z "$bash_completion_dir" ]; then
        print_warning "System bash completion directory not found, using user directory"
        bash_completion_dir="$HOME/.bash_completion.d"
        mkdir -p "$bash_completion_dir"
        
        # Add to bashrc if not already there
        if [ -f "$HOME/.bashrc" ]; then
            if ! grep -q "source.*bash_completion.d" "$HOME/.bashrc"; then
                echo "" >> "$HOME/.bashrc"
                echo "# EAWS CLI completion" >> "$HOME/.bashrc"
                echo "for f in ~/.bash_completion.d/*; do source \$f; done" >> "$HOME/.bashrc"
                print_info "Added completion setup to .bashrc"
            fi
        fi
    fi
    
    # Generate and install completion
    if command -v eaws >/dev/null 2>&1; then
        print_info "Generating completion script..."
        eaws completion bash > "$bash_completion_dir/eaws"
        print_success "Completion installed to $bash_completion_dir/eaws"
    else
        print_error "eaws command not found. Please install eaws first."
        return 1
    fi
    
    print_success "Bash completion setup complete!"
    print_info "Please restart your terminal or run: source ~/.bashrc"
}

# Test completion
test_completion() {
    print_info "Testing completion setup..."
    
    # Test if completion works
    if command -v eaws >/dev/null 2>&1; then
        print_info "Testing basic completion..."
        # This would require interactive testing, so we just check if files exist
        case "$SHELL_TYPE" in
            zsh)
                if [ -f "/opt/homebrew/share/zsh/site-functions/_eaws" ] || [ -f "$HOME/.zsh/completions/_eaws" ]; then
                    print_success "Completion files found"
                else
                    print_error "Completion files not found"
                fi
                ;;
            bash)
                if [ -f "/opt/homebrew/etc/bash_completion.d/eaws" ] || [ -f "$HOME/.bash_completion.d/eaws" ]; then
                    print_success "Completion files found"
                else
                    print_error "Completion files not found"
                fi
                ;;
        esac
    else
        print_error "eaws command not found"
    fi
}

# Print usage
print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  --shell SHELL    Force shell type (zsh|bash)"
    echo "  --test           Test completion setup"
    echo "  --help           Show this help message"
    echo
    echo "Examples:"
    echo "  $0               # Auto-detect shell and setup completion"
    echo "  $0 --shell zsh   # Force zsh completion setup"
    echo "  $0 --test        # Test completion setup"
}

# Main function
main() {
    local force_shell=""
    local test_mode=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --shell)
                force_shell="$2"
                shift 2
                ;;
            --test)
                test_mode=true
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
    print_info "EAWS CLI Completion Setup"
    print_info "========================="
    echo
    
    # Detect or use forced shell
    if [ -n "$force_shell" ]; then
        SHELL_TYPE="$force_shell"
        print_info "Using forced shell: $SHELL_TYPE"
    else
        detect_shell
        print_info "Detected shell: $SHELL_TYPE"
    fi
    
    # Test mode
    if [ "$test_mode" = true ]; then
        test_completion
        exit 0
    fi
    
    # Setup completion based on shell
    case "$SHELL_TYPE" in
        zsh)
            setup_zsh_completion
            ;;
        bash)
            setup_bash_completion
            ;;
        *)
            print_error "Unsupported shell: $SHELL_TYPE"
            print_info "Supported shells: zsh, bash"
            exit 1
            ;;
    esac
    
    echo
    print_success "Completion setup completed!"
    echo
    print_info "To test completion, try:"
    echo "  eaws <TAB>          # List available commands"
    echo "  eaws container <TAB> # List container subcommands"
    echo "  eaws --<TAB>        # List available flags"
    echo
    print_info "If completion doesn't work immediately, try:"
    echo "  source ~/.${SHELL_TYPE}rc"
    echo "  # or restart your terminal"
}

# Run main function
main "$@"

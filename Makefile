# Makefile for EAWS

# Variables
BINARY_NAME=eaws
BINARY_PATH=./$(BINARY_NAME)
GO_FILES=$(shell find . -name "*.go" -type f)
VERSION=$(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(shell date -u +"%Y-%m-%dT%H:%M:%SZ")

# Build flags
LDFLAGS=-ldflags="-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildTime=$(BUILD_TIME)"

# Install directory
INSTALL_DIR=/usr/local/bin

# Release directory
RELEASE_DIR=./releases

# Default target
.PHONY: all
all: build

# Build the binary
.PHONY: build
build:
	go build $(LDFLAGS) -o $(BINARY_NAME) .

# Build for multiple platforms
.PHONY: build-all
build-all: build-linux build-macos build-windows

.PHONY: build-linux
build-linux:
	GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY_NAME)-linux-amd64 .

.PHONY: build-macos
build-macos:
	GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY_NAME)-darwin-amd64 .
	GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o $(BINARY_NAME)-darwin-arm64 .

.PHONY: build-windows
build-windows:
	GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o $(BINARY_NAME)-windows-amd64.exe .

# Create release builds
.PHONY: release
release: clean build-all
	mkdir -p $(RELEASE_DIR)
	cp $(BINARY_NAME)-linux-amd64 $(RELEASE_DIR)/
	cp $(BINARY_NAME)-darwin-amd64 $(RELEASE_DIR)/
	cp $(BINARY_NAME)-darwin-arm64 $(RELEASE_DIR)/
	cp $(BINARY_NAME)-windows-amd64.exe $(RELEASE_DIR)/
	cd $(RELEASE_DIR) && \
	tar -czf $(BINARY_NAME)-linux-amd64.tar.gz $(BINARY_NAME)-linux-amd64 && \
	tar -czf $(BINARY_NAME)-darwin-amd64.tar.gz $(BINARY_NAME)-darwin-amd64 && \
	tar -czf $(BINARY_NAME)-darwin-arm64.tar.gz $(BINARY_NAME)-darwin-arm64 && \
	zip $(BINARY_NAME)-windows-amd64.zip $(BINARY_NAME)-windows-amd64.exe

# Generate checksums
.PHONY: checksums
checksums: release
	cd $(RELEASE_DIR) && \
	sha256sum * > checksums.txt

# Clean build artifacts
.PHONY: clean
clean:
	go clean
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_NAME)-*
	rm -rf $(RELEASE_DIR)

# Run tests
.PHONY: test
test:
	go test -v ./...

# Run with coverage
.PHONY: test-coverage
test-coverage:
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out

# Format code
.PHONY: fmt
fmt:
	go fmt ./...

# Run linter
.PHONY: lint
lint:
	golangci-lint run

# Install dependencies
.PHONY: deps
deps:
	go mod download
	go mod tidy

# Install the binary
.PHONY: install
install: build
	sudo cp $(BINARY_NAME) $(INSTALL_DIR)/

# Install with development symlink
.PHONY: install-dev
install-dev: build
	sudo ln -sf $(PWD)/$(BINARY_NAME) $(INSTALL_DIR)/$(BINARY_NAME)

# Local installation (using script)
.PHONY: install-local
install-local:
	./install-local.sh

# Local installation with dev symlink
.PHONY: install-local-dev
install-local-dev:
	./install-local.sh --dev-symlink

# Uninstall the binary
.PHONY: uninstall
uninstall:
	sudo rm -f $(INSTALL_DIR)/$(BINARY_NAME)

# Run the application
.PHONY: run
run:
	go run . $(ARGS)

# Make install scripts executable
.PHONY: setup-scripts
setup-scripts:
	chmod +x install.sh
	chmod +x uninstall.sh
	chmod +x install-local.sh
	chmod +x setup-completion.sh

# Setup shell completion
.PHONY: setup-completion
setup-completion:
	./setup-completion.sh

# Setup completion for specific shell
.PHONY: setup-completion-zsh
setup-completion-zsh:
	./setup-completion.sh --shell zsh

.PHONY: setup-completion-bash
setup-completion-bash:
	./setup-completion.sh --shell bash

# Test completion setup
.PHONY: test-completion
test-completion:
	./setup-completion.sh --test

# Create a package for distribution
.PHONY: package
package: release checksums
	@echo "Release packages created in $(RELEASE_DIR)/"
	@echo "Upload these files to GitHub releases:"
	@ls -la $(RELEASE_DIR)/

# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  build             Build the binary"
	@echo "  build-all         Build for all platforms"
	@echo "  build-linux       Build for Linux"
	@echo "  build-macos       Build for macOS"
	@echo "  build-windows     Build for Windows"
	@echo "  release           Create release builds with archives"
	@echo "  checksums         Generate SHA256 checksums"
	@echo "  package           Create complete release package"
	@echo "  clean             Clean build artifacts"
	@echo "  test              Run tests"
	@echo "  test-coverage     Run tests with coverage"
	@echo "  fmt               Format code"
	@echo "  lint              Run linter"
	@echo "  deps              Install dependencies"
	@echo "  install           Install binary to $(INSTALL_DIR)"
	@echo "  install-dev       Install with development symlink"
	@echo "  install-local     Install using local script"
	@echo "  install-local-dev Install with dev symlink using local script"
	@echo "  uninstall         Remove binary from $(INSTALL_DIR)"
	@echo "  run               Run the application (use ARGS=... for arguments)"
	@echo "  setup-scripts     Make install scripts executable"
	@echo "  setup-completion  Setup shell completion"
	@echo "  setup-completion-zsh Setup zsh completion"
	@echo "  setup-completion-bash Setup bash completion"
	@echo "  test-completion   Test completion setup"
	@echo "  help              Show this help message"

# Developer Guide

This guide covers how to set up, build, and contribute to the EAWS CLI project.

## Development Environment Setup

### Prerequisites

- **Go 1.19+**: [Download and install Go](https://golang.org/doc/install)
- **Git**: For version control
- **Make**: Build automation (usually pre-installed on Unix systems)
- **AWS CLI**: For testing AWS functionality

### Getting Started

1. **Clone the repository**:
   ```bash
   git clone https://github.com/manudiv16/eaws.git
   cd eaws
   ```

2. **Install dependencies**:
   ```bash
   make deps
   ```

3. **Build the project**:
   ```bash
   make build
   ```

4. **Run tests**:
   ```bash
   make test
   ```

## Development Workflow

### Building

```bash
# Build for current platform
make build

# Build for all platforms
make build-all

# Build specific platform
make build-linux
make build-macos
make build-windows
```

### Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run specific test
go test ./cmd -v
```

### Local Installation

```bash
# Install locally (copies binary)
make install-local

# Install with development symlink (auto-updates on rebuild)
make install-local-dev

# Just build (don't install)
./install-local.sh --build-only
```

### Code Quality

```bash
# Format code
make fmt

# Run linter (requires golangci-lint)
make lint

# Check for common issues
go vet ./...
```

## Project Structure

```
eaws/
├── main.go                 # Entry point
├── cmd/                    # Cobra commands
│   ├── root.go            # Root command
│   ├── logs.go            # Logs command group
│   ├── logs_query.go      # Logs query subcommand
│   ├── logs_view.go       # Logs view subcommand
│   ├── container.go       # Container command group
│   ├── container_list.go  # Container list subcommand
│   ├── container_connect.go # Container connect subcommand
│   └── pipeline.go        # Pipeline command
├── internal/              # Internal packages
│   └── utils/             # Utility functions
│       ├── aws.go         # AWS configuration
│       └── colors.go      # Color utilities
├── .github/               # GitHub Actions workflows
│   └── workflows/
│       └── release.yml    # Release automation
├── Formula/               # Homebrew formula
│   └── eaws.rb           # Homebrew formula
├── install.sh            # Installation script
├── uninstall.sh          # Uninstallation script
├── install-local.sh      # Local development installer
├── Makefile              # Build automation
├── README.md             # User documentation
├── MIGRATION.md          # Migration guide
├── CHANGELOG.md          # Version history
└── CONTRIBUTING.md       # This file
```

## Adding New Commands

### 1. Create Command File

Create a new file in `cmd/` directory:

```go
// cmd/new_command.go
package cmd

import (
    "fmt"
    "github.com/spf13/cobra"
    "eaws/internal/utils"
)

var newCmd = &cobra.Command{
    Use:   "new",
    Short: "Description of new command",
    Long:  "Detailed description of the new command",
    RunE: func(cmd *cobra.Command, args []string) error {
        // Command implementation
        return nil
    },
}

func init() {
    rootCmd.AddCommand(newCmd)
    
    // Add flags if needed
    newCmd.Flags().StringVarP(&flag, "flag", "f", "", "Flag description")
}
```

### 2. Add to Root Command

The command is automatically added in the `init()` function.

### 3. Update Documentation

- Add examples to README.md
- Update help text
- Add to migration guide if applicable

## AWS Integration

### Using AWS SDK

```go
import (
    "context"
    "github.com/aws/aws-sdk-go-v2/service/ecs"
    "eaws/internal/utils"
)

func exampleAWSCall() error {
    cfg, err := utils.LoadAWSConfig(profile)
    if err != nil {
        return err
    }
    
    client := ecs.NewFromConfig(cfg)
    ctx := context.Background()
    
    output, err := client.ListClusters(ctx, &ecs.ListClustersInput{})
    if err != nil {
        return err
    }
    
    // Process output
    return nil
}
```

### Error Handling

Always wrap AWS errors with context:

```go
if err != nil {
    return fmt.Errorf("failed to list clusters: %w", err)
}
```

## Interactive Prompts

Using `promptui` for user interactions:

```go
import "github.com/manifoldco/promptui"

func selectOption(options []string) (string, error) {
    prompt := promptui.Select{
        Label: "Select an option",
        Items: options,
    }
    
    _, result, err := prompt.Run()
    return result, err
}
```

## Output Formatting

Use utility functions for consistent output:

```go
import "eaws/internal/utils"

// Success message
utils.PrintSuccess("Operation completed")

// Error message
utils.PrintError("Operation failed")

// Info message
utils.PrintInfo("Processing...")

// Warning message
utils.PrintWarning("This is a warning")

// Colored text
fmt.Printf("Status: %s\n", utils.Green("Active"))
```

## Testing

### Unit Tests

Create test files with `_test.go` suffix:

```go
// cmd/example_test.go
package cmd

import (
    "testing"
)

func TestExampleFunction(t *testing.T) {
    // Test implementation
}
```

### Integration Tests

For AWS integration tests, use build tags:

```go
//go:build integration
// +build integration

package cmd

import (
    "testing"
)

func TestAWSIntegration(t *testing.T) {
    // Integration test
}
```

Run with: `go test -tags=integration ./...`

## Release Process

### Local Release

1. **Update version** in relevant files
2. **Create release build**:
   ```bash
   make release
   ```
3. **Generate checksums**:
   ```bash
   make checksums
   ```

### GitHub Release

1. **Tag the release**:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

2. **GitHub Actions** will automatically:
   - Build for all platforms
   - Create release archives
   - Generate checksums
   - Create GitHub release

### Homebrew

Update `Formula/eaws.rb` with new version and checksums.

## Contributing Guidelines

### Code Style

- Follow Go conventions
- Use `gofmt` for formatting
- Write clear commit messages
- Add tests for new features

### Pull Request Process

1. **Fork** the repository
2. **Create feature branch** from `main`
3. **Make changes** with tests
4. **Run tests** and linting
5. **Submit pull request**

### Commit Messages

Follow conventional commits:

```
feat: add new command
fix: resolve AWS connection issue
docs: update installation guide
refactor: improve error handling
```

## Troubleshooting

### Common Issues

1. **AWS credentials**: Ensure AWS CLI is configured
2. **Profile issues**: Check granted installation
3. **Build errors**: Verify Go version and dependencies
4. **Permission errors**: Use appropriate sudo/chmod

### Debug Mode

Enable verbose output:

```bash
eaws --verbose [command]
```

### Logs

Check system logs for SSM session issues:

```bash
# macOS
log show --predicate 'subsystem contains "aws"' --last 1h

# Linux
journalctl -u amazon-ssm-agent
```

## Documentation

### User Documentation

- **README.md**: User-facing documentation
- **MIGRATION.md**: Migration from bash version
- **Examples**: Include real-world usage examples

### Developer Documentation

- **Code comments**: Document complex functions
- **API documentation**: Use godoc format
- **Architecture decisions**: Document design choices

## Security

### AWS Credentials

- Never commit AWS credentials
- Use IAM roles when possible
- Follow least privilege principle

### Dependencies

- Regularly update dependencies
- Use `go mod audit` for vulnerability scanning
- Pin dependency versions in releases

## Performance

### Profiling

```bash
# CPU profiling
go build -o eaws-prof .
./eaws-prof -cpuprofile=cpu.prof [command]
go tool pprof cpu.prof

# Memory profiling
go build -o eaws-prof .
./eaws-prof -memprofile=mem.prof [command]
go tool pprof mem.prof
```

### Optimization

- Use AWS SDK connection pooling
- Implement caching for repeated API calls
- Minimize memory allocations in hot paths

## Resources

- [Cobra Documentation](https://cobra.dev/)
- [AWS SDK for Go v2](https://aws.github.io/aws-sdk-go-v2/)
- [Go Testing](https://golang.org/pkg/testing/)
- [promptui](https://github.com/manifoldco/promptui)
- [color](https://github.com/fatih/color)

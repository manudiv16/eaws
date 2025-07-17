# EAWS - Simple AWS CLI

A simple AWS CLI tool built with Go and Cobra that provides easy access to AWS services like ECS, CloudWatch Logs, and CodePipeline.

## Features

- 🚀 **Interactive CLI** - Uses interactive prompts for easy navigation
- 🎨 **Colorized Output** - Beautiful colored output for better readability
- 🐳 **ECS Support** - List and connect to ECS containers
- 📊 **CloudWatch Logs** - Query and view CloudWatch logs
- 🔄 **CodePipeline** - Monitor pipeline status and details
- 🔐 **AWS Profile Support** - Works with AWS profiles and granted tool

## Installation

### Prerequisites

- AWS CLI configured
- [granted](https://github.com/common-fate/granted) (optional, for profile management)

### Quick Install (Recommended)

**For macOS and Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/manudiv16/eaws-go/main/install.sh | bash
```

This script will:
- Detect your OS and architecture
- Download the latest release
- Install to `/usr/local/bin`
- Verify the installation

### Homebrew (macOS/Linux)

```bash
# Add the tap
brew tap manudiv16/eaws-go

# Install
brew install eaws

# Update
brew upgrade eaws
```

### Manual Installation

1. **Download the binary** from the [releases page](https://github.com/manudiv16/eaws-go/releases)
2. **Extract** (if needed) and **move** to your PATH:
   ```bash
   # Example for Linux
   tar -xzf eaws-linux-amd64.tar.gz
   sudo mv eaws-linux-amd64 /usr/local/bin/eaws
   chmod +x /usr/local/bin/eaws
   ```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/manudiv16/eaws-go.git
cd eaws-go

# Build and install
make install-local

# Or for development (creates symlink)
make install-local-dev
```

### Uninstall

```bash
# Using the uninstall script
curl -fsSL https://raw.githubusercontent.com/manudiv16/eaws-go/main/uninstall.sh | bash

# Or manually
sudo rm /usr/local/bin/eaws

# Or with Homebrew
brew uninstall eaws
```

## Usage

### Basic Commands

```bash
# Show help
eaws --help

# Use with specific AWS profile
eaws --profile my-profile [command]

# Enable verbose output
eaws --verbose [command]
```

### Container Management

```bash
# List all containers in clusters
eaws container list
# or
eaws c l

# Connect to a container
eaws container connect  
# or
eaws c c
```

### CloudWatch Logs

```bash
# Query logs using CloudWatch Insights
eaws logs query
# or
eaws l q

# View log streams
eaws logs view
# or
eaws l v
```

### CodePipeline

```bash
# Show pipeline status
eaws pipeline

# Show detailed pipeline information
eaws pipeline --debug
# or
eaws p -d
```

## Configuration

### AWS Profile

The tool supports AWS profiles in several ways:

1. **Command line flag**: `--profile my-profile`
2. **Environment variable**: `AWS_PROFILE=my-profile`
3. **Granted tool**: If available, will use `assume` command

### Environment Variables

- `AWS_PROFILE`: Set the AWS profile to use
- `NO_COLOR`: Disable colored output

## Examples

### List ECS Containers

```bash
$ eaws container list
✓ Selected cluster: my-cluster

Services in cluster:
  • web-service
  • api-service
  • worker-service
```

### Connect to ECS Container

```bash
$ eaws container connect
✓ Selected cluster: my-cluster
✓ Selected service: web-service
✓ Using task: arn:aws:ecs:...
✓ Container: web-app
✓ EC2 Instance: i-1234567890abcdef0
✓ Starting session with command: sudo docker exec -ti abc123 sh
```

### View Pipeline Status

```bash
$ eaws pipeline
✓ Selected pipeline: my-app-pipeline

Pipeline Status Summary:

Source - Succeeded
  Source - Succeeded 2024-01-15T10:30:00Z

Build - InProgress  
  Build - InProgress 2024-01-15T10:35:00Z

Deploy - NotStarted
  Deploy - NotStarted
```

## Migration from Bash Script

This Go version provides the same functionality as the original bash script with these improvements:

- **Better Error Handling**: Proper error messages and handling
- **Interactive Prompts**: Replaces `fzf` with built-in prompt library
- **Cross-platform**: Works on macOS, Linux, and Windows
- **No External Dependencies**: No need for `jq`, `fzf`, or other tools
- **Faster Execution**: Compiled binary vs interpreted script
- **Better AWS Integration**: Native AWS SDK instead of CLI calls

## Dependencies

- [Cobra](https://github.com/spf13/cobra) - CLI framework
- [AWS SDK for Go v2](https://github.com/aws/aws-sdk-go-v2) - AWS integration
- [promptui](https://github.com/manifoldco/promptui) - Interactive prompts  
- [color](https://github.com/fatih/color) - Colored output

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

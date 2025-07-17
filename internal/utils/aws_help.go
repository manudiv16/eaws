package utils

import (
	"fmt"
	"os"
	"strings"
)

// AWSSetupHelper provides helpful setup instructions based on the environment
type AWSSetupHelper struct{}

// NewAWSSetupHelper creates a new AWS setup helper
func NewAWSSetupHelper() *AWSSetupHelper {
	return &AWSSetupHelper{}
}

// PrintSetupInstructions prints context-aware setup instructions
func (h *AWSSetupHelper) PrintSetupInstructions(err error) {
	fmt.Printf("\n%s\n", Bold("AWS Setup Instructions:"))

	// Detect the environment and provide appropriate instructions
	h.printEnvironmentSpecificInstructions()

	// Print general troubleshooting
	h.printGeneralTroubleshooting()

	// Print quick fixes
	h.printQuickFixes()
}

// printEnvironmentSpecificInstructions provides environment-specific setup instructions
func (h *AWSSetupHelper) printEnvironmentSpecificInstructions() {
	fmt.Printf("\n%s\n", GreenBold("Environment-specific setup:"))

	// Check if we're in a corporate environment
	if h.isCorpEnvironment() {
		fmt.Printf("  %s %s\n", Blue("•"), "Corporate environment detected")
		fmt.Printf("    %s\n", "• Use AWS SSO: aws sso login --profile <profile-name>")
		fmt.Printf("    %s\n", "• Use granted: assume <profile-name>")
		fmt.Printf("    %s\n", "• Contact your AWS administrator for SSO setup")
		return
	}

	// Check if granted is available
	if h.isGrantedAvailable() {
		fmt.Printf("  %s %s\n", Blue("•"), "Granted is available:")
		fmt.Printf("    %s\n", "• List profiles: assume")
		fmt.Printf("    %s\n", "• Use profile: assume <profile-name>")
		fmt.Printf("    %s\n", "• Or use with eaws: eaws --profile <profile-name> [command]")
	} else {
		fmt.Printf("  %s %s\n", Blue("•"), "Standard AWS setup:")
		fmt.Printf("    %s\n", "• Configure credentials: aws configure")
		fmt.Printf("    %s\n", "• Use named profile: aws configure --profile <profile-name>")
		fmt.Printf("    %s\n", "• Set profile: export AWS_PROFILE=<profile-name>")
	}
}

// printGeneralTroubleshooting provides general troubleshooting steps
func (h *AWSSetupHelper) printGeneralTroubleshooting() {
	fmt.Printf("\n%s\n", GreenBold("Troubleshooting:"))
	fmt.Printf("  %s %s\n", Blue("•"), "Check AWS configuration:")
	fmt.Printf("    %s\n", "• aws sts get-caller-identity")
	fmt.Printf("    %s\n", "• aws configure list")
	fmt.Printf("    %s\n", "• echo $AWS_PROFILE")

	fmt.Printf("  %s %s\n", Blue("•"), "Check AWS SSO (if using SSO):")
	fmt.Printf("    %s\n", "• aws sso login")
	fmt.Printf("    %s\n", "• aws configure sso")

	fmt.Printf("  %s %s\n", Blue("•"), "Check credentials location:")
	fmt.Printf("    %s\n", "• ~/.aws/credentials")
	fmt.Printf("    %s\n", "• ~/.aws/config")
}

// printQuickFixes provides quick fix suggestions
func (h *AWSSetupHelper) printQuickFixes() {
	fmt.Printf("\n%s\n", GreenBold("Quick fixes:"))
	fmt.Printf("  %s %s\n", Blue("•"), "For immediate access:")
	fmt.Printf("    %s\n", "• Set temporary credentials:")
	fmt.Printf("      %s\n", "export AWS_ACCESS_KEY_ID=your_access_key")
	fmt.Printf("      %s\n", "export AWS_SECRET_ACCESS_KEY=your_secret_key")
	fmt.Printf("      %s\n", "export AWS_DEFAULT_REGION=us-east-1")

	fmt.Printf("  %s %s\n", Blue("•"), "For development:")
	fmt.Printf("    %s\n", "• Use LocalStack for local development")
	fmt.Printf("    %s\n", "• Use AWS CLI profiles for different environments")

	fmt.Printf("  %s %s\n", Blue("•"), "For CI/CD:")
	fmt.Printf("    %s\n", "• Use IAM roles for EC2/ECS/Lambda")
	fmt.Printf("    %s\n", "• Use environment variables in CI systems")
}

// isCorpEnvironment detects if we're in a corporate environment
func (h *AWSSetupHelper) isCorpEnvironment() bool {
	// Check for common corporate environment indicators
	homeDir, _ := os.UserHomeDir()

	// Check for corporate SSO config
	if _, err := os.Stat(homeDir + "/.aws/sso"); err == nil {
		return true
	}

	// Check for common corporate domains in environment
	if hostname, err := os.Hostname(); err == nil {
		corpDomains := []string{".corp", ".internal", ".company", ".local"}
		for _, domain := range corpDomains {
			if strings.Contains(hostname, domain) {
				return true
			}
		}
	}

	return false
}

// isGrantedAvailable checks if granted tool is available
func (h *AWSSetupHelper) isGrantedAvailable() bool {
	_, err := os.Stat("/usr/local/bin/assume")
	if err == nil {
		return true
	}

	_, err = os.Stat("/opt/homebrew/bin/assume")
	return err == nil
}

// DetectAWSIssue tries to detect the specific AWS authentication issue
func DetectAWSIssue() string {
	// Check if AWS CLI is installed
	if !isAWSCLIInstalled() {
		return "AWS CLI is not installed. Please install it first: https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
	}

	// Check if credentials file exists
	homeDir, _ := os.UserHomeDir()
	credentialsPath := homeDir + "/.aws/credentials"
	configPath := homeDir + "/.aws/config"

	if _, err := os.Stat(credentialsPath); os.IsNotExist(err) {
		if _, err := os.Stat(configPath); os.IsNotExist(err) {
			return "No AWS configuration found. Run 'aws configure' to set up your credentials."
		}
	}

	// Check environment variables
	if os.Getenv("AWS_PROFILE") == "" && os.Getenv("AWS_ACCESS_KEY_ID") == "" {
		return "No AWS profile or access key set. Set AWS_PROFILE or run 'aws configure'."
	}

	return "AWS credentials may be expired or invalid. Try 'aws sts get-caller-identity' to verify."
}

// isAWSCLIInstalled checks if AWS CLI is installed
func isAWSCLIInstalled() bool {
	_, err := os.Stat("/usr/local/bin/aws")
	if err == nil {
		return true
	}

	_, err = os.Stat("/opt/homebrew/bin/aws")
	return err == nil
}

package utils

import (
	"context"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

// AWSAuthError represents authentication-related errors
type AWSAuthError struct {
	Message string
	Cause   error
}

func (e *AWSAuthError) Error() string {
	return e.Message
}

func (e *AWSAuthError) Unwrap() error {
	return e.Cause
}

// LoadAWSConfig loads AWS configuration with optional profile
func LoadAWSConfig(profile string) (aws.Config, error) {
	ctx := context.Background()

	// Handle profile configuration
	if profile != "" {
		if err := setAWSProfile(profile); err != nil {
			return aws.Config{}, err
		}
	} else if os.Getenv("AWS_PROFILE") == "" {
		// No profile specified and no AWS_PROFILE set, try to use assume
		if err := tryAssumeProfile(); err != nil {
			PrintWarning("No AWS profile configured, using default credentials")
		}
	}

	// Load AWS configuration
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return aws.Config{}, &AWSAuthError{
			Message: "Failed to load AWS configuration. Please check your AWS credentials and configuration.",
			Cause:   err,
		}
	}

	// Verify credentials by making a simple API call
	if err := verifyAWSCredentials(cfg); err != nil {
		return aws.Config{}, err
	}

	return cfg, nil
}

// setAWSProfile sets the AWS profile using assume command or environment variable
func setAWSProfile(profile string) error {
	// Check if 'assume' command is available (from granted tool)
	if _, err := exec.LookPath("assume"); err == nil {
		return runAssumeCommand(profile)
	}

	// Fallback to setting AWS_PROFILE environment variable
	os.Setenv("AWS_PROFILE", profile)
	PrintInfo(fmt.Sprintf("Using AWS profile: %s", profile))
	return nil
}

// runAssumeCommand runs the assume command with proper error handling
func runAssumeCommand(profile string) error {
	cmd := exec.Command("assume", profile)

	// Capture stderr to get better error messages
	var stderr strings.Builder
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		errorMsg := stderr.String()
		if strings.Contains(errorMsg, "no such file or directory") {
			return &AWSAuthError{
				Message: fmt.Sprintf("AWS profile '%s' not found or granted tool not properly configured. Please check your AWS SSO configuration.", profile),
				Cause:   err,
			}
		}
		return &AWSAuthError{
			Message: fmt.Sprintf("Failed to assume AWS profile '%s': %s", profile, errorMsg),
			Cause:   err,
		}
	}

	PrintSuccess(fmt.Sprintf("Successfully assumed AWS profile: %s", profile))
	return nil
}

// tryAssumeProfile tries to run assume command without parameters
func tryAssumeProfile() error {
	if _, err := exec.LookPath("assume"); err != nil {
		return fmt.Errorf("assume command not found")
	}

	cmd := exec.Command("assume")
	var stderr strings.Builder
	cmd.Stderr = &stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to run assume command: %v", err)
	}

	return nil
}

// verifyAWSCredentials verifies that AWS credentials are valid
func verifyAWSCredentials(cfg aws.Config) error {
	stsClient := sts.NewFromConfig(cfg)
	ctx := context.Background()

	_, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})
	if err != nil {
		// Check for common authentication errors
		errorStr := err.Error()

		if strings.Contains(errorStr, "NoCredentialsError") {
			return &AWSAuthError{
				Message: "No AWS credentials found. Please run 'aws configure' or set up AWS SSO with 'aws sso login'.",
				Cause:   err,
			}
		}

		if strings.Contains(errorStr, "TokenRefreshRequired") || strings.Contains(errorStr, "ExpiredToken") {
			return &AWSAuthError{
				Message: "AWS credentials have expired. Please run 'aws sso login' to refresh your credentials.",
				Cause:   err,
			}
		}

		if strings.Contains(errorStr, "UnauthorizedOperation") || strings.Contains(errorStr, "AccessDenied") {
			return &AWSAuthError{
				Message: "AWS credentials are valid but insufficient permissions. Please check your IAM permissions.",
				Cause:   err,
			}
		}

		return &AWSAuthError{
			Message: "Failed to verify AWS credentials. Please check your AWS configuration.",
			Cause:   err,
		}
	}

	return nil
}

// CheckAWSProfile ensures AWS profile is configured and credentials are valid
func CheckAWSProfile(profile string) error {
	_, err := LoadAWSConfig(profile)
	if err != nil {
		// If it's an AWSAuthError, provide detailed help
		var authErr *AWSAuthError
		if errors.As(err, &authErr) {
			PrintError(authErr.Message)

			// Provide context-aware help
			helper := NewAWSSetupHelper()
			helper.PrintSetupInstructions(authErr)

			return authErr
		}
		return err
	}
	return nil
}

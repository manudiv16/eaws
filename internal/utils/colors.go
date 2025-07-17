package utils

import (
	"fmt"
	"os"

	"github.com/fatih/color"
)

var (
	Red        = color.New(color.FgRed).SprintFunc()
	Green      = color.New(color.FgGreen).SprintFunc()
	Yellow     = color.New(color.FgYellow).SprintFunc()
	Blue       = color.New(color.FgBlue).SprintFunc()
	Magenta    = color.New(color.FgMagenta).SprintFunc()
	Cyan       = color.New(color.FgCyan).SprintFunc()
	Bold       = color.New(color.Bold).SprintFunc()
	GreenBold  = color.New(color.FgGreen, color.Bold).SprintFunc()
	YellowBold = color.New(color.FgYellow, color.Bold).SprintFunc()
	CyanBold   = color.New(color.FgCyan, color.Bold).SprintFunc()
)

func init() {
	// Disable color if NO_COLOR environment variable is set
	if os.Getenv("NO_COLOR") != "" {
		color.NoColor = true
	}
}

func PrintSuccess(message string) {
	fmt.Printf("%s %s\n", Green("✓"), message)
}

func PrintError(message string) {
	fmt.Printf("%s %s\n", Red("✗"), message)
}

func PrintInfo(message string) {
	fmt.Printf("%s %s\n", Blue("ℹ"), message)
}

func PrintWarning(message string) {
	fmt.Printf("%s %s\n", Yellow("⚠"), message)
}

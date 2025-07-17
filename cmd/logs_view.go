package cmd

import (
	"fmt"

	"eaws/internal/utils"

	"github.com/spf13/cobra"
)

// logsViewCmd represents the logs view command
var logsViewCmd = &cobra.Command{
	Use:     "view",
	Aliases: []string{"v"},
	Short:   "Show log stream",
	Long:    `Show log stream for the selected container or service.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := utils.CheckAWSProfile(profile); err != nil {
			return fmt.Errorf("failed to configure AWS profile: %w", err)
		}

		utils.PrintInfo("Log stream viewing functionality")
		utils.PrintWarning("This command is not yet implemented")
		return nil
	},
}

func init() {
	logsCmd.AddCommand(logsViewCmd)
}

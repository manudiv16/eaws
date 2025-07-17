package cmd

import (
	"fmt"

	"eaws/internal/utils"

	"github.com/spf13/cobra"
)

// logsQueryCmd represents the logs query command
var logsQueryCmd = &cobra.Command{
	Use:     "query",
	Aliases: []string{"q"},
	Short:   "Use CloudWatch Insights",
	Long:    `Use CloudWatch Insights to query logs with a powerful query language.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := utils.CheckAWSProfile(profile); err != nil {
			return fmt.Errorf("failed to configure AWS profile: %w", err)
		}

		utils.PrintInfo("CloudWatch Insights query functionality")
		utils.PrintWarning("This command is not yet implemented")
		return nil
	},
}

func init() {
	logsCmd.AddCommand(logsQueryCmd)
}

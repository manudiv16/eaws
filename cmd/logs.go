/*
Copyright © 2025 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"github.com/spf13/cobra"
)

var (
	project string
)

// logsCmd represents the logs command
var logsCmd = &cobra.Command{
	Use:     "logs",
	Aliases: []string{"l"},
	Short:   "Show logs from CloudWatch",
	Long: `Show logs from CloudWatch with various options for querying and viewing log streams.

Examples:
  eaws logs query  # Visualize logs in CloudWatch Insights
  eaws logs view   # View the logs of the selected container`,
}

func init() {
	rootCmd.AddCommand(logsCmd)

	// Add flags specific to logs command
	logsCmd.PersistentFlags().StringVarP(&project, "project", "j", "", "Project to show information from")
}

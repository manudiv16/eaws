package cmd

import (
	"github.com/spf13/cobra"
)

// containerCmd represents the container command
var containerCmd = &cobra.Command{
	Use:     "container",
	Aliases: []string{"c"},
	Short:   "Helper command to manage ECS containers",
	Long:    `Helper command to manage ECS containers with various operations like listing and connecting.`,
}

func init() {
	rootCmd.AddCommand(containerCmd)
}

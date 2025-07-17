package cmd

import (
	"context"
	"fmt"
	"strings"

	"eaws/internal/utils"

	"github.com/aws/aws-sdk-go-v2/service/ecs"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

// containerListCmd represents the container list command
var containerListCmd = &cobra.Command{
	Use:     "list",
	Aliases: []string{"l"},
	Short:   "List all containers in clusters",
	Long:    `List all containers in ECS clusters with interactive selection.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := utils.CheckAWSProfile(profile); err != nil {
			return fmt.Errorf("failed to configure AWS profile: %w", err)
		}

		cfg, err := utils.LoadAWSConfig(profile)
		if err != nil {
			return fmt.Errorf("failed to load AWS config: %w", err)
		}

		client := ecs.NewFromConfig(cfg)
		ctx := context.Background()

		// Get clusters
		clustersOutput, err := client.ListClusters(ctx, &ecs.ListClustersInput{})
		if err != nil {
			return fmt.Errorf("failed to list clusters: %w", err)
		}

		if len(clustersOutput.ClusterArns) == 0 {
			utils.PrintWarning("No clusters found")
			return nil
		}

		// Extract cluster names
		var clusterNames []string
		for _, clusterArn := range clustersOutput.ClusterArns {
			parts := strings.Split(clusterArn, "/")
			if len(parts) > 1 {
				clusterNames = append(clusterNames, parts[len(parts)-1])
			}
		}

		// Interactive cluster selection
		prompt := promptui.Select{
			Label: "Select cluster",
			Items: clusterNames,
		}

		_, selectedCluster, err := prompt.Run()
		if err != nil {
			return fmt.Errorf("cluster selection cancelled: %w", err)
		}

		utils.PrintInfo(fmt.Sprintf("Selected cluster: %s", utils.GreenBold(selectedCluster)))

		// Get services in the selected cluster
		servicesOutput, err := client.ListServices(ctx, &ecs.ListServicesInput{
			Cluster: &selectedCluster,
		})
		if err != nil {
			return fmt.Errorf("failed to list services: %w", err)
		}

		if len(servicesOutput.ServiceArns) == 0 {
			utils.PrintWarning("No services found in this cluster")
			return nil
		}

		// Extract service names and print them
		fmt.Printf("\n%s\n", utils.GreenBold("Services in cluster:"))
		for _, serviceArn := range servicesOutput.ServiceArns {
			parts := strings.Split(serviceArn, "/")
			if len(parts) > 2 {
				serviceName := parts[len(parts)-1]
				fmt.Printf("  • %s\n", serviceName)
			}
		}

		return nil
	},
}

func init() {
	containerCmd.AddCommand(containerListCmd)
}

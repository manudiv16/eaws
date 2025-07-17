package cmd

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"

	"eaws/internal/utils"

	"github.com/aws/aws-sdk-go-v2/service/ecs"
	"github.com/aws/aws-sdk-go-v2/service/ecs/types"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

// containerConnectCmd represents the container connect command
var containerConnectCmd = &cobra.Command{
	Use:     "connect",
	Aliases: []string{"c"},
	Short:   "Connect to some container",
	Long:    `Connect to an ECS container using AWS Systems Manager Session Manager.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		startTime := time.Now()

		if err := utils.CheckAWSProfile(profile); err != nil {
			return fmt.Errorf("failed to configure AWS profile: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ AWS profile check: %v", time.Since(startTime)))
		}

		cfg, err := utils.LoadAWSConfig(profile)
		if err != nil {
			return fmt.Errorf("failed to load AWS config: %w", err)
		}

		ecsClient := ecs.NewFromConfig(cfg)
		ctx := context.Background()

		// Get clusters
		stepStart := time.Now()
		clustersOutput, err := ecsClient.ListClusters(ctx, &ecs.ListClustersInput{})
		if err != nil {
			return fmt.Errorf("failed to list clusters: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ List clusters: %v", time.Since(stepStart)))
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
		clusterPrompt := promptui.Select{
			Label: "Select cluster",
			Items: clusterNames,
		}

		_, selectedCluster, err := clusterPrompt.Run()
		if err != nil {
			return fmt.Errorf("cluster selection cancelled: %w", err)
		}

		utils.PrintInfo(fmt.Sprintf("Selected cluster: %s", utils.GreenBold(selectedCluster)))

		// Get services in the selected cluster
		stepStart = time.Now()
		servicesOutput, err := ecsClient.ListServices(ctx, &ecs.ListServicesInput{
			Cluster: &selectedCluster,
		})
		if err != nil {
			return fmt.Errorf("failed to list services: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ List services: %v", time.Since(stepStart)))
		}

		if len(servicesOutput.ServiceArns) == 0 {
			utils.PrintWarning("No services found in this cluster")
			return nil
		}

		// Extract service names
		var serviceNames []string
		for _, serviceArn := range servicesOutput.ServiceArns {
			parts := strings.Split(serviceArn, "/")
			if len(parts) > 2 {
				serviceNames = append(serviceNames, parts[len(parts)-1])
			}
		}

		// Interactive service selection
		servicePrompt := promptui.Select{
			Label: "Select service",
			Items: serviceNames,
		}

		_, selectedService, err := servicePrompt.Run()
		if err != nil {
			return fmt.Errorf("service selection cancelled: %w", err)
		}

		utils.PrintInfo(fmt.Sprintf("Selected service: %s", utils.GreenBold(selectedService)))

		// Get tasks for the selected service
		stepStart = time.Now()
		tasksOutput, err := ecsClient.ListTasks(ctx, &ecs.ListTasksInput{
			Cluster:     &selectedCluster,
			ServiceName: &selectedService,
		})
		if err != nil {
			return fmt.Errorf("failed to list tasks: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ List tasks: %v", time.Since(stepStart)))
		}

		if len(tasksOutput.TaskArns) == 0 {
			utils.PrintWarning("No tasks found for this service")
			return nil
		}

		var selectedTask string

		// If only one task, use it directly
		if len(tasksOutput.TaskArns) == 1 {
			selectedTask = tasksOutput.TaskArns[0]
			utils.PrintInfo(fmt.Sprintf("Using task: %s", utils.GreenBold(selectedTask)))
		} else {
			// Multiple tasks, let user choose
			var taskNames []string
			for _, taskArn := range tasksOutput.TaskArns {
				// Extract task ID from ARN for display
				parts := strings.Split(taskArn, "/")
				if len(parts) > 1 {
					taskNames = append(taskNames, parts[len(parts)-1])
				} else {
					taskNames = append(taskNames, taskArn)
				}
			}

			// Interactive task selection
			taskPrompt := promptui.Select{
				Label: "Select task",
				Items: taskNames,
			}

			taskIndex, _, err := taskPrompt.Run()
			if err != nil {
				return fmt.Errorf("task selection cancelled: %w", err)
			}

			selectedTask = tasksOutput.TaskArns[taskIndex]
			utils.PrintInfo(fmt.Sprintf("Selected task: %s", utils.GreenBold(selectedTask)))
		}

		// Describe the task to get container details
		stepStart = time.Now()
		describeOutput, err := ecsClient.DescribeTasks(ctx, &ecs.DescribeTasksInput{
			Cluster: &selectedCluster,
			Tasks:   []string{selectedTask},
		})
		if err != nil {
			return fmt.Errorf("failed to describe task: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ Describe task: %v", time.Since(stepStart)))
		}

		if len(describeOutput.Tasks) == 0 {
			return fmt.Errorf("no task details found")
		}

		task := describeOutput.Tasks[0]

		// Get container instance ID
		containerInstanceArn := task.ContainerInstanceArn
		if containerInstanceArn == nil {
			return fmt.Errorf("no container instance found for task")
		}

		// Get container runtime ID
		if len(task.Containers) == 0 {
			return fmt.Errorf("no containers found in task")
		}

		var selectedContainer *types.Container

		// If only one container, use it directly
		if len(task.Containers) == 1 {
			selectedContainer = &task.Containers[0]
			utils.PrintInfo(fmt.Sprintf("Using container: %s", utils.GreenBold(*selectedContainer.Name)))
		} else {
			// Multiple containers, let user choose
			var containerNames []string
			for _, container := range task.Containers {
				if container.Name != nil {
					containerNames = append(containerNames, *container.Name)
				}
			}

			// Interactive container selection
			containerPrompt := promptui.Select{
				Label: "Select container",
				Items: containerNames,
			}

			_, selectedContainerName, err := containerPrompt.Run()
			if err != nil {
				return fmt.Errorf("container selection cancelled: %w", err)
			}

			// Find the selected container
			for _, container := range task.Containers {
				if container.Name != nil && *container.Name == selectedContainerName {
					selectedContainer = &container
					break
				}
			}

			if selectedContainer == nil {
				return fmt.Errorf("selected container not found")
			}

			utils.PrintInfo(fmt.Sprintf("Selected container: %s", utils.GreenBold(*selectedContainer.Name)))
		}

		if selectedContainer.RuntimeId == nil {
			return fmt.Errorf("no runtime ID found for container")
		}

		// Get EC2 instance ID
		stepStart = time.Now()
		containerInstanceOutput, err := ecsClient.DescribeContainerInstances(ctx, &ecs.DescribeContainerInstancesInput{
			Cluster:            &selectedCluster,
			ContainerInstances: []string{*containerInstanceArn},
		})
		if err != nil {
			return fmt.Errorf("failed to describe container instance: %w", err)
		}
		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ Describe container instance: %v", time.Since(stepStart)))
		}

		if len(containerInstanceOutput.ContainerInstances) == 0 {
			return fmt.Errorf("no container instance details found")
		}

		ec2InstanceId := containerInstanceOutput.ContainerInstances[0].Ec2InstanceId
		if ec2InstanceId == nil {
			return fmt.Errorf("no EC2 instance ID found")
		}

		utils.PrintInfo(fmt.Sprintf("EC2 Instance: %s", utils.GreenBold(*ec2InstanceId)))

		// Start SSM session
		documentName := "AWS-StartInteractiveCommand"
		command := fmt.Sprintf("sudo docker exec -ti %s sh", *selectedContainer.RuntimeId)

		utils.PrintInfo(fmt.Sprintf("Starting session with command: %s", utils.Cyan(command)))
		utils.PrintInfo("🚀 Connecting to container...")

		// Use AWS CLI to start the session since SSM client doesn't support interactive sessions directly
		stepStart = time.Now()
		ssmCmd := exec.Command("aws", "ssm", "start-session",
			"--target", *ec2InstanceId,
			"--document-name", documentName,
			"--parameters", fmt.Sprintf("command=%s", command))

		ssmCmd.Stdin = os.Stdin
		ssmCmd.Stdout = os.Stdout
		ssmCmd.Stderr = os.Stderr

		if err := ssmCmd.Run(); err != nil {
			return fmt.Errorf("failed to start SSM session: %w", err)
		}

		if verbose {
			utils.PrintInfo(fmt.Sprintf("✓ SSM session completed: %v", time.Since(stepStart)))
			utils.PrintInfo(fmt.Sprintf("✓ Total execution time: %v", time.Since(startTime)))
		}
		return nil
	},
}

func init() {
	containerCmd.AddCommand(containerConnectCmd)
}

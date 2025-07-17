package cmd

import (
	"context"
	"fmt"
	"strings"
	"time"

	"eaws/internal/utils"

	"github.com/aws/aws-sdk-go-v2/service/codepipeline"
	"github.com/aws/aws-sdk-go-v2/service/codepipeline/types"
	"github.com/manifoldco/promptui"
	"github.com/spf13/cobra"
)

var debug bool

// pipelineCmd represents the pipeline command
var pipelineCmd = &cobra.Command{
	Use:     "pipeline",
	Aliases: []string{"p"},
	Short:   "Show status pipeline",
	Long:    `Show the status of CodePipeline pipelines with detailed information about stages and actions.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		if err := utils.CheckAWSProfile(profile); err != nil {
			return fmt.Errorf("failed to configure AWS profile: %w", err)
		}

		cfg, err := utils.LoadAWSConfig(profile)
		if err != nil {
			return fmt.Errorf("failed to load AWS config: %w", err)
		}

		client := codepipeline.NewFromConfig(cfg)
		ctx := context.Background()

		// List pipelines
		pipelinesOutput, err := client.ListPipelines(ctx, &codepipeline.ListPipelinesInput{})
		if err != nil {
			return fmt.Errorf("failed to list pipelines: %w", err)
		}

		if len(pipelinesOutput.Pipelines) == 0 {
			utils.PrintWarning("No pipelines found")
			return nil
		}

		// Extract pipeline names
		var pipelineNames []string
		for _, pipeline := range pipelinesOutput.Pipelines {
			if pipeline.Name != nil {
				pipelineNames = append(pipelineNames, *pipeline.Name)
			}
		}

		// Interactive pipeline selection
		prompt := promptui.Select{
			Label: "Select pipeline",
			Items: pipelineNames,
		}

		_, selectedPipeline, err := prompt.Run()
		if err != nil {
			return fmt.Errorf("pipeline selection cancelled: %w", err)
		}

		utils.PrintInfo(fmt.Sprintf("Selected pipeline: %s", utils.GreenBold(selectedPipeline)))

		// Get pipeline state
		stateOutput, err := client.GetPipelineState(ctx, &codepipeline.GetPipelineStateInput{
			Name: &selectedPipeline,
		})
		if err != nil {
			return fmt.Errorf("failed to get pipeline state: %w", err)
		}

		// Display pipeline information
		if !debug {
			// Show summary view
			fmt.Printf("\n%s\n", utils.GreenBold("Pipeline Status Summary:"))
			for _, stage := range stateOutput.StageStates {
				if stage.StageName != nil {
					stageName := *stage.StageName
					stageStatus := "Unknown"
					if stage.LatestExecution != nil && stage.LatestExecution.Status != "" {
						stageStatus = string(stage.LatestExecution.Status)
					}

					fmt.Printf("\n%s - %s\n", utils.GreenBold(stageName), utils.Yellow(stageStatus))

					// Show actions for this stage
					for _, action := range stage.ActionStates {
						if action.ActionName != nil {
							actionName := *action.ActionName
							actionStatus := "Unknown"
							lastChange := ""

							if action.LatestExecution != nil {
								if action.LatestExecution.Status != "" {
									actionStatus = string(action.LatestExecution.Status)
								}
								if action.LatestExecution.LastStatusChange != nil {
									lastChange = action.LatestExecution.LastStatusChange.Format(time.RFC3339)
								}
							}

							fmt.Printf("  %s - %s %s\n", actionName, utils.Yellow(actionStatus), utils.Cyan(lastChange))
						}
					}
				}
			}
		} else {
			// Show detailed view with interactive selection
			var stageNames []string
			for _, stage := range stateOutput.StageStates {
				if stage.StageName != nil {
					stageName := *stage.StageName
					stageStatus := "Unknown"
					if stage.LatestExecution != nil && stage.LatestExecution.Status != "" {
						stageStatus = string(stage.LatestExecution.Status)
					}
					stageNames = append(stageNames, fmt.Sprintf("%s - %s", stageName, stageStatus))
				}
			}

			// Interactive stage selection
			stagePrompt := promptui.Select{
				Label: "Select stage to inspect",
				Items: stageNames,
			}

			_, selectedStageItem, err := stagePrompt.Run()
			if err != nil {
				return fmt.Errorf("stage selection cancelled: %w", err)
			}

			stageName := strings.Split(selectedStageItem, " - ")[0]

			// Find the selected stage
			var selectedStage *types.StageState
			for _, stage := range stateOutput.StageStates {
				if stage.StageName != nil && *stage.StageName == stageName {
					selectedStage = &stage
					break
				}
			}

			if selectedStage == nil {
				return fmt.Errorf("stage not found")
			}

			// Show actions for selected stage
			var actionNames []string
			for _, action := range selectedStage.ActionStates {
				if action.ActionName != nil {
					actionName := *action.ActionName
					actionStatus := "Unknown"
					if action.LatestExecution != nil && action.LatestExecution.Status != "" {
						actionStatus = string(action.LatestExecution.Status)
					}
					actionNames = append(actionNames, fmt.Sprintf("%s - %s", actionName, actionStatus))
				}
			}

			// Interactive action selection
			actionPrompt := promptui.Select{
				Label: "Select action to inspect",
				Items: actionNames,
			}

			_, selectedActionItem, err := actionPrompt.Run()
			if err != nil {
				return fmt.Errorf("action selection cancelled: %w", err)
			}

			actionName := strings.Split(selectedActionItem, " - ")[0]

			// Find the selected action
			var selectedAction *types.ActionState
			for _, action := range selectedStage.ActionStates {
				if action.ActionName != nil && *action.ActionName == actionName {
					selectedAction = &action
					break
				}
			}

			if selectedAction == nil {
				return fmt.Errorf("action not found")
			}

			// Display detailed action information
			fmt.Printf("\n%s\n", utils.GreenBold("Action Details:"))
			fmt.Printf("Action name: %s\n", utils.GreenBold(*selectedAction.ActionName))

			if selectedAction.LatestExecution != nil {
				if selectedAction.LatestExecution.Status != "" {
					fmt.Printf("Status: %s\n", utils.GreenBold(string(selectedAction.LatestExecution.Status)))
				}
				if selectedAction.LatestExecution.ErrorDetails != nil && selectedAction.LatestExecution.ErrorDetails.Message != nil {
					fmt.Printf("Description: %s\n", utils.GreenBold(*selectedAction.LatestExecution.ErrorDetails.Message))
				}
			}

			if selectedAction.EntityUrl != nil {
				fmt.Printf("URL: %s\n", utils.GreenBold(*selectedAction.EntityUrl))
			}
		}

		return nil
	},
}

func init() {
	rootCmd.AddCommand(pipelineCmd)
	pipelineCmd.Flags().BoolVarP(&debug, "debug", "d", false, "Inspect each step")
}

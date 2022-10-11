#!/usr/bin/env bash
check_profile 

pipeline_name=$( aws codepipeline list-pipelines | jq ".pipelines[].name" | sed 's/"//g' | fzf )

pipeline=$( aws codepipeline get-pipeline-state --name "$pipeline_name" )

if ! [[ "${args[--debug]}" ]]
then
	for stage in $(echo "$pipeline" | jq -r '.stageStates[].stageName')
	do
		stage_state=$(echo "$pipeline" | jq -r '.stageStates[] | select(.stageName == "'"$stage"'")')
		echo "$stage_state" | jq -r '. | "'"$(green_bold "\(.stageName)")"' - '"$(yellow "\(.latestExecution.status)")"'\n"'
		echo "$stage_state" | jq -r '.actionStates[] | "\(.actionName) - '"$(yellow "\(.latestExecution.status)")"' '"$(cyan "\(.latestExecution.lastStatusChange)")"' "'
		echo ""
	done
fi

p_step=$(echo "$pipeline" | jq -r '.stageStates[] | "\(.stageName) - \(.latestExecution.status)" ' | fzf | awk '{print $1}' )
step=$(echo "$pipeline" | jq -r '.stageStates[] | select(.stageName == "'"$p_step"'")')
p_action=$(echo "$step" |  jq -r '.actionStates[] | "\(.actionName) - \(.latestExecution.status)"' | fzf | awk '{print $1}' )
action=$(echo "$step" | jq -r '.actionStates[] | select(.actionName == "'"$p_action"'")')

echo "$action" \
	| jq -r '. | "action name:'"$(green_bold "\(.actionName)")"'\nstatus: '"$(green_bold "\(.latestExecution.status)")"'\ndescription: '"$(green_bold "\(.latestExecution.errorDetails.message)")"'\nURL: '"$(green_bold "\(.entityUrl)")"'"'



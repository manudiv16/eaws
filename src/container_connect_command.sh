#!/usr/bin/env bash
check_profile 

# Get cluster
cluster=$( aws ecs list-clusters \
		|jq -r '.clusterArns[]' \
		| awk -F'/' '{print $2}' \
		| fzf )

short_cluster="--cluster ${cluster}"

# Get service
service=$(aws ecs \
		list-services ${short_cluster} \
		| jq '.serviceArns[]' \
		| awk -F'/' '{print $3}' \
		| sed 's/"//g' \
		| awk 'NF' \
		| fzf ) 

# Get task id
task=$( aws ecs \
		list-tasks ${short_cluster} \
		--service-name ${service} \
		| jq '.taskArns[]' \
		| sed 's/"//g' \
		| fzf -1 )

# container
describe_container=$( aws ecs \
		describe-tasks ${short_cluster} \
		--tasks ${task} )

conteiner_instance_id=$( echo ${describe_container} \
		| jq -r '.tasks[0].containerInstanceArn' )

container_runtime_id=$( echo ${describe_container} \
		| jq '.tasks[0].containers[] | "\(.name) \(.lastStatus) \(.healthStatus) \(.runtimeId)"' \
		| fzf -1 \
		| awk '{print $NF}' \
		| sed 's/"//g' )

ec2_instance=$( aws ecs \
		describe-container-instances ${short_cluster} \
		--container-instances ${conteiner_instance_id} \
		| jq -r '.containerInstances[0].ec2InstanceId' ) 

# Get target ssm
document_name="AWS-StartInteractiveCommand"

aws ssm start-session \
		--target ${ec2_instance} \
		--document-name ${document_name} \
		--parameters command="sudo docker exec -ti ${container_runtime_id} sh"

#!/usr/bin/env bash
check_profile 

# Get cluster
cluster=$( aws ecs list-clusters \
		| jq -r '.clusterArns[]' \
		| awk -F'/' '{print $2}' \
		| fzf )

# Get service
aws ecs list-services \
		--cluster ${cluster} \
		| jq '.serviceArns[]' \
		| awk -F'/' '{print $3}' \
		| sed 's/"//g' \
		| awk 'NF'  



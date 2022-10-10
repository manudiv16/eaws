check_profile 

# Get cluster
cluster=$(aws ecs list-clusters |jq -r '.clusterArns[]'| awk -F'/' '{print $2}'| fzf)

prof_clu="--cluster ${cluster}"

# Get service
aws ecs list-services ${prof_clu} | jq '.serviceArns[]' | awk -F'/' '{print $3}'| sed 's/"//g' | awk 'NF'  



check_profile() {
	if [ "${args[--profile]}" ];then
		source assume ${args[--profile]}
	elif [ "${AWS_PROFILE:-}" ]
	then
		source assume ${AWS_PROFILE:-}
	else 
		source assume ${args[--profile]}
	fi
}
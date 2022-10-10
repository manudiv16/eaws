#!/usr/bin/env bash
# shellcheck source=/dev/null
check_profile() {
	if [ "${args[--profile]}" ];then
		source assume "${args[--profile]}"
	elif ! [ "${AWS_PROFILE:-}" ]
	then
		source assume
	fi
}
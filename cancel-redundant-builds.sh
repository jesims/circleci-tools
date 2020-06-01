#!/usr/bin/env bash

echo-error () {
	echo "ERROR: $*"
}

var-set () {
	local val
	val=$(eval "echo \$$1")
	[ -n "$val" ]
}

require-var () {
	local var
	for var in "$@";do
		if ! var-set "$var";then
			echo-error "$var not defined"
			exit 1
		fi
	done
}

abort-on-error () {
	if [ $? -ne 0 ]; then
		echo-error "$@"
		exit 1
	fi
}

require-var CIRCLE_BUILD_NUM

if [ -n "$CIRCLECI" ];then
	PROJECT_VCS_TYPE=${PROJECT_VCS_TYPE:-'github'}
	require-var PROJECT_VCS_TYPE CIRCLE_PROJECT_USERNAME CIRCLE_PROJECT_REPONAME CIRCLE_BRANCH
	BASE_API_URL="https://circleci.com/api/v1.1/project/$PROJECT_VCS_TYPE/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/tree/$CIRCLE_BRANCH"
else
	require-var BASE_API_URL
	CIRCLE_TOKEN=''
fi

circle-get () {
	if [[ "$BASE_API_URL" != https://circleci.com/* ]];then
		cat "$BASE_API_URL.json"
	else
		require-var CIRCLE_TOKEN
		curl --silent \
			-H "Content-Type: application/json" \
			"${BASE_API_URL}?circle-token=${CIRCLE_TOKEN}"
	fi
}

node-date() {
	local date="$1"
	if [ -n "$date" ] && [ "$date" != 'null' ];then
		node -e "console.log(new Date(\"${date}\"))"
	fi
}

v=$(circle-get)
abort-on-error "getting builds from CircleCI: $v"
require-var v
if [ "$(echo "$v" | jq)" == '[]' ];then
	echo 'No builds found. Got empty response from CircleCI'
	exit 0
fi
current_build=$(echo "$v" | jq --raw-output ".[] | select(.build_num==$CIRCLE_BUILD_NUM)")
abort-on-error "finding current build: $current_build"
if [ -z "$current_build" ];then
	echo 'Could not find current build'
	exit 0
fi
require-var current_build
current_workflow_id=$(echo "${current_build}" | jq --raw-output ".workflows.workflow_id")
require-var current_workflow_id
current_author_date=$(node-date "$(echo "${current_build}" | jq --raw-output ".author_date")")
matches=$(echo "${v}" | jq --raw-output ".[] | select(.workflows.workflow_id!=\"$current_workflow_id\") | .author_date")

if [ -n "$current_author_date" ];then
	for date in ${matches};do
		date=$(node-date "$date")
		if [[ "$date" > "$current_author_date" ]]; then
			echo "Newer builds found $date > $current_author_date"
			exit 1
		fi
	done
fi

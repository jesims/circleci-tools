#!/usr/bin/env bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_VCS_TYPE=${PROJECT_VCS_TYPE:-'github'}
if [[ -n "$CIRCLECI" ]];then
	BASE_API_URL="https://circleci.com/api/v1.1/project/$PROJECT_VCS_TYPE/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/tree/$CIRCLE_BRANCH"
else
	BASE_API_URL="file"
	CIRCLE_TOKEN="UNDEFINED"
fi

echo-error () {
	echo "ERROR: $*"
}

var-set () {
	local val=$(eval "echo \$$1")
	test -n "$val"
}

require-var () {
	if ! var-set "$1";then
		echo-error "$1 not defined"
		exit 1
	fi
}

circle-get () {
	require-var CIRCLE_TOKEN
	if [[ "$BASE_API_URL" == "file" ]];then
		cat test.json
	else
		curl --silent \
			-H "Content-Type: application/json" \
			"${BASE_API_URL}?circle-token=${CIRCLE_TOKEN}"
	fi
}

node-date() {
	local date="$1"
	if [[ -n "$date" ]] && [[ "$date" != "null" ]];then
		node -e "console.log(new Date(\"${date}\"))"
	fi
}

v=$(circle-get)
require-var v
current_build=$(echo "$v" | jq --raw-output ".[] | select(.build_num==$CIRCLE_BUILD_NUM)")
require-var current_build
current_workflow_id=$(echo ${current_build} | jq --raw-output ".workflows.workflow_id")
require-var current_workflow_id
current_author_date=$(node-date $(echo ${current_build} | jq --raw-output ".author_date"))
matches=$(echo ${v} | jq --raw-output ".[] | select(.workflows.workflow_id!=\"$current_workflow_id\") | .author_date")

if [[ -n "$current_author_date" ]];then
	for date in ${matches};do
		date=$(node-date "$date")
		if [[ "$date" > "$current_author_date" ]]; then
			echo "Newer builds found $date > $current_author_date"
			exit 1
		fi
	done
fi

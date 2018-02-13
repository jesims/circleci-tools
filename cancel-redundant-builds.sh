#!/usr/bin/env bash

if [[ -n "$CIRCLECI" ]];then
	BASE_API_URL="https://circleci.com/api/v1.1/project/github/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/tree/$CIRCLE_BRANCH"
else
    CIRCLE_BUILD_NUM="8720"
	BASE_API_URL="http://localhost:3000/test.json"
	CIRCLE_TOKEN="UNDEFINED"
fi

echo_error () {
    echo "ERROR: $*"
}

var_set () {
    local val=$(eval "echo \$$1")
    test -n "$val"
}

require_var () {
    if ! var_set $1;then
        echo_error "$1 not defined"
        exit 1
    fi
}

circle_get () {
	require_var CIRCLE_TOKEN
	curl --silent \
        -H "Content-Type: application/json" \
		${BASE_API_URL}
}

v=$(circle_get)
current_build=$(echo ${v} | jq --raw-output ".[] | select(.build_num==$CIRCLE_BUILD_NUM)")
current_workflow_id=$(echo ${current_build} | jq --raw-output ".workflows.workflow_id")
current_author_date=$(echo ${current_build} | jq --raw-output ".author_date")
matches=$(echo ${v} | jq --raw-output ".[] | select((.workflows.workflow_id!=\"$current_workflow_id\") and (.author_date > \"$current_author_date\")) | .workflows.job_id")

if [[ -z "$matches" ]];then
    echo "No future builds found. Progressing"
else
    echo "I Should Cancel"
    echo "Future builds found. Halting"
    exit 1
fi


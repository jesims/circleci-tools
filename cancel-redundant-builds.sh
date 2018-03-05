#!/usr/bin/env bash
dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_VCS_TYPE=${PROJECT_VCS_TYPE:-'github'}
if [[ -n "$CIRCLECI" ]];then
	BASE_API_URL="https://circleci.com/api/v1.1/project/$PROJECT_VCS_TYPE/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/tree/$CIRCLE_BRANCH"
else
	BASE_API_URL="file"
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
	if [[ "$BASE_API_URL" == "file" ]];then
	    cat test.json
    else
        curl --silent \
            -H "Content-Type: application/json" \
            "${BASE_API_URL}?circle-token=${CIRCLE_TOKEN}"
    fi
}

v=$(circle_get)
require_var v
current_build=$(echo ${v} | jq --raw-output ".[] | select(.build_num==$CIRCLE_BUILD_NUM)")
require_var current_build
current_workflow_id=$(echo ${current_build} | jq --raw-output ".workflows.workflow_id")
require_var current_workflow_id
current_author_date=$(echo ${current_build} | jq --raw-output ".author_date")
require_var current_author_date
matches=$(echo ${v} | jq --raw-output ".[] | select(.workflows.workflow_id!=\"$current_workflow_id\") | .author_date")
current_author_date=$(node "$dir/toDate.js" ${current_author_date})

for d in $matches;do
    d=$(node toDate.js ${d})
    if [[ ${d} > ${current_author_date} ]]; then
        echo "Newer builds found ${d} > ${current_author_date}"
        exit 1
    fi
done


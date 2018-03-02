#!/usr/bin/env bash

export CIRCLECI=""
export PROJECT_VCS_TYPE="github"

function test_should_abort(){
    export CIRCLE_BUILD_NUM="9305"
    ./cancel-redundant-builds.sh
    status=$?
    if [[ ${status} == 0 ]];then
        echo "Test failed"
        exit 1
    fi
}

function test_should_pass(){
    export CIRCLE_BUILD_NUM="9311"
    ./cancel-redundant-builds.sh
    status=$?
    if [[ ${status} != 0 ]];then
        echo "Test failed"
        exit 1
    fi
}

test_should_abort && \
test_should_pass

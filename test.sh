#!/usr/bin/env bash
cd "$(realpath "$(dirname "$0")")" &&
source bindle/project.sh
if [ $? -ne 0 ]; then
	exit 1
fi

export CIRCLECI=''

assert-not-failed(){
	if [ $? != 0 ];then
		echo 'Test failed'
		exit 1
	fi
}

assert-failed(){
	if [ $? == 0 ];then
		echo 'Test did not fail'
		exit 1
	fi
}

test_should_abort(){
	export BASE_API_URL='test'
	export CIRCLE_BUILD_NUM='9305'
	./cancel-redundant-builds.sh
	assert-failed
}

test_should_pass(){
	export BASE_API_URL='test'
	export CIRCLE_BUILD_NUM='9311'
	./cancel-redundant-builds.sh
	assert-not-failed
}

test_should_skip(){
	export BASE_API_URL='test'
	export CIRCLE_BUILD_NUM='9312'
	./cancel-redundant-builds.sh
	assert-not-failed
}

test_empty(){
	export BASE_API_URL='empty'
	./cancel-redundant-builds.sh
	assert-not-failed
}

test_not_found(){
	export BASE_API_URL='test'
	export CIRCLE_BUILD_NUM='9313'
	./cancel-redundant-builds.sh
	assert-not-failed
}

-lint &&
echo-message 'Running tests' &&
test_should_abort &&
test_should_pass &&
test_should_skip &&
test_empty &&
test_not_found

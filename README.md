# circleci-tools

A collection of CircleCI tools to optimise build times and workflows

## Requirements

* bash
* jq
* nodejs (becuase CircleCI date values are not all UTC... Some have offsets)
* wget or curl

## Usage

1. Add CIRCLE_TOKEN environment variable to your project
1. Add `wget` or `curl` and script execution when you wish to check for newer builds

### Example CircleCI config

    jobs:
      test:
        docker:
          - image: jesiio/docker-git-awscli:latest
        steps:
          - run: 'curl -sSk https://raw.githubusercontent.com/jesims/circleci-tools/master/cancel-redundant-builds.sh | bash'
          - checkout
          - run: './test.sh'

    workflows:
      version: 2
      build_and_test:
        jobs:
          - test

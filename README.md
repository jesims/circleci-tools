# circleci-tools
A collection of CircleCI tools to optimise build times and workflows

## Requirements
- bash
- jq
- wget
- curl

## Usage

1. Add CIRCLE_TOKEN environment variable to your project
2. Add `wget` and script execution when you wish to check for newer builds

### Example CircleCI config

```
jobs:
  test:
    docker:
      - image: jesiio/docker-git-awscli:latest
    steps:
      - run: 'wget -O - https://raw.githubusercontent.com/jesims/circleci-tools/master/cancel-redundant-builds.sh | bash'
      - checkout
      - run: './test.sh'

workflows:
  version: 2
  build_and_test:
    jobs:
      - test
```

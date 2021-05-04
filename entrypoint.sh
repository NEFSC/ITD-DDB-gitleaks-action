#!/bin/bash

INPUT_APPEND_REPO_CONFIG="$1"
APPEND=""

INPUT_CONFIG_PATH="$2"
CONFIG=""

# check if a custom append config have been provided
if [ -f "$GITHUB_WORKSPACE/$INPUT_APPEND_REPO_CONFIG" ]; then
  APPEND=" --append-repo-config=$GITHUB_WORKSPACE/$INPUT_APPEND_REPO_CONFIG"
fi


# check if a custom config have been provided
if [ -f "$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH" ]; then
  CONFIG=" --config-path=$GITHUB_WORKSPACE/$INPUT_CONFIG_PATH"
fi

echo running gitleaks "$(gitleaks --version) with the following command👇"


if [ "$GITHUB_EVENT_NAME" = "push" ]
then
  echo gitleaks --path=$GITHUB_WORKSPACE --verbose --redact $APPEND $CONFIG
  CAPTURE_OUTPUT=$(gitleaks --path=$GITHUB_WORKSPACE --verbose --redact $APPEND $CONFIG)
elif [ "$GITHUB_EVENT_NAME" = "pull_request" ]
then 
  git --git-dir="$GITHUB_WORKSPACE/.git" log --left-right --cherry-pick --pretty=format:"%H" remotes/origin/$GITHUB_BASE_REF... > commit_list.txt
  echo gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $APPEND $CONFIG
  CAPTURE_OUTPUT=$(gitleaks --path=$GITHUB_WORKSPACE --verbose --redact --commits-file=commit_list.txt $APPEND $CONFIG)
fi

if [ $? -eq 1 ]
then
  GITLEAKS_RESULT=$(echo -e "\e[31m🛑 STOP! Gitleaks encountered leaks")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "----------------------------------"
  echo "$CAPTURE_OUTPUT"
  echo "::set-output name=result::$CAPTURE_OUTPUT"
  echo "----------------------------------"
  exit 1
else
  GITLEAKS_RESULT=$(echo -e "\e[32m✅ SUCCESS! Your code is good to go!")
  echo "$GITLEAKS_RESULT"
  echo "::set-output name=exitcode::$GITLEAKS_RESULT"
  echo "------------------------------------"
fi

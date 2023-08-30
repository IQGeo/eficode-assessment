#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

set +x
REPOS=$(jq -r ".[].nameWithOwner" "${2}")
DEST=../../reports/repository-actions.json
echo "[]" >$DEST
while read -r repo; do
  echo "Auditing repository actions for $repo ..."
  npx @stoe/action-reporting-cli \
    --repository "$repo" \
    --token "${GITHUB_TOKEN}" \
    --all \
    --exclude \
    --json repo-actions.json
  cp $DEST tmp.json
  jq -sc add tmp.json repo-actions.json >$DEST
  rm -rf repo-actions*.json tmp.json
  set -x
done <<<"$REPOS"

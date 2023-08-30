#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
DEST=../../reports/webhooks.json
echo "[]" >$DEST

while read -r repo; do
    echo "Auditing repository $repo ..."
    REPOHOOKS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/hooks | REPO=$repo jq '[{ repo: env.REPO, webhooks: . }]')
    echo "$REPOHOOKS_RESULT" >repo_hooks.json
    cp $DEST tmp.json
    jq -sc add tmp.json repo_hooks.json >$DEST
    rm -rf repo_hooks.json tmp.json

done <<<"$REPOS"

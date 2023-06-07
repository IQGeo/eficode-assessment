#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
echo "[]" > webhooks.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOHOOKS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/hooks | REPO=$repo jq '[{ repo: env.REPO, webhooks: . }]')
    echo "$REPOHOOKS_RESULT" > repo_hooks.json

    cp webhooks.json tmp.json
    jq -sc add tmp.json repo_hooks.json > ../../reports/webhooks.json

    rm -rf repo_hooks.json
    rm -rf tmp.json

done <<< "$REPOS"

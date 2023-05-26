#!/bin/bash

REPOS=$(jq -r ".[].name" repos.json)
echo "[]" > repoHooks.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOHOOKS_RESULT=$(gh api -H X-Github-Next-Global-ID:true /repos/$ORG_NAME/$repo/hooks | REPO=$repo jq '[{ repo: env.REPO, webhooks: . }]')
    echo "$REPOHOOKS_RESULT" > repo_hooks.json

    cp repoHooks.json tmp.json
    jq -sc add tmp.json repo_hooks.json > repoHooks.json

    rm -rf repo_hooks.json
    rm -rf tmp.json

done <<< "$REPOS"
#!/bin/bash
REPOS=$(jq -r ".[].name" repos.json)

echo "[]" > environments.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    ENV=$(gh api /repos/$ORG_NAME/$repo/environments -H X-Github-Next-Global-ID:true | REPO=$repo jq '[ { repo: env.REPO, env: [ .environments[] | { id: .id, name: .name, can_admins_bypass: .can_admins_bypass, protectionrules: [ .protection_rules[] | {id: .id, type: .type}] } ] } ]')
    echo "$ENV" > repo_env.json

    cp environments.json tmp.json
    jq -sc add tmp.json repo_env.json > environments.json

    rm -rf repo_env.json
    rm -rf tmp.json

done <<< "$REPOS"

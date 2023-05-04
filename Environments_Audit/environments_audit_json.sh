#!/bin/bash


REPOS=$(gh repo list --limit 500 "$ORG_NAME" --json name --jq '.[].name')

echo "[]" > environments.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    ENV=$(gh api /repos/$ORG_NAME/$repo/environments | REPO=$repo jq '[ { repo: env.REPO, env: [ .environments[] | { id: .id, name: .name } ] } ]')
    echo "$ENV" > repo_env.json

    cp environments.json tmp.json
    jq -s add tmp.json repo_env.json > environments.json

    rm -rf repo_env.json
    rm -rf tmp.json

done <<< "$REPOS"

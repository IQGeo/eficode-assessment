#!/bin/bash

REPOS=$(jq -r ".[].name" repos.json)
echo "[]" > repoUsers.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOUSERS_RESULT=$(gh api -H X-Github-Next-Global-ID:true /repos/$ORG_NAME/$repo/collaborators?affiliation=all | REPO=$repo jq '[{ repo: env.REPO, users: [{ login: .[].login }] }]')
    echo "$REPOUSERS_RESULT" > repo_users.json
    
    cp repoUsers.json tmp.json
    jq -sc add tmp.json repo_users.json > repoUsers.json

    rm -rf repo_users.json
    rm -rf tmp.json

done <<< "$REPOS"
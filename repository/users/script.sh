#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
echo "[]" > users.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOUSERS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/collaborators?affiliation=all | REPO=$repo jq '[{ repo: env.REPO, users: [{ login: .[].login }] }]')
    echo "$REPOUSERS_RESULT" > repo_users.json

    cp users.json tmp.json
    jq -sc add tmp.json repo_users.json > ../../reports/users.json

    rm -rf repo_users.json
    rm -rf tmp.json

done <<< "$REPOS"

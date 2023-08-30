#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
DEST=../../reports/users.json
echo "[]" >$DEST

while read -r repo; do
    echo "Auditing repository $repo ..."
    REPOUSERS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/collaborators?affiliation=all | REPO=$repo jq '[{ repo: env.REPO, users: [{ login: .[].login }] }]')
    echo "$REPOUSERS_RESULT" >repo_users.json
    cp $DEST tmp.json
    jq -sc add tmp.json repo_users.json >$DEST
    rm -rf repo_users.json tmp.json
done <<<"$REPOS"

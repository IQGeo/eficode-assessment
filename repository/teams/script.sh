#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
DEST=../../reports/teams.json
echo "[]" >$DEST

while read -r repo; do
    echo "Auditing repository $repo ..."

    REPOTEAMS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/teams | REPO=$repo jq '[{ repo: env.REPO, teams: [ { name: .[].name } ] }]')
    echo "$REPOTEAMS_RESULT" >repo_teams.json

    cp $DEST tmp.json
    jq -sc add tmp.json repo_teams.json >$DEST

    rm -rf repo_teams.json tmp.json
done <<<"$REPOS"

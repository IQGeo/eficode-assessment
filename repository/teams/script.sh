#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
echo "[]" > teams.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOTEAMS_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/teams | REPO=$repo jq '[{ repo: env.REPO, teams: [ { name: .[].name } ] }]')
    echo "$REPOTEAMS_RESULT" > repo_teams.json

    cp teams.json tmp.json
    jq -sc add tmp.json repo_teams.json > ../../reports/teams.json

    rm -rf repo_teams.json
    rm -rf tmp.json

done <<< "$REPOS"

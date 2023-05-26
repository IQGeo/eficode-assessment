#!/bin/bash

REPOS=$(jq -r ".[].name" repos.json)
echo "[]" > repoTeams.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    REPOTEAMS_RESULT=$(gh api -H X-Github-Next-Global-ID:true /repos/$ORG_NAME/$repo/teams | REPO=$repo jq '[{ repo: env.REPO, teams: [ { name: .[].name } ] }]')
    echo "$REPOTEAMS_RESULT" > repo_teams.json
    
    cp repoTeams.json tmp.json
    jq -sc add tmp.json repo_teams.json > repoTeams.json

    rm -rf repo_teams.json
    rm -rf tmp.json

done <<< "$REPOS"
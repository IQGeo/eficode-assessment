#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
echo "[]" > environments.json
echo "[]" > environments_secrets.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    # Get the environment meta data for this repository without secrets
    ENV=$(gh api --paginate /repos/${1}/$repo/environments -H X-Github-Next-Global-ID:true | REPO=$repo jq '[ { repo: env.REPO, env: [ .environments[] | { name: .name, can_admins_bypass: .can_admins_bypass, protectionrules: [ .protection_rules[] | {id: .id, type: .type}] } ] } ]')
    echo "$ENV" > repo_env.json
    cp environments.json tmp.json
    jq -sc add tmp.json repo_env.json > ../../reports/environments.json

    # Get the environment secrets for this repository
    ENVNAMES=$(jq -r ".[].env[].name" repo_env.json)
    echo "[]" > spec_environments_secrets.json
    while read -r envname ; do
        if [ -z $envname ]
        then
            continue
        fi

        ENVSECRETS=$(gh api --paginate /repos/${1}/$repo/environments/$envname/secrets -H X-Github-Next-Global-ID:true | REPO=$repo ENVNAME=$envname jq '[ {  name : env.ENVNAME , secrets: .secrets } ]')
        echo $ENVSECRETS > repo_env_secrets.json

        cp spec_environments_secrets.json tmpsecrets.json

        jq -s add tmpsecrets.json repo_env_secrets.json > spec_environments_secrets.json

        rm -rf repo_env_secrets.json tmpsecrets.json
    done <<< "$ENVNAMES"

    # Merge the environment secrets into environments_secrets.json
    ENVSECRETS=$(jq -r --arg REPO "$repo" '[{ repo: $REPO, env: . }]' spec_environments_secrets.json)
    echo $ENVSECRETS > envsecrets.json

    cp environments_secrets.json tmp.json

    jq -sc add tmp.json envsecrets.json > ../../reports/environments_secrets.json

    rm -rf repo_env.json tmp.json envsecrets.json, spec_environments_secrets.json

done <<< "$REPOS"

# # merge result into single json document - not currently working
# jq -s '.[0] + .[1]
#             | group_by(.repo)
#             | map({
#                         "repo": .[0].repo,
#                         "env": (
#                             group_by(.env[].name) |
#                             map({
#                                 name: first.env[].name,
#                                 can_admins_bypass: first.env[].can_admins_bypass,
#                                 protectionRules: ( map(.env[].protectionrules | select( . != null ))),
#                                 secrets: ( map(.env[].secrets | select( . != null )))
#                             })
#                         )
#                 })' environments.json environments_secrets.json > environments_merged.json

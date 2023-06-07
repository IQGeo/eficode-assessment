#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)

RESULT_PERMISSIONS='['

while read -r repo ; do

  RESULT_PERMISSIONS+='{"repo":"'
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+='", "permissions":'


  USER_PERMISSIONS=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/collaborators --jq '[ .[] | { login: .login, role_name: .role_name } ]')

  RESULT_PERMISSIONS+=$USER_PERMISSIONS

  RESULT_PERMISSIONS+='},'

done <<< "$REPOS"

RESULT_PERMISSIONS=${RESULT_PERMISSIONS::-1}
RESULT_PERMISSIONS+=']'

echo "$RESULT_PERMISSIONS" > ../../reports/permissions.json


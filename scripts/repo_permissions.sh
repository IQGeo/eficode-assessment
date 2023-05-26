#!/bin/bash


REPOS=$(jq -r ".[].name" repos.json)

RESULT_PERMISSIONS='['

while read -r repo ; do

  RESULT_PERMISSIONS+='{"repo":"'
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+='", "permissions":'


  USER_PERMISSIONS=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/$ORG_NAME/$repo/collaborators --jq '[ .[] | { login: .login, role_name: .role_name } ]')

  RESULT_PERMISSIONS+=$USER_PERMISSIONS

  RESULT_PERMISSIONS+='},'

done <<< "$REPOS"

RESULT_PERMISSIONS=${RESULT_PERMISSIONS::-1}
RESULT_PERMISSIONS+=']'

echo "$RESULT_PERMISSIONS" > permissions.json


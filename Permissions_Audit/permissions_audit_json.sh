#!/bin/bash


REPOS=$(gh repo list --limit 500 "$ORG_NAME" --json name --jq '.[].name')

RESULT_PERMISSIONS='['

while read -r repo ; do

  RESULT_PERMISSIONS+='{"repo":"'
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+='", "permissions":'


  USER_PERMISSIONS=$(gh api --paginate /repos/$ORG_NAME/$repo/collaborators --jq '[ .[] | { login: .login, role_name: .role_name } ]')

  RESULT_PERMISSIONS+=$USER_PERMISSIONS

  RESULT_PERMISSIONS+='},'

done <<< "$REPOS"

RESULT_PERMISSIONS=${RESULT_PERMISSIONS::-1}
RESULT_PERMISSIONS+=']'

echo "$RESULT_PERMISSIONS" > permissions.json


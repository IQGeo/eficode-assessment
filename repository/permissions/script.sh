#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports
REPOS=$(jq -r ".[].name" "${2}")
RESULT_PERMISSIONS='['

while read -r repo; do
  echo "Auditing repository $repo ..."
  RESULT_PERMISSIONS+='{"repo":"'
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+='", "permissions":'
  USER_PERMISSIONS=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/${1}/$repo/collaborators --jq '[ .[] | { login: .login, role_name: .role_name } ]')
  RESULT_PERMISSIONS+=$USER_PERMISSIONS
  RESULT_PERMISSIONS+='},'
done <<<"$REPOS"
# remove last character from RESULT_PERMISSIONS

RESULT_PERMISSIONS="${RESULT_PERMISSIONS%?}"
RESULT_PERMISSIONS+=']'
echo "$RESULT_PERMISSIONS" >../../reports/permissions.json

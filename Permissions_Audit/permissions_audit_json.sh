REPOS=$(gh repo list $ORG_NAME --json name --jq '.[].name')

RESULT_PERMISSIONS='['

while read -r repo ; do

  RESULT_PERMISSIONS+='{"repo":"'
  RESULT_PERMISSIONS+="$repo"
  RESULT_PERMISSIONS+='", "permissions":'


  USER_PERMISSIONS=$(gh api /repos/$ORG_NAME/$repo/collaborators --jq '[ .[] | { login: .login, role_name: .role_name } ]')
  
  RESULT_PERMISSIONS+=$USER_PERMISSIONS

  RESULT_PERMISSIONS+='},'

done <<< $REPOS

RESULT_PERMISSIONS+=']'

gh issue comment $ISSUE_URL --body "$RESULT_PERMISSIONS"


APPS=$(gh api /orgs/$ORG_NAME/installations --jq '.installations[] | "| \(.id) | \(.app_slug) |" ')

RESULT_APPS=$'\n\n# GitHub Apps \n'
RESULT_APPS+=$'| AppID | AppName |'
RESULT_APPS+=$'\n'
RESULT_APPS+=$'|---|---|'
RESULT_APPS+=$'\n'
RESULT_APPS+="$APPS"
RESULT_APPS+=$'\n\n'

gh issue comment $ISSUE_URL --body "$RESULT_APPS"
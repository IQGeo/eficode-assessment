APPS=$(gh api /orgs/$ORG_NAME/installations | jq -r '[.installations[] | {id: .id, app_slug: .app_slug}]' )

RESULT_APPS='"apps":'
RESULT_APPS+=$APPS

echo $RESULT_APPS

gh issue comment $ISSUE_URL --body "$RESULT_APPS"
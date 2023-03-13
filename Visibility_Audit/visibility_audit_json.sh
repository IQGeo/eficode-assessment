REPOS=$(gh api /orgs/$ORG_NAME/repos | jq -r '[ .[] | select(.visibility != "private") | { repo: .name, visibility: .visibility } ]')

RESULT_VISIBILITY=$REPOS

gh issue comment $ISSUE_URL --body "$RESULT_VISIBILITY"

echo $RESULT_VISIBILITY > visibility.json

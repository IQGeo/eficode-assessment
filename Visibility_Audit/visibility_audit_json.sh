REPOS=$(gh api /orgs/$ORG_NAME/repos | jq -r '[ .[] | select(.visibility != "private") | { repo: .name, visbility: .visibility } ]')

RESULT_VISIBILITY=$REPOS

gh issue comment $ISSUE_URL --body "$RESULT_VISIBILITY"


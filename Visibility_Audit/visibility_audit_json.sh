#!/bin/bash

REPOS=$(gh api --paginate "/orgs/$ORG_NAME/repos" | jq -r '[ .[] | select(.visibility != "private") | { repo: .name, visibility: .visibility } ]')

RESULT_VISIBILITY=$REPOS

echo "$RESULT_VISIBILITY" > visibility.json

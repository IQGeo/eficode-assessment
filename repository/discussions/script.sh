#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" "${2}")
DEST=../../reports/discussions.json
echo "[]" >$DEST

while read -r repo; do
  echo "Auditing repository $repo ..."

  DISCUSSIONS_RESULT=$(
    gh api graphql --paginate -H X-Github-Next-Global-ID:true -F owner="${1}" -F name="${repo}" -f query='query($owner: String!, $name: String!, $endCursor: String = null) {
      repository(owner: $owner, name: $name) {
        discussions(first: 100, after: $endCursor) {
          totalCount
          nodes {
            id
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    }' | REPO=$repo jq '[{ repo: env.REPO, discussions: .data.repository.discussions.totalCount }]'
  )
  echo "$DISCUSSIONS_RESULT" >repo_discussions.json

  cp $DEST tmp.json
  jq -sc add tmp.json repo_discussions.json >$DEST
  rm -rf repo_discussions.json tmp.json
done <<<"$REPOS"

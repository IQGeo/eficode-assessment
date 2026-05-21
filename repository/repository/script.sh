#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

DEST=../../reports/repos.json
echo "[]" >$DEST
REPOS=$(echo "$2" | tr ',' '\n')

# iterate over REPOS
for REPO in $REPOS; do
  echo "Getting repo: $REPO"
  REPOSITORIES=$(gh api graphql \
    -H X-Github-Next-Global-ID:true \
    -F owner="${1}" \
    -F name="$REPO" \
    -f query='query getRepo($owner: String!, $name: String!) {
    repository(owner: $owner, name: $name) {
      name
      nameWithOwner
      visibility
      isFork
      hasProjectsEnabled
      hasDiscussionsEnabled
      diskUsage
      updatedAt
      gitattributes: object(expression: "HEAD:.gitattributes") {
        __typename
      }
      lfsconfig: object(expression: "HEAD:.lfsconfig") {
        __typename
      }
      languages(first: 10) {
        edges {
          node { name }
          size
        }
      }
    }
  }' \
    --jq '.data.repository' |
    jq '.languages = [(.languages // {}).edges // [] | .[] | {name: .node.name, size: .size}]' |
    jq -s '.')
  echo "$REPOSITORIES" >repo.json
  cp $DEST tmp.json
  jq -sc add tmp.json repo.json >$DEST
  rm -rf repo.json tmp.json
done

#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

gh api graphql --paginate \
  -H X-Github-Next-Global-ID:true \
  -F login="${1}" \
  -f query='query getRepoPlusPlus($login: String!, $endCursor: String = null) {
  organization(login: $login) {
    repositories(first: 10, after: $endCursor) {
      totalCount
      nodes {
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
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
  rateLimit {
    cost
    nodeCount
  }
}' \
  --jq '.data.organization.repositories.nodes[]' \
  | jq '.languages = [(.languages // {}).edges // [] | .[] | {name: .node.name, size: .size}]' \
  | jq -sc > ../../reports/repos.json

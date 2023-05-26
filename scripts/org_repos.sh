#!/bin/bash
echo 'starting...'
REPOS=$(gh api graphql --paginate -H X-Github-Next-Global-ID:true -f query='query getRepoPlusPlus($endCursor: String = null) {
	organization(login: "'$ORG_NAME'") {
		repositories(first: 100, after: $endCursor) {
			totalCount
			nodes {
                name
				visibility
				isFork
				hasProjectsEnabled
				hasDiscussionsEnabled
				diskUsage
                nameWithOwner
                updatedAt

                
				gitattributes: object(expression: "HEAD:.gitattributes") {
					__typename
				}

                lfsconfig: object(expression: "HEAD:.lfsconfig") {
					__typename
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
}
' --jq '.data.organization.repositories.nodes[]'  | jq -sc > repos.json)

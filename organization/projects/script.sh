#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

PROJECTS_V2_RESULT=$(gh api graphql --paginate -H X-Github-Next-Global-ID:true -F login="${1}" -f query='
  query getProjectsV2($login: String!, $endCursor: String = null){
    organization(login: $login){
      projectsV2(first: 100, after: $endCursor) {
        nodes {
          id
          title
        }
        pageInfo {
				  hasNextPage
				  endCursor
			  }
      }

    }
  }' | jq '{ projectsV2: [ .data.organization.projectsV2.nodes[] ] }'
)

PROJECTS_OLD_RESULT=$(gh api graphql --paginate -H X-Github-Next-Global-ID:true -F login="${1}" -f query='
  query getProjectsOld($login: String!, $endCursor: String = null){
    organization(login: $login){
      projects(first: 100, after: $endCursor) {
        nodes {
          id
          name
        }
        pageInfo {
			  	hasNextPage
				  endCursor
			  }
      }
    }
  }' | jq '{ projectsOld: [ .data.organization.projects.nodes[] ] }'
)

echo "$PROJECTS_OLD_RESULT" > PROJECTS_OLD_RESULT.json
echo "$PROJECTS_V2_RESULT" > PROJECTS_V2_RESULT.json

JSON_RESULT=$(jq -sc 'add' PROJECTS_OLD_RESULT.json PROJECTS_V2_RESULT.json | ORG_NAME="${1}" jq -c '[{ org: env.ORG_NAME, projects: .}]')

echo "$JSON_RESULT" > ../../reports/projects.json

rm -rf PROJECTS_OLD_RESULT.json
rm -rf PROJECTS_V2_RESULT.json

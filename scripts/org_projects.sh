#!/bin/bash

PROJECTS_V2_RESULT=$(gh api graphql --paginate -f query='
  query getProjectsV2($endCursor: String = null){
    organization(login: "'$ORG_NAME'"){
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

PROJECTS_OLD_RESULT=$(gh api graphql --paginate -f query='
  query getProjectsOld($endCursor: String = null){
    organization(login: "'$ORG_NAME'"){
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

JSON_RESULT=$(jq -sc 'add' PROJECTS_OLD_RESULT.json PROJECTS_V2_RESULT.json | ORG_NAME="$ORG_NAME" jq '[{ org: env.ORG_NAME, projects: .}]')

echo "$JSON_RESULT" > projects.json
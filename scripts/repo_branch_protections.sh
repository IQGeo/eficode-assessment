#!/bin/bash

REPOS=$(jq -r ".[].name" repos.json)
echo "[]" > protections.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    PROTECTIONS_RESULT=$(gh api graphql -H X-Github-Next-Global-ID:true -f query='query {
	      repository(owner: "'$ORG_NAME'", name: "'$repo'") {
          branchProtectionRules(first: 20) {
            nodes {
                id
                pattern
                allowsDeletions
                allowsForcePushes
                blocksCreations
                dismissesStaleReviews
                isAdminEnforced
                lockAllowsFetchAndMerge
                lockBranch
                requireLastPushApproval
                requiredApprovingReviewCount
                requiresApprovingReviews
                requiredDeploymentEnvironments
                requiredStatusCheckContexts
                requiresApprovingReviews
                lockBranch
                restrictsPushes
                allowsForcePushes
                requiredStatusChecks {
                    app { name } 
                    context 
                    ... on RequiredStatusCheckDescription {
                        app {
                            slug
                            url
                        }
                    }
                }
                bypassPullRequestAllowances(first: 10) {
                    nodes {
                        actor {
                            ... on User {
                                id
                                login
                            }
                            ... on Team {
                                id
                                name
                            }
                            ... on App {
                                id
                                name
                            }
                        }
                    }
                }
            }
          }
        }
      }' | REPO=$repo jq '[{ repo: env.REPO, branchProtectionRules: [ .data.repository.branchProtectionRules.nodes[] ] }]'
    )

    echo "$PROTECTIONS_RESULT" > repo_protections.json

    cp protections.json tmp.json
    jq -sc add tmp.json repo_protections.json > protections.json

    rm -rf repo_protections.json
    rm -rf tmp.json

done <<< "$REPOS"

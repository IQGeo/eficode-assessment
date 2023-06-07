#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

REPOS=$(jq -r ".[].name" ../../reports/repos.json)
echo "[]" > protections.json

while read -r repo ; do
    echo "Auditing repository ${repo} ..."

    PROTECTIONS_RESULT=$(gh api graphql -H X-Github-Next-Global-ID:true -F owner="${1}" -F name="${repo}" -f query='query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
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
        creator {
          login
        }
        requireLastPushApproval
        requiredApprovingReviewCount
        requiresApprovingReviews
        requiredDeploymentEnvironments
        requiredStatusCheckContexts
        requiresApprovingReviews
        requiresCodeOwnerReviews
        requiresCommitSignatures
        requiresConversationResolution
        requiresDeployments
        requiresLinearHistory
        requiresStatusChecks
        restrictsPushes
        restrictsReviewDismissals

        lockBranch
        restrictsPushes

        requiredStatusChecks {
          app {
            name
          }
          context
          ... on RequiredStatusCheckDescription {
            app {
              slug
              url
            }
          }
        }
        bypassPullRequestAllowances(first: 50) {
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
    jq -sc add tmp.json repo_protections.json > ../../reports/branch-protection-rules.json

    rm -rf repo_protections.json
    rm -rf tmp.json

done <<< "$REPOS"

#!/bin/bash

REPOS=$(gh repo list --limit 500  "$ORG_NAME" --json name --jq '.[].name')

echo "[]" > protections.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    PROTECTIONS_RESULT=$(gh api graphql -f query='
      query GetBranchProtectionRules {
        repository(owner: "'$ORG_NAME'", name: "'$repo'") {
          branchProtectionRules(first: 100) {
            nodes {
              bypassForcePushAllowances(first: 100) {
                totalCount
              }
              bypassPullRequestAllowances(first: 100) {
                totalCount
              }
              requiresApprovingReviews
              lockBranch
              restrictsPushes
              allowsForcePushes
            }
          }
        }
      }' | REPO=$repo jq '[{ repo: env.REPO, branchProtectionRules: [ .data.repository.branchProtectionRules.nodes[] ] }]'
    )

    echo "$PROTECTIONS_RESULT" > repo_protections.json

    cp protections.json tmp.json
    jq -s add tmp.json repo_protections.json > protections.json

    rm -rf repo_protections.json
    rm -rf tmp.json

done <<< "$REPOS"
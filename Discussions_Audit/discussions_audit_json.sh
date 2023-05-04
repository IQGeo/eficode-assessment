#!/bin/bash

REPOS=$(gh repo list --limit 500 "$ORG_NAME" --json name --jq '.[].name')

echo "[]" > discussions.json

while read -r repo ; do
    echo "Auditing repository $repo ..."

    DISCUSSIONS_RESULT=$(gh api graphql -f query='
      query{
        repository(owner: "'$ORG_NAME'", name: "'$repo'"){
          discussions(first: 1) {
            totalCount
          }
        }
      }' | REPO=$repo jq '[{ repo: env.REPO, discussions: .data.repository.discussions.totalCount }]'
    )
    echo "$DISCUSSIONS_RESULT" > repo_discussions.json

    cp discussions.json tmp.json
    jq -s add tmp.json repo_discussions.json > discussions.json

    rm -rf repo_discussions.json
    rm -rf tmp.json

done <<< "$REPOS"
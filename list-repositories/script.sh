#!/bin/bash

set -eo pipefail

function export_repos() {
    echo "Exporting repos"
    echo $repos > ../repos_${i}.json
    i=$((i+1))
    repos=$(jq -n '[]')
}

organization="${1}"
bucket_size="${2}"
page_size="${3}"
sleep_time="${4}"

has_next_page=true
end_cursor=null
repos=$(jq -n '[]')

i=0

echo "Bucket size: ${bucket_size}"
echo "Page size: ${page_size}"
echo "Organization: ${organization}"

while [ "$has_next_page" = "true" ]; do
echo "Fetching repositories with end_cursor: $end_cursor"
echo "Bucket: $i"


results=$(gh api graphql \
    -H X-Github-Next-Global-ID:true \
    -F login="${organization}" \
    -F endCursor="${end_cursor}" \
    -F perPage="${page_size}" \
    -f query='query getRepoPlusPlus($login: String!, $endCursor: String = null, $perPage: Int = 50) {
    organization(login: $login) {
    repositories(first: $perPage, after: $endCursor) {
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
}')
tmp_repos=$(echo $results | jq -r '.data.organization.repositories.nodes')
has_next_page=$(echo $results | jq -r '.data.organization.repositories.pageInfo.hasNextPage')
end_cursor=$(echo $results | jq -r '.data.organization.repositories.pageInfo.endCursor')

echo "has_next_page: $has_next_page"

repos=$(echo $repos $tmp_repos | jq -s add)

# if repos size is greater or equals than bucket size, then export repos and reset repos
if [ $(echo $repos | jq -r '. | length') -ge ${bucket_size} ]; then
    export_repos
fi

sleep ${sleep_time}

done

export_repos
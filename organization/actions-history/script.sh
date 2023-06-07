#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports
echo "[]" > actions-history.json

REPOS=$(jq -r ".[].name" ../../reports/repos.json)

while read -r repo ; do
    echo "Auditing repository $repo ..."
    # Set the repository owner and name
    owner=${1}

    # Get the list of workflow IDs
    workflow_ids=$(gh api --paginate -H X-Github-Next-Global-ID:true /repos/$owner/$repo/actions/workflows | jq -r '.workflows[].id'  )

    if [ -z "$workflow_ids" ]; then
        echo "No workflows found for $repo"
        continue
    fi

    # Loop over each workflow ID and get the latest run_started_at timestamp
    runs=""
    for id in $workflow_ids; do
        response=$(gh api -H X-Github-Next-Global-ID:true repos/$owner/$repo/actions/workflows/$id/runs?per_page=1 | jq -r '{name: .workflow_runs[].name, last_run: .workflow_runs[].run_started_at?}' )
        if [ -z "$response" ]; then
            echo "No runs found for workflow $id"
            continue
        fi
        runs="$runs$response,"
    done

    if [ -z "$runs" ]; then
        echo "No runs found for $repo"
        continue
    fi

    # Output the results as a JSON document
    runs="${runs%?}"
    echo "[$runs]" | REPO=$repo jq -r '[{name: env.REPO, workflows: .}]' > workflows_last_run.json

    cp actions-history.json tmp.json
    jq -sc add workflows_last_run.json tmp.json > ../../reports/actions-history.json
    rm -rf tmp.json workflows_last_run.json
done <<< "$REPOS"

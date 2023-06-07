#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

gh api --paginate -H X-Github-Next-Global-ID:true "/orgs/${1}/hooks" \
  | jq -rc ".[] | {id, name, active, type}" \
  > ../../reports/organization_webhooks.json

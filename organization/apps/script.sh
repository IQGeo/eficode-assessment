#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

gh api --paginate -H X-Github-Next-Global-ID:true "/orgs/${1}/installations" \
  | jq -rc '[.installations[] | {id: .id, app_slug: .app_slug}]' \
  > ../../reports/apps.json

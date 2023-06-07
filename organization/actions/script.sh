#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

set +x

# https://github.com/stoe/action-reporting-cli
npx @stoe/action-reporting-cli \
  --owner "${1}" \
  --token "${GITHUB_TOKEN}" \
  --listeners \
  --uses \
  --exclude \
  --unique false \
  --json ../../reports/actions.json

# Find repos with scheduled listeners
jq -c '[
  .[]
    | select(.listeners[]? | startswith("schedule"))
    | {repo: .repo, workflow: .workflow, listeners: [.listeners[]? | select(startswith("schedule"))]}
  ]' \
  ../../reports/actions.json > ../../reports/actions-scheduled-listeners.json

set -x

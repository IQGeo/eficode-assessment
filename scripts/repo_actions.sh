#!/bin/bash

set -eo pipefail

# https://github.com/stoe/action-reporting-cli
npx @stoe/action-reporting-cli \
    --owner "${ORG_NAME}" \
    --token "${GITHUB_TOKEN}" \
    --listeners \
    --uses \
    --exclude \
    --unique true \
    --json ./actions.json

#Find repos with scheduled listeners
jq -c '[.[] | select(.listeners[]? | startswith("schedule")) 
        | {repo: .repo, workflow: .workflow, listeners: [.listeners[]? | select(startswith("schedule"))]}]' \
        actions.json > actions-scheduled-listeners.json

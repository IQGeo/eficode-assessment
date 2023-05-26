#!/bin/bash


APPS=$(gh api "/orgs/$ORG_NAME/installations" | jq -r '[.installations[] | {id: .id, app_slug: .app_slug}]' )

RESULT_APPS=''
RESULT_APPS+=$APPS

echo "$RESULT_APPS" > apps.json
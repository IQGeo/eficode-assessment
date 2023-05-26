#!/bin/bash

APPS=$(gh api -H X-Github-Next-Global-ID:true "/orgs/$ORG_NAME/installations" | jq -rc '[.installations[] | {id: .id, app_slug: .app_slug}]' )
RESULT_APPS=''
RESULT_APPS+=$APPS
echo "$RESULT_APPS" > apps.json
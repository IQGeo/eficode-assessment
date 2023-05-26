#!/bin/bash


HOOKS=$(gh api -H X-Github-Next-Global-ID:true "/orgs/$ORG_NAME/hooks" | jq -rc ".[] | {id, name, active, type}" )

RESULT_HOOKS=''
RESULT_HOOKS+=$HOOKS

echo "$RESULT_HOOKS" > orghooks.json
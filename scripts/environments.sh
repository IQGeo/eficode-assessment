#!/bin/bash

# Read the JSON file
data=$(jq '.' environments.json)

{
  printf "# Repo Environments and Protection Rules\n\n"
  printf "Number of protection rules for each environment:"
} > environments.md

# Loop through the data and format it into markdown
echo "${data}" | jq -rc '.[] | select(.env != [])' | while read -r repo; do
  repo_name=$(echo "${repo}" | jq -rc '.repo')
  envs=$(echo "${repo}" | jq -rc ".env")
  printf "\n\n## %s\n" "$repo_name" >> "environments.md"
  echo "${envs}" | jq -rc '.[]' | while read -r env; do
    env_name="$(echo "${env}" | jq -rc '.name')"
    num_rules=$(echo "${env}" | jq -rc ".protectionrules | length")
    printf "\n- %s: %s" "$env_name" "$num_rules" >> "environments.md"
  done
done

echo "" >> "environments.md"

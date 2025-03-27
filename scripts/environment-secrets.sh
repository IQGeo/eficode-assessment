#!/bin/bash

# Read the JSON file
data=$(jq '.' environments_secrets.json)

# Initialize markdown data
markdown_data=""

printf -v markdown_data "# Repo Environments and Secrets\n\n"

# Loop through the data and format it into markdown
for repo in $(echo "${data}" | jq -r '.[] | select(.env != []) | .repo'); do
  envs=$(echo "${data}" | jq -r ".[] | select(.repo == \"${repo}\") | .env[]")
  for env in $(echo "${envs}" | jq -r 'select(.secrets != []) | .name'); do
    printf -v markdown_data "%s## %s (Env: %s)\n\nSecrets:\n\n" "$markdown_data" "$repo" "$env"
    secrets=$(echo "${envs}" | jq -r "select(.name == \"${env}\") | .secrets[]?.name")
    for secret in ${secrets}; do
      printf -v markdown_data "%s- %s\n" "$markdown_data" "$secret"
    done
    printf -v markdown_data "%s\n" "$markdown_data"
  done
done

# Write the markdown data into a file
printf "%s" "${markdown_data}" > environment-secrets.md

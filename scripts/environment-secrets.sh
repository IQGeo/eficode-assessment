#!/bin/bash

# Read the JSON file
data=$(jq '.' environments_secrets.json)

# Initialize markdown data
markdown_data="# Repo Environments and Secrets\n\n"

# Loop through the data and format it into markdown
for repo in $(echo "${data}" | jq -r '.[] | select(.env != []) | .repo'); do
  envs=$(echo "${data}" | jq -r ".[] | select(.repo == \"${repo}\") | .env[]")
  for env in $(echo "${envs}" | jq -r 'select(.secrets != []) | .name'); do
    markdown_data+="## ${repo}\n\n### Environment: ${env}\n\nSecrets:\n"
    secrets=$(echo "${envs}" | jq -r "select(.name == \"${env}\") | .secrets[]?.name")
    for secret in ${secrets}; do
      markdown_data+="- ${secret}\n"
    done
    markdown_data+="\n"
  done
done

# Write the markdown data into a file
printf "%s" "${markdown_data}" > environment-secrets.md

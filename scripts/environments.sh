#!/bin/bash

# Read the JSON file
data=$(jq '.' environments.json)

# Initialize markdown data
markdown_data="# Repo Environments and Protection Rules\n\n"

# Loop through the data and format it into markdown
for repo in $(echo "${data}" | jq -r '.[] | select(.env != []) | .repo'); do
  markdown_data+="## ${repo}\n\n"
  envs=$(echo "${data}" | jq -r ".[] | select(.repo == \"${repo}\") | .env[]")
  for env in $(echo "${envs}" | jq -r '.name'); do
    num_rules=$(echo "${envs}" | jq -r "select(.name == \"${env}\") | .protectionrules | length")
    markdown_data+="### ${env}\n\nNumber of protection rules: ${num_rules}\n\n"
  done
done

# Write the markdown data into a file
printf "%s" "${markdown_data}" > environments.md

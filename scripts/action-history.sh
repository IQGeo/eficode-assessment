#!/bin/bash

# Read the JSON file
data=$(jq '.' actions-history.json)

# Initialize markdown data
markdown_data="# Repo Workflows and Last Run Dates\n\n"

# Loop through the data and format it into markdown
for name in $(echo "${data}" | jq -r '.[] | select(.workflows != []) | .name'); do
  markdown_data+="## ${name}\n\n"
  workflows=$(echo "${data}" | jq -r ".[] | select(.name == \"${name}\") | .workflows[] | {name: .name, last_run: .last_run} | @base64")
  for workflow in ${workflows}; do
    _jq() {
      echo ${workflow} | base64 --decode | jq -r ${1}
    }
    workflow_name=$(_jq '.name')
    last_run=$(_jq '.last_run')
    markdown_data+="- ${workflow_name}, Last Run: ${last_run}\n"
  done
  markdown_data+="\n"
done

# Write the markdown data into a file
printf '%s' "${markdown_data}" > action-history.md

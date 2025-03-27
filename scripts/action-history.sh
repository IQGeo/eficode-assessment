#!/bin/bash

# Read the JSON file
data=$(jq '.' actions-history.json)

# Initialize markdown data
markdown_data=""
printf -v markdown_data "# Repo Workflows and Last Run Dates\n\n"

# Loop through the data and format it into markdown
for name in $(echo "${data}" | jq -r '.[] | select(.workflows != []) | .name'); do
  printf -v markdown_data "%s## %s\n\n" "$markdown_data" "$name"
  workflows=$(echo "${data}" | jq -r ".[] | select(.name == \"${name}\") | .workflows[] | {name: .name, last_run: .last_run} | @base64")
  for workflow in ${workflows}; do
    _jq() {
      echo ${workflow} | base64 --decode | jq -r ${1}
    }
    workflow_name=$(_jq '.name')
    last_run=$(_jq '.last_run')
    printf -v markdown_data "%s- %s, Last Run: %s\n" "$markdown_data" "$workflow_name" "$last_run"
  done
  printf -v markdown_data "%s\n" "$markdown_data"
done

# Write the markdown data into a file
printf "%s" "${markdown_data}" > action-history.md

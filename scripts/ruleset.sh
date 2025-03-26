#!/bin/bash

# Read the JSON file and filter out repos with 0 rulesets
filtered_data=$(jq '.[] | select(.rulesets != 0)' ruleset.json)

# Initialize markdown data
markdown_data=""
printf -v markdown_data "# Report\n\n"

# Loop through the filtered data and format it into markdown
for repo in $(echo "${filtered_data}" | jq -r '.repo'); do
    rulesets=$(echo "${filtered_data}" | jq -r "select(.repo == \"${repo}\") | .rulesets")
    printf -v markdown_data "%s## %s\n\nRulesets: %s\n\n" "$markdown_data" "$repo" "$rulesets"
done

# Write the markdown data into a file
printf "%s" "${markdown_data}" > ruleset.md

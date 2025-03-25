#!/bin/bash

# Read the JSON file and filter out repos with 0 rulesets
filtered_data=$(jq '.[] | select(.rulesets != 0)' ruleset.json)

# Initialize markdown report
markdown_report="# Report\n\n"

# Loop through the filtered data and format it into markdown
for repo in $(echo "${filtered_data}" | jq -r '.repo'); do
    rulesets=$(echo "${filtered_data}" | jq -r "select(.repo == \"${repo}\") | .rulesets")
    markdown_report+="## ${repo}\n\nRulesets: ${rulesets}\n\n"
done

# Write the markdown report into a file
printf "%s" "${markdown_report}" > ruleset.md

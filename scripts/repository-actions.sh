#!/bin/bash

# Read the JSON file and get all unique uses entries
unique_uses=$(jq -r '.[] | select(.uses != null) | .uses[]' repository-actions.json | sort | uniq)

# Initialize markdown data
markdown_data="# Unique Uses Entries\n\n"

# Loop through the unique uses entries and format them into markdown
for uses in ${unique_uses}; do
    markdown_data+="- ${uses}\n"
done

# Write the markdown data into a file
printf "%s" "$markdown_data" > repository-actions.md

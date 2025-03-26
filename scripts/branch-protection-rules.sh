#!/bin/bash

# Read the JSON file
data=$(jq '.' branch-protection-rules.json)

# Initialize markdown data
markdown_data="# Repo Branch Protection Rules\n\n"

# Loop through the data and format it into markdown
for repo in $(echo "${data}" | jq -r '.[] | select(.branchProtectionRules != []) | .repo'); do
  markdown_data+="## ${repo}\n\n"
  rules=$(echo "${data}" | jq -r ".[] | select(.repo == \"${repo}\") | .branchProtectionRules[]")
  for rule in $(echo "${rules}" | jq -r '.pattern' | sed 's/\*/\\*/g'); do
    markdown_data+="- ${rule//\\\*/\*}\n"
  done
  markdown_data+="\n"
done

# Write the markdown data into a file
echo -e "${markdown_data}" > branch-protection-rules.md

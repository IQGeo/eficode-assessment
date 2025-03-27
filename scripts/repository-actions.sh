#!/bin/bash

ORGANIZATIONS="${1}"

# Convert ORGANIZATIONS to lowercase and create an array
ORGANIZATIONS=$(echo "${ORGANIZATIONS}" | tr '[:upper:]' '[:lower:]' | xargs)
IFS=',' read -r -a ORGANIZATIONS_ARRAY <<< "${ORGANIZATIONS}"
# printf "Organizations array: %s\n\n" "${ORGANIZATIONS_ARRAY[*]}"

# Read the JSON file and get all unique uses entries
unique_uses=$(jq -r '.[] | select(.uses != null) | .uses[]' repository-actions.json | sort | uniq)

# Initialize markdown data
markdown_data=""
printf -v markdown_data "# Unique Uses Entries\n"

# Initialize arrays for each group
local_actions=()
organization_actions=()
public_actions=()

# Loop through the unique uses entries and classify them
for uses in ${unique_uses}; do
  # slash_count=$(grep -o "/" <<< "$uses" | wc -l) # Count slashes once
  org_name=$(echo "$uses" | cut -d'/' -f1 | tr '[:upper:]' '[:lower:]')
  if [[ ${uses} == ./.github/* ]]; then
    local_actions+=("$uses")
  elif [[ " ${ORGANIZATIONS_ARRAY[*]} " =~ (^|[[:space:]])${org_name}([[:space:]]|$) ]]; then
      organization_actions+=("$uses")
  else
    public_actions+=("$uses")
  fi
done

if [[ ${#local_actions[@]} -gt 0 ]]; then
  printf -v markdown_data "%s\n## Local Actions\n\n" "$markdown_data"
  for action in "${local_actions[@]}"; do
    printf -v markdown_data "%s- %s\n" "$markdown_data" "$action"
  done
fi

if [[ ${#organization_actions[@]} -gt 0 ]]; then
  printf -v markdown_data "%s\n## Organization Actions\n\n" "$markdown_data"
  for action in "${organization_actions[@]}"; do
    printf -v markdown_data "%s- %s\n" "$markdown_data" "$action"
  done
fi

if [[ ${#public_actions[@]} -gt 0 ]]; then
  printf -v markdown_data "%s\n## Public Actions\n\n" "$markdown_data"
  for action in "${public_actions[@]}"; do
    printf -v markdown_data "%s- %s\n" "$markdown_data" "$action"
  done
fi

# Write the markdown data into a file
printf "%s" "$markdown_data" > repository-actions.md

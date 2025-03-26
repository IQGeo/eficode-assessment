#!/bin/bash

# Get the date 2 years ago in ISO 8601 format
two_years_ago=$(date -v-2y -u +'%Y-%m-%dT%H:%M:%SZ')

{
  printf "# Repos\n\n";

  printf "## Repositories updated more than 2 years ago\n\n";

  # Read the JSON file, filter objects where updatedAt is more than 2 years old, and output name and updatedAt as markdown bullets
  jq -r --arg two_years_ago "$two_years_ago" '.[] | select(.updatedAt < $two_years_ago) | "- Name: \(.name), Updated At: \(.updatedAt)"' repos.json

  # Write the header to the markdown file
  printf "\n## Disk usage in KB\n\n" >> repos.md

  # Read the JSON file, extract the repository name and diskUsage, convert diskUsage to megabytes, sort by diskUsage in descending order, and format as a list
  jq -r '.[] | "\(.diskUsage) \(.name)"' repos.json | awk '{diskUsage = $1 / 1024; $1=""; print diskUsage " " $0}' | sort -rn | awk '{diskUsage = $1; $1=""; print "- Name:" $0 ", Disk Usage: " diskUsage " MB"}' >> repos.md
} > repos.md


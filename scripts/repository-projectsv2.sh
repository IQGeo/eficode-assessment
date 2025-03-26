#!/bin/bash

{
  printf "# Repository Projects V2\n\n"

  # Read the JSON file and format the data into markdown
  jq -r '.[] | "## " + .nameWithOwner + "\n", (.projectsV2.nodes[] | "### Project: " + .title + "\n")' repository-projectsv2.json
} > repository-projectsv2.md

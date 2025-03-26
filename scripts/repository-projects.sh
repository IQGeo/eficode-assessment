#!/bin/bash

{
  printf "# Repository Projects\n"

  # Read the JSON file and format the data into markdown
  jq -r '.[] | "## " + .nameWithOwner + "\n", (.projects.nodes[] | "### Project: " + .name + "\n")' repository-projects.json
} > repository-projects.md

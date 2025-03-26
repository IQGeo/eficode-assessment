#!/bin/bash

# Read the JSON file and format the data into markdown
markdown_data=$(jq -r '.[] | "# " + .nameWithOwner, (.projects.nodes[] | "## Project: " + .name)' repository-projects.json)

# Write the markdown data into a file
echo "${markdown_data}" > repository-projects.md

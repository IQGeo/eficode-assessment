#!/bin/bash

# Read the JSON file and format the data into markdown
markdown_data=$(jq -r '.[] | "# " + .nameWithOwner, (.projectsV2.nodes[] | "## Project: " + .title)' repository-projectsv2.json)

# Write the markdown data into a file
echo "${markdown_data}" > repository-projectsv2.md

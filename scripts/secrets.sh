#!/bin/bash

# Read the JSON file and group the secrets by repo, excluding repos without secrets
# jq -r '.[].repos[] | select(.secrets | length > 0) | "# " + .repo, (.secrets[] | "* " + .)' secrets.json >> secrets.md

{
  printf "# Action Secrets\n"

  # Read the JSON file and group the secrets by repo and secret type, excluding repos without secrets
  jq -r '.[] | .secret_type as $st | .repos[] | select(.secrets | length > 0) | "\n## " + $st + " - " + .repo + "\n", (.secrets[] | "- " + .)' secrets.json
} > secrets.md

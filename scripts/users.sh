#!/bin/bash

{
  printf "# Users\n"

  # Read the JSON file and group the repositories by login
  jq -r 'reduce .[] as $item ({}; .[$item.users[].login] += [$item.repo]) | to_entries[] | "\n## " + .key + "\n", (.value[] | "- " + .)' users.json
} > users.md

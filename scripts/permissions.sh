#!/bin/bash

{
  printf "# Permissions\n\n"

  # Read the JSON file, extract the logins, sort them, get unique values, and format as markdown list
  jq -r '.[].permissions[].login' permissions.json | sort | uniq | awk '{print "- " $0}'
} > permissions.md

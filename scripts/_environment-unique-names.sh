#!/bin/bash

# Extract the environment names from the markdown document
env_names=$(sed -n 's/^### //p' environments.md)

# List the unique environment names
unique_env_names=$(echo "${env_names}" | sort | uniq)

# Print the unique environment names
echo "${unique_env_names}"

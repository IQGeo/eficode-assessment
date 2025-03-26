#!/bin/bash

# Extract the URLs from the markdown document
urls=$(egrep -o 'https?://[^ ]+' webhooks.md)

# Extract the host names from the URLs
hostnames=$(echo "${urls}" | cut -d'/' -f3)

# List the unique host names
unique_hostnames=$(echo "${hostnames}" | sort | uniq)

# Print the unique hostnames
echo "${unique_hostnames}"

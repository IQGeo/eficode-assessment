#!/bin/bash

printf "# Webhooks\n" > webhooks.md

# Read the JSON file and group the webhooks by repo, excluding repos without webhooks
jq -r '.[] | select(.webhooks | length > 0) | "\n## " + .repo + "\n", (.webhooks[] | "- id: " + (.id | tostring) + ", url: [" + .config.url + "]")' webhooks.json >> webhooks.md

# Extract the URLs from the markdown document
urls=$(egrep -o 'https?://[^ ]+' webhooks.md)

# Extract the host names from the URLs
hostnames=$(echo "${urls}" | cut -d'/' -f3)

# List the unique host names
unique_hostnames=$(echo "${hostnames}" | sort | uniq)

# Print the unique hostnames
# add the unique hostnames to the webhooks.md file with a header called Unique Hostnames
printf "\n## Unique Hostnames\n\n" >> webhooks.md

# Format the unique hostnames as bullet points and append them to the markdown file
for hostname in ${unique_hostnames}; do
  echo "- ${hostname}" >> webhooks.md
done

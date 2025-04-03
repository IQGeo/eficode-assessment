#!/bin/bash

# This script fetches repositories Name & isArchived a specified GitHub organization,
# along with its custom properties, and saves the data to a CSV file.

ORG="$1"
LIMIT=${2:-1000}

if [ -z "$ORG" ]; then
  echo "Usage: $0 <ORG>"
  exit 1
fi

FILE="${ORG}_repos_properties.csv"

echo "Fetching repository properties for organization: $ORG with a limit of $LIMIT repositories. Output will be saved to $FILE..."

echo "repo,is_archived,property_name,value" > "$FILE" && \
gh repo list "$ORG" --json name,isArchived --limit "$LIMIT" | jq -c 'sort_by(.name | ascii_downcase) | .[]' | \
while read -r REPO; do
  REPO_NAME=$(echo "$REPO" | jq -r '.name')
  IS_ARCHIVED=$(echo "$REPO" | jq -r '.isArchived')

  gh api -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$ORG/$REPO_NAME/properties/values" | \
  jq -r --arg repo "$REPO_NAME" --arg archived "$IS_ARCHIVED" '.[] | [$repo, $archived, .property_name, .value] | @csv' >> "$FILE"
done

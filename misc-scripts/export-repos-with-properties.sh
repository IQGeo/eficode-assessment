#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

# This script fetches repositories Name & isArchived from a specified GitHub organization,
# along with its custom properties, and saves the data to a CSV file.

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG> [LIMIT:1000] [OUTPUT_FILE:<ORG>_repos_properties_<timestamp>.csv]"
  exit 1
fi

ORG="$1"
LIMIT=${2:-1000}
FILE="${3:-${ORG}_repos_properties_$(get_timestamp).csv}"

echo "Fetching repository properties for organization: $ORG with a limit of $LIMIT repositories. Output will be saved to $FILE"

# Check if the user has access to the organization
check_gh_auth_org_membership "$ORG"

# Use gh_repos_list function from lib.sh to fetch repositories
repos=$(gh_repos_list "$ORG" "true" "$LIMIT")
if [ $? -ne 0 ]; then
  print_error "Failed to fetch repositories for organization $ORG"
  exit 1
fi

# Create CSV header
echo "repo,is_archived,property_name,value" > "$FILE"

# Process repositories and their properties
while IFS= read -r REPO; do
  REPO_NAME=$(echo "$REPO" | jq -r '.name')
  IS_ARCHIVED=$(echo "$REPO" | jq -r '.isArchived')

  properties=$(gh api -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "/repos/$ORG/$REPO_NAME/properties/values")

  echo "$properties" | jq -e 'length > 0' > /dev/null
  if [ $? -ne 0 ]; then
    properties=""
  fi

  if [ -z "$properties" ] ; then
    echo "$REPO_NAME,$IS_ARCHIVED,," >> "$FILE"
  else
    echo "$properties" | jq -r --arg repo "$REPO_NAME" --arg archived "$IS_ARCHIVED" '.[] | [$repo, $archived, .property_name, .value] | @csv' >> "$FILE"
  fi
done <<< "$(echo "$repos" | jq -c '.[]')"

print_success "Repository properties exported to $FILE"

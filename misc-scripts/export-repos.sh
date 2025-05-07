#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

# This script fetches repositories Name & isArchived from a specified GitHub organization,
# and saves the data to a CSV file.

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG> [LIMIT:1000]"
  exit 1
fi

ORG="$1"
LIMIT=${2:-1000}

FILE="${ORG}_repos.csv"

echo "Fetching repository properties for organization: $ORG with a limit of $LIMIT repositories. Output will be saved to $FILE..."

# Check if the user has access to the organization
check_gh_auth_org_membership "$ORG"

# Use gh_repos_list function from lib.sh to fetch repositories
repos=$(gh_repos_list "$ORG" "true" "$LIMIT")

# Create CSV header
echo "repo,is_archived" > "$FILE"

# Process repositories and write to CSV file
echo "$repos" | jq -rc '.[] | [.name, .isArchived] | @csv' >> "$FILE"

print_success "Repository data exported to $FILE"

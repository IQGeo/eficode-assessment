#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG>"
  exit 1
fi

ORG="$1"
FILE="${ORG}_repos_admins.csv"

# List all repos in the org and sort them by name
repos=$(gh repo list "$ORG" --json name,isArchived --limit 1000 | jq 'sort_by(.name | ascii_downcase)')

echo "Repository, IsArchived, Admins" > "$FILE"
while IFS= read -r repo; do
  echo "🔹 Repo: $repo"

  repo_name=$(echo "$repo" | jq -r '.name')
  is_archived=$(echo "$repo" | jq -r '.isArchived')

  # Get ((Direct)) collaborators with admin access
  logins=$(gh api "/repos/$ORG/$repo_name/collaborators?affiliation=direct&per_page=100" \
    --jq '.[] | select(.permissions.admin == true) | .login')

  admins_list=""
  for login in $logins; do
    # Fetch user's public name
    user_info=$(gh api "/users/$login")
    user_name=$(echo "$user_info" | jq -r '.name // "N/A"')

    # Append to the list of admins
    admins_list+="$login ($user_name), "
  done
  # Remove the trailing comma and space
  admins_list=${admins_list%, }
  # Write to the CSV file
  echo "$repo_name, $is_archived, \"$admins_list\"" >> "$FILE"
done <<< "$(echo "$repos" | jq -c '.[]')"

#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG>"
  exit 1
fi

ORG="$1"
FILE="${ORG}_repos_admins.csv"

# List all repos in the org and sort them by name
repos=$(gh repo list "$ORG" --json name,isArchived --limit 1000 | jq 'sort_by(.name | ascii_downcase)')

echo "Repository,IsArchived,Admin users,Admin teams" > "$FILE"
while IFS= read -r repo; do
  repo_name=$(echo "$repo" | jq -r '.name')
  is_archived=$(echo "$repo" | jq -r '.isArchived')

  # Get Direct collaborators with admin access
  logins=$(gh api "/repos/$ORG/$repo_name/collaborators?affiliation=direct&per_page=100" \
    --jq '.[] | select(.permissions.admin == true) | .login')

  # Get teams with admin access
  team_logins=$(gh api "/repos/$ORG/$repo_name/teams?per_page=100" \
    --jq '.[] | select(.permission == "admin") | .slug')

  users_list=""
  for login in $logins; do
    # Fetch user's public name and sanitize output
    user_info=$(gh api "/users/$login" | tr -d '\000-\037')
    user_name=$(echo "$user_info" | jq -r '.name // "N/A"' 2>/dev/null || echo "N/A")

    # Append to the list of admins
    users_list+="$login ($user_name), "
  done
  # Remove the trailing comma and space
  users_list=${users_list%, }
  if [ -n "$users_list" ]; then
    users_list="\"$users_list\""
  fi

  teams_list=""
  for team in $team_logins; do
    # Fetch team's public name and sanitize output
    team_info=$(gh api "/orgs/$ORG/teams/$team" | tr -d '\000-\037')
    team_name=$(echo "$team_info" | jq -r '.name // "N/A"' 2>/dev/null || echo "N/A")

    # Append to the list of teams
    teams_list+="$team ($team_name), "
  done
  # Remove the trailing comma and space
  teams_list=${teams_list%, }
  if [ -n "$teams_list" ]; then
    teams_list="\"$teams_list\""
  fi

  echo "🔹 Repo: $repo_name, Archived: $is_archived, Users: $users_list, Teams: $teams_list"
  # Write to the CSV file
  echo "$repo_name,$is_archived,$users_list,$teams_list" >> "$FILE"
done <<< "$(echo "$repos" | jq -c '.[]')"

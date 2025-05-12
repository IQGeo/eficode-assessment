#!/bin/bash

GITLAB_URL="${GITLAB_INSTANCE_URL:-"https://gitlab.com"}"
ACCESS_TOKEN="$GITLAB_ACCESS_TOKEN"
ROOT_GROUP="$GITLAB_GROUP"

auth_header="PRIVATE-TOKEN: $ACCESS_TOKEN"

visited_file=".visited_groups"
csv_file="output.csv"
json_file="output.json"

# Reset files
>"$csv_file"
>"$json_file"
>"$visited_file"

# Updated CSV header to remove CI/CD count
echo "group_path,active_repos,archived_repos,direct_subgroup_count" >>"$csv_file"
echo "[" >>"$json_file"

# Check if group ID has been visited
has_visited() {
  grep -qx "$1" "$visited_file"
}

mark_visited() {
  echo "$1" >>"$visited_file"
}

get_group_path() {
  curl -s --header "$auth_header" "$GITLAB_URL/api/v4/groups/$1" | jq -r '.full_path'
}

# Modified to return active and archived counts only
get_repo_counts() {
  local group_id=$1
  local active_count=0
  local archived_count=0
  local page=1

  while true; do
    res=$(curl -s --header "$auth_header" "$GITLAB_URL/api/v4/groups/$group_id/projects?include_subgroups=false&per_page=100&page=$page")
    num=$(echo "$res" | jq 'length')

    # Count active and archived repositories
    active=$(echo "$res" | jq '[.[] | select(.archived == false)] | length')
    archived=$(echo "$res" | jq '[.[] | select(.archived == true)] | length')

    ((active_count += active))
    ((archived_count += archived))

    [[ $num -lt 100 ]] && break
    ((page++))
  done

  # Return counts separated by comma
  echo "$active_count,$archived_count"
}

get_subgroups() {
  local group_id=$1
  local page=1
  while true; do
    response=$(curl -s --header "$auth_header" "$GITLAB_URL/api/v4/groups/$group_id/subgroups?per_page=100&page=$page")
    count=$(echo "$response" | jq 'length')
    [[ "$count" -eq 0 ]] && break
    echo "$response" | jq -c '.[]'
    ((page++))
  done
}

traverse_group() {
  local group_id=$1
  echo "Visiting group ID: $group_id"

  if has_visited "$group_id"; then return; fi
  echo "Mark visited."
  mark_visited "$group_id"

  local group_path
  group_path=$(get_group_path "$group_id")
  echo "Group path: $group_path"

  # Get repo counts (active, archived)
  local repo_counts
  repo_counts=$(get_repo_counts "$group_id")
  local active_repos
  local archived_repos
  active_repos=$(echo "$repo_counts" | cut -d',' -f1)
  archived_repos=$(echo "$repo_counts" | cut -d',' -f2)
  local total_repos=$((active_repos + archived_repos))

  echo "Active repos: $active_repos, Archived repos: $archived_repos, Total: $total_repos"

  local subgroups
  echo "Fetching subgroups for group ID: $group_id"
  subgroups=$(get_subgroups "$group_id")

  # Count only non-empty lines to avoid counting an extra empty line
  local subgroup_count
  if [[ -z "$subgroups" ]]; then
    subgroup_count=0
  else
    subgroup_count=$(echo "$subgroups" | grep -v '^$' | wc -l | tr -d ' ')
  fi
  echo "Subgroup count: $subgroup_count"

  # Output with counts (no CI/CD)
  echo "$group_path: $active_repos active, $archived_repos archived repos, $subgroup_count subgroups"
  echo "\"$group_path\",$active_repos,$archived_repos,$subgroup_count" >>"$csv_file"

  # Append to JSON with counts (no CI/CD)
  echo "  {\"group_path\": \"$group_path\", \"active_repos\": $active_repos, \"archived_repos\": $archived_repos, \"direct_subgroup_count\": $subgroup_count}," >>"$json_file"

  while IFS= read -r line; do
    # Skip empty or malformed lines
    [[ -z "$line" ]] && continue
    if subgroup_id=$(echo "$line" | jq -e -r '.id' 2>/dev/null); then
      echo "Visiting group ID: $subgroup_id"
      traverse_group "$subgroup_id"
    else
      echo "⚠️ Warning: Skipping malformed line: $line"
    fi
  done <<<"$subgroups"
}

# Start recursion
traverse_group "$ROOT_GROUP"

# Clean up JSON trailing comma
sed -i '' '$ s/,$//' "$json_file"
echo "]" >>"$json_file"

# Remove temp file
rm "$visited_file"

echo "✅ Done: output.csv and output.json generated with separate active and archived repo counts."

#!/bin/bash

ROOT=$(git rev-parse --show-toplevel)

#===================================================================================================
# Helpers
#===================================================================================================

print_success() { printf "\xE2\x9C\x94 %s\n" "$1"; }
print_warning() { printf "\xE2\x9D\x97 %s\n" "$1"; }
print_error() { printf "\xE2\x9D\x8C %s\n" "$1"; }

print_separator() { printf "\n\n%s\n\n" "$(printf '%.0s-' {1..50})"; }

# Get the current date and time
# $1 - Human-readable (optional) true/false - defaults to false
# $2 - Timestamp format (optional) [default: "%Y%m%d%H%M%S"]
get_timestamp() {
  if [ "${1:-"false"}" = "true" ]; then
    date +"${2:-"%Y-%m-%d %H:%M:%S"}"
  else
    date +"${2:-"%Y%m%d%H%M%S"}"
  fi
}

#===================================================================================================
# File helpers
#===================================================================================================

# Check if a file exists
# $1 - file path
# $2 - create file if it does not exist (optional) true/false - defaults to false
# $3 - file content (optional) - defaults to empty
file_exists() {
	if [ -z "$1" ]; then echo "Usage: file_exists <file_path> [create_if_not_found] [file_content_if_not_found]"; return 1; fi

	if [ ! -f "$1" ]; then
		if [ "$2" == "true" ]; then
			if [ -n "$3" ]; then echo "$3" > "$1"; else touch "$1"; fi
		else
			echo "File $1 does not exist"; return 1;
		fi
	fi
}

# Remove empty lines from a file
# $1 - file path
remove_empty_lines() {
  if [ -z "$1" ]; then
    echo "Usage: remove_empty_lines <file_path>"
    return 1
  fi
  file_exists "$1" "true"

  # Remove empty lines and lines with only whitespace
  # The /pattern/N;P command is used to match the pattern and the line below it, and then print that line
  # sed -i '/^$/N;/^\n$/d' "$1"

  sed -i '' '/^[[:space:]]*$/d' "$1"
}

#===================================================================================================
# String helpers
#===================================================================================================

# Quote a string if it is not empty
# $1 - string to format
quote_if_not_empty() { if [ -n "$1" ]; then echo "\"$1\""; else echo ""; fi; }

#===================================================================================================
# Install dependencies
#===================================================================================================

install_brew() {
  command -v brew >/dev/null 2>&1 || {
    echo "brew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
      echo "Failed to install brew"
      exit 1
    }
  }
}

install_gh() {
  command -v gh >/dev/null 2>&1 || {
    echo "gh not found. Installing..."
    brew install gh || {
      echo "Failed to install gh"
      exit 1
    }
  }
}

install_gh_gei() {
  gh extension list | grep -q 'gh-gei' || {
    echo "gh-gei extension not found. Installing..."
    gh extension install github/gh-gei || {
      echo "Failed to install gh-gei extension"
      exit 1
    }
  }
}

install_pipx() {
  command -v pipx >/dev/null 2>&1 || {
    echo "pipx not found. Installing..."
    brew install pipx || {
      echo "Failed to install pipx"
      exit 1
    }
    pipx ensurepath
  }
}

install_xlsx2csv() {
  command -v xlsx2csv >/dev/null 2>&1 || {
    echo "xlsx2csv not found. Installing..."
    pipx install xlsx2csv || {
      echo "Failed to install xlsx2csv"
      exit 1
    }
  }
}

#===================================================================================================
# Excel helpers
#===================================================================================================

sheet_exists_in_excel_file() {
  local excel_file="$1"
  local sheet_name="$2"
  if ! xlsx2csv -n "$sheet_name" "$excel_file" >/dev/null 2>&1; then
    echo "Sheet '$sheet_name' does not exist in the Excel file '$excel_file'."
    return 1
  fi
}

sheet_column_exists() {
  local excel_file="$1"
  local sheet_name="$2"
  local column_name="$3"
  if ! xlsx2csv -n "$sheet_name" "$excel_file" | head -n 1 | tr ',' '\n' | grep -q "^$column_name$"; then
    echo "Column '$column_name' does not exist in the sheet '$sheet_name' of the Excel file '$excel_file'."
    return 1
  fi
}

# List all columns in a sheet
# $1 - Excel file path
# $2 - Sheet name
# $3 - Columns at line number (optional) [default: 1]
# Usage: list_excel_sheet_columns <excel_file> <sheet_name> [<line_number>]
# If no line number is provided, the first line will be used
list_excel_sheet_columns() {
  local excel_file="$1"
  local sheet_name="$2"
  local line_number="${3:-1}"

  if [ -z "$excel_file" ] || [ -z "$sheet_name" ]; then
    echo "Usage: list_excel_sheet_columns <excel_file> <sheet_name> [<line_number>]"
    return 1
  fi
  if ! sheet_exists_in_excel_file "$excel_file" "$sheet_name"; then
    return 1
  fi
  # Get the columns from the specified line number
  xlsx2csv -n "$sheet_name" "$excel_file" | sed -n "${line_number}p" | tr ',' '\n'
  # xlsx2csv -n "$sheet_name" "$excel_file" | head -n 1 | tr ',' '\n'
}

# Convert an Excel sheet to CSV
# $1 - Excel file path
# $2 - Sheet name
# $3 - Output CSV file path (optional)
# $4 - Starting line number (optional) [default: 1]
# If no output file is provided, the CSV will be printed to stdout
# Usage: excel_sheet_to_csv_by_name <excel_file> <sheet_name> [<output_csv_file>] [<start_line>]
excel_sheet_to_csv_by_name() {
  local excel_file="$1"
  local sheet_name="$2"
  local output_csv_file="$3"
  local start_line="${4:-1}"

  if [ -z "$output_csv_file" ]; then
    xlsx2csv -n "$sheet_name" "$excel_file" | tail -n +"$start_line"
  else
    xlsx2csv -n "$sheet_name" "$excel_file" | tail -n +"$start_line" >"$output_csv_file"
  fi
}

# Convert CSV to JSON
# $1 - CSV file path
# $2 - Output JSON file path (optional)
# If no output file is provided, the JSON will be printed to stdout
# Usage: csv_to_json <csv_file> [<json_file>]
csv_to_json() {
  local csv_file="$1"
  local json_file="$2"
  if [ -z "$csv_file" ]; then
    echo "Usage: csv_to_json <csv_file> [<json_file>]"
    return 1
  fi
  if [ -z "$json_file" ]; then
    # Convert CSV to JSON and print to stdout
    python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' <"$csv_file"
  else
    # Convert CSV to JSON and save to file
    python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' <"$csv_file" >"$json_file"
  fi
}

#===================================================================================================
# JSON helpers
#===================================================================================================

get_by_key_from_json_object() {
  local json_object="$1"
  local key="$2"
  echo "$json_object" | jq --arg key "$key" '.[$key]' -r
}

#===================================================================================================
# GitHub helpers
#===================================================================================================

check_env_var() {
  local var_name="$1"
  local var_value="${!var_name}"

  if [ -z "$var_value" ]; then
    echo "$var_name is not set. Please set the $var_name environment variable."
    exit 1
  fi
}

get_org_membership() {
  gh api "/user/memberships/orgs/${1}" 2>/dev/null | jq -r '.state' || echo "inactive"
}
check_gh_auth_org_membership() {
  local org="$1"
  local membership

  membership="$(get_org_membership "$org")"

  if [ "$membership" != "active" ]; then
    echo "Your GitHub account does not have access to the organization '${org}' or you are not logged in."
    echo "Please ensure you are logged in with 'gh auth login' and have the necessary permissions."
    echo "Or maybe you need to 'gh auth switch' to the correct account."
    exit 1
  fi
}

api_repos_list() {
  gh api "/orgs/${1}/repos" --paginate --slurp
}
api_repos_list_names() {
  api_repos_list "$1" | jq -r '[.[] | .[].name]'
}

create_team_using_gh_gei() {
  local org="$1"
  local gh_team="$2"
  local az_group="$3"
  echo "Updating ${org} team: ${gh_team} to IdP group: ${az_group}..."
  gh gei create-team --github-org "$org" --team-name "$gh_team" --idp-group "$az_group"
}

generate_migration_script() {
  local github_source_org="$1"
  local github_target_org="$2"
  local output_script="$3"

  # Check if all parameters are provided
  if [[ -z "$github_source_org" || -z "$github_target_org" || -z "$output_script" ]]; then
    echo "Error: Missing parameters."
    echo "Usage: generate_migration_script <github_source_org> <github_target_org> <output_script>"
    return 1
  fi

  gh gei generate-script --github-source-org "$github_source_org" --github-target-org "$github_target_org" --download-migration-logs --output "$output_script"
}

#===================================================================================================
# Repository admin helpers
#===================================================================================================

# Get all repositories from an organization sorted alphabetically
# $1 - organization name
# $2 - include archived (optional, default: false)
# $3 - limit (optional, default: 1000)
# Returns: JSON array of repositories with name and isArchived fields if $2 is true
gh_repos_list() {
  local org="$1"
  local include_archived="${2:-false}"
  local limit="${3:-1000}"

  if [ -z "$org" ]; then
    echo "Usage: gh_repos_list <org> [include archived: true|false (default: false)] [limit (default: 1000)]"
    return 1
  fi

  json_params="name"
  if [ "$2" = "true" ]; then
    json_params+=",isArchived"
  fi

  gh repo list "$org" --json "$json_params" --limit "$limit" | jq 'sort_by(.name | ascii_downcase)'
}

# Get admin users for a repository
# $1 - organization name
# $2 - repository name
# $3 - include full name (optional, default: false)
# Returns: formatted string of admin users
get_repo_admin_users() {
  local org="$1"
  local repo_name="$2"
  local include_full_name="${3:-false}"
  local users_list=""

  if [ -z "$org" ] || [ -z "$repo_name" ]; then
    echo "Usage: get_repo_admin_users <org> <repo_name> [include_full_name]"
    return 1
  fi

  # Get Direct collaborators with admin access
  local logins
  logins=$(gh api "/repos/$org/$repo_name/collaborators?affiliation=direct&per_page=100" \
    --jq '.[] | select(.permissions.admin == true) | .login')

  for login in $logins; do
    if [ "$include_full_name" = "true" ]; then
      # Fetch user's full name and sanitize output
      local user_info
      user_info=$(gh api "/users/$login" | tr -d '\000-\037')
      local user_name
      user_name=$(echo "$user_info" | jq -r '.name // "N/A"' 2>/dev/null || echo "N/A")

      users_list+="$login ($user_name), "
    else
      users_list+="$login, "
    fi
  done

  # Remove the trailing comma and space
  users_list=${users_list%, }

  echo "$users_list"
}

# Get admin teams for a repository
# $1 - organization name
# $2 - repository name
# $3 - include full name (optional, default: false)
# Returns: formatted string of admin teams
get_repo_admin_teams() {
  local org="$1"
  local repo_name="$2"
  local include_full_name="${3:-false}"
  local teams_list=""

  if [ -z "$org" ] || [ -z "$repo_name" ]; then
    echo "Usage: get_repo_admin_teams <org> <repo_name> [include_full_name]"
    return 1
  fi

  # Get teams with admin access
  local team_logins
  team_logins=$(gh api "/repos/$org/$repo_name/teams?per_page=100" \
    --jq '.[] | select(.permission == "admin") | .slug')

  for team in $team_logins; do
    if [ "$include_full_name" = "true" ]; then
      # Fetch team's full name and sanitize output
      local team_info
      team_info=$(gh api "/orgs/$org/teams/$team" | tr -d '\000-\037')
      local team_name
      team_name=$(echo "$team_info" | jq -r '.name // "N/A"' 2>/dev/null || echo "N/A")

      teams_list+="$team ($team_name), "
    else
      teams_list+="$team, "
    fi
  done

  # Remove the trailing comma and space
  teams_list=${teams_list%, }

  echo "$teams_list"
}

# Generate a CSV report of repository admins
# $1 - organization name
# $2 - include full name (optional, default: false)
# $3 - output file name (optional, default: <org>_repos_admins_<timestamp>.csv)
generate_repo_admins_report() {
  local org="$1"
  local include_full_name="${2:-false}"
  local output_file="${3:-${org}_repos_admins_$(get_timestamp).csv}"

  if [ -z "$org" ]; then
    echo "Usage: generate_repo_admins_report <org> [include_full_name] [output_file]"
    return 1
  fi

  check_gh_auth_org_membership "$ORG"

  # Get all repos in the org
  local repos
  repos=$(gh_repos_list "$org" "true")

  echo "Repository,IsArchived,Admin users,Admin teams" > "$output_file"

  while IFS= read -r repo; do
    local repo_name is_archived users_list teams_list

    repo_name=$(echo "$repo" | jq -r '.name')
    is_archived=$(echo "$repo" | jq -r '.isArchived')

    # Get admin users
    users_list=$(quote_if_not_empty "$(get_repo_admin_users "$org" "$repo_name" "$include_full_name")")

    # Get admin teams
    teams_list=$(quote_if_not_empty "$(get_repo_admin_teams "$org" "$repo_name" "$include_full_name")")

    echo "🔹 Repo: $repo_name, Archived: $is_archived, Users: $users_list, Teams: $teams_list"

    # Write to the CSV file
    echo "$repo_name,$is_archived,$users_list,$teams_list" >> "$output_file"
  done <<< "$(echo "$repos" | jq -c '.[]')"

  echo "Report generated: $output_file"
}

#!/bin/bash

ROOT=$(git rev-parse --show-toplevel)

#==============================================================================
# Helpers
#==============================================================================

print_success() { printf "\xE2\x9C\x94 %s\n" "$1"; }
print_warning() { printf "\xE2\x9D\x97 %s\n" "$1"; }
print_error() { printf "\xE2\x9D\x8C %s\n" "$1"; }

print_separator() { printf "\n\n%s\n\n" "$(printf '%.0s-' {1..50})"; }

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

repos_list_names() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <org> [limit:1000]"
    return 1
  fi
  local limit=${2:-1000}
  gh repo list "$1" --json name --limit "$limit" | jq -r 'sort_by(.name | ascii_downcase) | [.[].name]'
}
api_repos_list() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <org>"
    return 1
  fi
  local response
  response=$(gh api "/orgs/${1}/repos" --paginate --slurp)
  echo "$response"
}
api_repos_list_names() {
  if [ -z "$1" ]; then
    echo "Usage: $0 <org>"
    return 1
  fi
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

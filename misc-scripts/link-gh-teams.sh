#!/bin/bash

# This script automates the process of linking GitHub teams to Azure groups using data from an Excel file.
#
# It performs the following steps:
# 1. Installs required dependencies (Homebrew, GitHub CLI, pipx, xlsx2csv).
# 2. Exports a specific sheet from the provided Excel file to a CSV file.
# 3. Converts the CSV file to a JSON file for easier processing.
# 4. Iterates over the JSON data to extract Azure group and GitHub team information.
# 5. Uses the GitHub CLI to create and link GitHub teams to Azure groups based on the extracted data.
# 6. Verifies the user's access to the specified GitHub organization.
# 7. Ensures the required GitHub Personal Access Token (GH_PAT) is set for authentication.

# Usage:
# ./link-gh-teams.sh <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column>
# Example:
# ./link-gh-teams.sh 'my-org' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'

ORG="$1"
EXCEL_FILE="$2"
SHEET_NAME="$3"

AZURE_GROUP_COLUMN="$4"
GITHUB_TEAM_COLUMN="$5"

if [ -z "$ORG" ] || [ -z "$EXCEL_FILE" ] || [ -z "$SHEET_NAME" ] || [ -z "$AZURE_GROUP_COLUMN" ] || [ -z "$GITHUB_TEAM_COLUMN" ]; then
  echo "Usage: $0 <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column>"
  exit 1
fi

CSV_FILE="${EXCEL_FILE%.xlsx}.csv"
CSV_AS_JSON_FILE="${EXCEL_FILE%.xlsx}.json"

install_dependencies() {
  command -v brew >/dev/null 2>&1 || {
    echo "brew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Failed to install brew"; exit 1; }
  }

  command -v gh >/dev/null 2>&1 || {
    echo "gh not found. Installing..."
    brew install gh || { echo "Failed to install gh"; exit 1; }
  }

  gh extension list | grep -q 'gh-gei' || {
    echo "gh-gei extension not found. Installing..."
    gh extension install github/gh-gei || { echo "Failed to install gh-gei extension"; exit 1; }
  }

  command -v pipx >/dev/null 2>&1 || {
    echo "pipx not found. Installing..."
    brew install pipx || { echo "Failed to install pipx"; exit 1; }
    pipx ensurepath
  }

  command -v xlsx2csv >/dev/null 2>&1 || {
    echo "xlsx2csv not found. Installing..."
    pipx install xlsx2csv || { echo "Failed to install xlsx2csv"; exit 1; }
  }
}

excel_sheet_to_csv_by_name() {
  local excel_file="$1"
  local sheet_name="$2"
  xlsx2csv -n "$sheet_name" "$excel_file" | tail -n +2
}

csv_to_json() {
  python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' < "$1"
}

get_by_key_from_json_object() {
  local json_object="$1"
  local key="$2"
  echo "$json_object" | jq --arg key "$key" '.[$key]' -r
}

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

create_team_using_gh_gei() {
  local org="$1"
  local gh_team="$2"
  local az_group="$3"
  echo "Updating ${org} team: ${gh_team} to IdP group: ${az_group}..."
  gh gei create-team --github-org "$org" --team-name "$gh_team" --idp-group "$az_group"
}

install_dependencies || exit 1

check_gh_auth_org_membership "$ORG"

# Please follow the instructions here: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
# You'll need these requird scoped in your ==>(CLASSIC)<== PAT: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
check_env_var "GH_PAT"

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv_by_name "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"

echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${CSV_AS_JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${CSV_AS_JSON_FILE}"

while IFS= read -r group; do
  az_group="$(get_by_key_from_json_object "$group" "$AZURE_GROUP_COLUMN")"
  gh_team="$(get_by_key_from_json_object "$group" "$GITHUB_TEAM_COLUMN")"

  create_team_using_gh_gei "$ORG" "$gh_team" "$az_group"
done < <(jq -c '.[]' "$CSV_AS_JSON_FILE")

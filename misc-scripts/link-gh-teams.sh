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
# sh ./link-gh-teams.sh <org> <excel_file> <sheet_name> <azure_group_column> <github_team_column>
# Example:
# sh ./link-gh-teams.sh 'my-org' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'

# REPO_ROOT="$(git rev-parse --show-toplevel)"
DIR="$(dirname "$(readlink -f "$0")")"

. "$DIR/lib.sh"

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
JSON_FILE="${EXCEL_FILE%.xlsx}.json"

install_brew
install_gh
install_gh_gei
install_pipx
install_xlsx2csv

check_gh_auth_org_membership "$ORG"

# Please follow the instructions here: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
# You'll need these requird scoped in your ==>(CLASSIC)<== PAT: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
check_env_var "GH_PAT"

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv_by_name "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"

echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${JSON_FILE}"

while IFS= read -r group; do
  az_group="$(get_by_key_from_json_object "$group" "$AZURE_GROUP_COLUMN")"
  gh_team="$(get_by_key_from_json_object "$group" "$GITHUB_TEAM_COLUMN")"

  # echo "Creating and linking GitHub team '${gh_team}' to Azure group '${az_group}'..."
  create_team_using_gh_gei "$ORG" "$gh_team" "$az_group"
done <<< "$(jq -c '.[]' "$JSON_FILE")"

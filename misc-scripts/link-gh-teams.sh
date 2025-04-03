#!/bin/bash

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

__install_dependencies() {
  command -v brew >/dev/null 2>&1 || {
    echo "brew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || { echo "Failed to install brew"; exit 1; }
  }

  command -v gh >/dev/null 2>&1 || {
    echo "gh not found. Installing..."
    brew install gh || { echo "Failed to install gh"; exit 1; }
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

excel_sheet_to_csv() {
  local excel="$1"
  local sheet="$2"
  xlsx2csv -n "$sheet" "$excel" | tail -n +2
}

csv_to_json() {
  python3 -c 'import csv, json, sys; print(json.dumps([dict(r) for r in csv.DictReader(sys.stdin)]))' < "$1"
}

get_by_key_from_json_object() {
  local json_object="$1"
  local key="$2"
  echo "$json_object" | jq --arg key "$key" '.[$key]' -r
}

create_team_using_gh_gei() {
  local gh_team="$1"
  local az_group="$2"
  echo "Updating team: ${gh_team} to IdP group: ${az_group}..."
  gh gei create-team --github-org "$ORG" --team-name "$gh_team" --idp-group "$az_group"
}

__install_dependencies || exit 1

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"

echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${CSV_AS_JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${CSV_AS_JSON_FILE}"

while IFS= read -r mapping; do
  az_group="$(get_by_key_from_json_object "$mapping" "$AZURE_GROUP_COLUMN")"
  gh_team="$(get_by_key_from_json_object "$mapping" "$GITHUB_TEAM_COLUMN")"

  create_team_using_gh_gei "$gh_team" "$az_group"
done < <(jq -c '.[]' "$CSV_AS_JSON_FILE")

# bash ./link-gh-teams.sh 'avolta-migration-sandbox-2' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'

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

GH_EXTERNAL_GROUPS_FILE="${ORG}_external_groups.json"
GH_GROUPS_MAPPING_FILE="${ORG}_group_mapping.json"

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

fetch_external_groups() {
  local org_name="$1"
  local response
  response=$(gh api --paginate --slurp \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "/orgs/${org_name}/external-groups")
  echo "$response" | jq '[.[] | .groups[]]'
}

__install_dependencies || exit 1

# TODO verify the org exists using the current user's token/gh auth status
# VERIFY_ORG=$(gh api "/orgs/${ORG}" 2>&1)

echo "Export ${SHEET_NAME} sheet from ${EXCEL_FILE} file to ${CSV_FILE}..."
excel_sheet_to_csv "${EXCEL_FILE}" "${SHEET_NAME}" > "${CSV_FILE}"

echo "Converting exported sheet as CSV from ${CSV_FILE} to JSON here: ${CSV_AS_JSON_FILE}..."
csv_to_json "${CSV_FILE}" > "${CSV_AS_JSON_FILE}"

GH_GROUPS=$(fetch_external_groups "$ORG")
GH_GROUPS_LENGTH=$(echo "$GH_GROUPS" | jq length)
echo "Fetched ${GH_GROUPS_LENGTH} external groups from ${ORG}, saving to ${GH_EXTERNAL_GROUPS_FILE}..."
echo "$GH_GROUPS" > "$GH_EXTERNAL_GROUPS_FILE"

json_array="[]"
while IFS= read -r group; do
  group_id="$(echo "$group" | jq -r '.group_id')"
  group_name=$(echo "$group" | jq -r '.group_name')

  # Find matching rows in the exported csv_to_json file for the current GitHub group
  matching_row=$(jq -r --arg group_name "$group_name" --arg azure_column "$AZURE_GROUP_COLUMN" \
    '.[] | select(.[$azure_column] == $group_name)' "$CSV_AS_JSON_FILE")

  if [ -n "$matching_row" ]; then
    github_team_name="$(echo "$matching_row" | jq --arg github_team_column "$GITHUB_TEAM_COLUMN" '.[$github_team_column]' -r)"

    # echo "AZ_Group: ${group_name} - GH_ID: ${group_id} - GH_Team: ${github_team_name}"

    json_array=$(echo "$json_array" | jq -c --arg group_id "$group_id" --arg group_name "$group_name" --arg github_team_name "$github_team_name" \
      '. += [{ "group_id": $group_id, "group_name": $group_name, "github_team_name": $github_team_name }]')
  else
    echo "No matching rows found for GitHub group: ${group_name}"
  fi
done < <(jq -c '.[]' "$GH_EXTERNAL_GROUPS_FILE")

echo "Saving mapped records json file to to ${GH_GROUPS_MAPPING_FILE}..."
echo "$json_array" > "$GH_GROUPS_MAPPING_FILE"

echo "Linking ${ORG} teams..."
jq -c '.[]' "$GH_GROUPS_MAPPING_FILE" | while read -r group; do
  group_id=$(echo "$group" | jq -r '.group_id')
  group_name=$(echo "$group" | jq -r '.group_name')
  github_team_name=$(echo "$group" | jq -r '.github_team_name')

  echo "Linking: ${group_name} - [${github_team_name}] to (${group_id})"
  gh gei create-team --github-org "$ORG" --team-name "$github_team_name" --idp-group "$group_name"
done

# bash ./link-gh-groups.sh 'avolta-ag' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'
# bash ./link-gh-groups.sh 'avolta-migration-sandbox-2' 'Github Azure mappings.xlsx' 'GitHub - Azure Mapping' 'Azure Group Actual' 'GitHub Team'
# jq -r --arg group_name "AZG_GitHub_SSO_GH_CA_Advertisement-Promotion_AutoQA" --arg azure_column "Azure Group Actual" '.[] | select(.[$azure_column] == $group_name)' ./Github\ Azure\ mappings.json

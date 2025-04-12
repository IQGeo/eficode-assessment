#!/bin/bash

# Usage:
# sh ./migrate.sh <source_org> <target_org> <excel_file> <sheet_name> <repo_name_column> <production_migration_status_column>
# Example:
# sh ./migrate.sh dufry avolta-migration-sandbox 'Github Azure mappings.xlsx' 'CA Repos Full_Migration Plan' 'Repository Scope' 'Production Migration Status'
# sh ./migrate.sh dufry avolta-ag 'Github Azure mappings.xlsx' 'CA Repos Full_Migration Plan' 'Repository Scope' 'Production Migration Status'

# REPO_ROOT="$(git rev-parse --show-toplevel)"
DIR="$(dirname "$(readlink -f "$0")")"

. "$DIR/lib.sh"

MIGRATE_SCRIPT="$DIR/migrate.ps1"
MIGRATE_SCRIPT_CLEANED="$DIR/migrate_cleaned.ps1"

SOURCE_ORG="$1"
TARGET_ORG="$2"
EXCEL_FILE="$3"
SHEET_NAME="$4"
REPO_NAME_COLUMN="$5"
PRODUCTION_MIGRATION_STATUS_COLUMN="$6"

if [ "$#" -ne 6 ]; then
  echo "Usage: $0 <source_org> <target_org> <excel_file> <sheet_name> <repo_name_column> <production_migration_status_column>"
  exit 1
fi

install_brew
install_gh
install_gh_gei
install_pipx
install_xlsx2csv

# Please follow the instructions here: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
# You'll need these requird scoped in your ==>(CLASSIC)<== PAT: https://docs.github.com/en/migrations/using-github-enterprise-importer/migrating-between-github-products/managing-access-for-a-migration-between-github-products#granting-the-migrator-role-with-the-gei-extension
check_env_var "GH_PAT"

excel_sheet_to_csv_by_name "$EXCEL_FILE" "$SHEET_NAME" >"$DIR/sheet.csv"
csv_to_json "$DIR/sheet.csv" >"$DIR/sheet.json"

# Get all repos names
read -a all_repos <<< $(repos_list_names "$SOURCE_ORG" | jq -r '.[]')

# Get repos to migrate
# jq -r '.[] | .["Repository Scope"]' "sheet.json"
# TODO Update the following filters to be dynamic
read -a repos_to_migrate <<< $(jq -r '.[] | select(.["'"$PRODUCTION_MIGRATION_STATUS_COLUMN"'"] == "Wave 2" or .["'"$PRODUCTION_MIGRATION_STATUS_COLUMN"'"] == "Wave 3") | .["'"$REPO_NAME_COLUMN"'"]' "$DIR/sheet.json")
# printf '%s\n' "${repos_to_migrate[@]}"

repos_to_skip=()
for repo in "${all_repos[@]}"; do
  if [[ ! " ${repos_to_migrate[*]} " =~ ${repo} ]]; then
    repos_to_skip+=("$repo")
  fi
done
# printf '%s\n' "${repos_to_skip[@]}"

generate_migration_script "$SOURCE_ORG" "$TARGET_ORG" "$MIGRATE_SCRIPT"

skip_line=0
echo "" > "$MIGRATE_SCRIPT_CLEANED"
# Process the migration file line by line
while IFS= read -r line; do
  skip_line=0
  # Check for lines starting a repo block
  for repo in "${repos_to_skip[@]}"; do
    if [[ "$line" == *"\$RepoMigrations[\"$repo\"]"* || "$line" == *"--target-repo \"$repo\""* ]]; then
      skip_line=1
      # echo "Skipping: $line"
      break
    fi
  done

  if [[ $skip_line -eq 0 ]]; then
    echo "$line"
    echo "$line" >>"$MIGRATE_SCRIPT_CLEANED"
  fi
done <"$MIGRATE_SCRIPT"

# removeEmptyLines "$MIGRATE_SCRIPT_CLEANED"

#!/bin/bash

# Usage:
# sh ./migrate.sh <source_org> <target_org> <excel_file> <sheet_name> <repo_name_column> <status_column> <status_column_filter> [<filtered_output_file>]
#
# gh auth switch to personal account (which is owner over the source org)
# export GH_PAT=<personal-gh-pat>
#
# Examples:
#
# sh ./migrate.sh dufry avolta-migration-sandbox 'Github Azure mappings.xlsx' 'CA Repos Full_Migration Plan' 'Repository Scope' 'Production Migration Status' 'Wave 6'
# sh ./migrate.sh dufry avolta-ag 'Github Azure mappings.xlsx' 'CA Repos Full_Migration Plan' 'Repository Scope' 'Production Migration Status' 'Wave 6'

# TODOs:
# - [x] Update the filters to select certain waves to be dynamic
# - [x] Output (total number of repos) - (number of repos to be migrated) - (number of repos to be skipped)
# - [x] After the script is done, open the diff of the migration scripts (original vs cleaned) in VSCode
# - [x] If the excel file or sheet name aren't correct or not found, then print a message and exit
# - [x] If the columns for repo name and status aren't correct or not found, then print a message and exit
# - [x] Add an attribute to define output file

# REPO_ROOT="$(git rev-parse --show-toplevel)"
DIR="$(dirname "$(readlink -f "$0")")"

. "$DIR/lib.sh"

SOURCE_ORG="$1"
TARGET_ORG="$2"
EXCEL_FILE="$3"
SHEET_NAME="$4"
REPO_NAME_COLUMN="$5"
STATUS_COLUMN="$6"
STATUS_COLUMN_FILTER="$7"

MIGRATE_SCRIPT="$DIR/migrate.ps1"
MIGRATE_SCRIPT_FILTERED="${8:-migrate_filtered.ps1}"
MIGRATE_SCRIPT_FILTERED="$DIR/$MIGRATE_SCRIPT_FILTERED"

if [ "$#" -lt 7 ]; then
  echo "Usage: $0 <source_org> <target_org> <excel_file> <sheet_name> <repo_name_column> <status_column> <status_column_filter> [<filtered_output_file>]"
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

if ! file_exists "$EXCEL_FILE"; then exit 1; fi
if ! sheet_exists_in_excel_file "$EXCEL_FILE" "$SHEET_NAME"; then exit 1; fi

excel_sheet_to_csv_by_name "$EXCEL_FILE" "$SHEET_NAME" >"$DIR/sheet.csv"
csv_to_json "$DIR/sheet.csv" >"$DIR/sheet.json"

# Get all repos names
read -a all_repos <<< $(repos_list_names "$SOURCE_ORG" | jq -r '.[]')

# Get repos to migrate
# jq -r '.[] | .["Repository Scope"]' "sheet.json"
read -a repos_to_migrate <<< $(jq -r '.[] | select(.["'"$STATUS_COLUMN"'"] == "'"$STATUS_COLUMN_FILTER"'") | .["'"$REPO_NAME_COLUMN"'"]' "$DIR/sheet.json")
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
total_skipped_lines=0
printf "" > "$MIGRATE_SCRIPT_FILTERED"
# Process the migration file line by line
while IFS= read -r line; do
  skip_line=0
  # Check for lines starting a repo block
  for repo in "${repos_to_skip[@]}"; do
    if [[ "$line" == *"\$RepoMigrations[\"$repo\"]"* || "$line" == *"--target-repo \"$repo\""* ]]; then
      skip_line=1
      ((total_skipped_lines++))
      # echo "Skipping: $line"
      break
    fi
  done

  if [[ $skip_line -eq 0 ]]; then
    # echo "$line"
    echo "$line" >>"$MIGRATE_SCRIPT_FILTERED"
  fi
done <"$MIGRATE_SCRIPT"

# Output (total number of repos) - (number of repos to be migrated) - (number of repos to be skipped)
total_repos="${#all_repos[@]}"
repos_to_migrate_count="${#repos_to_migrate[@]}"
repos_to_skip_count="${#repos_to_skip[@]}"
printf "\n\n"
printf "%.0s-" {1..50}
printf "\n\n"
echo "Total number of repos: $total_repos"
echo "Number of repos to be migrated: $repos_to_migrate_count"
echo "Number of repos to be skipped: $repos_to_skip_count"
echo "Total number of skipped lines: $total_skipped_lines"

# Open the diff of the migration scripts (original vs cleaned) in VSCode
code --diff "$MIGRATE_SCRIPT" "$MIGRATE_SCRIPT_FILTERED"

# removeEmptyLines "$MIGRATE_SCRIPT_FILTERED"

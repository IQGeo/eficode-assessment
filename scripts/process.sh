#!/bin/bash

# Path to the target (data) directory
DESTINATION_FOLDER="${1}"
# Comma separated string with the target github organization names
ORGANIZATIONS="${2}"

echo "Initializing the script with the provided parameters:"
echo "Destination Folder: ${DESTINATION_FOLDER}"
printf "Organizations: %s\n\n" "${ORGANIZATIONS}"

if [ ! -d "$DESTINATION_FOLDER" ] || [ -z "$(find "$DESTINATION_FOLDER" -maxdepth 1 -name '*.json' -print -quit)" ]; then
  echo "Error: Destination folder does not exist or contains no JSON files."
  echo "Usage: $0 <destination_folder> <organizations>"
  exit 1
fi

# Validate ORGANIZATIONS parameter
if [[ -z "${ORGANIZATIONS}" ]]; then
    echo "Error: ORGANIZATIONS parameter is missing or empty. Please provide a comma-separated list of GitHub organization names."
    echo "Usage: $0 <destination_folder> <organizations>"
    exit 1
fi

echo "Changing directory to the script's location: $(dirname "${BASH_SOURCE[0]}")"
cd "$(dirname "${BASH_SOURCE[0]}")" || exit

echo "Copying all scripts from the current directory to the destination folder: ${DESTINATION_FOLDER}"
cp ./*.sh "${DESTINATION_FOLDER}"/

echo "Changing directory to the destination folder: ${DESTINATION_FOLDER}"
cd "${DESTINATION_FOLDER}" || exit

echo "Executing scripts in the destination folder"
for script in *.sh; do
    if [[ "${script}" != "process.sh" && "${script}" != _* ]]; then
      printf "\nRunning %s\n" "${script}"
      bash "${script}" "${ORGANIZATIONS}"
    fi
done

echo "Creating combined report"
sh ./_combine_reports.sh

printf "\nGenerating PDF files for all Markdown files in this folder\n"
sh ./_generate_pdfs.sh

printf "\nMoving Markdown and PDF files to ../reports\n"
mv ./*.md ../reports/
mv ./*.pdf ../reports/
printf "\nRemoving scripts from the destination folder: %s\n" "${DESTINATION_FOLDER}"
rm -f ./*.sh

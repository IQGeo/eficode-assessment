#!/bin/bash

SOURCE_FOLDER="${1}"
DESTINATION_FOLDER="${2}"

if [ -z "$SOURCE_FOLDER" ]; then
  echo "Source folder is required" ; exit 1
fi

if [ -z "$DESTINATION_FOLDER" ]; then
  echo "Destination folder is required"; exit 1
fi

if [ ! -d "$DESTINATION_FOLDER" ]; then
  mkdir -p "$DESTINATION_FOLDER"
fi

# Read all zip files in the source folder and unzip them to a destination folder
find "$SOURCE_FOLDER" -type f -name "*.zip" -exec unzip -o {} -d "$DESTINATION_FOLDER" \;

# Read all the json files in the destination folder and format them inplace using jq
find "$DESTINATION_FOLDER" -type f -name "*.json" -exec sh -c 'jq . "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \;

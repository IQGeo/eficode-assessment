#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/lib.sh"

if [ -z "$1" ]; then
  echo "Usage: $0 <ORG> [INCLUDE_FULL_NAME: true|false (default: false)]"
  exit 1
fi

ORG="$1"
INCLUDE_FULL_NAME=${2:-false}

# Generate the report
generate_repo_admins_report "$ORG" "$INCLUDE_FULL_NAME"

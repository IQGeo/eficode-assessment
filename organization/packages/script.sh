#!/bin/bash

set -eo pipefail

OWNER="${1}"

# create ../../reports if it doesn't exist
mkdir -p ../../reports

TYPES=(npm maven rubygems docker nuget)

for i in "${TYPES[@]}"; do
  type="${i}"
  echo "Auditing type ${type} ..."

  gh api \
    -H X-Github-Next-Global-ID:true \
    --paginate \
    "/orgs/${OWNER}/packages?package_type=${type}" \
    --jq "[ .[] | {"name": .name, "package_type": .package_type, "linked_repo": .repository.name } ]" \
    > "${i}_type.json"

done

jq -s add *_type.json \
  > ../../reports/repository-packages.json

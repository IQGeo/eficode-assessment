#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

TYPES=(npm maven rubygems docker nuget)
DEST=packages.json
echo "[]" >$DEST

for i in "${TYPES[@]}"; do
  type="$i"
  echo "Auditing type $type ..."

  PACKAGES_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true "/orgs/${1}/packages?package_type=$type")
  echo $PACKAGES_RESULT | jq "[{ org: .[].owner.login, packages: [ { type: .[].package_type, name: .[].name, repository_name: .[].repository.name, repository_full_name: .[].repository.full_name } ] }]" \
    >type_packages.json

  cp $DEST tmp.json
  jq -sc add tmp.json type_packages.json >$DEST
  rm -rf type_packages.json, tmp.json
done

jq -c ' [{org: (.[0].org), packages: ([ .[].packages? | .[] | { type: .type, name: .name, repository_name: .repository_name, repository_full_name: .repository_full_name  } ] ) } ]' $DEST >../../reports/packages.json

# Group by repository full name and filter by scoped repositories
REPOS=$(jq -r ".[].nameWithOwner" "$2")

cat $DEST |
  jq -rc '.[] | .packages | .[] | {repository_full_name: .repository_full_name, repository_name: .repository_name, name: .name, type: .type}' |
  jq -s '.' |
  jq -rc 'group_by(.repository_full_name) | .[] | {repository_full_name: .[0].repository_full_name, repository_name: .[0].repository_name, packages: [.[] | {name: .name, type: .type}]}' |
  jq -s '.' |
  jq -rc --arg repos "${REPOS[@]}" '.[] | select(.repository_full_name as $repo | $repos | index($repo))' \
    >../../reports/repository-packages.json

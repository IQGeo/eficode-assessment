#!/bin/bash

set -eo pipefail

# create ../../reports if it doesn't exist
mkdir -p ../../reports

TYPES=(npm maven rubygems docker nuget)

echo "[]" > packages.json

for i in "${TYPES[@]}"
do
	type="$i"
    echo "Auditing type $type ..."

    gh api --paginate -H X-Github-Next-Global-ID:true "/orgs/${1}/packages?package_type=$type"

    PACKAGES_RESULT=$(gh api --paginate -H X-Github-Next-Global-ID:true "/orgs/${1}/packages?package_type=$type" | TYPE=$type ORG_NAME=${1} jq '[{ org: env.ORG_NAME, packages: [ { type: env.TYPE, name: .[].name } ] }]')

    echo "$PACKAGES_RESULT" > type_packages.json

    cp packages.json tmp.json

    jq -sc add tmp.json type_packages.json  > packages.json

    rm -rf type_packages.json
    rm -rf tmp.json
done

jq -c ' [{org: (.[0].org), packages: ([ .[].packages? | .[] | { type: .type, name: .name } ] ) } ]' packages.json > ../../reports/packages.json

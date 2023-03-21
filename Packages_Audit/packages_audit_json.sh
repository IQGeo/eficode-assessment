TYPES=(npm maven rubygems docker nuget container)

echo "[]" > packages.json

for i in "${TYPES[@]}"
do
	type="$i"
    echo "Auditing type $type ..."

    PACKAGES_RESULT=$(gh api /orgs/$ORG_NAME/packages?package_type=$type | TYPE=$type ORG_NAME=$ORG_NAME jq '[{ org: env.ORG_NAME, packages: [ { type: env.TYPE, name: .[].name } ] }]')

    echo $PACKAGES_RESULT > type_packages.json

    cp packages.json tmp.json
    jq -s add tmp.json type_packages.json  > packages.json

    rm -rf type_packages.json
    rm -rf tmp.json

done

cp packages.json tmp.json
jq ' [{org: (.[0].org), packages: ([ .[].packages? | .[] | { type: .type, name: .name } ] ) } ]' tmp.json > packages.json
rm -rf tmp.json

gh issue comment $ISSUE_URL --body-file packages.json

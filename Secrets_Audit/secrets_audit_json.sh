ORG_NAME=sparlant-demo-org

build_repo_secrets_list() {
  repo_name=$1
  secret_type=$2

  REPO_SECRETS=$(gh secret list --app $secret_type --repo $repo_name)

  echo "$REPO_SECRETS"
}

build_org_secrets_list() {
  org_name=$1
  secret_type=$2

  REPO_SECRETS=$(gh secret list --app $secret_type --org $org_name)

  echo "$REPO_SECRETS"
}

RESULT_SECRETS=$'\n\n# Secrets \n'

declare -A secrettypes0=(
    [name]='Actions Secrets'
    [type]='actions'
    [repo_results]=''
    [org_results]=''
)
declare -A secrettypes1=(
    [name]='Dependabot Secrets'
    [type]='dependabot'
    [repo_results]=''
    [org_results]=''
)
declare -A secrettypes2=(
    [name]='Codespaces Secrets'
    [type]='codespaces'
    [repo_results]=''
    [org_results]=''
)

declare -n secrettypes

REPOS=$(gh repo list $ORG_NAME --json name --jq '.[].name')

JSON_RESULT="["

for secrettypes in ${!secrettypes@}; do
    echo "${secrettypes[type]}"

    JSON_RESULT+="{"
    JSON_RESULT+='"secret_type":"'
    JSON_RESULT+="${secrettypes[name]}"
    JSON_RESULT+='",'
    JSON_RESULT+='"repos":['


    while read -r repo ; do
        echo "Auditing repository $repo ..."

        JSON_RESULT+='{ "repo":"'
        JSON_RESULT+="$repo"
        JSON_RESULT+='"'

        REPO_SECRETS=($(build_repo_secrets_list $ORG_NAME/$repo "${secrettypes[type]}" | awk '{ print $1 }'))

        if [ "$REPO_SECRETS" != "" ]; then
            JSON_RESULT+=',"secrets":'
            REPO_JSON_RESULT=$(jq -n '$ARGS.positional' --args "${REPO_SECRETS[@]}")
            JSON_RESULT+="$REPO_JSON_RESULT"
        fi
        JSON_RESULT+='},'
    done <<< $REPOS

    JSON_RESULT=${JSON_RESULT::-1} 
    JSON_RESULT+='],"org":{'

    ORG_SECRETS=($(build_org_secrets_list $ORG_NAME "${secrettypes[type]}" | awk '{ print $1 }'))
    if [ "$ORG_SECRETS" != "" ]; then
        JSON_RESULT+='"secrets":'
        ORG_JSON_RESULT=$(jq -n '$ARGS.positional' --args "${ORG_SECRETS[@]}")
        JSON_RESULT+="$ORG_JSON_RESULT"
    fi

    JSON_RESULT+="}"
    JSON_RESULT+="},"
done
unset -n secrettypes

JSON_RESULT=${JSON_RESULT::-1} 
JSON_RESULT+="]"

gh issue comment $ISSUE_URL --body "$JSON_RESULT"

echo $RESULT > secrets.json

#!/bin/bash

add_value() {
  value=$1

  if [ "$value" = "null" ] || [ "$value" = "0" ] || [ "$value" = "[]" ];
  then
    SUMMARY+=$"   |"
  else
    SUMMARY+=$" x |"
  fi
}

organization_report() {
  SUMMARY+=$'## Organization \n\n'
  SUMMARY+=$'| Org | Apps | Actions Secrets | Dependabot Secrets | Codespaces Secrets | Projects | Packages | '
  SUMMARY+=$' \n|---|---|---|---|---|---|---|  \n '

  org_name=$(jq -r '.[0] | .org' org.json)
  org_apps=$(jq -r '.[0] | .apps' org.json)
  org_actions_secrets=$(jq -r '.[0] | .actions_secret' org.json)
  org_dependabot_secret=$(jq -r '.[0] | .dependabot_secret' org.json)
  org_codespaces_secret=$(jq -r '.[0] | .codespaces_secret' org.json)
  org_projects=$(jq -r '.[0] | .projects' org.json)
  org_packages=$(jq -r '.[0] | .packages' org.json)

  SUMMARY+=$'| '
  SUMMARY+="$org_name"
  SUMMARY+=$' |'

  add_value "$org_apps"
  add_value "$org_actions_secrets"
  add_value "$org_dependabot_secret"
  add_value "$org_codespaces_secret"
  add_value "$org_codespaces_secret"
  add_value "$org_projects"
  add_value "$org_packages"
}

repositories_report() {
  SUMMARY+=$'\n\n\n## Repositories \n\n'

  SUMMARY+=$'\n\n\n | Repo | Visibility | LFS | Permissions | Actions Secrets | Dependabot Secrets | Codespaces Secrets | Environments | Branch protection rules | Discussions | '
  SUMMARY+=$' \n|---|---|---|---|---|---|---|---|---|---|  \n '

  while read repo; do
    repo_name=$(jq -r '. | .repo' <<< "$repo")
    visibility=$(jq -r '. | .visibility' <<< "$repo")
    lfs=$(jq -r '. | .lfs' <<< "$repo")
    permissions=$(jq -c '. | .permissions' <<< "$repo")
    actions_secrets=$(jq -c '. | .actions_secret' <<< "$repo")
    dependabot_secret=$(jq -c '. | .dependabot_secret' <<< "$repo")
    codespaces_secret=$(jq -c '. | .codespaces_secret' <<< "$repo")
    env=$(jq -c '. | .env' <<< "$repo")
    branchProtectionRules=$(jq -c '. | .branchProtectionRules' <<< "$repo")
    discussions=$(jq -c '. | .discussions' <<< "$repo")

    SUMMARY+=$'| '
    SUMMARY+="$repo_name"
    SUMMARY+=$' |'

    add_value "$visibility"
    add_value "$lfs"
    add_value "$permissions"
    add_value "$actions_secrets"
    add_value "$dependabot_secret"
    add_value "$codespaces_secret"
    add_value "$env"
    add_value "$branchProtectionRules"
    add_value "$discussions"
    SUMMARY+=$' \n '
  done <<< $(jq -c '.[]' repositories.json)
}

repositories_summary() {
  lfs_count=$(jq -r '[ .[] | select(.lfs) ] | length' repositories.json)
  discussions_count=$(jq -r '[ .[] | select(.discussions > 0) ] | length' repositories.json)
  environments_count=$(jq -r '[ .[] | select(.env | length > 0 ) ] | length' repositories.json)
  branch_protection_rules_count=$(jq -r '[ .[] | select(.branchProtectionRules | length > 0) ] | length' repositories.json)
  permissions_count=$(jq -r '[ .[] | select(.permissions | length > 0) ] | length' repositories.json)
  actions_secrets_count=$(jq -r '[ .[] | select(.actions_secret | length > 0) ] | length' repositories.json)
  dependabot_secret_count=$(jq -r '[ .[] | select(.dependabot_secret | length > 0) ] | length' repositories.json)
  codespaces_secret_count=$(jq -r '[ .[] | select(.codespaces_secret | length > 0) ] | length' repositories.json)
  visibility_count=$(jq -r '[ .[] | select(.visibility) ] | length' repositories.json)

  SUMMARY+=$'\n\n\n## Summary \n\n'
  SUMMARY+=$'| Visibility | LFS | Permissions | Actions Secrets | Dependabot Secrets | Codespaces Secrets | Environments | Branch protection rules | Discussions | '
  SUMMARY+=$' \n|---|---|---|---|---|---|---|---|---|  \n '
  SUMMARY+=$'| '
  add_value "$visibility_count"
  add_value "$lfs_count"
  add_value "$permissions_count"
  add_value "$actions_secrets_count"
  add_value "$dependabot_secret_count"
  add_value "$codespaces_secret_count"
  add_value "$environments_count"
  add_value "$branch_protection_rules_count"
  add_value "$discussions_count"
  SUMMARY+=$' \n '
}

SUMMARY=$''

organization_report
repositories_summary
repositories_report

echo "$SUMMARY" > summary.md 
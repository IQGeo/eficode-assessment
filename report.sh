jq '.[] | select(.secret_type=="Actions Secrets")' secrets.json | jq '[ .repos[] | { repo: .repo, actions_secret: .secrets }  ]' > actions_secrets.json
jq '.[] | select(.secret_type=="Dependabot Secrets")' secrets.json | jq '[ .repos[] | { repo: .repo, dependabot_secret: .secrets }  ]' > dependabot_secrets.json
jq '.[] | select(.secret_type=="Codespaces Secrets")' secrets.json | jq '[ .repos[] | { repo: .repo, codespaces_secret: .secrets }  ]' > codespaces_secrets.json

jq -s 'add' permissions.json visibility.json actions_secrets.json dependabot_secrets.json codespaces_secrets.json lfs.json environments.json protections.json | jq ' group_by(.repo) | map(add) ' > repositories.json

ORG_NAME="$ORG_NAME" jq '.[] | select(.secret_type=="Actions Secrets")' secrets.json | jq '[ .org | { org: env.ORG_NAME, actions_secret: .secrets }  ]' > org_actions_secrets.json
ORG_NAME="$ORG_NAME" jq '.[] | select(.secret_type=="Dependabot Secrets")' secrets.json | jq '[ .org | { org: env.ORG_NAME, dependabot_secret: .secrets }  ]' > org_dependabot_secrets.json
ORG_NAME="$ORG_NAME" jq '.[] | select(.secret_type=="Codespaces Secrets")' secrets.json | jq '[ .org | { org: env.ORG_NAME, codespaces_secret: .secrets }  ]' > org_codespaces_secrets.json

ORG_NAME="$ORG_NAME" jq '[ [ .[] | { org: env.ORG_NAME, id: .id, app_slug: .app_slug }  ] | group_by(.org)[]  | {org: (.[0].org), apps: [.[] | { id: .id, app_slug: .app_slug } ]} ]' apps.json > org_apps.json

jq -s 'add' org_actions_secrets.json org_dependabot_secrets.json org_codespaces_secrets.json org_apps.json projects.json | jq ' group_by(.org)  | map(add)' > org.json

gh issue comment $ISSUE_URL --body-file org.json
gh issue comment $ISSUE_URL --body-file repositories.json

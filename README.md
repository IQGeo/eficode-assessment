# GEI Audit

GitHub Action to audit an organization before running `gh gei`.

## Scope

According to the [official documentation](https://docs.github.com/en/early-access/enterprise-importer/understanding-github-enterprise-importer/migration-support-for-github-enterprise-importer#githubcom-migration-support) here are the not supported data that are covered by this assessment:

- [x] Git LFS objects and large binaries
- [x] GitHub secrets
  - [x] Organization
    - [x] Dependabot
    - [x] Codespaces
    - [x] Actions
  - [x] Repository
    - [x] Dependabot
    - [x] Codespaces
    - [x] Actions
- [x] GitHub Actions Environments
- [ ] Webhook secrets
- [x] Projects (classic) at the organization level
- [x] Any Projects (the new projects experience)
- [x] Discussions at the repository level
- [x] Packages in GitHub Packages
- [x] GitHub Apps
- [x] User access to the repository
- [x] Repository visibility  
- [x] Some branch protection rules

## How to use it?

You have to create a personnal access token with this scope:
- `codespace:secrets`
- `read:discussion`
- `read:org`
- `read:packages`
- `read:project`
- `repo`

Then, you have to store the value in a GitHub Actions Secret called `PAT`. 

Finally, you can manually trigger the workflow called `Migration assessment` and give the name of the org that you want to assess. 
# EMU Assessment

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
- [x] Webhooks
- [x] Forked repositories
- [x] Environments
- [x] Projects (classic) at the organization level
- [x] Any Projects (the new projects experience)
- [x] Discussions at the repository level
- [x] Packages in GitHub Packages
- [x] GitHub Apps
- [x] User access to the repository
- [x] Repository visibility  
- [x] branch protection rules

## How to use it?

TODO: describe how to use the GitHub app 'emu-assessment'

Then, you have to store the application ID and private key in a GitHub Actions Secret called APPLICATION_ID and APPLICATION_PRIVATE_KEY  

Finally, you can manually trigger:
- the workflow called `Org Migration assessment` and give the name of the org that you want to assess
- the workflow called `MultiOrg Migration assessment` and give a list of org names that you want to assess

## Result

The result will be available in a GitHub Issue with the name of the organization. You'll find a summary of the result in the body and then multiple comments with the json result per feature, for the global org features, for the global org respotiory features and at the end some explanations on how to manage it on the new GitHub enterprise account.

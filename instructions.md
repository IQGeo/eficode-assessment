# POST-MIGRATION

## Visibility

You can use these [REST API Endpoint](https://docs.github.com/en/enterprise-cloud@latest/rest/repos/repos?apiVersion=2022-11-28#update-a-repository) or follow these [steps](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/managing-repository-settings/setting-repository-visibility#changing-a-repositorys-visibility).

## LFS

You can follow these [steps](https://github.github.com/enterprise-migrations/#/./4.3.0-post-migration-global-caveats?id=lfs).

## Permissions

You can manage repository permissions by:
- using teams
  - create a team
    - [UI](https://docs.github.com/en/organizations/organizing-members-into-teams/creating-a-team)
    - [API](https://docs.github.com/en/rest/teams/teams?apiVersion=2022-11-28#create-a-team)
  - add a member to a team
    - [UI](https://docs.github.com/en/organizations/organizing-members-into-teams/adding-organization-members-to-a-team)
    - [API](https://docs.github.com/en/rest/teams/members?apiVersion=2022-11-28#add-or-update-team-membership-for-a-user)
  - give permission to a team on a repository
    - [UI](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-team-access-to-an-organization-repository)
    - [API](https://docs.github.com/en/rest/teams/teams?apiVersion=2022-11-28#add-or-update-team-repository-permissions)
- managing individual permissions
  - give permission to a user on a repository
    - [UI](https://docs.github.com/en/organizations/managing-user-access-to-your-organizations-repositories/managing-an-individuals-access-to-an-organization-repository)
    - [API](https://docs.github.com/en/rest/collaborators/collaborators?apiVersion=2022-11-28#add-a-repository-collaborator)

We strongly recommend to use teams for managing repository permissions and visibility, facilitating conversaton, and reducing management overhead. Teams used for permission management should be synced with an IdP group (like Okta). This allows existng IdP processes and audit controls to be relied upon for managing access to code.  
Onboarding, ofboarding, and access changes are all managed by the IdP.  
With teams, you can easily see which teams maintain which projects: a list of all repositories to which a team has been granted explicit permissions (beyond the organizaton’s default) is available on each team’s page in GitHub.  

## Secrets

You can manage:
- at the repository level:
  - actions secrets by following these [steps](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-a-repository)
  - environment secrets by following these [steps](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-environment)
  - codespaces secrets by following these [steps](https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-a-repository)
  - dependabot secrets by following these [steps](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot#adding-a-repository-secret-for-dependabot)
- at the organization level:
  - actions secrets by following these [steps](https://docs.github.com/en/actions/security-guides/encrypted-secrets#creating-encrypted-secrets-for-an-organization)
  - codespaces secrets by following these [steps]( https://docs.github.com/en/codespaces/managing-codespaces-for-your-organization/managing-encrypted-secrets-for-your-repository-and-organization-for-github-codespaces#adding-secrets-for-an-organization)
  - dependabot secrets by following these [steps](https://docs.github.com/en/code-security/dependabot/working-with-dependabot/configuring-access-to-private-registries-for-dependabot#adding-an-organization-secret-for-dependabot)

You cannot "move" or "copy" a secret from repository from another one. You cannot retrieve the value of a secret. You can only create a new secret and use the current value if you have previously stored it in a secret manager like 1Password7 or KeePass for example.

## Environments

You can create/udpate an environment by following these [steps](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment) or using this [REST API Endpoint](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#creating-an-environment).

## Branch protection rules

You can create/udpate a branch protection rule by following these [steps](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/managing-a-branch-protection-rule#about-branch-protection-rules) or using this [REST API Endpoint](https://docs.github.com/en/enterprise-cloud@latest/rest/branches/branch-protection?apiVersion=2022-11-28#update-branch-protection).

## Discussions

You cannot really migrate the discussion but you can recreate important ones by using the [GraphQL API](https://docs.github.com/en/graphql/guides/using-the-graphql-api-for-discussions) for example.

## Webhooks

You can follow these [steps](https://github.github.com/enterprise-migrations/#/./4.3.0-post-migration-global-caveats?id=webhooks).

## GitHub Apps

You can create a GitHub Apps by following there [steps](https://docs.github.com/fr/apps/creating-github-apps/creating-github-apps/creating-a-github-app). Then, you'll have to update the certificate, application ID and installation ID used by your application to authenticate.

## Projects

You can create a GitHub Projects by following these steps or these [steps](https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/creating-a-project).

## Packages

You can download all your packages from your old instance (with `npm install` for example for a NodeJS application) and then publish these packages to your new instance (with `npm publish` for example for a NodeJS application).

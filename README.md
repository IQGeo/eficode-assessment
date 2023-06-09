# GHEC Migration Audit

This repository consist of all the relevant bash scripts, packaged as composite action for each data point and an example workflow optimized for scale on how to consume these. This README provides instructions on how audit organizations and repositories for migration with GEI, in order to assess the data not migrated. The output of this audit is a series of json files with all the data point that you would need to apply post migration. The data points are: 

- Organization
  - actions
  - GitHub Apps
  - packages (npm, maven, rubygems, docker, nuget)
  - projects
  - repositories
  - secrets (organization, repository, action, dependabot, codespaces)
  - webhooks
- Repository
  - branch protection rules
  - discussions
  - environments and secrets
  - permissions
  - teams
  - users
  - webhooks

Note that currently we can not retrieve containers from the packages endpoint with a GitHub App.

For more information regarding which data is or is not migrated, see [GitHub.com migration support](https://docs.github.com/en/migrations/using-github-enterprise-importer/understanding-github-enterprise-importer/migration-support-for-github-enterprise-importer#githubcom-migration-support). 





## Prerequisites
- Organization owner in order to create and install the GitHub app.
- GitHub App with bare minimum permissions. 

## Getting started

1. Create a GitHub app and assign the following permission: 
	  
	  **Read access:**
	
	> Dependabot alerts, actions, actions variables, administration, checks, code, codespaces, codespaces lifecycle admin, codespaces metadata, commit statuses, custom repository roles, dependabot secrets, deployments, discussions, environments, issues, members, merge queues, metadata, organization actions variables, organization administration, organization codespaces, organization codespaces secrets, organization codespaces settings, organization dependabot secrets, organization hooks, organization personal access token requests, organization personal access tokens, organization plan, organization projects, organization secrets, organization self hosted runners, packages, pages, pull requests, repository advisories, repository hooks, repository projects, secret scanning alerts, secrets, security events, and team discussions
	  
	  **Read and write access:**
	 
	> codespaces secrets and workflows


2. Copy the Application ID and private key and create 2 organization secrets called APPLICATION_ID and APPLICATION_PRIVATE_KEY and assign the values.


3. Install the GitHub App into the organizations needed to be audited. Select either relevant or all repositories. 


4. Trigger the sample workflow `GHEC EMU Migration Audit` with one or more organization names as input parameter.
	


## Result
The result from running the composite actions, will be a series of artifacts for each organization and repository data point containing one or more json files.  


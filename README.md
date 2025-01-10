# Azure Deployment Environments (ADE)

This repository contains a collection of Azure Resource Manager (ARM) templates for deploying and managing standardized cloud environments in Azure. 

Using Bicep, a domain-specific language (DSL) for deploying Azure resources declaratively, it enables developers and infrastructure teams to define reusable, modular, and versioned infrastructure-as-code components.

The templates are organized per environment, allowing tailored configurations for different scenarios such as development sandboxes or production-ready web applications with Microsoft SQL Server backends.

By leveraging Azure CLI, Azure Developer CLI, and scripting, these templates provide the foundation for an automated and repeatable deployment process, facilitating consistent and reliable environment setup and maintenance.

## Prerequisites

* install Azure CLI (az)
* install Azure Developer CLI (azd) for debugging

## Create Deployment-Environment

The repository has the following folder structure:

```
└───Environments
    ├───Sandbox
    |   ├───azuredeploy.json
    |   └───infra
    │       └───main.bicep    
    └───WebApp-MSSQL
        ├───azuredeploy.json    
        └───infra
            └───main.bicep
```

After you make changes to the .bicep files make sure to run the following command to update the azuredeploy.json files used by the Azure Deployment Environment (ADE) system:

```bash
.\build.ps1
```

The `build.ps1` PowerShell script will traverse all subfolders and transpile the `main.bicep` script into the `azuredeploy.json` ARM template using the `az bicep build --file $bicepFilePath --outfile $jsonOutputPath` command.


## How to add this Azure Deployment Environments (ADE) Catalog to DevCenter?

* Generate a GitHub Access Token to enable secure access to your repository.
* Take note of the GitHub repository URL, for example: https://github.com/fnbk/azure-deployment-env.git
* Use the token and repository link to add a new catalog to DevCenter, integrating your ADE templates into the developer workflow.



# Useful Commands

**Useful commands for deployment with `azd` command:
```bash
# login
azd auth login

# configure azd to use use local infra files
azd config unset platform

# will create .azure directory and store configuration
azd init --environment test1

# provision azure infrastructure
azd provision

# delete all azure resources (no questions asked)
azd down --force --purge

# cleanup any configurations
rm -r ./azure

# cleanup home directory
rm -r ~/.azd

# logout
azd auth logout

# find out my user's object ID
az ad signed-in-user show --query id
```


**Manual provisioning:**
```pwsh
$environmentName = "sunshine"
$location = "westeurope"
$bicepFile = "Environments/WebApp-MSSQL/infra/main.bicep"
$userPrincipalName = "hello@example.com"

$userPrincipalId = (az ad user show --id $userPrincipalName | ConvertFrom-Json).id
$resourceGroupName = "rg-$environmentName"

Write-Host "location: $location"
Write-Host "resourceGroupName: $resourceGroupName"
Write-Host "userPrincipalName: $userPrincipalName"
Write-Host "userPrincipalId: $userPrincipalId"
Write-Host "bicepFile: $bicepFile"

if($userPrincipalId){
    Write-Host "Creating Resource Group"
    az group create --name $resourceGroupName --location $location
    Write-Host "Starting Privisioning"
    az deployment group create --resource-group $resourceGroupName --template-file $bicepFile --parameters environmentName=$environmentName userOrAppId=$userPrincipalId
} else {
    Write-Host "User Principal Name cannot be found."
}

Write-Host "Done"
```

Delete all resources:
```bash
az group delete --name $resourceGroupName --yes --no-wait
```


**Tags:**
* azd-env-name: environmentName
* azd-service-name: resource tagged with azd-service-name with a value that matches the name of your service from azure.yaml.
source: https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/faq#how-does-azd-find-the-azure-resource-to-deploy-my-code-to


**Environment variables provided by `azd`:**
* AZURE_ENV_NAME - The name of the environment in-use, e.g. todo-app-dev
* AZURE_LOCATION - The location of the environment in-use, e.g. westeurope
* AZURE_PRINCIPAL_ID - The running user/service principal, e.g. 925cff12-ffff-4e9f-9580-8c06239dcaa4 Determined automatically during provisioning.
* AZURE_SUBSCRIPTION_ID - The targeted subscription, e.g. 925cff12-ffff-4e9f-9580-8c06239dcaa4


**deploy using `az devcenter` command:**
```bash
az devcenter dev environment create --name 'my-dev-environment' --environment-type 'Dev' --dev-center 'dev-center-name' --project 'dev-center-project' --catalog-name 'catalog-name' --environment-definition-name 'my-template-definition'
```



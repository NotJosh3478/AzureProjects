Infrastructure information: The deployment is separated into two different launch bicep files the main.bicep and deploySessionHosts.bicep the reason it's separated is so the admin can input
the avd-admin-password and avd-admin-username into the keyvault to be used and so the password and username are not show in plain-text history.

Module files used in main.bicep include: applicationGroup.bicep, hostPool.bicep, keyVault.bicep, keyVaultRoleAssignment.bicep, network.bicep, nsg.bicep, roleAssignment.bicep,
and workspace.bicep
Module files used in deploySessionHosts.bicep include: sessionHost.bicep

Three subnets are created: ${prefix}-snet-${environment}-sessionhosts, ${prefix}-snet-${environment}-private-endpoints, and ${prefix}-snet-${environment}-management
Three nsgs are created: ${prefix}-nsg-${environment}-sessionhosts, ${prefix}-nsg-${environment}-private-endpoints, and ${prefix}-nsg-${environment}-management



Deploy instructions: deploy main.bicep then insert avd-admin-username and avd-admin-password into keyvault and run deploySessionHosts.bicep
    
Deploy main.bicep:    az deployment sub create --name avd-prod-deployment --location westus2 --template-file main.bicep

Find keyvault name:
az keyvault list `
  --resource-group az-Virtual-Desktop-RG `
  --query "[].name" `
  --output tsv

Insert avd-admin-username:
az keyvault secret set `
  --vault-name <Vault-name> `
  --name avd-admin-username `
  --value <username>

Insert avd-admin-password:
--Comment--
The reason you would run this instead of the typical command is to keep the plain-text password out of powershell history.
--Comment--
$securePassword = Read-Host "Enter AVD admin password" -AsSecureString
$password = [System.Net.NetworkCredential]::new('', $securePassword).Password

az keyvault secret set `
  --vault-name <Vault-name> `
  --name avd-admin-password `
  --value $password

Remove-Variable password

Turn the avd-admin-username and avd-admin-password into variables for easier deployment:
$avdAdminUser = az keyvault secret show `
  --vault-name <Vault-name> `
  --name avd-admin-username `
  --query id `
  --output tsv

$avdAdminPassword = az keyvault secret show `
  --vault-name <Vault-name> `
  --name avd-admin-password `
  --query id `
  --output tsv

Deployment once you have the variables set for $avdAdminPassword and $avdAdminUser
az deployment sub create `
  --name avd-sessionhosts-prod `
  --location westus2 `
  --template-file deploySessionHosts.bicep `
  --parameters `
    environment=prod `
    prefix=avd `
    rgName=az-Virtual-Desktop-RG `
    adminUsernameSecretUri=$avdAdminUser `
    adminPasswordSecretUri=$avdAdminPassword

Once deployment is successful add users to applicationGroup and connect using Windows App




Cleanup instructions: delete az-Virtual-Desktop-RG
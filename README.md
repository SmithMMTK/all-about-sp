# all-about-sp

## Get Service Principle and Sign-in Tasks


- [x] Create Service Principle and Password
- [x] Sign-in with Service Principle

- [x] Create Diaganostic Logs to collect Sign-in logs
- [x] Get Last logon by KQL

```sql
AADServicePrincipalSignInLogs
| where TimeGenerated > ago(7d)
```


## Get Service Principle Expired Date

### Create service principle for automation process

```bash
az ad sp create-for-rbac -n "smi15sp-sp-auto" --role Reader \
    --scopes /subscriptions/0c405f85-9068-46a6-b1c7-766b17bbd69a

az logout
az login --service-principal --username $appId --password $pwd  --tenant $TENANT_ID  
az account show -o table
```


```powershell
Install-Module -Name AzureAD -Repository PSGallery -Force
Get-AzureADServicePrincipal -ObjectId 7de2424d-f9d8-4ee7-b1f4-4b2441dc6ebf

```





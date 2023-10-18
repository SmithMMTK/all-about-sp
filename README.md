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

```powershell
Install-Module -Name AzureAD -Repository PSGallery -Force

Get-AzureADServicePrincipal -ObjectId 7de2424d-f9d8-4ee7-b1f4-4b2441dc6ebf

```





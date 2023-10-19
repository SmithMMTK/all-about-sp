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

*** Ensure Service Principle has Global Reader role in Entra ID ***

- get-sp-task-scheduler.ps1 to run in Windwos Task scheduler
- get-sp-task-automation.ps1 to run with Azure Automation Account


### Add a variables to Azure Automation Account



### Get LogAnalytics Key

*Settings* → *Agents management* → **Primary key**

```
PrimaryKey: xxx

```

*Settings* → *Agents management* → **Workspace ID**

```
WorkspaceID: xxx

```

### Add Variable

*Azure Automation Account* → *Variables* → **Add Variable**

```
Name: appId
Type: String
Value: [AppId]
Encrypted: Yes

```

Azure Automation Account → Variables → Add Variable
```
Name: appPwd
Type: String
Value: [Secret]
Encrypted: Yes

```

*Azure Automation Account* → *Variables* → **Add Variable**

```
Name: LogAnalyticsPrimaryKey
Type: String
Value: [PrimaryKey]]
Encrypted: Yes

```

*Azure Automation Account* → *Variables* → **Add Variable**

```
Name: LogAnalyticsWorkspaceID
Type: String
Value: [WorkspaceID]]
Encrypted: Yes

```

*Azure Automation Account* → *Variables* → **Add Variable**

```
Name: MonitoredTenantID
Type: String
Value: [tenant]
Encrypted: Yes

```

## Deploy Workbook to automation acccount
[get-sp-automation.ps1](get-sp-automation.ps1)

## KQL 
```sql
AppRegistrationExpiration_CL
| summarize arg_max(TimeGenerated,*) by AppId_g
//| where DaysToExpiration_d <= 50 //Change this value to the expiration threshold | where TimeGenerated > ago(1d)
| project TimeGenerated, DisplayName_s, AppId_g, Id_g, DaysUntilExpiration_d, Status_s, Note_s
```





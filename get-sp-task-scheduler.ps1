
## Required AzureAD
## Install-Module -Name AzureAD
## Required Az
## Install-Module -Name Az


# $appId="xxx"
# $appPwd="xxx"
# $tenantID="xxx"
            
## Get Service Principle
## Create credential object
## Define Tenant ID
## Service Principle must have Global Reader privileges to be able to read service principle attributes

$SecurePassword = ConvertTo-SecureString $appPwd -AsPlainText -Force

$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $appId, $SecurePassword


## Logon to Azure by Service Principle
# For first time before run script you need to install Az module
# Install-Module -Name Az -Repository PSGallery -Force

Write-output 'Logging into Azure...'

try {
    Connect-AzAccount -ServicePrincipal -Credential $Credential -Tenant $tenantID
    Write-Output "  "
    Write-Output "Logged in to Azure as $($appId)"
    Get-AzContext
    
} catch {
    write-error "$($_.Exception)"
    throw "$($_.Exception)"
}

### End of Authentication 

### Query Service Principle
Write-output 'Querying Service Principle...'
$applications = Get-AzADApplication
# To see attributes of the application object, run the following command: 
# $applications[0].PSObject.Properties


# Initialize an empty array to store application credentials
$appWithCredentials = @()


# Loop through each application in the $applications array, sorted by DisplayName
$applications | Select-Object Id, AppId, DisplayName, Note, PasswordCredentials | ForEach-Object {
   
    # Parse the JSON stored in PasswordCredentials
    foreach ($password in $_.PasswordCredentials) {
        $passwordJson = $password | ConvertTo-Json
        $passwordCredential = $passwordJson | ConvertFrom-Json
        $startDateTime = $passwordCredential.StartDateTime -as [datetime]
        $endDateTime = $passwordCredential.EndDateTime -as [datetime]
    }

    ## Calcuate the number of days until the password expires
    $daysUntilExpiration = ($endDateTime - (Get-Date)).Days

    ## If the password has already expired, set Status = Expired else set Status = Active
    if ($daysUntilExpiration -lt 0) {
        $status = 'Expired'
    } else {
        $status = 'Active'
    }

 
    # Output the relevant information
    $appInfo = @{
        DisplayName = $_.DisplayName
        Id = $_.Id
        AppId = $_.AppId
        StartDateTime = $startDateTime
        EndDateTime = $endDateTime
        Note = $_.Note
        DaysUntilExpiration = $daysUntilExpiration
        Status = $status
    }

    $appWithCredentials += $appInfo
    
}

Write-Output "Extracted $($appWithCredentials.Count) applications with credentials"

### End of Query Service Principle

Function _SendToLogAnalytics{
    Param(
        [string]$customerId,
        [string]$sharedKey,
        [string]$logs,
        [string]$logType,
        [string]$timeStampField
    )
        # Generate the body for the Invoke-WebRequest
        $body = ([System.Text.Encoding]::UTF8.GetBytes($Logs))
        $method = "POST"
        $contentType = "application/json"
        $resource = "/api/logs"
        $rfc1123date = [DateTime]::UtcNow.ToString("r")
        $contentLength = $body.Length

        #Create the encoded hash to be used in the authorization signature
        $xHeaders = "x-ms-date:" + $rfc1123date
        $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource
        $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
        $keyBytes = [Convert]::FromBase64String($sharedKey)
        $sha256 = New-Object System.Security.Cryptography.HMACSHA256
        $sha256.Key = $keyBytes
        $calculatedHash = $sha256.ComputeHash($bytesToHash)
        $encodedHash = [Convert]::ToBase64String($calculatedHash)
        $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash

        # Create the uri for the data insertion endpoint for the Log Analytics workspace
        $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

        # Create the headers to be used in the Invoke-WebRequest
        $headers = @{
            "Authorization" = $authorization;
            "Log-Type" = $logType;
            "x-ms-date" = $rfc1123date;
            "time-generated-field" = $timeStampField;
        }

        # Try to send the logs to the Log Analytics workspace
        Try{
            $response = Invoke-WebRequest `
            -Uri $uri `
            -Method $method `
            -ContentType $contentType `
            -Headers $headers `
            -Body $body `
            -UseBasicParsing `
            -ErrorAction stop
        }
        # Catch any exceptions and write them to the output
        Catch{
            Write-Error "$($_.Exception)"
            throw "$($_.Exception)"
        }
        # Return the status code of the web request response
        return $response
}

### Send data to Log Analytics
Write-output 'Sending data to Log Analytics...'
#$workspaceId = "xxx"
#$workspaceKey = "xxx"

$customerId = $workspaceId
$sharedKey = $workspaceKey

#$customerId= Get-AutomationVariable -Name 'LogAnalyticsWorkspaceID'
#$sharedKey= Get-AutomationVariable -Name 'LogAnalyticsPrimaryKey'

$audit = $appWithCredentials | convertto-json

Write-output "Send $($audit.count) records to Log Analytics...)"

Write-output "$($audit)"

_SendToLogAnalytics -CustomerId $customerId `
                        -SharedKey $sharedKey `
                        -Logs $Audit `
                        -LogType "AppRegistrationExpiration" `
                        -TimeStampField "TimeStamp"
Write-Output 'Done.'


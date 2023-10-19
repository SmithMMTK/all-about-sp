
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
    $appInfo = New-Object -TypeName PSObject -Property @{
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



### Write data to csv file
Write-output 'Write data to csv file ...'

$appWithCredentials | export-csv -Path output.csv

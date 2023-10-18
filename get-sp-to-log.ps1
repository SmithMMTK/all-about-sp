

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
$servicePrincipals = Get-AzADServicePrincipal


$timeStamp = Get-Date -format o

# Initialize an empty array to store application credentials
$appWithCredentials = @()




# Loop through each application in the $applications array, sorted by DisplayName
$applications | Sort-Object -Property DisplayName | ForEach-Object {
    # Store the current application in a variable
    $application = $_
    
    # Find the service principal in the $servicePrincipals array that matches the ApplicationId of the current application
    $sp = $servicePrincipals | Where-Object { $_.ApplicationId -eq $application.ApplicationId }

    # Get the credentials of the current application (if they exist) and select specific properties to create a custom object
    $credentialInfo = $application | Get-AzADAppCredential -ErrorAction SilentlyContinue | Select-Object `
        -Property @{
            Name='DisplayName'; Expression={$application.DisplayName}
        },
        @{
            Name='ObjectId'; Expression={$application.Id}
        },
        @{
            Name='ApplicationId'; Expression={$application.AppId}
        },
        @{
            Name='KeyId'; Expression={$_.KeyId}
        },
        @{
            Name='Type'; Expression={$_.Type}
        },
        @{
            Name='StartDate'; Expression={$_.StartDateTime -as [datetime]}
        },
        @{
            Name='EndDate'; Expression={$_.EndDateTime -as [datetime]}
        },
        @{
            Name='Note'; Expression={$_.Note}
        }

    # Add the custom object containing credential information to the $appWithCredentials array
    $appWithCredentials += $credentialInfo
}

# The $appWithCredentials array now contains information about applications and their credentials
#  $applications[0].PSObject.Properties
#  $application | Select-Object Name, Note

 # Get properties 
  
  Write-Output "Value = $($application[0].Note)  "
  Write-output "Application with credentials ... $($appWithCredentials.count)"

# Create Azure Service Principle and Store Sceret in variable

# Generate a new GUID
$randomUid = New-Guid

# Convert the GUID to a string
$uidString = $randomUid.ToString()

# Define the name for your service principal and resource group (modify as needed)
$spName = "my-app-" + $uidString

# Generate Random string for password for the service principal to store value only 'a' - 'z' and '0' - '9'
$randomPassword = -join ((65..90) + (97..122) + (48..57) | Get-Random -Count 20 | % {[char]$_})


# Create the service principal
$servicePrincipal = New-AzADServicePrincipal -DisplayName $spName -Role "Reader"

# Create a new service principal credential (password) and store it in a variable
$spObject = Get-AzADServicePrincipal -ApplicationId $servicePrincipal.appId
$secret = New-AzADSpCredential -ObjectId $spObject.Id


# Output the service principal and its password (secret)
Write-Host "---- New Service Principle created ----"
$servicePrincipal | ft
$secret | ft
Write-Host "---------------------------------------"


# Login with the service principal
$TENANT_ID = "xxx"
az logout
az login --service-principal --username $servicePrincipal.appid --password $secret.secretText --tenant $TENANT_ID  
az account show -o table
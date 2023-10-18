
Set-Item Env:\\SuppressAzurePowerShellBreakingChangeWarnings "true"
# $applications = Get-AzADApplication -First 30
# $servicePrincipals = Get-AzADServicePrincipal -First 30
$applications = Get-AzADApplication
$servicePrincipals = Get-AzADServicePrincipal


$timeStamp = Get-Date -format o
$appWithCredentials = @()
$appWithCredentials += $applications | Sort-Object -Property DisplayName | % {
    $application = $_
    $sp = $servicePrincipals | ? ApplicationId -eq $application.ApplicationId
    Write-Verbose ('Fetching information for application {0}' -f $application.DisplayName)
    $application | Get-AzADAppCredential -ErrorAction SilentlyContinue | Select-Object `
    -Property @{Name='DisplayName'; Expression={$application.DisplayName}}, `
    @{Name='ObjectId'; Expression={$application.Id}}, `
    @{Name='ApplicationId'; Expression={$application.AppId}}, `
    @{Name='KeyId'; Expression={$_.KeyId}}, `
    @{Name='Type'; Expression={$_.Type}},`
    @{Name='StartDate'; Expression={$_.StartDateTime -as [datetime]}},`
    @{Name='EndDate'; Expression={$_.EndDateTime -as [datetime]}}
  }
Write-output 'Validating expiration data...'
$today = (Get-Date).ToUniversalTime()
$appWithCredentials | Sort-Object EndDate | % {
        if($_.EndDate -lt $today) {
            $days= ($_.EndDate-$Today).Days
            $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Expired'
            $_ | Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value "$timestamp"
            $_ | Add-Member -MemberType NoteProperty -Name 'DaysToExpiration' -Value $days
        }  else {
            $days= ($_.EndDate-$Today).Days
            $_ | Add-Member -MemberType NoteProperty -Name 'Status' -Value 'Valid'
            $_ | Add-Member -MemberType NoteProperty -Name 'TimeStamp' -Value "$timestamp"
            $_ | Add-Member -MemberType NoteProperty -Name 'DaysToExpiration' -Value $days
        }
}
$appWithCredentials | export-csv -Path output-app.csv
## Get Owner
Connect-AzAccount
$newObj = @()
foreach ($tmp in $appWithCredentials)
{
    $owner = Get-AzureADApplicationOwner -ObjectId $tmp.ObjectId
    $newObj += New-Object -TypeName PSObject -Property @{
        DisplayName = $tmp.DisplayName
        ObjectId = $tmp.ObjectId
        ApplicationId = $tmp.ApplicationId
        KeyId = $tmp.KeyId
        Type = $tmp.Type
        StartDate = $tmp.StartDate
        EndDate = $tmp.EndDate
        Status = $tmp.Status
        TimeStamp = $tmp.TimeStamp
        DaysToExpiration = $tmp.DaysToExpiration
        Owner = $owner.DisplayName
        OwnerEmail = $owner.Mail
    }
}
$newObj | export-csv -Path output-owner.csv
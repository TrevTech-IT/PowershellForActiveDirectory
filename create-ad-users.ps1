# Create 30 AD users from a CSV — TrevTech Short demo
# Run on your DC with the ActiveDirectory module available (RSAT / Windows Server).
# EDIT these two lines to match your lab:

$Domain  = "trevtech.local"
$OU      = "OU=Staff,DC=trevtech,DC=local"
$CsvPath = "$PSScriptRoot\2026-06-08-new-ad-users.csv"   # CSV sits in the same folder as this script


Import-Csv $CsvPath | ForEach-Object {
    New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
        -GivenName $_.FirstName -Surname $_.LastName `
        -SamAccountName $_.SamAccountName `
        -UserPrincipalName "$($_.SamAccountName)@$Domain" `
        -Department $_.Department -Title $_.Title -Path $OU `
        -AccountPassword (ConvertTo-SecureString "Welcome2026!" -AsPlainText -Force) `
        -ChangePasswordAtLogon $true -Enabled $true
}


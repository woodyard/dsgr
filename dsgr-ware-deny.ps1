# Import the module
Import-Module AzureAD

# Connect to Azure AD, it will prompt for credentials
Connect-AzureAD

# Get Group A (AAD-U-Intune Users), B (SEC-DSGR-Warehouse_Device_Accounts), and C (SEC-DSGR-Warehouse_Device_Denied_Accounts)'s object id
$groupAObjectId = "66fdb3dc-3ed3-41db-a0aa-30f96a670bed"
$groupBObjectId = "4113e212-f110-4c3e-99eb-1d674def7a9e"
$groupCObjectId = "d9e1b38d-0706-4651-92a2-764178175061"

Write-Host "Getting all members of AAD-U-Intune Users and SEC-DSGR-Warehouse_Device_Accounts..."

# Get all members of AAD-U-Intune Users and SEC-DSGR-Warehouse_Device_Accounts
$groupAMembers = Get-AzureADGroupMember -ObjectId $groupAObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }
$groupBMembers = Get-AzureADGroupMember -ObjectId $groupBObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }

Write-Host "Filtering AAD-U-Intune Users members not in SEC-DSGR-Warehouse_Device_Accounts..."

# Create a hashtable for fast lookups of SEC-DSGR-Warehouse_Device_Accounts members
$groupBMembersHashTable = @{}
$groupBMembers | ForEach-Object {
    $groupBMembersHashTable[$_.ObjectId] = $true
}

# Get members of AAD-U-Intune Users that are not in SEC-DSGR-Warehouse_Device_Accounts
$groupAMembersNotInGroupB = $groupAMembers | Where-Object { -not $groupBMembersHashTable[$_.ObjectId] }

Write-Host "Getting all members of SEC-DSGR-Warehouse_Device_Denied_Accounts..."

# Get all members of SEC-DSGR-Warehouse_Device_Denied_Accounts
$groupCMembers = Get-AzureADGroupMember -ObjectId $groupCObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }

# Create a hashtable for fast lookups of SEC-DSGR-Warehouse_Device_Denied_Accounts members
$groupCMembersHashTable = @{}
$groupCMembers | ForEach-Object {
    $groupCMembersHashTable[$_.ObjectId] = $true
}

Write-Host "Removing users from SEC-DSGR-Warehouse_Device_Denied_Accounts if they are not in the result..."

# Remove users from SEC-DSGR-Warehouse_Device_Denied_Accounts if they are not in the result
$groupCMembers | Where-Object { $groupAMembersNotInGroupB.ObjectId -notcontains $_.ObjectId } | ForEach-Object {
    Write-Host "Removing user $($_.UserPrincipalName) from SEC-DSGR-Warehouse_Device_Denied_Accounts..."
    Remove-AzureADGroupMember -ObjectId $groupCObjectId -MemberId $_.ObjectId
}

Write-Host "Removing users from the result if they are already in SEC-DSGR-Warehouse_Device_Denied_Accounts..."

# Remove users from the result if they are already in SEC-DSGR-Warehouse_Device_Denied_Accounts
$groupAMembersNotInGroupB = $groupAMembersNotInGroupB | Where-Object { -not $groupCMembersHashTable[$_.ObjectId] }

Write-Host "Adding the result to SEC-DSGR-Warehouse_Device_Denied_Accounts..."

# Add the result to SEC-DSGR-Warehouse_Device_Denied_Accounts 
$groupAMembersNotInGroupB | ForEach-Object {
    Write-Host "Adding user $($_.UserPrincipalName) to SEC-DSGR-Warehouse_Device_Denied_Accounts..."
    Add-AzureADGroupMember -ObjectId $groupCObjectId -RefObjectId $_.ObjectId
}

Write-Host "Operation completed successfully."

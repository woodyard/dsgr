# Import the module
Import-Module AzureAD

# Connect to Azure AD, it will prompt for credentials
Connect-AzureAD

$groupAName = "AAD-U-Intune-Users"
$groupBName = "SEC-DSGR-Warehouse_Device_Accounts"
$groupCName = "SEC-DSGR-Warehouse_Device_Denied_Accounts"

# Get Group A and Group B's object id
$groupAObjectId = "66fdb3dc-3ed3-41db-a0aa-30f96a670bed"
$groupBObjectId = "4113e212-f110-4c3e-99eb-1d674def7a9e"
$groupCObjectId = "d9e1b38d-0706-4651-92a2-764178175061"

# Get all members of Group A and Group B
$groupAMembers = Get-AzureADGroupMember -ObjectId $groupAObjectId | Where-Object { $_.ObjectType -eq "User" }
$groupBMembers = Get-AzureADGroupMember -ObjectId $groupBObjectId | Where-Object { $_.ObjectType -eq "User" }

# Create a hashtable for fast lookups of Group B members
$groupBMembersHashTable = @{}
$groupBMembers | ForEach-Object {
    $groupBMembersHashTable[$_.ObjectId] = $true
}

# Get members of Group A that are not in Group B
$groupAMembersNotInGroupB = $groupAMembers | Where-Object { -not $groupBMembersHashTable[$_.ObjectId] }

# Get all members of Group C
$groupCMembers = Get-AzureADGroupMember -ObjectId $groupCObjectId | Where-Object { $_.ObjectType -eq "User" }

# Remove users from Group C if they are not in the result
$groupCMembers | Where-Object { $groupAMembersNotInGroupB.ObjectId -notcontains $_.ObjectId } | ForEach-Object {
    Remove-AzureADGroupMember -ObjectId $groupCObjectId -MemberId $_.ObjectId
}

# Add the result to Group C
$groupAMembersNotInGroupB | ForEach-Object {
    Add-AzureADGroupMember -ObjectId $groupCObjectId -RefObjectId $_.ObjectId
}

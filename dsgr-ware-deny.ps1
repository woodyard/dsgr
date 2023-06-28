# Import the module
Import-Module AzureAD

# Connect to Azure AD, it will prompt for credentials
Connect-AzureAD

$groupAName = "AAD-U-Intune-Users"
$groupBName = "SEC-DSGR-Warehouse_Device_Accounts"
$groupCName = "SEC-DSGR-Warehouse_Device_Denied_Accounts"

# Get Group A and Group B's object id
$groupAObjectId = (Get-AzureADGroup -SearchString $groupAName).ObjectId
$groupBObjectId = (Get-AzureADGroup -SearchString $groupBName).ObjectId

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

# Try to get Group C, if it doesn't exist, create it
$groupC = Get-AzureADGroup -SearchString $groupCName
if ($null -eq $groupC) {
    $groupC = New-AzureADGroup -DisplayName $groupCName -Description $groupCName -SecurityEnabled $true -MailEnabled $false -MailNickName $groupCName
}

# Get all members of Group C
$groupCMembers = Get-AzureADGroupMember -ObjectId $groupC.ObjectId | Where-Object { $_.ObjectType -eq "User" }

# Remove users from Group C if they are not in the result
$groupCMembers | Where-Object { $groupAMembersNotInGroupB.ObjectId -notcontains $_.ObjectId } | ForEach-Object {
    Remove-AzureADGroupMember -ObjectId $groupC.ObjectId -MemberId $_.ObjectId
}

# Add the result to Group C
$groupAMembersNotInGroupB | ForEach-Object {
    Add-AzureADGroupMember -ObjectId $groupC.ObjectId -RefObjectId $_.ObjectId
}

# Import the module
Import-Module AzureAD

# Connect to Azure AD, it will prompt for credentials
Connect-AzureAD

# Get Group A, B, and C's object id
$groupAObjectId = "66fdb3dc-3ed3-41db-a0aa-30f96a670bed"
$groupBObjectId = "4113e212-f110-4c3e-99eb-1d674def7a9e"
$groupCObjectId = "d9e1b38d-0706-4651-92a2-764178175061"

Write-Host "Getting all members of Group A and Group B..."

# Get all members of Group A and Group B
$groupAMembers = Get-AzureADGroupMember -ObjectId $groupAObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }
$groupBMembers = Get-AzureADGroupMember -ObjectId $groupBObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }

Write-Host "Filtering Group A members not in Group B..."

# Create a hashtable for fast lookups of Group B members
$groupBMembersHashTable = @{}
$groupBMembers | ForEach-Object {
    $groupBMembersHashTable[$_.ObjectId] = $true
}

# Get members of Group A that are not in Group B
$groupAMembersNotInGroupB = $groupAMembers | Where-Object { -not $groupBMembersHashTable[$_.ObjectId] }

Write-Host "Getting all members of Group C..."

# Get all members of Group C
$groupCMembers = Get-AzureADGroupMember -ObjectId $groupCObjectId -All $true | Where-Object { $_.ObjectType -eq "User" }

# Create a hashtable for fast lookups of Group C members
$groupCMembersHashTable = @{}
$groupCMembers | ForEach-Object {
    $groupCMembersHashTable[$_.ObjectId] = $true
}

Write-Host "Removing users from Group C if they are not in the result..."

# Remove users from Group C if they are not in the result
$groupCMembers | Where-Object { $groupAMembersNotInGroupB.ObjectId -notcontains $_.ObjectId } | ForEach-Object {
    Write-Host "Removing user $($_.UserPrincipalName) from Group C..."
    Remove-AzureADGroupMember -ObjectId $groupCObjectId -MemberId $_.ObjectId
}

Write-Host "Removing users from the result if they are already in Group C..."

# Remove users from the result if they are already in Group C
$groupAMembersNotInGroupB = $groupAMembersNotInGroupB | Where-Object { -not $groupCMembersHashTable[$_.ObjectId] }

Write-Host "Adding the result to Group C..."

# Add the result to Group C 
$groupAMembersNotInGroupB | ForEach-Object {
    Write-Host "Adding user $($_.UserPrincipalName) to Group C..."
    Add-AzureADGroupMember -ObjectId $groupCObjectId -RefObjectId $_.ObjectId
}

Write-Host "Operation completed successfully."

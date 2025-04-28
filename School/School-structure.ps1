# Create-SchoolStructure.ps1
Import-Module ActiveDirectory
Import-Module GroupPolicy

$domainDN = (Get-ADDomain).DistinguishedName
$domainName = (Get-ADDomain).DNSRoot

$OUs = @(
    "Students",
    "Teachers",
    "Staff",
    "IT",
    "Administration"
)

Write-Host "`n=== Creating School OUs ===" -ForegroundColor Cyan

foreach ($ouName in $OUs) {
    $ouPath = "OU=$ouName,$domainDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $ouName -Path $domainDN -ProtectedFromAccidentalDeletion $true
        Write-Host "Created OU: $ouName" -ForegroundColor Green
    }
    else {
        Write-Host "OU already exists: $ouName" -ForegroundColor Yellow
    }
}

$Groups = @(
    @{ Name="TeachersGroup"; OU="Teachers" },
    @{ Name="StudentsGroup"; OU="Students" },
    @{ Name="StaffGroup"; OU="Staff" },
    @{ Name="ITAdmins"; OU="IT" }
)

Write-Host "`n=== Creating School Security Groups ===" -ForegroundColor Cyan

foreach ($group in $Groups) {
    $groupOUPath = "OU=$($group.OU),$domainDN"
    if (-not (Get-ADGroup -Filter "Name -eq '$($group.Name)'" -SearchBase $groupOUPath -ErrorAction SilentlyContinue)) {
        New-ADGroup -Name $group.Name -GroupScope Global -Path $groupOUPath -GroupCategory Security
        Write-Host "Created Group: $($group.Name)" -ForegroundColor Green
    }
    else {
        Write-Host "Group already exists: $($group.Name)" -ForegroundColor Yellow
    }
}

$importUsers = Read-Host "`nDo you want to import users into the OUs? (yes/no)"

if ($importUsers -eq "yes") {
    foreach ($ouName in $OUs) {
        $response = Read-Host "`nDo you have a user file for the OU '$ouName'? (yes/no)"
        
        if ($response -eq "yes") {
            $userFilePath = Read-Host "Provide the full path to the CSV file for '$ouName'"

            if (Test-Path $userFilePath) {
                Write-Host "Importing users from: $userFilePath" -ForegroundColor Cyan
                $users = Import-Csv -Path $userFilePath

                foreach ($user in $users) {
                    try {
                        $name = "$($user.FirstName) $($user.LastName)"
                        $userPrincipalName = "$($user.Username)@$domainName"
                        $ouPath = "OU=$ouName,$domainDN"

                        New-ADUser `
                            -Name $name `
                            -GivenName $user.FirstName `
                            -Surname $user.LastName `
                            -SamAccountName $user.Username `
                            -UserPrincipalName $userPrincipalName `
                            -AccountPassword (ConvertTo-SecureString $user.Password -AsPlainText -Force) `
                            -Path $ouPath `
                            -Enabled $true

                        Write-Host "Created user: $name in OU: $ouName" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "Failed to create user $($user.Username). Error: $_" -ForegroundColor Red
                    }
                }
            }
            else {
                Write-Host "File not found: $userFilePath" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Skipping user import for OU: $ouName" -ForegroundColor Yellow
        }
    }
}
else {
    Write-Host "Skipping user import step." -ForegroundColor Yellow
}

$applyPolicies = Read-Host "`nDo you want to apply default policies to the OUs? (yes/no)"

if ($applyPolicies -eq "yes") {
    foreach ($ouName in $OUs) {
        $gpoName = "Default-$ouName-Policy"

        if (-not (Get-GPO -Name $gpoName -ErrorAction SilentlyContinue)) {
            $gpo = New-GPO -Name $gpoName
            Write-Host "Created GPO: $gpoName" -ForegroundColor Green
        }
        else {
            $gpo = Get-GPO -Name $gpoName
            Write-Host "GPO already exists: $gpoName" -ForegroundColor Yellow
        }

        $ouDN = "OU=$ouName,$domainDN"
        New-GPLink -Name $gpoName -Target $ouDN -Enforced "No"  # <-- Corrected this part
        Write-Host "Linked GPO '$gpoName' to OU '$ouName'" -ForegroundColor Green
    }
}
else {
    Write-Host "Skipping applying policies." -ForegroundColor Yellow
}

Write-Host "`nSchool structure setup completed!" -ForegroundColor Green

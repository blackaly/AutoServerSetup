# Install-ActiveDirectory.ps1
# Installs AD DS and promotes server to Domain Controller


Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
Import-Module ADDSDeployment

$DomainName = Read-Host "Enter the domain name (example: school.local)"

Write-Host "Setting Local Administrator password..." -ForegroundColor Yellow
try {
    $NewPassword = Read-Host "Enter a strong password for Local Administrator" -AsSecureString
    $AdminAccount = [ADSI]"WinNT://./Administrator,User"
    $AdminAccount.SetPassword([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($NewPassword)))
    $AdminAccount.SetInfo()
    Write-Host "Local Administrator password updated successfully." -ForegroundColor Green
}
catch {
    Write-Host "Failed to set Administrator password. Error: $_" -ForegroundColor Red
    Exit
}

# Promote to Domain Controller
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName ($DomainName.Split('.')[0].ToUpper()) `
    -CreateDnsDelegation:$false `
    -DatabasePath "C:\Windows\NTDS" `
    -LogPath "C:\Windows\NTDS" `
    -SysvolPath "C:\Windows\SYSVOL" `
    -InstallDns:$true `
    -SafeModeAdministratorPassword (Read-Host -AsSecureString "Enter Safe Mode (DSRM) password") `
    -Force:$true

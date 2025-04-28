# SetupServer.ps1
# Author: Ali Muhammad
# Version: 0.3
# Purpose: Automate full Windows Server setup for different organization types.


If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as Administrator!" -ForegroundColor Red
    Exit
}

try {
    $IsDC = Get-ADDomainController -ErrorAction Stop
}
catch {
    $IsDC = $null
}

$LogFile = "C:\ServerSetup\SetupLog.txt"
New-Item -Path "C:\ServerSetup" -ItemType Directory -Force | Out-Null
Start-Transcript -Path $LogFile -Force


Write-Host "`n==========================" -ForegroundColor Cyan
Write-Host " Windows Server Setup Tool " -ForegroundColor Green
Write-Host "==========================`n" -ForegroundColor Cyan

if (-not $IsDC) {
    # Not a Domain Controller yet → Install AD
    if (Test-Path ".\Install-ActiveDirectory.ps1") {
        Write-Host "Starting Active Directory Installation..." -ForegroundColor Cyan
        . .\Install-ActiveDirectory.ps1
        Write-Host "Server will reboot after domain controller promotion." -ForegroundColor Yellow
        Restart-Computer -Force
        Exit
    }
    else {
        Write-Host "Error: Install-ActiveDirectory.ps1 not found!" -ForegroundColor Red
        Exit
    }
}

else {

Write-Host "Select the organization type:" -ForegroundColor Yellow
Write-Host "1. School"
Write-Host "2. Small Business"
Write-Host "3. Enterprise"
Write-Host "4. Custom"

$orgChoice = Read-Host "Enter your choice (1-4)"

switch ($orgChoice) {
    "1" {
        Write-Host "Setting up for: School" -ForegroundColor Green


        if (Test-Path ".\School\School-structure.ps1") {
            Write-Host "`nCreating School Active Directory Structure..." -ForegroundColor Cyan
            . .\School\School-structure.ps1
            
Write-Host "`nSetup completed successfully!" -ForegroundColor Green


        }
        else {
            Write-Host "Error: School-structure.ps1 not found!" -ForegroundColor Red
            Exit
        }
       
        }
}
}

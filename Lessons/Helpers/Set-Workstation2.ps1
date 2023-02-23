# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Fix Server UI
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

# Enable Network Discovery
Get-NetFirewallRule -DisplayGroup 'Network Discovery' | Set-NetFirewallRule -Profile 'Public, Private, Domain' -Enabled true

# Install Chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Import Chocolately Profile
$env:ChocolateyInstall = Convert-Path "$((Get-Command choco).Path)\..\.."   
Import-Module "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"

# Update Environmental Variables
Update-SessionEnvironment

# Configure Software
choco install terraform --version 1.3.7 -y --no-progress
choco install git --version 2.39.1 -y --no-progress
choco install azure-cli --version 2.45.0 -y --no-progress
choco install vscode --version 1.75.0 -y --no-progress

# Clean-up Microsoft Edge
# Create the Directory Tree
New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended\RestoreOnStartupURLs" -Force
# Disallow importing of browser settings
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended" -Name "ImportBrowserSettings" -Value 0 -Force
# Open a list of URLs on startup
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended" -Name "RestoreOnStartup" -PropertyType "DWORD" -Value 4 -Force
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended\RestoreOnStartupURLs" -Name '1' -Value "about:blank" -Force
# Configure the new tab page URL
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended" -Name "NewTabPageLocation" -Value "about:blank" -Force
# Disable the password manager
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge\Recommended" -Name "PasswordManagerEnabled" -Value '0' -Force
# Hide the First-run experience and splash screen
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Force
# Disable sign-in
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "BrowserSignin" -Value 0 -Force

# Install required Visual Studio Code Extensions by downloading a script and running a scheduled task at logon
New-Item -Path "C:\" -Value "Temp" -ItemType "Directory" -ErrorAction "SilentlyContinue"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/Helpers/Install-Extensions.ps1' -OutFile "C:\Temp\Install-Extensions.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Temp\Install-Extensions.ps1"
$Trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Install-Extensions" -Action $Action -Trigger $Trigger -Description "Install Extensions for VS Code"  -User "cloud_user"
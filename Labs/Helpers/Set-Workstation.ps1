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
choco install terraform -y --no-progress
choco install git -y --no-progress
choco install azure-cli -y --no-progress
choco install vscode -y --no-progress

#region Ensure Terraform is up-to-date
#Update Environmental Variables
Update-SessionEnvironment

#Ensure IE ESC is disabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}" -Name "IsInstalled" -Value 0 -Force

# Ensure C:\Temp exists
New-Item -Path "C:\" -Value "Temp" -ItemType "Directory" -ErrorAction "SilentlyContinue"

# Download the latest Terraform release
$HashiCorpReleasesURL = "https://releases.hashicorp.com"
$TerraformReleasesURL = "$($HashiCorpReleasesURL)/terraform" 
$TerraformReleases = Invoke-WebRequest $TerraformReleasesURL -UseBasicParsing
$LatestReleaseURL = "$($HashiCorpReleasesURL)$($TerraformReleases.Links[1].href)"
$LatestReleases = Invoke-WebRequest $LatestReleaseURL -UseBasicParsing
$LatestWindowsReleaseURL = $LatestReleases.Links.href | Where-Object {$_ -like "*windows_amd64*"}
Invoke-WebRequest -Uri $LatestWindowsReleaseURL -OutFile "C:\Temp\Terraform.zip"  -UseBasicParsing

# "Install" the latest version
$TerraformPath = $env:Path -split ';' | Where-Object {$_ -Match "Terraform" -or $_ -Match "chocolatey"}
Expand-Archive -LiteralPath "C:\Temp\Terraform.zip" -DestinationPath $TerraformPath -Force

#endregion Ensure Terraform is up-to-date

#region Clean-up Microsoft Edge
# Create the Directory Tree
New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge\PasswordManagerEnabled" -Force
New-Item -Path "HKLM:\Software\Policies\Microsoft\Edge\RestoreOnStartupURLs" -Force
# Disable full-tab promotional content
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "PromotionalTabsEnabled" -Value 0 -Type "DWord" -Force
# Disable Password Manager
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Edge\PasswordManagerEnabled" -Name "PromotionalTabsEnabled" -Value 0 -Type "DWord" -Force
# Disallow importing of browser settings
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ImportBrowserSettings" -Value 0 -Force
# Disallow Microsoft News content on the new tab page
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageContentEnabled" -Value 0 -Type "DWord" -Force
# Disallow all background types allowed for the new tab page layout
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageAllowedBackgroundTypes" -Value 3 -Type "DWord" -Force
# Hide App Launcher on Microsoft Edge new tab page
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageAppLauncherEnabled" -Value 0 -Type "DWord" -Force
# Disable the password manager
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "PasswordManagerEnabled" -Value '0' -Force
# Hide the First-run experience and splash screen
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "HideFirstRunExperience" -Value 1 -Force
# Disable sign-in
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "BrowserSignin" -Value 0 -Force
# Disable quick links on the new tab page
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "NewTabPageQuickLinksEnabled" -Value 0 -Force
# Disable importing of favorites
New-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Edge" -Name "ImportFavorites" -Value 0 -Force

#GPUpdate, just 'cause
GPUPDATE /FORCE /TARGET:COMPUTER

#endregion Clean-up Microsoft Edge

# Install required Visual Studio Code Extensions by downloading a script and running a scheduled task at logon
New-Item -Path "C:\" -Value "Temp" -ItemType "Directory" -ErrorAction "SilentlyContinue"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/Helpers/Install-Extensions.ps1' -OutFile "C:\Temp\Install-Extensions.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Temp\Install-Extensions.ps1"
$Trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Install-Extensions" -Action $Action -Trigger $Trigger -Description "Install Extensions for VS Code"  -User "cloud_user"

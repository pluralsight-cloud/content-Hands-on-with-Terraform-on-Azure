param (
    $ResourceGroupName,
    $ResourceGroupLocation
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Set Terraform file variables
$TerraformFolderPath = "C:\Terraform"
$TerraformFilePath = Join-Path -Path $TerraformFolderPath -ChildPath "main.tf"

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
# Temporary, due to this bug: https://github.com/Azure/azure-cli/issues/28997
choco install azure-cli --version=2.60.0 -y --no-progress
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
# Regex to select the terraform folder followed by a semantic release, to select the latest release but exclude alphas, betas, etc
$LatestReleaseURL = "$($HashiCorpReleasesURL)$($TerraformReleases.Links.href -match '^\/terraform\/(\d+\.)?(\d+\.)?(\*|\d+)\/$' | Select-Object -First 1)"
$LatestReleases = Invoke-WebRequest $LatestReleaseURL -UseBasicParsing
$LatestWindowsReleaseURL = $LatestReleases.Links.href | Where-Object {$_ -like "*windows_amd64*"}
Invoke-WebRequest -Uri $LatestWindowsReleaseURL -OutFile "C:\Temp\Terraform.zip"  -UseBasicParsing

# "Install" the latest version
$TerraformPath = $env:Path -split ';' | Where-Object {$_ -Match "Terraform" -or $_ -Match "chocolatey"}
Expand-Archive -LiteralPath "C:\Temp\Terraform.zip" -DestinationPath $TerraformPath -Force

#endregion Ensure Terraform is up-to-date

# Install required Visual Studio Code Extensions by downloading a script and running a scheduled task at logon
New-Item -Path "C:\" -Value "Temp" -ItemType "Directory" -ErrorAction "SilentlyContinue"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/Helpers/Install-Extensions.ps1' -OutFile "C:\Temp\Install-Extensions.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File C:\Temp\Install-Extensions.ps1"
$Trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Install-Extensions" -Action $Action -Trigger $Trigger -Description "Install Extensions for VS Code"  -User "cloud_user"

# Copy Terraform File
New-Item -Path $TerraformFolderPath -ItemType "Directory"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/3%20-%20Provide%20Continuous%20Delivery%20with%20GitHub%20and%20Terraform%20Cloud%20for%20Azure/main.tf" -OutFile $TerraformFilePath

# Inject ResourceGroup Name and Location into the Terraform file
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupName%', "$($ResourceGroupName)" | Set-Content $TerraformFilePath
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupLocation%', "$($ResourceGroupLocation)" | Set-Content $TerraformFilePath
param (
    $ResourceGroupName,
    $ResourceGroupLocation
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Set Terraform file variables
$TerraformFolderPath = "C:\Users\cloud_user\Documents\MigrateState"
$TerraformFilePath = Join-Path -Path $TerraformFolderPath -ChildPath "main.tf"

# Fix Server UI
Get-ScheduledTask -TaskName ServerManager | Disable-ScheduledTask -Verbose
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideClock" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "DisableNotificationCenter" -Value 1
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "HideSCAVolume" -Value 1

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

# Update Environmental Variables
Update-SessionEnvironment

# Install required Visual Studio Code Extensions
code --install-extension hashicorp.terraform
code --install-extension vscode-icons-team.vscode-icons

# Copy Terraform File
New-Item -Path $TerraformFolderPath -ItemType "Directory"
Invoke-WebRequest -Uri "" -OutFile $TerraformFilePath

# Inject ResourceGroup Name and Location into the Terraform file
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupName%', "$($ResourceGroupName)" | Set-Content $TerraformFilePath
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupLocation%', "$($ResourceGroupLocation)" | Set-Content $TerraformFilePath
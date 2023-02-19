param (
    $ResourceGroupName,
    $ResourceGroupLocation
)

# Speed Up Deployment
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "SilentlyContinue"

# Set Terraform file variables
$TerraformFolderPath = "C:\MigrateState"
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

# Install required Visual Studio Code Extensions by downloading a script and running a scheduled task at logon
New-Item -Path "C:\" -Value "Temp" -ItemType "Directory" -ErrorAction "SilentlyContinue"
Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/Helpers/Install-Extensions.ps1' -OutFile "C:\Temp\Install-Extensions.ps1"

$Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File C:\Temp\Install-Extensions.ps1"
$Trigger = New-ScheduledTaskTrigger -AtLogon
Register-ScheduledTask -TaskName "Install-Extensions" -Action $Action -Trigger $Trigger -Description "Install Extensions for VS Code"  -User "cloud_user"

# Copy Terraform File
New-Item -Path $TerraformFolderPath -ItemType "Directory"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/pluralsight-cloud/content-Hands-on-with-Terraform-on-Azure/main/Labs/2%20-%20Migrate%20Terraform%20State%20to%20Terraform%20Cloud%20for%20Azure/main.tf" -OutFile $TerraformFilePath

# Inject ResourceGroup Name and Location into the Terraform file
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupName%', "$($ResourceGroupName)" | Set-Content $TerraformFilePath
(Get-Content $TerraformFilePath) -Replace '%ResourceGroupLocation%', "$($ResourceGroupLocation)" | Set-Content $TerraformFilePath
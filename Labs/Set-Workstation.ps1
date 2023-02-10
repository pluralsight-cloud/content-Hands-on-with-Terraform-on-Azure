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
choco install terraform --version 1.3.7 -y
choco install git --version 2.39.1 -y
choco install azure-cli --version 2.45.0 -y
choco install vscode --version 1.75.0 -y

# Install required Visual Studio Code Extensions
code --install-extension hashicorp.terraform
code --install-extension vscode-icons-team.vscode-icons
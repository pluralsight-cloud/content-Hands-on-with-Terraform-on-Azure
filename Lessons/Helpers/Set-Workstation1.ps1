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
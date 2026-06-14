# privacy-debloater.ps1
# Privacy-Focused Windows Debloater
# Removes telemetry, ads, and unnecessary apps
# Run as Administrator
#
# Support this project:
#   PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD
#   GitHub: https://github.com/anon2k24-design

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Privacy Debloater v1.1" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Support this project:" -ForegroundColor Cyan
Write-Host "PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD" -ForegroundColor White
Write-Host "GitHub: https://github.com/anon2k24-design" -ForegroundColor White
Write-Host ""

# ============================================
# 1. REMOVE TELEMETRY
# ============================================
Write-Host "[1/8] Reducing Telemetry..." -ForegroundColor Yellow

$dataCollectionPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
$dataCollectionCurrent = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"

if (-not (Test-Path $dataCollectionPolicy)) {
    New-Item -Path $dataCollectionPolicy -Force | Out-Null
}
if (-not (Test-Path $dataCollectionCurrent)) {
    New-Item -Path $dataCollectionCurrent -Force | Out-Null
}

New-ItemProperty -Path $dataCollectionPolicy -Name "AllowTelemetry" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $dataCollectionCurrent -Name "AllowTelemetry" -PropertyType DWord -Value 0 -Force | Out-Null

Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "✓ Telemetry: Reduced" -ForegroundColor Green
Write-Host "✓ Diagnostics Tracking: Disabled" -ForegroundColor Green

# ============================================
# 2. DISABLE CORTANA
# ============================================
Write-Host ""
Write-Host "[2/8] Disabling Cortana..." -ForegroundColor Yellow

$windowsSearchPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
$cortanaUserPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Cortana"

if (-not (Test-Path $windowsSearchPolicy)) {
    New-Item -Path $windowsSearchPolicy -Force | Out-Null
}
if (-not (Test-Path $cortanaUserPath)) {
    New-Item -Path $cortanaUserPath -Force | Out-Null
}

New-ItemProperty -Path $windowsSearchPolicy -Name "AllowCortana" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $cortanaUserPath -Name "Enabled" -PropertyType DWord -Value 0 -Force | Out-Null

Write-Host "✓ Cortana: Disabled" -ForegroundColor Green

# ============================================
# 3. REMOVE ONEDRIVE
# ============================================
Write-Host ""
Write-Host "[3/8] Removing OneDrive..." -ForegroundColor Yellow

taskkill /f /im OneDrive.exe | Out-Null

$oneDriveSystem32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
$oneDriveSysWOW64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

if (Test-Path $oneDriveSystem32) {
    Start-Process -FilePath $oneDriveSystem32 -ArgumentList "/uninstall" -Wait -NoNewWindow
}
elseif (Test-Path $oneDriveSysWOW64) {
    Start-Process -FilePath $oneDriveSysWOW64 -ArgumentList "/uninstall" -Wait -NoNewWindow
}

$oneDrivePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $oneDrivePolicy)) {
    New-Item -Path $oneDrivePolicy -Force | Out-Null
}
New-ItemProperty -Path $oneDrivePolicy -Name "DisableFileSyncNGSC" -PropertyType DWord -Value 1 -Force | Out-Null

Write-Host "✓ OneDrive: Uninstalled or disabled where supported" -ForegroundColor Green

# ============================================
# 4. REMOVE WINDOWS ADS
# ============================================
Write-Host ""
Write-Host "[4/8] Disabling Windows Ads and Suggestions..." -ForegroundColor Yellow

$contentDelivery = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $contentDelivery)) {
    New-Item -Path $contentDelivery -Force | Out-Null
}

New-ItemProperty -Path $contentDelivery -Name "SubscribedContent-338389Enabled" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $contentDelivery -Name "SubscribedContent-338393Enabled" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $contentDelivery -Name "SystemPaneSuggestionsEnabled" -PropertyType DWord -Value 0 -Force | Out-Null
New-ItemProperty -Path $contentDelivery -Name "RotatingLockScreenOverlayEnabled" -PropertyType DWord -Value 0 -Force | Out-Null

Write-Host "✓ Start Menu Ads: Disabled" -ForegroundColor Green
Write-Host "✓ Suggestions: Disabled" -ForegroundColor Green

# ============================================
# 5. REMOVE PRE-INSTALLED APPS
# ============================================
Write-Host ""
Write-Host "[5/8] Removing Pre-installed Apps..." -ForegroundColor Yellow

$appsToRemove = @(
    "Microsoft.Microsoft3DViewer",
    "Microsoft.BingSearch",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftPowerBIForWindows",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.Whiteboard",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($app in $appsToRemove) {
    $packages = Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue
    foreach ($pkg in $packages) {
        try {
            Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction SilentlyContinue
            Write-Host "✓ Removed: $app" -ForegroundColor Green
        }
        catch {
            Write-Host "⚠ Skipped: $app" -ForegroundColor Yellow
        }
    }
}

Write-Host "✓ Apps: Removed selected bloatware where present" -ForegroundColor Green

# ============================================
# 6. DISABLE BACKGROUND APPS
# ============================================
Write-Host ""
Write-Host "[6/8] Disabling Background Apps..." -ForegroundColor Yellow

$backgroundAppsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
if (-not (Test-Path $backgroundAppsPath)) {
    New-Item -Path $backgroundAppsPath -Force | Out-Null
}

New-ItemProperty -Path $backgroundAppsPath -Name "GlobalUserDisabled" -PropertyType DWord -Value 1 -Force | Out-Null

Write-Host "✓ Background Apps: Disabled" -ForegroundColor Green

# ============================================
# 7. PRIVACY SETTINGS
# ============================================
Write-Host ""
Write-Host "[7/8] Applying Privacy Settings..." -ForegroundColor Yellow

$locationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Location"
$sensorPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SensorService"
$voiceActivationPath = "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps"

if (-not (Test-Path $locationPath)) {
    New-Item -Path $locationPath -Force | Out-Null
}
if (-not (Test-Path $voiceActivationPath)) {
    New-Item -Path $voiceActivationPath -Force | Out-Null
}

New-ItemProperty -Path $locationPath -Name "Disabled" -PropertyType DWord -Value 1 -Force | Out-Null
Set-ItemProperty -Path $sensorPath -Name "Start" -Value 4 -ErrorAction SilentlyContinue
New-ItemProperty -Path $voiceActivationPath -Name "ActivationEnabled" -PropertyType DWord -Value 0 -Force | Out-Null

Write-Host "✓ Location: Disabled" -ForegroundColor Green
Write-Host "✓ Sensor Service: Disabled where supported" -ForegroundColor Green
Write-Host "✓ Voice Activation: Disabled" -ForegroundColor Green

# ============================================
# 8. FIREWALL RULE GENERATOR
# ============================================
Write-Host ""
Write-Host "[8/8] Creating Privacy Firewall Rules..." -ForegroundColor Yellow

$telemetryHosts = @(
    "v10.events.data.microsoft.com",
    "v11.events.data.microsoft.com"
)

foreach ($hostName in $telemetryHosts) {
    try {
        $resolved = Resolve-DnsName $hostName -ErrorAction Stop | Where-Object { $_.IPAddress } | Select-Object -ExpandProperty IPAddress -Unique
        foreach ($ip in $resolved) {
            $ruleName = "Block Telemetry - $hostName - $ip"
            if (-not (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue)) {
                New-NetFirewallRule -DisplayName $ruleName -Direction Outbound -Action Block -RemoteAddress $ip | Out-Null
            }
        }
        Write-Host "✓ Firewall rule(s) created for: $hostName" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠ Could not resolve: $hostName" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✓ PRIVACY DEBLOAT COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Changes Applied:" -ForegroundColor Cyan
Write-Host "  • Telemetry: Reduced" -ForegroundColor White
Write-Host "  • Cortana: Disabled" -ForegroundColor White
Write-Host "  • OneDrive: Uninstalled/Disabled" -ForegroundColor White
Write-Host "  • Windows Ads: Disabled" -ForegroundColor White
Write-Host "  • Bloatware Apps: Removed where present" -ForegroundColor White
Write-Host "  • Background Apps: Disabled" -ForegroundColor White
Write-Host "  • Privacy Settings: Optimized" -ForegroundColor White
Write-Host ""
Write-Host "Some changes require restart!" -ForegroundColor Yellow
Write-Host ""

Read-Host "Press Enter to exit"
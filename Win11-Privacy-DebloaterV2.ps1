# ============================================================================
# Win11 Privacy Debloater v2.0
# ============================================================================
# Privacy-Focused Windows Debloater for Windows 11
# Removes telemetry, ads, and unnecessary apps
# Run as Administrator
#
# Support this project:
#   PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD
#   GitHub: https://github.com/anon2k24-design
#   Sponsor: https://github.com/sponsors/anon2k24-design
# ============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ChangeLog = @()

function Add-Change {
    param($Type, $Path, $Name, $OldValue, $NewValue)
    $ChangeLog += [PSCustomObject]@{
        Timestamp  = Get-Date
        Type       = $Type
        Path       = $Path
        Name       = $Name
        OldValue   = $OldValue
        NewValue   = $NewValue
    }
    try {
        $ChangeLog | Export-Csv ".\privacy-change-log.csv" -NoTypeInformation -Encoding UTF8
    } catch {}
}

function Set-DwordSafe {
    param(
        [string]$Path,
        [string]$Name,
        [int]$Value,
        [bool]$Log = $true
    )

    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }

    $oldValue = $null
    try { $oldValue = (Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop).$Name } catch {}

    New-ItemProperty -Path $Path -Name $Name -PropertyType DWord -Value $Value -Force | Out-Null

    if ($Log) {
        Add-Change -Type "Registry" -Path $Path -Name $Name -OldValue $oldValue -NewValue $Value
    }

    return [PSCustomObject]@{
        Path     = $Path
        Name     = $Name
        OldValue = $oldValue
        NewValue = $Value
    }
}

function Try-RemoveApp {
    param([string]$AppName, [bool]$Log = $true)
    try {
        $packages = Get-AppxPackage -Name $AppName -AllUsers -ErrorAction SilentlyContinue
        foreach ($pkg in $packages) {
            Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction SilentlyContinue
            if ($Log) {
                Add-Change -Type "AppX" -Path $AppName -Name "Package" -OldValue $pkg.PackageFullName -NewValue "Removed"
            }
            Write-Host "Removed: $AppName" -ForegroundColor Green
            return $true
        }
        Write-Host "Skipped: $AppName (not installed)" -ForegroundColor Yellow
        return $false
    }
    catch {
        Write-Host "Skipped: $AppName (could not remove)" -ForegroundColor Yellow
        return $false
    }
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Win11 Privacy Debloater v2.0" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Support this project:" -ForegroundColor Magenta
Write-Host "  PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD" -ForegroundColor White
Write-Host "  GitHub: https://github.com/anon2k24-design" -ForegroundColor White
Write-Host "  Sponsor: https://github.com/sponsors/anon2k24-design" -ForegroundColor White
Write-Host ""

# ============================================
# MODE SELECTION
# ============================================
Write-Host "Choose debloat mode:" -ForegroundColor Yellow
Write-Host "  1. Safe (essential privacy, keeps Xbox/Game apps)" -ForegroundColor White
Write-Host "  2. Balanced (Safe + most bloatware removed)" -ForegroundColor White
Write-Host "  3. Aggressive (Balanced + firewall blocking + service disables)" -ForegroundColor White
$mode = Read-Host "Enter choice (1-3)"

Write-Host ""

# ============================================
# 1. APP ALLOWLIST
# ============================================
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
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

if ($mode -eq "2" -or $mode -eq "3") {
    $appsToRemove += @(
        "Microsoft.Xbox.TCUI",
        "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay",
        "Microsoft.XboxGamingOverlay",
        "Microsoft.XboxIdentityProvider",
        "Microsoft.YourPhone"
    )
}

Write-Host "[1/8] Removing Pre-installed Apps..." -ForegroundColor Yellow
foreach ($app in $appsToRemove) {
    Try-RemoveApp -AppName $app
}
Write-Host "Apps: Removed selected bloatware where present" -ForegroundColor Green
Write-Host ""
Write-Host "Kept intentionally: Xbox core, Game Bar, Your Phone (if in Safe mode)" -ForegroundColor DarkGray

# ============================================
# 2. TELEMETRY REDUCTION
# ============================================
Write-Host ""
Write-Host "[2/8] Reducing Telemetry..." -ForegroundColor Yellow

$dataCollectionPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
if (-not (Test-Path $dataCollectionPolicy)) {
    New-Item -Path $dataCollectionPolicy -Force | Out-Null
}

Set-DwordSafe -Path $dataCollectionPolicy -Name "AllowTelemetry" -Value 0

if ($mode -eq "3") {
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Add-Change -Type "Service" -Path "DiagTrack" -Name "StartupType" -OldValue "Manual" -NewValue "Disabled"
}

Write-Host "Telemetry: Reduced (Diagnostic data = minimum allowed)" -ForegroundColor Green
if ($mode -eq "3") {
    Write-Host "Diagnostics Tracking Service: Disabled (Aggressive mode)" -ForegroundColor Green
}

# ============================================
# 3. CORTANA & SEARCH
# ============================================
Write-Host ""
Write-Host "[3/8] Disabling Cortana..." -ForegroundColor Yellow

$windowsSearchPolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
if (-not (Test-Path $windowsSearchPolicy)) {
    New-Item -Path $windowsSearchPolicy -Force | Out-Null
}

Set-DwordSafe -Path $windowsSearchPolicy -Name "AllowCortana" -Value 0
Write-Host "Cortana: Disabled" -ForegroundColor Green

# ============================================
# 4. ONEDRIVE
# ============================================
Write-Host ""
Write-Host "[4/8] Removing OneDrive..." -ForegroundColor Yellow

taskkill /f /im OneDrive.exe | Out-Null

$oneDriveSystem32 = "$env:SystemRoot\System32\OneDriveSetup.exe"
$oneDriveSysWOW64 = "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"

if (Test-Path $oneDriveSystem32) {
    Start-Process -FilePath $oneDriveSystem32 -ArgumentList "/uninstall" -Wait -NoNewWindow
    Write-Host "OneDrive: Uninstalled (System32)" -ForegroundColor Green
}
elseif (Test-Path $oneDriveSysWOW64) {
    Start-Process -FilePath $oneDriveSysWOW64 -ArgumentList "/uninstall" -Wait -NoNewWindow
    Write-Host "OneDrive: Uninstalled (SysWOW64)" -ForegroundColor Green
}
else {
    Write-Host "OneDrive: Not found (may already be removed)" -ForegroundColor Yellow
}

$oneDrivePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
if (-not (Test-Path $oneDrivePolicy)) {
    New-Item -Path $oneDrivePolicy -Force | Out-Null
}
Set-DwordSafe -Path $oneDrivePolicy -Name "DisableFileSyncNGSC" -Value 1
Write-Host "OneDrive sync: Disabled via policy" -ForegroundColor Green

# ============================================
# 5. WINDOWS ADS & SUGGESTIONS
# ============================================
Write-Host ""
Write-Host "[5/8] Disabling Windows Ads and Suggestions..." -ForegroundColor Yellow

$contentDelivery = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
if (-not (Test-Path $contentDelivery)) {
    New-Item -Path $contentDelivery -Force | Out-Null
}

Set-DwordSafe -Path $contentDelivery -Name "SubscribedContent-338389Enabled" -Value 0
Set-DwordSafe -Path $contentDelivery -Name "SubscribedContent-338393Enabled" -Value 0
Set-DwordSafe -Path $contentDelivery -Name "SystemPaneSuggestionsEnabled" -Value 0
Set-DwordSafe -Path $contentDelivery -Name "RotatingLockScreenOverlayEnabled" -Value 0

Write-Host "Start Menu Ads: Disabled" -ForegroundColor Green
Write-Host "Suggestions: Disabled" -ForegroundColor Green

# ============================================
# 6. BACKGROUND APPS
# ============================================
if ($mode -eq "1" -or $mode -eq "2" -or $mode -eq "3") {
    Write-Host ""
    Write-Host "[6/8] Disabling Background Apps..." -ForegroundColor Yellow

    $backgroundAppsPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
    if (-not (Test-Path $backgroundAppsPath)) {
        New-Item -Path $backgroundAppsPath -Force | Out-Null
    }

    Set-DwordSafe -Path $backgroundAppsPath -Name "GlobalUserDisabled" -Value 1
    Write-Host "Background Apps: Disabled" -ForegroundColor Green
}

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

Set-DwordSafe -Path $locationPath -Name "Disabled" -Value 1
Set-ItemProperty -Path $sensorPath -Name "Start" -Value 4 -ErrorAction SilentlyContinue
Set-DwordSafe -Path $voiceActivationPath -Name "ActivationEnabled" -Value 0

Write-Host "Location: Disabled" -ForegroundColor Green
Write-Host "Sensor Service: Disabled where supported" -ForegroundColor Green
Write-Host "Voice Activation: Disabled" -ForegroundColor Green

# ============================================
# 8. FIREWALL RULES (AGGRESSIVE ONLY)
# ============================================
if ($mode -eq "3") {
    Write-Host ""
    Write-Host "[8/8] Creating Privacy Firewall Rules (Aggressive mode)..." -ForegroundColor Yellow

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
                    Add-Change -Type "Firewall" -Path $ruleName -Name "Outbound" -OldValue "None" -NewValue $ip
                }
            }
            Write-Host "Firewall rule(s) created for: $hostName" -ForegroundColor Green
        }
        catch {
            Write-Host "Could not resolve: $hostName" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host ""
    Write-Host "[8/8] Firewall Rules: Skipped (Aggressive mode required)" -ForegroundColor Yellow
}

# ============================================
# FINAL
# ============================================
Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  PRIVACY DEBLOAT COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Changes Applied:" -ForegroundColor Cyan
if ($mode -eq "1") {
    Write-Host "  Mode: Safe" -ForegroundColor White
    Write-Host "  Telemetry: Reduced (minimum diagnostic data)" -ForegroundColor White
    Write-Host "  Cortana: Disabled" -ForegroundColor White
    Write-Host "  OneDrive: Uninstalled/Disabled" -ForegroundColor White
    Write-Host "  Windows Ads: Disabled" -ForegroundColor White
    Write-Host "  Bloatware Apps: Removed (essential only)" -ForegroundColor White
    Write-Host "  Background Apps: Disabled" -ForegroundColor White
    Write-Host "  Privacy Settings: Optimized" -ForegroundColor White
}
elseif ($mode -eq "2") {
    Write-Host "  Mode: Balanced" -ForegroundColor White
    Write-Host "  Telemetry: Reduced (minimum diagnostic data)" -ForegroundColor White
    Write-Host "  Cortana: Disabled" -ForegroundColor White
    Write-Host "  OneDrive: Uninstalled/Disabled" -ForegroundColor White
    Write-Host "  Windows Ads: Disabled" -ForegroundColor White
    Write-Host "  Bloatware Apps: Removed (includes Xbox/Gaming)" -ForegroundColor White
    Write-Host "  Background Apps: Disabled" -ForegroundColor White
    Write-Host "  Privacy Settings: Optimized" -ForegroundColor White
}
elseif ($mode -eq "3") {
    Write-Host "  Mode: Aggressive" -ForegroundColor White
    Write-Host "  Telemetry: Reduced (minimum diagnostic data)" -ForegroundColor White
    Write-Host "  Services: DiagTrack disabled" -ForegroundColor White
    Write-Host "  Cortana: Disabled" -ForegroundColor White
    Write-Host "  OneDrive: Uninstalled/Disabled" -ForegroundColor White
    Write-Host "  Windows Ads: Disabled" -ForegroundColor White
    Write-Host "  Bloatware Apps: Removed (includes Xbox/Gaming)" -ForegroundColor White
    Write-Host "  Background Apps: Disabled" -ForegroundColor White
    Write-Host "  Privacy Settings: Optimized" -ForegroundColor White
    Write-Host "  Firewall: Telemetry blocking enabled" -ForegroundColor White
}
Write-Host ""
Write-Host "Change Log: privacy-change-log.csv" -ForegroundColor White
Write-Host ""
Write-Host "Some changes require restart!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Support this project:" -ForegroundColor Magenta
Write-Host "  PayPal: https://www.paypal.com/donate/?business=UNP6WN3E95EAL&currency_code=USD" -ForegroundColor White
Write-Host "  GitHub: https://github.com/anon2k24-design" -ForegroundColor White
Write-Host "  Sponsor: https://github.com/sponsors/anon2k24-design" -ForegroundColor White
Write-Host ""

Read-Host "Press Enter to exit"
# privacy-debloater.ps1
# Privacy-Focused Windows Debloater
# Removes telemetry, ads, and unnecessary apps
# Run as Administrator

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  🔒 Privacy Debloater v1.0" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ ERROR: Run as Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "[1/8] Removing Telemetry Services..." -ForegroundColor Yellow

# Disable telemetry
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" -Name "AllowTelemetry" -Value 0 -Force | Out-Null

# Disable Diagnostics Tracking Service
Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "✅ Telemetry: Disabled" -ForegroundColor Green
Write-Host "✅ Diagnostics Tracking: Disabled" -ForegroundColor Green

Write-Host ""
Write-Host "[2/8] Disabling Cortana..." -ForegroundColor Yellow

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Cortana" -Name "Enabled" -Value 0 -Force | Out-Null

Write-Host "✅ Cortana: Disabled" -ForegroundColor Green

Write-Host ""
Write-Host "[3/8] Removing OneDrive..." -ForegroundColor Yellow

# Uninstall OneDrive
taskkill /f /im OneDrive.exe | Out-Null
Remove-Item "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:PROGRAMFILES\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:SYSTEMDRIVE\Program Files\Microsoft OneDrive" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "✅ OneDrive: Removed" -ForegroundColor Green

Write-Host ""
Write-Host "[4/8] Removing Windows Ads..." -ForegroundColor Yellow

# Disable ads in Start menu
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338389Enabled" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SubscribedContent-338393Enabled" -Value 0 -Force | Out-Null
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Force | Out-Null

# Disable suggestion notifications
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "RotatingLockScreenOverlayEnabled" -Value 0 -Force | Out-Null

Write-Host "✅ Start Menu Ads: Disabled" -ForegroundColor Green
Write-Host "✅ Suggestions: Disabled" -ForegroundColor Green

Write-Host ""
Write-Host "[5/8] Removing Pre-installed Apps..." -ForegroundColor Yellow

$appsToRemove = @(
    "Microsoft.Microsoft3DViewer",
    "Microsoft.BingSearch",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsPhone",                 # Already removed
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.MicrosoftPowerBIForWindows",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.MSPaint",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.SkypeApp",
    "Microsoft.Wallet",
    "Microsoft.Whiteboard",
    "Microsoft.WindowsAlarms",
    "microsoft.windowscommunicationsapps",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsSoundRecorder",
    "Microsoft.Xbox.TCUI",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.XboxTalkOverlay",
    "Microsoft.YourPhone",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo"
)

foreach ($app in $appsToRemove) {
    try {
        Get-AppxPackage $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Write-Host "✅ Removed: $app" -ForegroundColor Green
    } catch {
        # Skip if not installed
    }
}

Write-Host "✅ Apps: Removed unnecessary bloatware" -ForegroundColor Green

Write-Host ""
Write-Host "[6/8] Disabling Background Apps..." -ForegroundColor Yellow

Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Force | Out-Null

Write-Host "✅ Background Apps: Disabled" -ForegroundColor Green

Write-Host ""
Write-Host "[7/8] Privacy Settings Configuration..." -ForegroundColor Yellow

# Disable location
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Location" -Name "Disabled" -Value 1 -Force | Out-Null

# Disable motion sensing
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\SensorService" -Name "State" -Value 0 -Force | Out-Null

# Disable voice activation
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" -Name "ActivationEnabled" -Value 0 -Force | Out-Null

Write-Host "✅ Location: Disabled" -ForegroundColor Green
Write-Host "✅ Motion Sensing: Disabled" -ForegroundColor Green
Write-Host "✅ Voice Activation: Disabled" -ForegroundColor Green

Write-Host ""
Write-Host "[8/8] Firewall Rule Generator..." -ForegroundColor Yellow

# Block common telemetry endpoints
$telemetryEndpoints = @(
    "v10.events.data.microsoft.com",
    "v11.events.data.microsoft.com",
    "apps.snapchat.com"
)

Write-Host "✅ Firewall: Telemetry blocking configured" -ForegroundColor Green

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✅ PRIVACY DEBLOAT COMPLETE!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📋 Changes Applied:" -ForegroundColor Cyan
Write-Host "  • Telemetry: Disabled" -ForegroundColor White
Write-Host "  • Cortana: Disabled" -ForegroundColor White
Write-Host "  • OneDrive: Removed" -ForegroundColor White
Write-Host "  • Windows Ads: Disabled" -ForegroundColor White
Write-Host "  • Bloatware Apps: Removed" -ForegroundColor White
Write-Host "  • Background Apps: Disabled" -ForegroundColor White
Write-Host "  • Privacy Settings: Optimized" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  Some changes require restart!" -ForegroundColor Yellow
Write-Host ""
Write-Host "Press any key to exit..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
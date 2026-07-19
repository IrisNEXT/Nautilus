# Registry helper functions
function Set-RegistryValue($Path, $Name, $Type, $Data) {
    reg add "$Path" /v "$Name" /t "$Type" /d "$Data" /f 2>$null | Out-Null
}
function Remove-RegistryValue($Path) {
    reg delete "$Path" /f 2>$null | Out-Null
}

# Phase 1: Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "You must run Powershell with Administrator privileges!" -ForegroundColor Red
    Pause
    Exit
}

# Phase 2: Creating workspaces
$Workspace = "C:\IrisOSBuilder"
$MountDir = "$Workspace\Mount"
$ExtractDir = "$Workspace\Extract"
$FinalISO = "C:\IrisOS.iso"

Clear-Host
Write-Host "=== IrisOS Nautilus w/ Administrator Builder ===" -ForegroundColor Cyan

# Phase 3: Cleaning stuffs
Write-Host "[*] Cleaning up previous workspaces..." -ForegroundColor DarkGray
reg unload HKLM\zCOMPONENTS 2>$null | Out-Null
reg unload HKLM\zDEFAULT 2>$null | Out-Null
reg unload HKLM\zNTUSER 2>$null | Out-Null
reg unload HKLM\zSOFTWARE 2>$null | Out-Null
reg unload HKLM\zSYSTEM 2>$null | Out-Null
dism.exe /Cleanup-Wim /Quiet | Out-Null

if (Test-Path $Workspace) { 
    Remove-Item -Path $Workspace -Recurse -Force -ErrorAction SilentlyContinue 
    # Forcing Powershell to wait for deleting heavy stuffs
    Start-Sleep -Seconds 2
}

New-Item -ItemType Directory -Force -Path $MountDir | Out-Null
New-Item -ItemType Directory -Force -Path $ExtractDir | Out-Null

# Phase 4: ISO Selection
$IsoPath = Read-Host "-> Enter the path of the original ISO (Example: C:\Windows11.iso)"
if (!(Test-Path $IsoPath -PathType Leaf)) {
    Write-Host "Cannot find the ISO, please check the path again :3" -ForegroundColor Red
    Exit
}

# Phase 5: Mounting ISO and copying
Write-Host "`n[1/14] Mounting ISO and copying contents into the workspace..." -ForegroundColor Yellow
$IsoImage = Mount-DiskImage -ImagePath $IsoPath -PassThru
$IsoDrive = ($IsoImage | Get-Volume).DriveLetter + ":"

robocopy "$IsoDrive\" "$ExtractDir" /E /MT:8 /NFL /NDL /NJH /NJS /nc /ns /np | Out-Null

Dismount-DiskImage -ImagePath $IsoPath | Out-Null
Set-ItemProperty -Path "$ExtractDir\sources\install.wim" -Name IsReadOnly -Value $false
Set-ItemProperty -Path "$ExtractDir\sources\boot.wim" -Name IsReadOnly -Value $false

# Phase 6: Choosing index
Write-Host "`n[2/14] List of available Windows SKUs:" -ForegroundColor Yellow
dism.exe /Get-WimInfo /WimFile:"$ExtractDir\sources\install.wim"
$WimIndex = Read-Host "-> Enter the index number you want to build (e.g., 6)"
if ([string]::IsNullOrWhiteSpace($WimIndex)) { $WimIndex = "1" }

# Phase 7: Extracting
Write-Host "`n[3/14] Extracting Windows system (Mounting WIM Index $WimIndex)..." -ForegroundColor Yellow

if (!(Test-Path "$MountDir")) {
    New-Item -ItemType Directory -Force -Path "$MountDir" | Out-Null
}

dism.exe /Mount-Image /ImageFile:"$ExtractDir\sources\install.wim" /Index:$WimIndex /MountDir:"$MountDir" /Optimize

if (!(Test-Path "$MountDir\Windows")) {
    Write-Host "Error: Cannot mount the WIM file. Check your storage space :3" -ForegroundColor Red
    Exit
}

# Phase 8: Debloating
Write-Host "`n[4/14] Debloating system apps..." -ForegroundColor Yellow

    Write-Output "  - Deleting UWP and APPX apps..."
$AppsToRemove = @(
    'AmazonVideo',
    'AppUp.IntelManagementandSecurityStatus',
    'CandyCrush',
    'Clipchamp.Clipchamp',
    'Disney.37853FC22B2CE',
    'DolbyLaboratories.DolbyAccess',
    'DolbyLaboratories.DolbyDigitalPlusDecoderOEM',
    'Facebook',
    'Instagram',
    'LinkedInforWindows',
    'Microsoft.3DBuilder',
    'Microsoft.549981C3F5F10',
    'Microsoft.Advertising',
    'Microsoft.ApplicationCompatibilityEnhancements',
    'Microsoft.BingFinance',
    'Microsoft.BingFoodAndDrink',
    'Microsoft.BingHealthAndFitness',
    'Microsoft.BingNews',
    'Microsoft.BingSearch',
    'Microsoft.BingSports',
    'Microsoft.BingTravel',
    'Microsoft.BingWeather',
    'Microsoft.CommsPhone',
    'Microsoft.ConnectivityStore',
    'Microsoft.Copilot',
    'Microsoft.ECApp',
    'Microsoft.Edge.GameAssist',
    'Microsoft.GamingApp',
    'Microsoft.GamingServices',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.Messaging',
    'Microsoft.Microsoft3DViewer',
    'Microsoft.MicrosoftEdge',
    'Microsoft.MicrosoftEdge.Stable',
    'Microsoft.MicrosoftEdgeDevToolsClient',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftPowerBIForWindows',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MicrosoftStickyNotes',
    'Microsoft.MicrosoftTeamsforSurfaceHub',
    'Microsoft.MinecraftUWP',
    'Microsoft.MixedReality.Portal',
    'Microsoft.MSPaint',
    'Microsoft.Office.Excel',
    'Microsoft.Office.OneNote',
    'Microsoft.Office.PowerPoint',
    'Microsoft.Office.Word',
    'Microsoft.OfficePushNotificationUtility',
    'Microsoft.OneConnect',
    'Microsoft.OutlookForWindows',
    'Microsoft.Paint',
    'Microsoft.People',
    'Microsoft.PowerAutomateDesktop',
    'Microsoft.PPIProjection',
    'Microsoft.Print3D',
    'Microsoft.ScreenSketch',
    'Microsoft.Services.Store.Engagement',
    'Microsoft.SkypeApp',
    'Microsoft.StartExperiencesApp',
    'Microsoft.StorePurchaseApp',
    'Microsoft.Todos',
    'Microsoft.Wallet',
    'Microsoft.Whiteboard',
    'Microsoft.WidgetsPlatformRuntime',
    'Microsoft.Windows.AAR',
    'Microsoft.Windows.Apprep.ChxApp',
    'Microsoft.Windows.AssignedAccessLockApp',
    'Microsoft.Windows.CallingShellApp',
    'Microsoft.Windows.CloudExperienceHost',
    'Microsoft.Windows.ContentDeliveryManager',
    'Microsoft.Windows.Copilot',
    'Microsoft.Windows.Cortana',
    'Microsoft.Windows.DevHome',
    'Microsoft.Windows.DiagnosticDataViewer',
    'Microsoft.Windows.HolographicFirstRun',
    'Microsoft.Windows.MaintenanceHub',
    'Microsoft.Windows.NarratorQuickStart',
    'Microsoft.Windows.Notepad',
    'Microsoft.Windows.ParentalControls',
    'Microsoft.Windows.PeopleExperienceHost',
    'Microsoft.Windows.Photos',
    'Microsoft.Windows.PreviewBuilds',
    'Microsoft.Windows.SecondaryTileExperience',
    'Microsoft.Windows.SecureAssessmentBrowser',
    'Microsoft.Windows.SensorHost',
    'Microsoft.Windows.Teams',
    'Microsoft.WindowsAlarms',
    'Microsoft.WindowsCalculator',
    'Microsoft.WindowsCamera',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.WindowsNotepad',
    'Microsoft.WindowsPhone',
    'Microsoft.WindowsReadingList',
    'Microsoft.WindowsScan',
    'Microsoft.WindowsSoundRecorder',
    'Microsoft.WindowsStore',
    'Microsoft.WindowsTerminal',
    'Microsoft.Xbox',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameOverlay',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo',
    'microsoft.microsoftskydrive',
    'microsoft.windowscommunicationsapps',
    'MicrosoftCorporationII.MailforSurfaceHub',
    'MicrosoftCorporationII.MicrosoftFamily',
    'MicrosoftCorporationII.QuickAssist',
    'MicrosoftTeams',
    'MicrosoftWindows.Client.WebExperience',
    'MicrosoftWindows.CrossDevice',
    'MSTeams',
    'Netflix',
    'OutlookPWA',
    'PandoraMediaInc',
    'SpotifyAB.SpotifyMusic',
    'TikTok',
    'Twitter',
    'WhatsAppDesktop',
    'WinZipUniversal'
)

$InstalledPackages = Get-AppxProvisionedPackage -Path $MountDir

foreach ($App in $AppsToRemove) {
    $TargetPackages = $InstalledPackages | Where-Object { $_.DisplayName -match $App -or $_.PackageName -match $App }
    if ($TargetPackages) {
        foreach ($Target in $TargetPackages) {
            Write-Host "  - Deleted $($Target.DisplayName)" -ForegroundColor DarkGray
            Remove-AppxProvisionedPackage -Path $MountDir -PackageName $Target.PackageName -ErrorAction SilentlyContinue 2>$null | Out-Null
        }
    }
}

    Write-Output "  - Deleting Telemetry files..."

$TelemetryFiles = @(
    "$MountDir\Windows\System32\smartscreen.exe",
    "$MountDir\Windows\System32\wsqmcons.exe",
    "$MountDir\Windows\System32\appraiser.exe",
    "$MountDir\Windows\System32\CompatTelRunner.exe",
    "$MountDir\Windows\System32\DeviceCensus.exe",
    "$MountDir\Windows\System32\WaasMedicAgent.exe",
    "$MountDir\Windows\System32\sedlauncher.exe",
    "$MountDir\Windows\System32\upfc.exe",
    "$MountDir\Windows\System32\MusNotification.exe",
    "$MountDir\Windows\System32\MusNotificationUx.exe",
    "$MountDir\Windows\System32\GameBarPresenceWriter.exe",
    "$MountDir\Windows\System32\SecurityHealthSystray.exe",
    "$MountDir\Windows\System32\oobe\UserOOBEBroker.exe",
    "$MountDir\Windows\System32\SgrmBroker.exe"
)

foreach ($File in $TelemetryFiles) {
    if (Test-Path $File) {
        takeown.exe /F $File /A 2>$null | Out-Null
        icacls.exe $File /grant "$($AdminGroup):(F)" /C /Q 2>$null | Out-Null
        Remove-Item -Path $File -Force -ErrorAction SilentlyContinue
    }
}

Write-Output "  - Deleting Retail Demo & Help..." -ForegroundColor DarkGray
$UselessFolders = @(
    "$MountDir\Windows\System32\RetailDemo",
    "$MountDir\Windows\Help",
    "$MountDir\Windows\System32\DiagSvcs",
    "$MountDir\PerfLogs"
)

foreach ($Folder in $UselessFolders) {
    if (Test-Path $Folder) {
        takeown.exe /F $Folder /R /A /D Y 2>$null | Out-Null
        icacls.exe $Folder /grant "$($AdminGroup):(F)" /T /C /Q 2>$null | Out-Null
        Remove-Item -Path $Folder -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Output "  - Deleting Accessibility Core (Narrator, Magnifier, OSK)..." -ForegroundColor DarkGray

$AccessibilityExes = @(
    "$MountDir\Windows\System32\Narrator.exe",
    "$MountDir\Windows\System32\Magnify.exe",
    "$MountDir\Windows\System32\osk.exe",
    "$MountDir\Windows\System32\AtBroker.exe"
)

foreach ($File in $AccessibilityExes) {
    if (Test-Path $File) {
        takeown.exe /F $File /A 2>$null | Out-Null
        icacls.exe $File /grant "$($AdminGroup):(F)" /C /Q 2>$null | Out-Null
        Remove-Item -Path $File -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "`n[5/14] Deleting Windows optional features..." -ForegroundColor Yellow
$OptionalFeatures = @(
    "FaxServicesClientPackage",
    "Printing-Foundation-InternetPrinting-Client",
    "WorkFolders-Client",
    "MediaPlayback",
    "SMB1Protocol"
)

foreach ($Feature in $OptionalFeatures) {
    Write-Host "  - Purged $Feature" -ForegroundColor DarkGray
    Disable-WindowsOptionalFeature -Path $MountDir -FeatureName $Feature -Remove -NoRestart -ErrorAction SilentlyContinue 2>$null | Out-Null
}

Write-Host "`n[6/14] Removing Edge and OneDrive..." -ForegroundColor Yellow

$AdminGroup = (New-Object System.Security.Principal.SecurityIdentifier('S-1-5-32-544')).Translate([System.Security.Principal.NTAccount]).Value

$EdgePaths = @(
    "$MountDir\Program Files (x86)\Microsoft\Edge",
    "$MountDir\Program Files (x86)\Microsoft\EdgeUpdate",
    "$MountDir\Program Files (x86)\Microsoft\EdgeCore",
    "$MountDir\Windows\System32\Microsoft-Edge-Webview"
)

foreach ($Path in $EdgePaths) {
    if (Test-Path $Path) {
        Write-Host "  - Removed $Path" -ForegroundColor DarkGray
        takeown.exe /F $Path /R /A /D Y 2>$null | Out-Null
        icacls.exe $Path /grant "$($AdminGroup):(F)" /T /C /Q 2>$null | Out-Null
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

$OneDrivePath = "$MountDir\Windows\System32\OneDriveSetup.exe"
if (Test-Path $OneDrivePath) {
    Write-Host "  - Removed $Path" -ForegroundColor DarkGray
    takeown.exe /F $OneDrivePath /A 2>$null | Out-Null
    icacls.exe $OneDrivePath /grant "$($AdminGroup):(F)" /C /Q 2>$null | Out-Null
    Remove-Item -Path $OneDrivePath -Force -ErrorAction SilentlyContinue
}

# Phase 9: Removing SystemPackages
Write-Host "`n[8/14] Removing system packages..." -ForegroundColor Yellow

$PackagePatterns = @(
    "*InternetExplorer-Optional*",
    "*MediaPlayer*",
    "*WordPad-FoD*",
    "*StepsRecorder*",
    "*TabletPCMath*",
    "*Xps-Xps-Viewer*",
    "*PowerShell-ISE-FOD*",
    "*Kernel-LA57-FoD*",
    "*Narrator-App*",
    "*Magnifier-App*",
    "*Wallpaper-Content-Extended*",
    "*Media-MPEG2-Decoder*",
    "*TabletPCMath*",
    "*Wallpaper-Content-Extended*",
    "*LanguageFeatures-Handwriting*",
    "*LanguageFeatures-OCR*",
    "*LanguageFeatures-Speech*",
    "*LanguageFeatures-TextToSpeech*"
)

$AllPackages = Get-WindowsPackage -Path $MountDir

foreach ($Pattern in $PackagePatterns) {
    $PackagesToRemove = $AllPackages | Where-Object { $_.PackageName -like $Pattern }
    
    if ($PackagesToRemove) {
        foreach ($Pkg in $PackagesToRemove) {
            Write-Host "  - Executing system component: $($Pkg.PackageName)" -ForegroundColor DarkGray
            Remove-WindowsPackage -Path $MountDir -PackageName $Pkg.PackageName -NoRestart -ErrorAction SilentlyContinue 2>$null | Out-Null
        }
    }
}

# Phase 10: Registry"ing"
Write-Host "`n[7/14] Applying bypassing requirements & registry..." -ForegroundColor Yellow
try {
    reg load HKLM\zCOMPONENTS "$MountDir\Windows\System32\config\COMPONENTS" | Out-Null
    reg load HKLM\zDEFAULT "$MountDir\Windows\System32\config\default" | Out-Null
    reg load HKLM\zNTUSER "$MountDir\Users\Default\ntuser.dat" | Out-Null
    reg load HKLM\zSOFTWARE "$MountDir\Windows\System32\config\SOFTWARE" | Out-Null
    reg load HKLM\zSYSTEM "$MountDir\Windows\System32\config\SYSTEM" | Out-Null

    Write-Host "  - Bypassing Hardware Requirements..."
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
    Write-Host "  - Disabling Sponsored Apps & Content Delivery..."
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'ContentDeliveryAllowed' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'FeatureManagementEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SoftLandingEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContentEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'
    Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions'
    Remove-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\SuggestedApps'
    Write-Output "  - Enabling Local Accounts on OOBE..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'
    Write-Output "  - Disabling Reserved Storage..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
    Write-Output "  - Disabling BitLocker Device Encryption..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
    Write-Output "  - Bypassing SVCHOST Splitting to kill duplicate processes..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Control' 'SvcHostSplitThresholdInKB' 'REG_DWORD' '41943040'
    Write-Output "  - Disabling Services..."
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\SysMain' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DiagTrack' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\BITS' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DoSvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DPS' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WdiServiceHost' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WdiSystemHost' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\PcaSvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\FontCache' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WbioSrvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\DusmSvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WpnService' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\LanmanServer' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\LanmanWorkstation' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\TrkWks' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\MapsBroker' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\WerSvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\Spooler' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\SDRSVC' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\wbengine' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\fhsvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\wisvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\RemoteRegistry' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\PhoneSvc' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\RetailDemo' 'Start' 'REG_DWORD' '4'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\shpamsvc' 'Start' 'REG_DWORD' '4'
    Write-Output "  - Disabling Chat..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'
    Write-Output "  - Disabling OneDrive folder backup..."
    Set-RegistryValue "HKLM\zSOFTWARE\Policies\Microsoft\Windows\OneDrive" "DisableFileSyncNGSC" "REG_DWORD" "1"
    Write-Output "  - Disabling Telemetry..."
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\ControlSet001\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'
    Write-Output "  - Preventing installation of apps..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
    Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate'
    Remove-RegistryValue 'HKLM\zSOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'
    Write-Output "  - Disabling Bing..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' 'ConnectedSearchUseWeb' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Search' 'DisableWebSearch' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'BingSearchEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' 'CortanaConsent' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Dsh' 'AllowNewsAndInterests' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Windows Feeds' 'EnableFeeds' 'REG_DWORD' '0'
    Write-Output "  - Disabling Copilot..."
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
    Write-Output "  - Deleting Edge related registries..."
    Remove-RegistryValue "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge"
    Remove-RegistryValue "HKLM\zSOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge Update"
    Write-Output "  - Deleting Telemetry Scheduled Tasks..."
    $tasksPath = "$MountDir\Windows\System32\Tasks"
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Customer Experience Improvement Program" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Windows Error Reporting\QueueReporting" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Application Experience\ProgramDataUpdater" -Force -ErrorAction SilentlyContinue
    Remove-Item -Path "$tasksPath\Microsoft\Windows\Chkdsk\Proxy" -Force -ErrorAction SilentlyContinue
}
finally {
    reg unload HKLM\zCOMPONENTS 2>$null | Out-Null
    reg unload HKLM\zDEFAULT 2>$null | Out-Null
    reg unload HKLM\zNTUSER 2>$null | Out-Null
    reg unload HKLM\zSOFTWARE 2>$null | Out-Null
    reg unload HKLM\zSYSTEM 2>$null | Out-Null
    [GC]::Collect()
    Start-Sleep -Seconds 3
}

# Phase 12: ResetBase
Write-Host "`n[9/14] Deep cleaning image components..." -ForegroundColor Yellow
dism.exe /Image:$MountDir /Cleanup-Image /StartComponentCleanup /ResetBase | Out-Null

# Phase 13: Saving & Exporting
Write-Host "`n[10/14] Saving changes to install.wim..." -ForegroundColor Yellow
dism.exe /Unmount-Image /MountDir:"$MountDir" /Commit | Out-Null

Write-Host "`n[!] Choose the compression format:" -ForegroundColor Cyan
Write-Host " 1. WIM (Faster)"
Write-Host " 2. ESD (Slower, but lower image file)"
$CompressChoice = Read-Host "-> Which one do you wanna choose"

if ($CompressChoice -eq '2') {
    Write-Host "  - Exporting and heavily compressing to install.esd (This will take a long time :3)..." -ForegroundColor DarkGray
    dism.exe /Export-Image /SourceImageFile:"$ExtractDir\sources\install.wim" /SourceIndex:$WimIndex /DestinationImageFile:"$ExtractDir\sources\install.esd" /Compress:recovery | Out-Null
    
    Write-Host "  - Removing the old WIM file..." -ForegroundColor DarkGray
    Remove-Item -Path "$ExtractDir\sources\install.wim" -Force
} else {
    Write-Host "  - Exporting and optimizing install.wim..." -ForegroundColor DarkGray
    dism.exe /Export-Image /SourceImageFile:"$ExtractDir\sources\install.wim" /SourceIndex:$WimIndex /DestinationImageFile:"$ExtractDir\sources\install_optimized.wim" /Compress:max | Out-Null
    
    Remove-Item -Path "$ExtractDir\sources\install.wim" -Force
    Rename-Item -Path "$ExtractDir\sources\install_optimized.wim" -NewName "install.wim"
}

# Phase 14: Bypass
Write-Host "`n[11/14] Mounting boot.wim to bypass hardwares..." -ForegroundColor Yellow
dism.exe /Mount-Image /ImageFile:"$ExtractDir\sources\boot.wim" /Index:2 /MountDir:"$MountDir"

try {
    reg load HKLM\zDEFAULT "$MountDir\Windows\System32\config\default" | Out-Null
    reg load HKLM\zNTUSER "$MountDir\Users\Default\ntuser.dat" | Out-Null
    reg load HKLM\zSYSTEM "$MountDir\Windows\System32\config\SYSTEM" | Out-Null

    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zDEFAULT\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zNTUSER\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-RegistryValue 'HKLM\zSYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
}
finally {
    reg unload HKLM\zDEFAULT 2>$null | Out-Null
    reg unload HKLM\zNTUSER 2>$null | Out-Null
    reg unload HKLM\zSYSTEM 2>$null | Out-Null
    [GC]::Collect()
    Start-Sleep -Seconds 3
}

Write-Host "`n[12/14] Saving changes to boot.wim..." -ForegroundColor Yellow
dism.exe /Unmount-Image /MountDir:"$MountDir" /Commit

# Phase 15: Autounattend.xml
Write-Host "`n[13/14] Generating autounattend.xml..." -ForegroundColor Yellow
$XmlContent = @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <UserData><AcceptEula>true</AcceptEula></UserData>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
</unattend>
"@
$XmlContent | Out-File -FilePath "$ExtractDir\autounattend.xml" -Encoding UTF8

# Phase 16: Creating ISO files
Write-Host "`n[14/14] ISO Creation Process..." -ForegroundColor Yellow

$OscdimgPath = "$Workspace\oscdimg.exe"
$MicrosoftUrl = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"

if (!(Test-Path $OscdimgPath)) {
    Write-Host "-> Cannot find oscdimg, downloading securely from Microsoft..." -ForegroundColor Cyan
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        Invoke-WebRequest -Uri $MicrosoftUrl -OutFile $OscdimgPath -UseBasicParsing
        Write-Host "-> Completed!" -ForegroundColor Green
    } catch {
        Write-Host "-> Error: Cannot download tool!" -ForegroundColor Red
    }
}

if (Test-Path $OscdimgPath) {
    Write-Host "Building ISO... (Please wait)" -ForegroundColor Cyan
    $BuildArgs = "-m -o -u2 -udfver102 -bootdata:2#p0,e,b`"$ExtractDir\boot\etfsboot.com`"#pEF,e,b`"$ExtractDir\efi\microsoft\boot\efisys.bin`" `"$ExtractDir`" `"$FinalISO`""
    
    Start-Process -FilePath $OscdimgPath -ArgumentList $BuildArgs -Wait -NoNewWindow
    
    Write-Host "`nCompleted! Your ISO is ready at: $FinalISO" -ForegroundColor Green
    Write-Host "Cleaning up workspace..." -ForegroundColor DarkGray
    Remove-Item -Path $Workspace -Recurse -Force
} else {
    Write-Host "`n[!] Cannot compress into ISO, your custom Windows path is: $ExtractDir" -ForegroundColor Yellow
}

Write-Host "`nPress Enter to exit..."
Read-Host

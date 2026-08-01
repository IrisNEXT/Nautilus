# Nautilus [Builder] for Windows 11

Nautilus is a lightweight, free and easy to use PowerShell that allows you to quickly debloat your Windows ISO. Instead of manually applying tweaks on a live system, this tool automates the creation of a fully debloated, pure and telemetry-free Windows 11 ISO (`.iso`). 

Building with pure performance for both low-end and high-end PCs, Nautilus does not use CompactOS, makes the process quick and easy!

![Powershell](/Images/powershell.png)

> Nautilus is also heavily based on Tiny11Builder in Tweaks, APPXs removal, etc...

## ⚠️ Disclaimer

> [!Warning]
> Great care went into making sure this script does not unintentionally break any OS functionality, but use at your own risk! This script modifies core system images offline. Always test your generated ISO on a Virtual Machine before deploying it on your main hardware.

## What things will be removed:

#### APPXs
- Clipchamp.Clipchamp
- Microsoft.ApplicationCompatibilityEnhancements
- Microsoft.BingNews
- Microsoft.BingSearch
- Microsoft.BingWeather
- Microsoft.GamingApp
- Microsoft.GetHelp
- Microsoft.MicrosoftOfficeHub
- Microsoft.MicrosoftSolitaireCollection
- Microsoft.MicrosoftStickyNotes
- Microsoft.OutlookForWindows
- Microsoft.Paint
- Microsoft.PowerAutomateDesktop
- Microsoft.ScreenSketch
- Microsoft.Todos
- Microsoft.Windows.DevHome
- Microsoft.Windows.Photos
- Microsoft.WindowsAlarms
- Microsoft.WindowsCalculator
- Microsoft.WindowsCamera
- Microsoft.WindowsFeedbackHub
- Microsoft.WindowsNotepad
- Microsoft.WindowsSoundRecorder
- Microsoft.WindowsStore
- Microsoft.WindowsTerminal
- Microsoft.Xbox.TCUI
- Microsoft.XboxGamingOverlay
- Microsoft.XboxIdentityProvider
- Microsoft.XboxSpeechToTextOverlay
- Microsoft.YourPhone
- Microsoft.ZuneMusic
- MicrosoftCorporationII.QuickAssist
- MicrosoftWindows.Client.WebExperience
- MicrosoftWindows.CrossDevice
- MSTeams

#### Optional Features
- Printing-Foundation-InternetPrinting-Client
- WorkFolders-Client
- MediaPlayback
- SMB1Protocol

#### And more...
- Edge and OneDrive
- Retail Demo
- DiagSvcs
- Perflogs
- CompatTelRunner
- DeviceCensus
- appraiser
- wsqmcons
- InternetExplorer
- LanguageFeatures-Handwriting
- LanguageFeatures-OCR
- LanguageFeatures-Speech
- LanguageFeatures-TextToSpeech
- MediaPlayer
- OneDrive-Setup-Package
- PowerShell-ISE-FOD
- QuickAssist-
- StepsRecorder
- TabletPCMath
- Wallpaper-Content-Extended
- WordPad-FoD

## Tweaks
- Telemetry, sponsors apps
- Disable Copilot
- GameDXR and Xbox
- Enable Local Accounts
- Disable Bing
- Disable ContentDelivery
- Disable Bitlocker
- Bypass TPM 2.0 and unsupported CPU
- ResetBase

## So... how to use the builder?

### Requirements
- A pure Windows 11 ISO downloaded from Microsoft.
- At least 20GB of free space on your `C:\` drive for the workspace.
- **Administrator Privileges** (The script will automatically check for this).

### Running the Script

1. Download the latest version of the script (`NautilusBuilder.ps1`).
2. Open PowerShell as Administrator.
3. Temporarily allow script execution by running:
   ```PowerShell
   Set-ExecutionPolicy Unrestricted -Scope Process -Force

## License
Nautilus is licensed under the GPLv3 license. See the LICENSE file for more information.

## Credits
- [NTDEV](https://github.com/ntdevlabs) for creating and hosting Tiny11Builder
- [Luu Phuong](https://github.com/lyghtlychee) for providing some neccessary infos
- [Raphire](https://github.com/Raphire) for Win11Debloat
- ...

## Support me
- Non-available, unfortunately

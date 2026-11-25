; Nova Transfer — Inno Setup installer
; Build: ISCC installer.iss  (from desktop\nova_transfer\)

#define AppName "Nova Transfer"
#define AppVersion "1.2.0"
#define AppPublisher "JKdizains"
#define AppURL "https://jkdizains.lv"
#define AppExe "NovaTransfer.exe"

[Setup]
AppId={{8F2C4E1A-1234-4F00-A000-123456789ABC}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
DefaultDirName={autopf}\JKapps\Nova Transfer
; All JKapps share one parent folder; move older installs there.
UsePreviousAppDir=no
DefaultGroupName=JKapps\{#AppName}
OutputDir=..\..\BUILDS
OutputBaseFilename=NovaTransfer_1.2.0_windows-setup_2026-11-25
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExe}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[InstallDelete]
; Older versions installed to Program Files\Nova Transfer.
Type: filesandordirs; Name: "{autopf}\Nova Transfer"
Type: filesandordirs; Name: "{autoprograms}\{#AppName}"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"

[Files]
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\{#AppName}"; Filename: "{app}\{#AppExe}"
Name: "{group}\Uninstall {#AppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExe}"; Tasks: desktopicon

[Run]
; Firewall: drop any rule Windows auto-created for the exe (a "Block"
; one from a dismissed prompt beats every Allow), then allow inbound
; TCP pairing + UDP discovery on every network profile — on "Public"
; Wi-Fi the phone otherwise scans the QR and never reaches the PC.
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=all program=""{app}\{#AppExe}"""; Flags: runhidden; StatusMsg: "Configuring Windows Firewall..."
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=all program=""{autopf}\Nova Transfer\{#AppExe}"""; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Nova Transfer"""; Flags: runhidden
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""Nova Transfer"" dir=in action=allow program=""{app}\{#AppExe}"" enable=yes profile=any"; Flags: runhidden
Filename: "{app}\{#AppExe}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""Nova Transfer"""; Flags: runhidden; RunOnceId: "NovaFirewall"

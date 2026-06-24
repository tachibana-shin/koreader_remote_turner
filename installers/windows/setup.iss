; Inno Setup script for KOReader Remote Turner
#define MyAppName "KOReader Remote Turner"
#define MyAppPublisher "koreader-remote-turner"
#define MyAppURL "https://github.com/shin-curry/koreader-remote-turner"
#define MyAppExeName "koreader_remote_turner.exe"

[Setup]
AppId={{F3C5A8E0-9A1B-4B7C-8D5E-6F2A3B4C5D6E}
AppName={#MyAppName}
AppVersion={#MyAppVer}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=koreader-remote-{#MyAppVer}-windows-{#MyAppArch}
SetupIconFile={#SourcePath}\..\..\windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#SourcePath}\..\..\build\windows\{#MyAppPlatform}\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

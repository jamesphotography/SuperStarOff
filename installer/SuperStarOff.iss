; SuperStarOff Windows Installer Script
; 慧眼去星 Windows 安装包配置
; 
; 使用 Inno Setup 编译此脚本生成安装程序
; 下载 Inno Setup: https://jrsoftware.org/isinfo.php

#define MyAppName "SuperStarOff"
#define MyAppNameCN "慧眼去星"
#define MyAppVersion "1.1.0"
#define MyAppPublisher "James Zhen Yu"
#define MyAppURL "https://www.youtube.com/@JamesZhenYu"
#define MyAppExeName "superstaroff.exe"

[Setup]
; 应用信息
AppId={{8F5E7A3B-9C2D-4E1F-A8B6-7D4C3E2F1A0B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppNameCN} v{#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}

; 安装目录
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppNameCN}
DisableProgramGroupPage=yes

; 输出设置
OutputDir=..\installer_output
OutputBaseFilename=SuperStarOff-Installer-v{#MyAppVersion}
Compression=lzma2
SolidCompression=yes

; 权限设置
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=dialog

; 界面设置
WizardStyle=modern
; UninstallDisplayIcon={app}\{#MyAppExeName}

; 许可证和信息页面（可选）
; LicenseFile=LICENSE.txt
InfoBeforeFile=installer_welcome.txt

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
english.BeveledLabel=SuperStarOff - AI Star Removal Tool

[Files]
; 主程序和依赖 - 从 PyInstaller dist 目录复制
Source: "..\dist2\superstaroff\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; JSX 脚本
Source: "..\src\StarOff.jsx"; DestDir: "{app}\scripts"; Flags: ignoreversion

[Dirs]
Name: "{app}\scripts"

[Icons]
; 开始菜单快捷方式
Name: "{group}\{#MyAppNameCN} - 安装 Photoshop 插件"; Filename: "{app}\scripts\install_to_photoshop.bat"
Name: "{group}\卸载 {#MyAppNameCN}"; Filename: "{uninstallexe}"

[Run]
; 安装完成后运行 Photoshop 插件安装脚本
Filename: "{app}\scripts\install_to_photoshop.bat"; Description: "安装 Photoshop 插件"; Flags: postinstall shellexec skipifsilent

[UninstallRun]
; 卸载时清理 Photoshop 脚本
Filename: "{app}\scripts\uninstall_from_photoshop.bat"; Flags: runhidden

[Code]
// Pascal Script 代码用于自定义安装逻辑

var
  PhotoshopPage: TInputOptionWizardPage;
  PhotoshopVersions: array of String;
  PhotoshopPaths: array of String;
  PhotoshopCount: Integer;

// 扫描已安装的 Photoshop 版本
procedure ScanPhotoshopVersions();
var
  Years: array of String;
  I: Integer;
  Path, Path64, Path86: String;
begin
  SetArrayLength(Years, 5);
  Years[0] := '2026';
  Years[1] := '2025';
  Years[2] := '2024';
  Years[3] := '2023';
  Years[4] := '2022';
  
  PhotoshopCount := 0;
  SetArrayLength(PhotoshopVersions, 5);
  SetArrayLength(PhotoshopPaths, 5);
  
  for I := 0 to 4 do
  begin
    // Check 64-bit Program Files first
    Path64 := ExpandConstant('{pf64}') + '\Adobe\Adobe Photoshop ' + Years[I] + '\Presets\Scripts';
    // Check 32-bit Program Files as fallback
    Path86 := ExpandConstant('{pf32}') + '\Adobe\Adobe Photoshop ' + Years[I] + '\Presets\Scripts';
    
    Path := '';
    if DirExists(Path64) then
      Path := Path64
    else if DirExists(Path86) then
      Path := Path86;
    
    if Path <> '' then
    begin
      PhotoshopVersions[PhotoshopCount] := 'Photoshop ' + Years[I];
      PhotoshopPaths[PhotoshopCount] := Path;
      PhotoshopCount := PhotoshopCount + 1;
    end;
  end;
end;

// 初始化向导
procedure InitializeWizard();
var
  I: Integer;
begin
  ScanPhotoshopVersions();
  
  // 创建 Photoshop 选择页面
  PhotoshopPage := CreateInputOptionPage(wpSelectDir,
    '选择 Photoshop 版本',
    '选择要安装插件的 Photoshop 版本',
    '检测到以下 Photoshop 版本，请选择要安装插件的版本：',
    True, False);
  
  if PhotoshopCount > 0 then
  begin
    for I := 0 to PhotoshopCount - 1 do
    begin
      PhotoshopPage.Add(PhotoshopVersions[I]);
      PhotoshopPage.Values[I] := True;  // 默认全选
    end;
  end
  else
  begin
    PhotoshopPage.Add('未检测到 Photoshop（稍后手动安装）');
    PhotoshopPage.Values[0] := True;
  end;
end;

// 安装完成后复制 JSX 到选中的 Photoshop 版本
procedure CurStepChanged(CurStep: TSetupStep);
var
  I: Integer;
  SourceFile, DestFile: String;
begin
  if CurStep = ssPostInstall then
  begin
    SourceFile := ExpandConstant('{app}') + '\scripts\StarOff.jsx';
    
    for I := 0 to PhotoshopCount - 1 do
    begin
      if PhotoshopPage.Values[I] then
      begin
        DestFile := PhotoshopPaths[I] + '\StarOff.jsx';
        FileCopy(SourceFile, DestFile, False);
      end;
    end;
  end;
end;

// 卸载时删除 Photoshop 中的脚本
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Years: array of String;
  I: Integer;
  Path64, Path86: String;
begin
  if CurUninstallStep = usPostUninstall then
  begin
    SetArrayLength(Years, 5);
    Years[0] := '2026';
    Years[1] := '2025';
    Years[2] := '2024';
    Years[3] := '2023';
    Years[4] := '2022';
    
    for I := 0 to 4 do
    begin
      Path64 := ExpandConstant('{pf64}') + '\Adobe\Adobe Photoshop ' + Years[I] + '\Presets\Scripts\StarOff.jsx';
      Path86 := ExpandConstant('{pf32}') + '\Adobe\Adobe Photoshop ' + Years[I] + '\Presets\Scripts\StarOff.jsx';
      
      if FileExists(Path64) then
        DeleteFile(Path64);
      if FileExists(Path86) then
        DeleteFile(Path86);
    end;
  end;
end;

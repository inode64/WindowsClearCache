!include "MUI2.nsh"

Name "Windows Clear Cache"
OutFile "WindowsClearCacheInstaller.exe"
InstallDir "$PROGRAMFILES\\WindowsClearCache"
RequestExecutionLevel admin

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_LANGUAGE "English"

Section "Install"
  SetOutPath "$INSTDIR"
  File "DriveClean.ps1"

  DetailPrint "Open Disk Cleanup configuration"
  nsExec::ExecToLog 'cleanmgr.exe /sageset:1'

  MessageBox MB_YESNO "Create a weekly scheduled cleanup task?" IDNO SkipTask
  nsExec::ExecToLog 'schtasks /Create /TN "WindowsClearCache" /TR "powershell.exe -ExecutionPolicy Bypass -File \\\"$INSTDIR\\DriveClean.ps1\\\"" /SC WEEKLY /RL HIGHEST /F'
SkipTask:
SectionEnd

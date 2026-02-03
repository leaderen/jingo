; ============================================================================
; JinGo VPN - NSIS Installer Script
; ============================================================================
; Usage: makensis /DVERSION=1.0.0 /DSOURCE_DIR=path\to\files installer.nsi
; ============================================================================

!include "MUI2.nsh"
!include "FileFunc.nsh"

; ---- Build parameters (passed via /D flags) ----
!ifndef VERSION
    !define VERSION "1.0.0"
!endif
!ifndef SOURCE_DIR
    !define SOURCE_DIR "dist"
!endif
!ifndef BRAND
    !define BRAND "JinGo"
!endif

; ---- General ----
Name "${BRAND} VPN"
!ifdef OUTFILE
    OutFile "${OUTFILE}"
!else
    OutFile "jingo-${VERSION}-windows-setup.exe"
!endif
InstallDir "$PROGRAMFILES64\${BRAND} VPN"
InstallDirRegKey HKLM "Software\${BRAND} VPN" "InstallDir"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
SetCompressorDictSize 32

; ---- Version info ----
VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName" "${BRAND} VPN"
VIAddVersionKey "ProductVersion" "${VERSION}"
VIAddVersionKey "FileVersion" "${VERSION}"
VIAddVersionKey "FileDescription" "${BRAND} VPN Installer"
VIAddVersionKey "LegalCopyright" "Copyright ${BRAND}"

; ---- MUI settings ----
!define MUI_ABORTWARNING
; Icon: use .ico file if available, otherwise NSIS default
!ifdef ICON_FILE
    !define MUI_ICON "${ICON_FILE}"
    !define MUI_UNICON "${ICON_FILE}"
!endif

; ---- Pages ----
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${SOURCE_DIR}\README.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ---- Languages ----
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Vietnamese"

; ============================================================================
; Install section
; ============================================================================
Section "Install"
    SetOutPath "$INSTDIR"

    ; Kill running instance
    nsExec::ExecToLog 'taskkill /F /IM JinGo.exe'

    ; Copy all files
    File /r "${SOURCE_DIR}\*.*"

    ; Write uninstaller
    WriteUninstaller "$INSTDIR\uninstall.exe"

    ; Registry entries
    WriteRegStr HKLM "Software\${BRAND} VPN" "InstallDir" "$INSTDIR"
    WriteRegStr HKLM "Software\${BRAND} VPN" "Version" "${VERSION}"

    ; Add/Remove Programs entry
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "DisplayName" "${BRAND} VPN"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "UninstallString" "$\"$INSTDIR\uninstall.exe$\""
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "DisplayIcon" "$INSTDIR\JinGo.exe"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "DisplayVersion" "${VERSION}"
    WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "Publisher" "${BRAND}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "NoModify" 1
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "NoRepair" 1

    ; Estimate size
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN" \
        "EstimatedSize" $0

    ; Start menu shortcuts
    CreateDirectory "$SMPROGRAMS\${BRAND} VPN"
    CreateShortCut "$SMPROGRAMS\${BRAND} VPN\${BRAND} VPN.lnk" "$INSTDIR\JinGo.exe" "" "$INSTDIR\JinGo.exe" 0
    CreateShortCut "$SMPROGRAMS\${BRAND} VPN\Uninstall.lnk" "$INSTDIR\uninstall.exe" "" "$INSTDIR\uninstall.exe" 0

    ; Desktop shortcut
    CreateShortCut "$DESKTOP\${BRAND} VPN.lnk" "$INSTDIR\JinGo.exe" "" "$INSTDIR\JinGo.exe" 0
SectionEnd

; ============================================================================
; Uninstall section
; ============================================================================
Section "Uninstall"
    ; Kill running instance
    nsExec::ExecToLog 'taskkill /F /IM JinGo.exe'

    ; Remove files (delete entire install directory)
    RMDir /r "$INSTDIR"

    ; Remove shortcuts
    Delete "$DESKTOP\${BRAND} VPN.lnk"
    RMDir /r "$SMPROGRAMS\${BRAND} VPN"

    ; Remove registry entries
    DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${BRAND}VPN"
    DeleteRegKey HKLM "Software\${BRAND} VPN"
SectionEnd

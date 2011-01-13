; �ýű�ʹ�� HM VNISEdit �ű��༭���򵼲���

; ��װ�����ʼ���峣��
!define PRODUCT_NAME "UPXShell"
!define PRODUCT_VERSION "1.01"
!define PRODUCT_BUILDVERSION "10.12.10.12"
!define PRODUCT_PUBLISHER "sandysoft"
!define PRODUCT_WEB_SITE "http://code.google.com/p/upxshell/"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\UpxShell.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_BRANDINGTEXT "sandy"

SetCompressor lzma

; ------ MUI �ִ����涨�� (1.67 �汾���ϼ���) ------
!include "MUI.nsh"
!include "Sections.nsh"

; MUI Ԥ���峣��
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"

; ��ӭҳ��
!insertmacro MUI_PAGE_WELCOME
; ���Э��ҳ��
;!define MUI_LICENSEPAGE_RADIOBUTTONS
;!insertmacro MUI_PAGE_LICENSE "${PATH_COMMONFILE}\License.txt"
; ���ѡ��ҳ��
;!insertmacro MUI_PAGE_COMPONENTS
; ��װĿ¼ѡ��ҳ��
!insertmacro MUI_PAGE_DIRECTORY
; ��װ����ҳ��
!insertmacro MUI_PAGE_INSTFILES
; ��װ���ҳ��
!define MUI_FINISHPAGE_RUN "$INSTDIR\UpxShell.exe"
!insertmacro MUI_PAGE_FINISH

; ��װж�ع���ҳ��
!insertmacro MUI_UNPAGE_INSTFILES

; ��װ�����������������
!insertmacro MUI_LANGUAGE "SimpChinese"

; ��װԤ�ͷ��ļ�
!insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
; ------ MUI �ִ����涨����� ------

Name "${PRODUCT_NAME} V${PRODUCT_VERSION}"
OutFile "${PRODUCT_NAME} V${PRODUCT_VERSION} Build${PRODUCT_BUILDVERSION}.exe"
InstallDir "$PROGRAMFILES\${PRODUCT_NAME}"
InstallDirRegKey HKLM "${PRODUCT_UNINST_KEY}" "UninstallString"
ShowInstDetails show
ShowUnInstDetails show
BrandingText "${PRODUCT_BRANDINGTEXT}"


var TmpInstallDir

Function .onInit
  ReadRegStr $TmpInstallDir HKLM "${PRODUCT_DIR_REGKEY}" "PATH"
  IfErrors +2 0
  StrCpy $INSTDIR $TmpInstallDir
FunctionEnd


Section "������" SEC01
  ;��Զѡ��
  SectionIn RO

  SetOutPath "$INSTDIR"
  SetOverwrite ON

  File "..\bin\Whatsnew.txt"
  File "..\bin\UPXShell.exe"
  File "..\bin\UPXRes.dll"
  
  SetOutPath "$INSTDIR\Language"
	File "..\bin\Language\*.lng"

  CreateDirectory "$SMPROGRAMS\UPXShell"
  CreateShortCut "$SMPROGRAMS\UPXShell\UpxShell.lnk" "$INSTDIR\UPXShell.exe"
  CreateShortCut "$DESKTOP\UpxShell.lnk" "$INSTDIR\UPXShell.exe"

SectionEnd


Section -AdditionalIcons
  SetOutPath $INSTDIR
  WriteIniStr "$INSTDIR\web.url" "InternetShortcut" "URL" "${PRODUCT_WEB_SITE}"
  CreateShortCut "$SMPROGRAMS\UPXShell\web.lnk" "$INSTDIR\web.url"
  CreateShortCut "$SMPROGRAMS\UPXShell\Uninstall.lnk" "$INSTDIR\uninst.exe"
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\UpxShell.exe"
  ;���ǰ�װʱ�Զ�Ѱ��Ŀ¼
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "Path" "$INSTDIR"

  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\UpxShell.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
SectionEnd

/******************************
 *  �����ǰ�װ�����ж�ز���  *
 ******************************/

Section Uninstall
  Delete "$INSTDIR\Whatsnew.txt"
  Delete "$INSTDIR\UPXShell.exe"
  Delete "$INSTDIR\UPXRes.dll"
  Delete "$INSTDIR\web.url"
  Delete "$INSTDIR\uninst.exe"

  Delete "$DESKTOP\UpxShell.lnk"

  Delete "$SMPROGRAMS\UPXShell\UpxShell.lnk"
  Delete "$SMPROGRAMS\UPXShell\web.lnk"
  Delete "$SMPROGRAMS\UPXShell\Uninstall.lnk"
  RMDir "$SMPROGRAMS\UPXShell"
  Delete "$INSTDIR\Language\*.lng"
  RMDir "$INSTDIR\Language"

  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd

#-- ���� NSIS �ű��༭�������� Function ���α�������� Section ����֮���д���Ա��ⰲװ�������δ��Ԥ֪�����⡣--#

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "��ȷʵҪ��ȫ�Ƴ� $(^Name) ���������е������" IDYES +2
  Abort
FunctionEnd

Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) �ѳɹ��ش���ļ�����Ƴ���"
FunctionEnd

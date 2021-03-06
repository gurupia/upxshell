unit Globals;

interface

uses
  uUpxResAPI;

const
  MsgCount = 44; // Contains original english messages
  EngMsgs: array [1 .. MsgCount] of string = (
    'Could not access file. It may be allready open',
    'The file attribute is set to ReadOnly. To proceed it must be unset. Continue?',
    'Best',                                 //3
    'This file doesn''t seem to be packed. Run the Scrambler?', //4
    ' (in ',                                //5
    ' seconds)',                            //6
    'decompress',                           //7
    'compress',                             //8
    'There is nothing to ',                 //9
    'N/A',                                  //10
    'No directory selected',                //11
    '...update failed :-(',                 //12
    'Could not connect to update server!',  //13
    'Updated version of product found!',    //14
    'Parsing update file...',               //15
    'Retrieving update information...',     //16
    'File successfully compressed',         //17
    'File successfully decompressed',       //18
    'File compressed with warnings',        //19
    'File decompressed with warnings',      //20
    'Errors occured. File not compressed',  //21
    'Errors occured. File not decompressed',//22
    ' & tested',                            //23
    ' & tested w/warnings',                 //24
    ' & test failed',                       //25
    'UPX returned following error:\n',      //26
    ' & scrambled',                         //27
    '...update found',                      //28
    '...no updates found',                  //29
    'OK',                                   //30
    'Failed',                               //31
    'Skip',                                 //32
    'File Name',                            //33
    'Folder',                               //34
    'Size',                                 //35
    'Packed',                               //36
    'Result',                               //37
    'Error',                                //38
    'Confirmation',                         //39
    'Select directory to compress:',        //40
    'This file is now Scrambled!',          //41
    'This file has NOT been scrambled!',    //42
    'Compress with UPX',                    //43
    'Custom upx.exe'                        //44
    );

type
  // The global configuration type
  TConfig = record
    DebugMode: boolean; // Are we in debug mode?
    LocalizerMode: boolean; // Translation editor's mode
  end;

type
  TKeyType = (ktString, ktInteger, ktBoolean); // Passed to ReadKey and StoreKey

  TRegValue = record // This one is returned by ReadKey and passed to StoreKey
    Str: string;
    Int: integer;
    Bool: boolean;
  end;

type
  TToken = record
    Token: ShortString;
    Value: ShortString;
  end;

  TTokenStr = array of TToken;


type
  // Used for the IntergrateContext procedure to check what to do.
  TIntContext = (doSetup, extRegister, extUnRegister);
  TIntContextOptions = set of TIntContext;

  // This is all used when passing data for localization purposes
type
  TComponentProperty = record
    Name: string;
    Value: string;
  end;

type
  TComponentProperties = record
    Name: string;
    Properties: array of TComponentProperty;
  end;

type
  TFormProperties = record
    Name: string;
    Properties: array of TComponentProperties;
  end;

type
  TLocalizerFormMode = (lfmProperties, lfmMessages);

var
  Config: TConfig; // Holds the global application configuration
  GlobFileName: string; // Holds the opened file name
  WorkDir: string; // Holds the working directory of UPX Shell
  LanguageSubdir: string = 'Language';
  LangFile: string; // Holds the current language file name
  Extension: integer = 1; // Contains OpenDialog last selected extension
  GlobFileSize: integer; // Contains file size for ratio calculation
  Messages: array [1 .. MsgCount] of string; // Contains the translated messages

  { ** Global Procedures ** }
procedure IntergrateContext(const Options: TIntContextOptions);
function QueryTime(const GetTime: boolean; var StartTime: int64): string;
function ReadKey(const Name: string; KeyType: TKeyType): TRegValue;
procedure StoreKey(const Name: string; const Value: TRegValue;
  KeyType: TKeyType);


function ProcessSize(const Size: integer): string;
function GetFileSize(const FileName: string): integer;


function GetAppVersion(AppName: string; var ProductVersion, FileVersion: string)
  : boolean;

implementation

uses
  Windows, SysUtils, Registry, Dialogs, Classes, Math,
  Translator,
  MainFrm;

const
  // ** Array for filetypes
  RegExtensions: array [1 .. 10] of string = ('.bpl', '.com', '.dll', '.dpl',
    '.exe', '.ocx', '.scr', '.sys', '.acm', '.ax');

  { ** ** }
procedure RegisterExtensions(const Extensions: array of string;
  const OpenCommand: string; const ActionValue: string);
var
  Reg: TRegistry;
  I: integer;
  Def: string;
begin
  Reg := TRegistry.Create();
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    for I := 0 to High(Extensions) do
    begin
      if Reg.OpenKey('\' + Extensions[I], True) then
      begin
        Def := Reg.ReadString('');
        if Def = '' then
        begin
          Def := copy(Extensions[I], 2, 3) + 'file';
          Reg.WriteString('', Def);
        end;
      end;
      Reg.CloseKey;

      if (Def <> '') then
      begin
        if Reg.CreateKey('\' + Def + '\shell\UPXshell\command') then
        begin
          if Reg.OpenKey('\' + Def + '\shell\UPXshell', True) then
          begin
            Reg.WriteString('', ActionValue);
          end;
          Reg.CloseKey;

          if Reg.OpenKey('\' + Def + '\shell\UPXshell\command', True) then
          begin
            Reg.WriteString('', OpenCommand);
          end;
          Reg.CloseKey;
        end;
        Reg.CloseKey;
      end;
    end;
  finally
    FreeAndNil(Reg);
  end;
end;

{ ** ** }
procedure UnRegisterExtensions(const Extensions: array of string);
var
  Reg: TRegistry;
  I: integer;
  Def: string;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CLASSES_ROOT;
    for I := Low(Extensions) to High(Extensions) do
    begin
      if Reg.OpenKey('\' + Extensions[I], False) then
      begin
        Def := Reg.ReadString('');
      end;
      Reg.CloseKey;

      if Def <> '' then
      begin
        Reg.DeleteKey('\' + Def + '\shell\UPXshell');
        Reg.CloseKey;
      end;
    end;
  finally
    FreeAndNil(Reg);
  end;
end;

{ ** ** }
procedure IntergrateContext(const Options: TIntContextOptions);
{ ** (doSetup, extRegister, extUnRegister) ** }
var
  Path: string;
  ActionValue: string;
  RegValue: TRegValue;
begin
  Path := WorkDir + 'UPXShell.exe "%1" %*';
  ActionValue := Trim(TranslateMsg('Compress with UPX'));

  if extRegister in Options then
  begin
    RegisterExtensions(RegExtensions, Path, ActionValue);
    // update the registry with new settings
    RegValue.Bool := True;
    StoreKey('ShellIntegrate', RegValue, ktBoolean);
  end
  else if extUnRegister in Options then
  begin
    UnRegisterExtensions(RegExtensions);
    RegValue.Bool := False;
    StoreKey('ShellIntegrate', RegValue, ktBoolean);
  end;

  // If this is called from the Setup then we need to close after finishing Integration.
  if doSetup in Options then
  begin
    exit;
  end;
end;

{ ** ** }
function QueryTime(const GetTime: boolean; var StartTime: int64): string;
var
  Frequency, EndTime: int64;
  Time: string[5];
begin
  if GetTime then
  begin
    QueryPerformanceFrequency(Frequency);
    QueryPerformanceCounter(EndTime);
    Time := FloatToStr((EndTime - StartTime) / Frequency);
    Result := Time;
  end
  else
  begin
    QueryPerformanceCounter(StartTime);
    Result := '';
  end;
end;

{ ** Reads registry value from default UPX Shell folder and returns TRegResult ** }
function ReadKey(const Name: string; KeyType: TKeyType): TRegValue;
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\ION Tek\UPX Shell\3.x', True) then
    begin
      if Reg.ValueExists(Name) then
      begin
        case KeyType of // Checks the type of key and retrieves it
          ktString:
            begin
              Result.Str := Reg.ReadString(Name);
            end;
          ktInteger:
            begin
              Result.Int := Reg.ReadInteger(Name);
            end;
          ktBoolean:
            begin
              Result.Bool := Reg.ReadBool(Name);
            end;
        end;
      end
      else
      begin
        case KeyType of // Checks the type of key and retrieves it
          ktString:
            begin
              Result.Str := '';
            end;
          ktInteger:
            begin
              Result.Int := -1;
            end;
          ktBoolean:
            begin
              Result.Bool := False;
            end;
        end;
      end;
    end;
    Reg.CloseKey;
  finally
    FreeAndNil(Reg);
  end;
end;

{ ** And this one saves a specified key to registry ** }
procedure StoreKey(const Name: string; const Value: TRegValue;
  KeyType: TKeyType);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKey('Software\ION Tek\UPX Shell\3.x', True) then
    begin
      case KeyType of
        ktString:
          begin
            Reg.WriteString(Name, Value.Str);
          end;
        ktInteger:
          begin
            Reg.WriteInteger(Name, Value.Int);
          end;
        ktBoolean:
          begin
            Reg.WriteBool(Name, Value.Bool);
          end;
      end;
    end;
    Reg.CloseKey;
  finally
    FreeAndNil(Reg);
  end;
end;



{ ** ** }
function ProcessSize(const Size: integer): string;
begin
  Result := IntToStr(Size);
  case length(Result) of
    1 .. 3:
      begin
        Result := IntToStr(Size) + ' B';
      end;
    4 .. 6:
      begin
        Result := IntToStr(Size shr 10) + ' KB';
      end;
    7 .. 9:
      begin
        Result := IntToStr(Size shr 20) + ' MB';
      end;
    10 .. 12:
      begin
        Result := IntToStr(Size shr 30) + ' GB';
      end;
  end;
end;

{ ** ** }
function GetFileSize(const FileName: string): integer;
var
  sr: TSearchRec;
begin
  if FindFirst(FileName, faAnyFile, sr) = 0 then
  begin
    Result := sr.Size;
  end
  else
  begin
    Result := -1;
  end;
  FindClose(sr);
end;



function GetAppVersion(AppName: string; var ProductVersion, FileVersion: string)
  : boolean;
var
  versionsize, ValueSize: Cardinal;
  VersionBuf, VersionValue: pchar;

begin
  Result := false;
  if Trim(AppName) = '' then
    exit;
  versionsize := GetFileVersionInfoSize(pchar(AppName), versionsize);
  if versionsize = 0 then
    exit;
  VersionBuf := AllocMem(versionsize);
  try
    GetFileVersionInfo(pchar(AppName), 0, versionsize, VersionBuf);

    if VerQueryValue(VersionBuf,
      pchar
        ('\StringFileInfo\080403A8\ProductVersion'), Pointer(VersionValue),
      ValueSize) then
      ProductVersion := VersionValue;

    if VerQueryValue(VersionBuf, pchar('\StringFileInfo\080403A8\FileVersion'),
      Pointer(VersionValue), ValueSize) then
      FileVersion := VersionValue;
    Result := True;
  finally
    Freemem(VersionBuf);
  end;

end;


end.

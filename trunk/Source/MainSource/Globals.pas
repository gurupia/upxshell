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

  // The following is used to get UPX Shell build info
  // OLD VERSION: TBuildInfo     = (biFull, biNoBuild, biMajor, biMinor, biRelease, biBuild, biCute);
type
  TBuildInfo = record
    biFull: string;
    biNoBuild: string;
    biMajor: integer;
    biMinor: integer;
    biRelease: integer;
    biBuild: integer;
    biCute: string;
  end;

var
  BuildInfo: TBuildInfo;

type
  TLine = array [0 .. 500] of char; // Used in getting the DOS line
  TExtractDelete = (edExtract, edDelete); // Used for ExtractUPX()
  TCompDecomp = (cdCompress, cdDecompress { , cdEmpty } );
  // Passed to CompressFile() and holds
  // whether to compress or decompress the file
  TCompResult = (crSuccess, crWarning, crError); // Passed to SetStatus()

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
  TFormLocalizations = array of TFormProperties;
  TLocalizerFormMode = (lfmProperties, lfmMessages);

var
  Config: TConfig; // Holds the global application configuration
  GlobFileName: string; // Holds the opened file name
  WorkDir: string; // Holds the working directory of UPX Shell
  LanguageSubdir: string = 'Language';
  LangFile: string; // Holds the current language file name
  Extension: integer = 1; // Contains OpenDialog last selected extension
  GlobFileSize: integer; // Contains file size for ratio calculation
  Busy: boolean = False; // Set when compressing or scrambling files
  hStdOut: THandle; // Contains handle to standard console output
  CompressionResult: boolean = False; // Result of the compress operation
  Messages: array [1 .. MsgCount] of string; // Contains the translated messages
  bStdUPXVersion: byte; // Contains the default UPXVersion selected, see TUPXVersions.
  curUPXVersion: TUPXVersions;

  { ** Global Procedures ** }
procedure IntergrateContext(const Options: TIntContextOptions);
function QueryTime(const GetTime: boolean; var StartTime: int64): string;
function ReadKey(const Name: string; KeyType: TKeyType): TRegValue;
procedure StoreKey(const Name: string; const Value: TRegValue;
  KeyType: TKeyType);
procedure GetBuild;


function LastPos(const Substr: char; const S: string): integer;

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

procedure GetBuild;
var
  pInfo: PVSFixedFileInfo;
  dInfo: cardinal;
  dSize: cardinal;
  dTemp: cardinal;
  pBuffer: PChar;
  pFile: PChar;
begin
  FillChar(BuildInfo, SizeOf(BuildInfo), 0);

  pFile := PChar(ParamStr(0));
  dSize := GetFileVersionInfoSize(pFile, dTemp);

  if dSize <> 0 then
  begin
    GetMem(pBuffer, dSize);

    try
      if GetFileVersionInfo(pFile, dTemp, dSize, pBuffer) then
      begin
        if VerQueryValue(pBuffer, '\', Pointer(pInfo), dInfo) then
        begin
          with BuildInfo do
          begin
            biMajor := HiWord(pInfo^.dwFileVersionMS);
            biMinor := LoWord(pInfo^.dwFileVersionMS);
            biRelease := HiWord(pInfo^.dwFileVersionLS);
            biBuild := LoWord(pInfo^.dwFileVersionLS);
            biFull := Format('%d.%d.%d.%d', [biMajor, biMinor, biRelease,
              biBuild]);
            biNoBuild := Format('%d.%d.%d', [biMajor, biMinor, biRelease]);
            biCute := Format('%d.%d%d', [biMajor, biMinor, biRelease]);
          end;
        end;
      end;
    finally
      FreeMem(pBuffer, dSize);
    end;
  end;
end;


{ **
  * Method which will find the last position of a char of a given string.
  * ---
  * @param: Char    -  Substr  - The character which to look for.
  * @param: String  - S       - The String (Haystack) where to look for the Substr.
  ** }
function LastPos(const Substr: char; const S: string): integer;
begin
  for Result := Length(S) downto 1 do
  begin
    if S[Result] = Substr then
    begin
      Break;
    end;
  end;
end;

end.

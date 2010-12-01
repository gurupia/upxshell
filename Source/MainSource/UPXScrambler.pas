
unit UPXScrambler;

interface

uses
  Classes, SysUtils;

function fScrambleUPX(const FileName: string): boolean;

implementation


function fScrambleUPX(const FileName: string): boolean;
var
  fsSource: TFileStream;
  GlobalChain: array [1 .. $2BE0] of AnsiChar;
  PosString: integer;
  FileSize: Int64;
begin
  Result := False;
  try
    fsSource := TFileStream.Create(FileName, fmOpenReadWrite);
    FileSize := fsSource.Size;
    // Scramble UPX0 -> code | UPX0 located in upx v0.6 until present
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('UPX0', GlobalChain) <> 0 then
    begin
      PosString := pos('UPX0', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write('CODE', 4);
      Result := True;
    end;
    // Scramble UPX1 -> text | UPX1 located in upx v0.6 until present
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('UPX1', GlobalChain) <> 0 then
    begin
      PosString := pos('UPX1', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write('DATA', 4);
      Result := True;
    end;
    // Scramble UPX2 -> data | UPX2 located in upx v0.6 until v1.0x
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('UPX2', GlobalChain) <> 0 then
    begin
      PosString := pos('UPX2', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write('BSS'#$00, 4);
      Result := True;
    end;
    // Scramble UPX3 -> data | UPX3 located in upx v0.7x i think.
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('UPX3', GlobalChain) <> 0 then
    begin
      PosString := pos('UPX3', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write('IDATA', 5);
      Result := True;
    end;
    // Scramble OLD '$Id: UPXScrambler.pas,v 1.14 2007/01/23 21:43:50 dextra Exp $Id: UPX' located in upx v0.06 until v1.07x
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('$Id: UPX', GlobalChain) <> 0 then
    begin
      // Start '$Id: UPX'
      PosString := pos('$Id: UPX', GlobalChain);
      fsSource.Position := PosString - 1;
      // Write 13 times 0 becouse of the version string removal.
      fsSource.Write(#0#0#0#0#0#0#0#0#0#0#0#0#0, 13);
      // Start 'UPX!'
      PosString := pos('UPX!', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write(#0#0#0#0#0#0, 6);
      Result := True;
    end
    else
    begin
      // Scramble NEW UPX! -> nil | UPX! located in upx v1.08 until present
      if pos('UPX!', GlobalChain) <> 0 then
      begin
        // -6 Becouse of the version string removal.
        PosString := pos('UPX!', GlobalChain);
        fsSource.Position := PosString - 6;
        fsSource.Write(#0#0#0#0#0#0#0#0#0#0#0, 11);
        Result := True;
      end;
    end;
    // Scramble anything that is left of something called UPX within the header
    fsSource.Position := 0;
    fsSource.ReadBuffer(GlobalChain, FileSize);
    if pos('UPX', GlobalChain) <> 0 then
    begin
      PosString := pos('UPX', GlobalChain);
      fsSource.Position := PosString - 1;
      fsSource.Write(#0#0#0, 3);
      Result := True;
    end;
  finally
    FreeAndNil(fsSource);
  end;
end;

end.



unit LocalizerFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, Globals, Shared;

type
  TLocalizerForm = class(TForm)
    pnlControlName: TPanel;
    pnlOk:          TPanel;
    btnOk:          TButton;
    scbProps:       TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
  private
    procedure InitControlEditors();
    procedure SaveControlEditors();
  public
    FMode:    TLocalizerFormMode;
    FControl: TComponentProperties;
  end;

var
  LocalizerForm: TLocalizerForm;

implementation

{$R *.dfm}

procedure TLocalizerForm.FormCreate(Sender: TObject);
var
  Save: longint;
begin
  //Removes the header from the form
  if BorderStyle = bsNone then
  begin
    Exit;
  end;
  Save := GetWindowLong(Handle, GWL_STYLE);
  if (Save and WS_CAPTION) = WS_CAPTION then
  begin
    case BorderStyle of
      bsSingle, bsSizeable:
      begin
        SetWindowLong(Handle, GWL_STYLE,
          Save and (not WS_CAPTION) or WS_BORDER);
      end;
      bsDialog:
      begin
        SetWindowLong(Handle, GWL_STYLE,
          Save and (not WS_CAPTION) or DS_MODALFRAME or WS_DLGFRAME);
      end;
    end;
    Height := Height - GetSystemMetrics(SM_CYCAPTION);
    Refresh;
  end;
end;

procedure TLocalizerForm.InitControlEditors;

  procedure CreateEditor(const Prop: TComponentProperty; Index: integer; EditLeft: integer = 80; EditWidth: integer = 230; const LabelHint: string = '');
  var
    lblTmp: TLabel;
    txtTmp: TEdit;
  begin
    lblTmp          := TLabel.Create(self);
    lblTmp.Name     := 'lbl' + Prop.Name;
    lblTmp.Visible  := False;
    lblTmp.Parent   := scbProps;
    lblTmp.Top      := 12 + (24 * Index);
    lblTmp.Left     := 8;
    lblTmp.Caption  := Prop.Name;
    lblTmp.Hint     := LabelHint;
    lblTmp.ShowHint := True;
    lblTmp.AutoSize := True;
    lblTmp.Font.Style := [fsBold];
    lblTmp.Visible  := True;

    txtTmp         := TEdit.Create(self);
    txtTmp.Name    := 'edt' + Prop.Name;
    txtTmp.Visible := False;
    txtTmp.Parent  := scbProps;
    txtTmp.Top     := 8 + (24 * Index);
    txtTmp.Left    := EditLeft;
    txtTmp.Height  := 21;
    txtTmp.Width   := EditWidth;
    txtTmp.Text    := StringEncode(Prop.Value);
    txtTmp.Visible := True;
  end;

var
  I:    integer;
  Prop: TComponentProperty;
begin
  if FMode = lfmProperties then
  begin
    pnlControlName.Caption := self.FControl.Name;
    for I := 0 to high(FControl.Properties) do
    begin
      CreateEditor(FControl.Properties[I], I);
    end;
  end
  else
  if FMode = lfmMessages then
  begin
    // quadruple the size of the form
    Left       := Left mod 2;
    Width      := Width * 2;
    Top        := Top mod 2;
    Height     := Height * 2;
    btnOk.Left := btnOk.Left * 2;

    pnlControlName.Caption := 'UPX Shell Messages';

    for I := 1 to high(Globals.Messages) do
    begin
      if Globals.Messages[I] <> '' then
      begin
        Prop.Value := Globals.Messages[I];
      end
      else
      begin
        Prop.Value := Globals.EngMsgs[I];
      end;
      Prop.Name := 'msg' + IntToStr(I);
      CreateEditor(Prop, I - 1, 60, 580, Prop.Value);
    end;
  end;
end;

procedure TLocalizerForm.FormShow(Sender: TObject);
begin
  InitControlEditors();
end;

procedure TLocalizerForm.btnOkClick(Sender: TObject);
begin
  SaveControlEditors();
end;

procedure TLocalizerForm.SaveControlEditors;
var
  I: integer;
begin
  if FMode = lfmProperties then
  begin
    for I := 0 to high(FControl.Properties) do
    begin
      FControl.Properties[I].Value :=
        StringDecode(TEdit(self.FindComponent('edt' + FControl.Properties[I].Name)).Text);
    end;
  end
  else
  if FMode = lfmMessages then
  begin
    for I := 1 to high(Globals.Messages) do
    begin
      Globals.Messages[I] :=
        StringDecode(TEdit(self.FindComponent('edt' + 'msg' + IntToStr(I))).Text);
    end;
  end;
end;

end.

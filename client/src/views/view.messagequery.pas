unit View.MessageQuery; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, 
  Buttons; 
 
type 
  TMessageQueryIcon = (icQuestion, icPositive, icWarning, icNegative); 
 
  { TMessageQuery } 
 
  TMessageQuery = class(TForm) 
    imgCancel: TImage; 
    imgYes: TImage; 
    imgNo: TImage; 
    imgAviso: TImage; 
    ImageListIcones: TImageList; 
    ImageListMaior: TImageList; 
    lblMsgCancel: TLabel; 
    lblMsgYes: TLabel; 
    lblMensagem1: TLabel; 
    lblMensagem2: TLabel; 
    lblMsgNo: TLabel; 
    panBotaoCancel: TPanel; 
    panBotaoYes: TPanel; 
    panBotaoNo: TPanel; 
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); 
    procedure FormShow(Sender: TObject); 
    procedure panBotaoCancelClick(Sender: TObject); 
    procedure panBotaoCancelMouseEnter(Sender: TObject); 
    procedure panBotaoCancelMouseLeave(Sender: TObject); 
    procedure panBotaoNoClick(Sender: TObject); 
    procedure panBotaoNoMouseEnter(Sender: TObject); 
    procedure panBotaoNoMouseLeave(Sender: TObject); 
    procedure panBotaoYesClick(Sender: TObject); 
    procedure panBotaoYesEnter(Sender: TObject); 
    procedure panBotaoYesExit(Sender: TObject); 
  private 
    FRetorno: TModalResult; 
    FBotao: Integer; 
  public 
    constructor Create(AOwner: TComponent); override; 
    property Retorno: TModalResult read FRetorno; 
  end; 
 
  function ShowMessageQuery(AOwner: TWinControl; 
                            ATitle: string; 
                            AMessage: string; 
                            AButtonYesText: string = 'Sim'; 
                            AButtonNoText: string = 'Não'; 
                            AButtonCancelText: string = 'Cancelar'; 
                            AIconType: TMessageQueryIcon = icQuestion): TModalResult; 
 
  function ShowMessageSimple(AOwner: TWinControl; 
                            AMessage: string; 
                            AIconType: TMessageQueryIcon = icPositive): TModalResult; 
 
var 
  MessageQuery: TMessageQuery; 
 
implementation 
 
function ShowMessageQuery(AOwner: TWinControl; ATitle: string; 
  AMessage: string; AButtonYesText: string; AButtonNoText: string; 
  AButtonCancelText: string; AIconType: TMessageQueryIcon): TModalResult; 
var 
  f: TMessageQuery; 
begin 
  Result := mrCancel; 
  f := TMessageQuery.Create(AOwner); 
  f.Caption := ATitle; 
  f.lblMensagem1.Caption := AMessage; 
  f.lblMensagem2.Caption := AMessage; 
  f.lblMsgCancel.Caption := AButtonCancelText; 
  f.lblMsgNo.Caption := AButtonNoText; 
  f.lblMsgYes.Caption := AButtonYesText; 
  f.imgAviso.ImageIndex := Ord(AIconType); 
  f.ShowModal; 
  Result := f.Retorno; 
  f.Free; 
end; 
 
function ShowMessageSimple(AOwner: TWinControl; AMessage: string;
                           AIconType: TMessageQueryIcon): TModalResult;
var 
  f: TMessageQuery; 
begin 
  Result := mrCancel; 
  f := TMessageQuery.Create(AOwner); 
  f.Caption := ''; 
  f.lblMensagem1.Caption := AMessage; 
  f.lblMensagem2.Caption := AMessage; 
  f.lblMsgCancel.Caption := ''; 
  f.lblMsgNo.Caption := ''; 
  f.lblMsgYes.Caption := 'OK'; 
  f.imgAviso.ImageIndex := Ord(AIconType); 
  f.ShowModal; 
  Result := f.Retorno; 
  f.Free; 
end; 
 
{$R *.lfm} 
 
{ TMessageQuery } 
 
constructor TMessageQuery.Create(AOwner: TComponent); 
begin 
  inherited Create(AOwner); 
  FRetorno := mrCancel; 
  FBotao := -1; 
end; 
 
procedure TMessageQuery.FormShow(Sender: TObject); 
begin 
  if Trim(Caption) = '' then Caption := 'Atenção'; 
  panBotaoCancel.Visible := Length(Trim(lblMsgCancel.Caption))>0; 
  panBotaoNo.Visible := Length(Trim(lblMsgNo.Caption))>0; 
  if Trim(lblMsgYes.Caption) = '' then 
    lblMsgYes.Caption := 'OK'; 
  if not panBotaoCancel.Visible and not panBotaoNo.Visible then begin 
    panBotaoYes.Left := panBotaoNo.Left; 
    lblMsgYes.Left := 55; 
  end; 
end; 
 
procedure TMessageQuery.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState); 
begin 
  if Key = 13 then 
  case FBotao of 
    1: 
      begin 
        FRetorno := mrCancel; 
        Close; 
      end; 
    2: 
      begin 
        FRetorno := mrNo; 
        Close; 
      end; 
    3: 
      begin 
        FRetorno := mrYes; 
        Close; 
      end; 
  end; 
end; 
 
{  BOTÃO CANCELAR } 
procedure TMessageQuery.panBotaoCancelClick(Sender: TObject); 
begin 
  FRetorno := mrCancel; 
  Close; 
end; 
 
procedure TMessageQuery.panBotaoCancelMouseEnter(Sender: TObject); 
begin 
  panBotaoCancel.Color := clSkyBlue; 
  panBotaoNo.Color := clBtnFace; 
  panBotaoYes.Color := clBtnFace; 
  FBotao := 1; 
end; 
 
procedure TMessageQuery.panBotaoCancelMouseLeave(Sender: TObject); 
begin 
  panBotaoCancel.Color := clBtnFace; 
  FBotao := -1; 
end; 
 
{ BOTÃO NO } 
 
procedure TMessageQuery.panBotaoNoClick(Sender: TObject); 
begin 
  FRetorno := mrNo; 
  Close; 
end; 
 
procedure TMessageQuery.panBotaoNoMouseEnter(Sender: TObject); 
begin 
  panBotaoCancel.Color := clBtnFace; 
  panBotaoNo.Color := clSkyBlue; 
  panBotaoYes.Color := clBtnFace; 
  FBotao := 2; 
end; 
 
procedure TMessageQuery.panBotaoNoMouseLeave(Sender: TObject); 
begin 
  panBotaoNo.Color := clBtnFace; 
  FBotao := -1; 
end; 
 
{ BOTÃO YES } 
 
procedure TMessageQuery.panBotaoYesClick(Sender: TObject); 
begin 
  FRetorno := mrYes; 
  Close; 
end; 
 
procedure TMessageQuery.panBotaoYesEnter(Sender: TObject); 
begin 
  panBotaoCancel.Color := clBtnFace; 
  panBotaoNo.Color := clBtnFace; 
  panBotaoYes.Color := clSkyBlue; 
  FBotao := 3; 
end; 
 
procedure TMessageQuery.panBotaoYesExit(Sender: TObject); 
begin 
  panBotaoYes.Color := clBtnFace; 
  FBotao := -1; 
end; 
 
end. 
 


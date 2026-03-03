unit ChatCardMessage;

(*
  Card de mensagem do chat
  Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, Graphics, LCLType, LCLIntf, DateUtils;

type
  TOnClickDeleteEvent  = procedure(AIdChat: Integer; AFileName: string) of object;
  TChatCardMessageStatus = (msUnread, msRead);

  { TChatCardMessage }

  TChatCardMessage = class(TCustomControl)
  private
    FCanDelete: Boolean;
    FAlreadyDeleted: Boolean;
    FImageList: TImageList;
    FImageListIndex: Integer;
    FRemoveBtn: TImage;
    FObjetoPronto: Boolean;
    FMouseEnter: Boolean;
    FColorForMe: TColor;
    FColorForOther: TColor;
    FText: string;
    FTime: String;
    FNomeRemetente: string;
    FIsMine: Boolean;
    FInitialDate: Boolean;
    FStatus: TChatCardMessageStatus;
    FIdChat: Integer;
    FDeletedFrase: string;

    procedure AjustarPosicao;
    function NomeMes(AMes: Integer): string;
    function NomeRemetente(ANome: string): string;
    function EmojiLineHeight(const AFont: TFont): Integer;
    procedure SetAlreadyDeleted(AValue: Boolean);
    procedure SetColorForMe(AValue: TColor);
    procedure SetColorForOther(AValue: TColor);
    procedure SetImageList(AValue: TImageList);
    procedure SetImageListIndex(AValue: Integer);
    procedure SetIsMine(AValue: Boolean);
    procedure SetStatus(AValue: TChatCardMessageStatus);
    procedure ClickDeleteMessage(Sender: TObject);
    procedure OnMouseEnter(Sender: TObject);
    procedure OnMouseLeave(Sender: TObject);
  protected
    procedure Paint; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Resize; override;
  public
    OnClickDeleteMessage: TOnClickDeleteEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ImageList: TImageList read FImageList write SetImageList;
    property ImageListIndex: Integer read FImageListIndex write SetImageListIndex;
    property CanDelete: Boolean read FCanDelete write FCanDelete;
    procedure CalculateSize;
    property ChatID: Integer read FIdChat;
    property ColorForMe: TColor read FColorForMe write SetColorForMe;
    property ColorForOther: TColor read FColorForOther write SetColorForOther;
    property Deleted: Boolean read FAlreadyDeleted write SetAlreadyDeleted;
    procedure InitialDate(ADate: TDateTime);
    property IsInitialDate: Boolean read FInitialDate;
    property IsMine: Boolean read FIsMine write SetIsMine;
    property Status: TChatCardMessageStatus read FStatus write SetStatus;
    procedure Setup(AIdChat, ASenderID: Integer; ASenderName, AMessage: string;
                    ATime: TDateTime; AIsMine: Boolean;
                    ADeleted: Boolean;
                    AStatus: TChatCardMessageStatus);
  end;

implementation

{ TChatCardMessage }

constructor TChatCardMessage.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FObjetoPronto := False;
  FMouseEnter := False;
  ControlStyle := ControlStyle + [csOpaque];

  TabStop := False;
  ParentFont := False;
  FInitialDate := False;
  FTime := FormatDateTime('hh:nn', Now);
  FCanDelete := False;
  FAlreadyDeleted := False;
  FDeletedFrase := 'Deletado';

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := clNone;
  AutoSize := False;
  Constraints.MaxWidth := 260; // será ajustado pelo form

  FColorForMe := $00E6FCD5;
  FColorForOther := $00F3F4E0;

  // Remover
  FRemoveBtn := TImage.Create(Self);
  FRemoveBtn.Parent := Self;
  FRemoveBtn.Cursor := crHandPoint;
  FRemoveBtn.Left := Width - 20;
  FRemoveBtn.Top := 5;
  FRemoveBtn.Height := 15;
  FRemoveBtn.Width := 15;
  FRemoveBtn.Stretch := True;
  FRemoveBtn.Transparent := True;
  FRemoveBtn.Hint := 'Apagar esta mensagem';
  FRemoveBtn.ShowHint := True;
  FRemoveBtn.Visible := False;
  FRemoveBtn.OnClick := @ClickDeleteMessage;
  FRemoveBtn.OnMouseEnter := @OnMouseEnter;
  FRemoveBtn.OnMouseLeave := @OnMouseLeave;

  FObjetoPronto := True;
end;

destructor TChatCardMessage.Destroy;
begin
  inherited Destroy;
end;

procedure TChatCardMessage.Setup(AIdChat, ASenderID: Integer; ASenderName,
  AMessage: string; ATime: TDateTime; AIsMine: Boolean; ADeleted: Boolean;
  AStatus: TChatCardMessageStatus);
begin
  FIdChat := AIdChat;
  FNomeRemetente := NomeRemetente(ASenderName);
  FText := Trim(AMessage);
  FTime := FormatDateTime('hh:nn', ATime); // yyyy-mm-dd hh:nn:ss
  FIsMine := AIsMine;
  FStatus := AStatus;
  FAlreadyDeleted := ADeleted;
  FInitialDate := False;

  if ADeleted then FCanDelete := False;

  AjustarPosicao;
  CalculateSize;
  Invalidate;
end;

procedure TChatCardMessage.CalculateSize;
var
  R: TRect;
begin
  if not HandleAllocated then Exit;

  Canvas.Font.Assign(Font);

  R := Rect(0, 0, Constraints.MaxWidth - 20, 0);

  DrawText(Canvas.Handle, PChar(FText), -1, R, DT_WORDBREAK or DT_CALCRECT);

  if FInitialDate then begin
    Width  := R.Width + 20;
    Height := R.Height + 3;
  end else begin
    Width  := R.Width + 24;
    if Width < 100 then Width := 100;
    if (FNomeRemetente <> '') and (not FIsMine) and (Width <= 100) then Width := 160;
    Height := R.Height + 25; // espaço para hora + check
  end;
end;

procedure TChatCardMessage.InitialDate(ADate: TDateTime);
begin
  FInitialDate := True;

  if FormatDateTime('yyyy-mm-dd', now) = FormatDateTime('yyyy-mm-dd', ADate) then
    FText := 'Hoje'
  else
    FText := FormatDateTime('dd', ADate) + ' de ' + NomeMes(MonthOf(ADate)) + ' de ' + FormatDateTime('yyyy', ADate);

  FTime := FormatDateTime('hh:nn', ADate);
  FIdChat := 0;
  CalculateSize;
  Invalidate;
end;

function TChatCardMessage.NomeMes(AMes: Integer): string;
var
  lang: string;
begin
  lang := 'br';
  Result := '';
  // Result := DefaultFormatSettings.LongMonthNames[AMes];
  case AMes of
     1: begin
          Result := 'Janeiro';
          if lang = 'en' then Result := 'January';
          if lang = 'es' then Result := 'Enero';
        end;
     2: begin
          Result := 'Fevereiro';
          if lang = 'en' then Result := 'February';
          if lang = 'es' then Result := 'Febrero';
        end;
     3: begin
          Result := 'Março';
          if lang = 'en' then Result := 'March';
          if lang = 'es' then Result := 'Marzo';
        end;
     4: begin
          Result := 'Abril';
          if lang = 'en' then Result := 'Abril';
          if lang = 'es' then Result := 'Abril';
        end;
     5: begin
          Result := 'Maio';
          if lang = 'en' then Result := 'May';
          if lang = 'es' then Result := 'Mayo';
        end;
     6: begin
          Result := 'Junho';
          if lang = 'en' then Result := 'June';
          if lang = 'es' then Result := 'Junio';
        end;
     7: begin
          Result := 'Julho';
          if lang = 'en' then Result := 'July';
          if lang = 'es' then Result := 'Julio';
        end;
     8: begin
          Result := 'Agosto';
          if lang = 'en' then Result := 'August';
          if lang = 'es' then Result := 'Agosto';
        end;
     9: begin
          Result := 'Setembro';
          if lang = 'en' then Result := 'September';
          if lang = 'es' then Result := 'Septiembre';
        end;
    10: begin
          Result := 'Outubro';
          if lang = 'en' then Result := 'October';
          if lang = 'es' then Result := 'Octubre';
        end;
    11: begin
          Result := 'Novembro';
          if lang = 'en' then Result := 'November';
          if lang = 'es' then Result := 'Noviemre';
        end;
    12: begin
          Result := 'Dezembro';
          if lang = 'en' then Result := 'December';
          if lang = 'es' then Result := 'Diciembre';
        end;
  end;
end;

function TChatCardMessage.NomeRemetente(ANome: string): string;
var
  s: array of string;
  i: integer;
begin
  Result := '';
  ANome  := Trim(ANome);
  s := ANome.Split([' '], TStringSplitOptions.ExcludeEmpty);
  i := High(s);

  if i = 0 then
    Result := s[0]
  else if i > 0 then
    Result := s[0] + ' ' + s[i];
end;

procedure TChatCardMessage.AjustarPosicao;
begin
  if not FObjetoPronto then Exit;
  // botão de excluir o usuário
  FRemoveBtn.Visible := False;
  if not FMouseEnter then Exit;
  if Assigned(FRemoveBtn) and not FAlreadyDeleted and FCanDelete then begin
    if (FImageListIndex >= 0) then begin
      FRemoveBtn.Images := FImageList;
      FRemoveBtn.ImageIndex := FImageListIndex;
    end;

    FRemoveBtn.Left := Width - 20;
    FRemoveBtn.Top := 5;
    FRemoveBtn.Visible := True;
  end;
end;

function TChatCardMessage.EmojiLineHeight(const AFont: TFont): Integer;
begin
  Result := Round(Canvas.TextHeight('Ag') * 1.5);
end;

procedure TChatCardMessage.SetAlreadyDeleted(AValue: Boolean);
begin
  if FAlreadyDeleted = AValue then Exit;
  FAlreadyDeleted := AValue;
  FCanDelete := not AValue;
  Invalidate;
end;

procedure TChatCardMessage.SetColorForMe(AValue: TColor);
begin
  if FColorForMe = AValue then Exit;
  FColorForMe := AValue;
  Invalidate;
end;

procedure TChatCardMessage.SetColorForOther(AValue: TColor);
begin
  if FColorForOther = AValue then Exit;
  FColorForOther := AValue;
  Invalidate;
end;

procedure TChatCardMessage.SetImageList(AValue: TImageList);
begin
  if FImageList = AValue then Exit;
  FImageList := AValue;
end;

procedure TChatCardMessage.SetImageListIndex(AValue: Integer);
begin
  if FImageListIndex = AValue then Exit;
  FImageListIndex := AValue;
end;

procedure TChatCardMessage.SetIsMine(AValue: Boolean);
begin
  if FIsMine = AValue then Exit;
  FIsMine := AValue;
  Invalidate;
end;

procedure TChatCardMessage.SetStatus(AValue: TChatCardMessageStatus);
begin
  if FStatus = AValue then Exit;
  FStatus := AValue;
  Invalidate;
end;

procedure TChatCardMessage.ClickDeleteMessage(Sender: TObject);
begin
  if Assigned(OnClickDeleteMessage) and not FAlreadyDeleted then
    OnClickDeleteMessage(FIdChat, '');
end;

procedure TChatCardMessage.OnMouseEnter(Sender: TObject);
begin
  FMouseEnter := True;
  AjustarPosicao;
end;

procedure TChatCardMessage.OnMouseLeave(Sender: TObject);
begin
  FMouseEnter := False;
  AjustarPosicao;
end;

procedure TChatCardMessage.MouseEnter;
begin
  inherited MouseEnter;
  FMouseEnter := True;
  AjustarPosicao
end;

procedure TChatCardMessage.MouseLeave;
begin
  inherited MouseLeave;
  FMouseEnter := False;
  AjustarPosicao
end;

procedure TChatCardMessage.Resize;
begin
  inherited Resize;
end;

procedure TChatCardMessage.Paint;
var
  BubbleRect, TextRect: TRect;
  BubbleColor, TextColor: TColor;
  CheckStr, lMessage: string;
  LineHeight: Integer;
begin
  // inherited Paint;
  // para evitar "fantasmas" nos cantos
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  lMessage := FText;

  if FIsMine then begin
    BubbleColor := FColorForMe;
    TextColor := clBlack;
  end else begin
    BubbleColor := FColorForOther;
    TextColor := clBlack;
  end;

  if FInitialDate then begin
    BubbleColor := $00FBFBFB;
    TextColor := clGray;
  end;

  if FAlreadyDeleted then begin
    // mensagem deletada
    BubbleColor := $00DEDEDE;
    TextColor := $00292994;
    lMessage := FDeletedFrase;
  end;

  BubbleRect := Rect(0, 0, Width, Height);

  // Fundo
  Canvas.Brush.Color := BubbleColor;
  Canvas.Pen.Color := BubbleColor;
  Canvas.RoundRect(BubbleRect, 12, 12);

  // borda
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := $00E0E0E0;
  Canvas.RoundRect(BubbleRect, 12, 12);

  // Texto
  // Canvas.Font.Size := Self.Font.Size;
  Canvas.Font.Color := TextColor;

  if FInitialDate then begin
    Canvas.Font.Size := 8;
    TextRect := Rect(2, 2, Width - 2, Height - 2);
    DrawText(Canvas.Handle, PChar(lMessage), -1, TextRect, DT_CENTER);
  end
  else begin
    LineHeight := EmojiLineHeight(Canvas.Font);
    TextRect := Rect(10, 6, Width - 10, Height + LineHeight - 22);
    DrawText(Canvas.Handle, PChar(lMessage), -1, TextRect, DT_WORDBREAK);
  end;

  if FInitialDate or FAlreadyDeleted then Exit;

  // Remetente, Hora e check
  Canvas.Font.Size := 8;
  Canvas.Font.Color := clGray;

  // rementente
  if not FIsMine and (FNomeRemetente <> '') then
    Canvas.TextOut(10, Height - 16, FNomeRemetente);

  // Check
  if FIsMine then begin
    Canvas.TextOut(Width - Canvas.TextWidth(FTime) - 28, Height - 16, FTime);
    Canvas.Font.Color := clGray;

    if FStatus = msRead then begin
      Canvas.Font.Color := clGreen;
      CheckStr := '✓✓';
    end
    else
      CheckStr := '✓';

    Canvas.TextOut(Width - 24, Height - 16, CheckStr);
  end else
    Canvas.TextOut(Width - Canvas.TextWidth(FTime) - 6, Height - 16, FTime);
end;

end.


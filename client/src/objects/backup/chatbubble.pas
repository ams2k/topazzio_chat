unit ChatBubble;

{$mode objfpc}{$H+}

{
  Componente para exibir a mensagem do chat na lista
}

interface

uses
  Classes, SysUtils, Controls, Graphics, LCLType, LCLIntf, DateUtils;

type
  TBubbleMessageStatus = (msSent, msRead);

  { TChatBubble }

  TChatBubble = class(TCustomControl)
  private
    FText: string;
    FTime: String;
    FNomeRemetente: string;
    FIsMine: Boolean;
    FInitialDate: Boolean;
    FStatus: TBubbleMessageStatus;
    FIdChat: Integer;
    function NomeMes(AMes: Integer): string;
    function NomeRemetente(ANome: string): string;
    function EmojiLineHeight(const AFont: TFont): Integer;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure CalculateSize;
    procedure InitialDate(ADate: TDateTime);
    procedure Setup(AIdChat: Integer; ANomeRemetente, AMsg: string; ATime: String; AIsMine: Boolean; AStatus: TBubbleMessageStatus);
    property IsMine: Boolean read FIsMine write FIsMine;
    property Status: TBubbleMessageStatus read FStatus write FStatus;
    property IsInitialDate: Boolean read FInitialDate;
  end;

implementation

{ TChatBubble }

constructor TChatBubble.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle := ControlStyle + [csOpaque];

  TabStop := False;
  //Enabled := False;
  ParentFont := False;
  FInitialDate := False;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color := clNone;
  AutoSize := False;
  Constraints.MaxWidth := 360; // será ajustado pelo form
end;

procedure TChatBubble.Setup(AIdChat: Integer; ANomeRemetente,AMsg: string; ATime: String; AIsMine: Boolean; AStatus: TBubbleMessageStatus);
begin
  FIdChat := AIdChat;
  FNomeRemetente := NomeRemetente(ANomeRemetente);
  FText := AMsg;
  FTime := ATime;
  FIsMine := AIsMine;
  FStatus := AStatus;

  FInitialDate := False;

  CalculateSize;
  Invalidate;
end;

procedure TChatBubble.CalculateSize;
var
  R: TRect;
begin
  if not HandleAllocated then Exit;

  Canvas.Font.Assign(Font);

  R := Rect(0, 0, Constraints.MaxWidth - 20, 0);

  DrawText(Canvas.Handle, PChar(FText), -1, R, DT_WORDBREAK or DT_CALCRECT);

  if FInitialDate then begin
    Width  := R.Width + 20;
    Height := R.Height + 8;
  end else begin
    Width  := R.Width + 24;
    if Width < 100 then Width := 100;
    if (FNomeRemetente <> '') and (Width <= 100) then Width := 160;
    Height := R.Height + 25; // espaço para hora + check
  end;
end;

procedure TChatBubble.InitialDate(ADate: TDateTime);
begin
  FInitialDate := True;
  FText := FormatDateTime('dd', ADate) + ' de ' + NomeMes(MonthOf(ADate)) + ' de ' + FormatDateTime('yyyy', ADate);
  FIdChat := 0;
  CalculateSize;
  Invalidate;
end;

function TChatBubble.NomeMes(AMes: Integer): string;
begin
  //Result := DefaultFormatSettings.LongMonthNames[AMes];
  case AMes of
     1: Result := 'Janeiro';
     2: Result := 'Fevereiro';
     3: Result := 'Março';
     4: Result := 'Abril';
     5: Result := 'Maio';
     6: Result := 'Junho';
     7: Result := 'Julho';
     8: Result := 'Agosto';
     9: Result := 'Setembro';
    10: Result := 'Outubro';
    11: Result := 'Novembro';
    12: Result := 'Dezembro';
  else
    Result := '';
  end;
end;

function TChatBubble.NomeRemetente(ANome: string): string;
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

function TChatBubble.EmojiLineHeight(const AFont: TFont): Integer;
begin
  Result := Round(Canvas.TextHeight('Ag') * 1.5);
end;

procedure TChatBubble.Paint;
var
  BubbleRect, TextRect: TRect;
  BubbleColor, TextColor: TColor;
  CheckStr: string;
  LineHeight: Integer;
begin
  //inherited Paint;
  //para evitar "fantasmas" nos cantos
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  if FIsMine then begin
    BubbleColor := $00E6FCD5; // $00DCF8C6; // verde WhatsApp
    TextColor := clBlack;
  end else begin
    BubbleColor := $00F3F4E0; // $00EBECD8; //azul claro
    TextColor := clBlack;
  end;

  if FInitialDate then begin
    BubbleColor := $00FBFBFB;
    TextColor := clGray;
  end;

  BubbleRect := Rect(0, 0, Width, Height);

  // Fundo
  Canvas.Brush.Color := BubbleColor;
  Canvas.Pen.Color := BubbleColor;
  Canvas.RoundRect(BubbleRect, 12, 12);

  //borda
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := $00E0E0E0;
  Canvas.RoundRect(BubbleRect, 12, 12);

  // Texto
  //Canvas.Font.Size := Self.Font.Size;
  Canvas.Font.Color := TextColor;

  if FInitialDate then begin
    Canvas.Font.Size := 8;
    TextRect := Rect(2, 2, Width - 2, Height - 2);
    DrawText(Canvas.Handle, PChar(FText), -1, TextRect, DT_CENTER);
  end
  else begin
    LineHeight := EmojiLineHeight(Canvas.Font);
    TextRect := Rect(10, 6, Width - 10, Height + LineHeight - 22);
    DrawText(Canvas.Handle, PChar(FText), -1, TextRect, DT_WORDBREAK);
  end;

  if FInitialDate then Exit;

  // Remetente, Hora e check
  Canvas.Font.Size := 8;
  Canvas.Font.Color := clGray;

  //rementente
  if not FIsMine and (FNomeRemetente <> '') then
    Canvas.TextOut(10, Height - 16, FNomeRemetente);

  // Check
  if FIsMine then begin
    Canvas.TextOut(Width - Canvas.TextWidth(FTime) - 28, Height - 16, FTime);

    if FStatus = msRead then
      CheckStr := '✓✓'
    else
      CheckStr := '✓';

    Canvas.Font.Color := clGray;
    Canvas.TextOut(Width - 24, Height - 16, CheckStr);
  end else
    Canvas.TextOut(Width - Canvas.TextWidth(FTime) - 6, Height - 16, FTime);
end;

end.


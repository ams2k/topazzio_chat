unit ChatBubbleFile;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Graphics, ImgList, LCLType, LCLIntf, DateUtils;

type
  TOnClickEvent = procedure(AChatID: Integer; AArquivo: string; ASize: Int64) of object;
  TBubbleFileMessageStatus = (msSent, msRead);

  { TChatBubbleFile }

  TChatBubbleFile = class(TCustomControl)
  private
    FImageList: TImageList;

    FIdChat: Integer;
    FFileNameStr: string;
    FFileSizeStr: string;
    FTimeStr: string;
    FFileExt: string;
    FFileSize: Int64;
    FIsMine: Boolean;
    FStatus: TBubbleFileMessageStatus;

    FRadius, FPadding: Integer;
    FImageIndex: Integer;
    FImageWidth: Integer;
    FTextLeft: Integer;

    procedure CalculateSize;
    procedure SetImageList(AValue: TImageList);
    function GetFileIconIndex(const AFileName: string): Integer;
  protected
    procedure Paint; override;
    procedure Click; override;
  public
    OnClickEvent: TOnClickEvent;

    constructor Create(AOwner: TComponent); override;

    property ImageList: TImageList read FImageList write SetImageList;
    property Status: TBubbleFileMessageStatus read FStatus write FStatus;
    property IsMine: Boolean read FIsMine write FIsMine;
    procedure Setup(AIdChat: Integer; AFileName: string; ASize: Int64;
                    ATime: String; AIsMine: Boolean; AStatus: TBubbleFileMessageStatus);
  end;

implementation

{ TChatBubbleFile }

constructor TChatBubbleFile.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  ControlStyle   := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop    := False;
  ParentFont := False;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color     := clNone;
  AutoSize  := False;
  Constraints.MaxWidth  := 360; // será ajustado pelo form
  Constraints.MinHeight := 60;
  ShowHint := True;
  Hint     := '';
  FRadius  := 12;
  FPadding := 10;
  FImageIndex := -1;
  FImageWidth := 32;
  FTextLeft   := FImageWidth + FPadding + 6;
end;

procedure TChatBubbleFile.Setup(AIdChat: Integer; AFileName: string;
                                ASize: Int64; ATime: String; AIsMine: Boolean;
                                AStatus: TBubbleFileMessageStatus);
begin
  FIdChat := AIdChat;
  FFileNameStr := AFileName;
  FFileSize := ASize;
  FTimeStr := ATime;
  FIsMine := AIsMine;
  FStatus := AStatus;
  Hint := 'Enviado por Márcio';

  FFileSizeStr :=  FormatFloat('#,##0 KB', FFileSize / 1024);
  FImageIndex := GetFileIconIndex(AFileName);

  CalculateSize;
  Invalidate;
end;

procedure TChatBubbleFile.SetImageList(AValue: TImageList);
begin
  if FImageList = AValue then Exit;
  FImageList := AValue;
end;

procedure TChatBubbleFile.CalculateSize;
var
  R: TRect;
begin
  if not HandleAllocated then Exit;

  Canvas.Font.Assign(Font);

  R := Rect(FImageWidth + FPadding * 2, 0, Constraints.MaxWidth - 20, 0);

  DrawText(Canvas.Handle, PChar(FFileNameStr), -1, R, DT_WORDBREAK or DT_CALCRECT);

  Width := 300;
  Height := R.Height + 32; // espaço para hora + check
end;

function TChatBubbleFile.GetFileIconIndex(const AFileName: string): Integer;
//obtem o icone conforme extensão do arquivo
begin
  FFileExt := LowerCase( ExtractFileExt(AFileName) );

  if (FFileExt = '.mp3') or (FFileExt = '.wav') then Exit(1);
  if (FFileExt = '.xls') or (FFileExt = '.xlsx') or (FFileExt = '.ods') then Exit(2);
  if (FFileExt = '.png') or (FFileExt = '.jpg') or (FFileExt = '.jpeg') then Exit(3);
  if (FFileExt = '.pdf') then Exit(4);
  if (FFileExt = '.txt') then Exit(5);
  if (FFileExt = '.mp4') or (FFileExt = '.mkv') or (FFileExt = '.avi') then Exit(6);
  if (FFileExt = '.doc') or (FFileExt = '.docx') or (FFileExt = '.odt') then Exit(7);
  if (FFileExt = '.zip') or (FFileExt = '.rar') or (FFileExt = '.gz') then Exit(8);

  Result := 0; //anexo qualquer
end;

procedure TChatBubbleFile.Click;
begin
  inherited Click;
  if Assigned(OnClickEvent) then
    OnClickEvent(FIdChat, FFileNameStr, FFileSize);
end;

procedure TChatBubbleFile.Paint;
var
  BubbleRect, TextRect: TRect;
  BubbleColor, TextColor: TColor;
  CheckStr: string;
begin
  //inherited Paint;
  //para evitar "fantasmas" nos cantos
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  if FIsMine then begin
    BubbleColor := $00E6FCD5; //$00DCF8C6; // verde WhatsApp
    TextColor := clBlack;
  end else begin
    BubbleColor := $00F3F4E0; //$00EBECD8; //azul claro
    TextColor := clBlack;
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

  // ícone
  if Assigned(FImageList) and (FImageIndex >= 0) then
    FImageList.Draw(Canvas, 6, 6, FImageIndex, Enabled);

  // Texto
  Canvas.Font.Size := Self.Font.Size;
  Canvas.Font.Color := TextColor;
  TextRect := Rect(FTextLeft, 6, Width - 10, Height - 22);
  DrawText(Canvas.Handle, PChar(FFileNameStr), -1, TextRect, DT_WORDBREAK);

  // Hora, File Size, Extensão
  Canvas.Font.Size := 8;
  Canvas.Font.Color := clGray;

  //file size
  Canvas.TextOut(10, Height - 16, UpperCase(FFileExt) + ' - ' + FFileSizeStr);

  // Check
  if FIsMine then begin
    Canvas.TextOut(Width - Canvas.TextWidth(FTimeStr) - 28, Height - 16, FTimeStr);

    if FStatus = msRead then
      CheckStr := '✓✓'
    else
      CheckStr := '✓';

    Canvas.Font.Color := clGray;
    Canvas.TextOut(Width - 24, Height - 16, CheckStr);
  end else
    Canvas.TextOut(Width - Canvas.TextWidth(FTimeStr) - 6, Height - 16, FTimeStr);
end;

end.


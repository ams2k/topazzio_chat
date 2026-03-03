unit ChatCardFile;

// Card de mensagem do chat para exibir informações do arquivo enviado

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, ExtCtrls, StdCtrls, Graphics, ImgList, LCLType, LCLIntf, DateUtils;

type
  TOnClickDownloadEvent = procedure(AChatID: Integer; AArquivo: string; ASize: Int64) of object;
  TOnClickDeleteEvent  = procedure(AIdChat: Integer; AFileName: string) of object;
  TChatCardFileStatus = (msUnread, msRead);

  { TChatCardFile }

  TChatCardFile = class(TCustomControl)
  private
    FCanDelete: Boolean;
    FAlreadyDeleted: Boolean;
    FColorForMe: TColor;
    FColorForOther: TColor;
    FImageDeleteList: TImageList;
    FImageDeleteListIndex: Integer;
    FImageFileList: TImageList;
    FImageFileListIndex: Integer;
    FRemoveBtn: TImage;

    FIdChat: Integer;
    FFileNameStr: string;
    FFileSizeStr: string;
    FTimeStr: string;
    FFileExt: string;
    FFileSize: Int64;
    FIsMine: Boolean;
    FStatus: TChatCardFileStatus;

    FRadius, FPadding: Integer;
    FImageIndex: Integer;
    FImageWidth: Integer;
    FTextLeft: Integer;
    FObjetoPronto: Boolean;
    FMouseEnter: Boolean;
    FDeletedFrase: string;

    procedure AjustarPosicao;
    function GetFileSizeText(AValue: Int64): string;
    procedure SetAlreadyDeleted(AValue: Boolean);
    procedure SetColorForMe(AValue: TColor);
    procedure SetColorForOther(AValue: TColor);
    procedure SetImageDeleteList(AValue: TImageList);
    procedure SetImageDeleteListIndex(AValue: Integer);
    procedure SetImageFileList(AValue: TImageList);
    function GetFileIconIndex(const AFileName: string): Integer;
    procedure SetImageFileListIndex(AValue: Integer);
    procedure ClickDeleteMessage(Sender: TObject);
    procedure OnMouseEnter(Sender: TObject);
    procedure OnMouseLeave(Sender: TObject);
  protected
    procedure Paint; override;
    procedure Click; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Resize; override;
  public
    OnClickDownloadEvent: TOnClickDownloadEvent;
    OnClickDeleteMessage: TOnClickDeleteEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    property ImageFileList: TImageList read FImageFileList write SetImageFileList;
    property ImageFileListIndex: Integer read FImageFileListIndex write SetImageFileListIndex;
    property ImageDeleteList: TImageList read FImageDeleteList write SetImageDeleteList;
    property ImageDeleteListIndex: Integer read FImageDeleteListIndex write SetImageDeleteListIndex;
    procedure CalculateSize;
    property CanDelete: Boolean read FCanDelete write FCanDelete;
    property ChatID: Integer read FIdChat;
    property ColorForMe: TColor read FColorForMe write SetColorForMe;
    property ColorForOther: TColor read FColorForOther write SetColorForOther;
    property Deleted: Boolean read FAlreadyDeleted write SetAlreadyDeleted;
    property IsMine: Boolean read FIsMine write FIsMine;
    property Status: TChatCardFileStatus read FStatus write FStatus;
    procedure Setup(AIdChat: Integer; AFileName: string; ASize: Int64;
                    ATime: TDateTime; AIsMine: Boolean; ASentBy: string;
                    ADeleted: Boolean;
                    AStatus: TChatCardFileStatus);
  end;

implementation

{ TChatCardFile }

constructor TChatCardFile.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FObjetoPronto := False;
  FMouseEnter := False;
  ControlStyle   := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop    := False;
  ParentFont := False;

  Font.Name := 'Segoe UI';
  Font.Size := 9;
  Color     := clNone;
  AutoSize  := False;
  Constraints.MaxWidth  := 260; // será ajustado pelo form
  Constraints.MinHeight := 60;
  ShowHint := True;
  Hint     := '';
  FRadius  := 12;
  FPadding := 10;
  FImageIndex := -1;
  FImageWidth := 32;
  FTextLeft   := FImageWidth + FPadding + 6;
  FCanDelete := False;
  FAlreadyDeleted := False;
  FDeletedFrase := 'Deletado';

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

destructor TChatCardFile.Destroy;
begin
  inherited Destroy;
end;

procedure TChatCardFile.Setup(AIdChat: Integer; AFileName: string;
  ASize: Int64; ATime: TDateTime; AIsMine: Boolean; ASentBy: string;
  ADeleted: Boolean; AStatus: TChatCardFileStatus);
begin
  FIdChat := AIdChat;
  FFileNameStr := AFileName;
  FFileSize := ASize;
  FTimeStr := FormatDateTime('hh:nn', ATime);
  FIsMine := AIsMine;
  FStatus := AStatus;
  Hint := 'Enviado por ' + ASentBy;
  FAlreadyDeleted := ADeleted;

  if ADeleted then FCanDelete := False;

  FFileSizeStr := GetFileSizeText(FFileSize);
  FImageIndex := GetFileIconIndex(AFileName);

  AjustarPosicao;
  CalculateSize;
  Invalidate;
end;

procedure TChatCardFile.SetImageFileList(AValue: TImageList);
begin
  if FImageFileList = AValue then Exit;
  FImageFileList := AValue;
end;

procedure TChatCardFile.CalculateSize;
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

function TChatCardFile.GetFileIconIndex(const AFileName: string): Integer;
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

procedure TChatCardFile.SetImageFileListIndex(AValue: Integer);
begin
  if FImageFileListIndex = AValue then Exit;
  FImageFileListIndex := AValue;
end;

procedure TChatCardFile.ClickDeleteMessage(Sender: TObject);
begin
  if Assigned(OnClickDeleteMessage) and not FAlreadyDeleted then
    OnClickDeleteMessage(FIdChat, FFileNameStr);
end;

procedure TChatCardFile.OnMouseEnter(Sender: TObject);
begin
  FMouseEnter := True;
  AjustarPosicao;
end;

procedure TChatCardFile.OnMouseLeave(Sender: TObject);
begin
  FMouseEnter := False;
  AjustarPosicao;
end;

function TChatCardFile.GetFileSizeText(AValue: Int64): string;
//tamanho do arquivo em bytes, Kb, Mb, Gb
var
  lkb, lmb, lgb: Int64;
begin
  lkb := 1024;
  lmb := 1024 * lkb;
  lgb := 1024 * lmb;

  if (AValue < lkb) then
    Result := FormatFloat('0 Bytes', AValue)
  else if (AValue < lmb) then
    Result := FormatFloat('0.0 KB', AValue / lkb)
  else if (AValue < lgb) then
    Result := FormatFloat('0.0 MB', AValue / lmb)
  else
    Result := FormatFloat('0.0 GB', AValue / lgb);
end;

procedure TChatCardFile.SetAlreadyDeleted(AValue: Boolean);
// define como deletada
begin
  if FAlreadyDeleted = AValue then Exit;
  FAlreadyDeleted := AValue;
  FCanDelete := not AValue;
  Invalidate;
end;

procedure TChatCardFile.AjustarPosicao;
begin
  if not FObjetoPronto then Exit;
  // botão de excluir o usuário
  FRemoveBtn.Visible := False;
  if not FMouseEnter then Exit;
  if Assigned(FRemoveBtn) and not FAlreadyDeleted and FCanDelete then begin
    if (FImageDeleteListIndex >= 0) then begin
      FRemoveBtn.Images := FImageDeleteList;
      FRemoveBtn.ImageIndex := FImageDeleteListIndex;
    end;

    FRemoveBtn.Left := Width - 20;
    FRemoveBtn.Top := 5;
    FRemoveBtn.Visible := True;
  end;
end;

procedure TChatCardFile.SetColorForMe(AValue: TColor);
begin
  if FColorForMe = AValue then Exit;
  FColorForMe := AValue;
  Invalidate;
end;

procedure TChatCardFile.SetColorForOther(AValue: TColor);
begin
  if FColorForOther = AValue then Exit;
  FColorForOther := AValue;
  Invalidate;
end;

procedure TChatCardFile.SetImageDeleteList(AValue: TImageList);
begin
  if FImageDeleteList = AValue then Exit;
  FImageDeleteList := AValue;
end;

procedure TChatCardFile.SetImageDeleteListIndex(AValue: Integer);
begin
  if FImageDeleteListIndex = AValue then Exit;
  FImageDeleteListIndex := AValue;
end;

procedure TChatCardFile.Click;
begin
  inherited Click;
  if Assigned(OnClickDownloadEvent) and not FAlreadyDeleted then
    OnClickDownloadEvent(FIdChat, FFileNameStr, FFileSize);
end;

procedure TChatCardFile.MouseEnter;
begin
  inherited MouseEnter;
  FMouseEnter := True;
  AjustarPosicao;
end;

procedure TChatCardFile.MouseLeave;
begin
  inherited MouseLeave;
  FMouseEnter := False;
  AjustarPosicao;
end;

procedure TChatCardFile.Resize;
begin
  inherited Resize;
end;

procedure TChatCardFile.Paint;
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
    BubbleColor := FColorForMe;
    TextColor := clBlack;
  end else begin
    BubbleColor := FColorForOther;
    TextColor := clBlack;
  end;

  if FAlreadyDeleted then begin
    // mensagem deletada
    BubbleColor := $00DEDEDE;
    TextColor := $00292994;
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

  if FAlreadyDeleted then begin
    // Texto
    Canvas.Font.Size := Self.Font.Size;
    Canvas.Font.Color := TextColor;
    TextRect := Rect(10, 6, Width - 10, Height - 22);
    DrawText(Canvas.Handle, PChar(FDeletedFrase), -1, TextRect, DT_WORDBREAK);
    Exit;
  end;

  // ícone
  if Assigned(FImageFileList) and (FImageFileListIndex >= 0) then
    FImageFileList.Draw(Canvas, 6, 6, FImageFileListIndex, Enabled);

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


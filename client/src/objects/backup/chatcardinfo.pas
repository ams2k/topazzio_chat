unit ChatCardInfo;

// Card com dados de mensagens não lidas
// Avatar, nome, data de envio das mensagens e quantidade mensagens não lidas

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Buttons, Graphics,
  LCLType, LCLIntf, Service.Usuario;

type
  TOnClickEvent  = procedure(AChatRoom: string) of object;

  { TChatCardInfo }

  TChatCardInfo = class(TCustomControl)
  private
    FBackColor: TColor;
    FSelectedColor: TColor;
    FServiceUsuario: TServiceUsuario;
    FAvatar: TImage;
    FNameLabel: TLabel;
    FDateLabel: TLabel;
    FUnreadShape: TShape;
    FUnreadBadge: TLabel;

    FIdUser: Integer;
    FUserName: string;
    FUnreadCount: Integer;
    FChatRoom: string;
    FObjetoPronto: Boolean;
    FMouseEnter: Boolean;
    FSelected: Boolean;

    function AlterarCor(AColor: TColor; AEscurecer: Boolean; APercent: byte): TColor;
    function GetAvatarBitmap: TBitmap;
    procedure Operacao_Start;
    procedure Operacao_End;
    procedure OnClickComum(Sender: TObject);
    procedure OnMouseEnter(Sender: TObject);
    procedure OnMouseLeave(Sender: TObject);
    procedure SetBackColor(AValue: TColor);
    procedure SetSelected(AValue: Boolean);
    procedure SetSelectedColor(AValue: TColor);
  protected
    procedure Click; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Paint; override;
    procedure Resize; override;
  public
    OnClickInfo: TOnClickEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property BackColor: TColor read FBackColor write SetBackColor;
    property Selected: Boolean read FSelected write SetSelected default False;
    property SelectedColor: TColor read FSelectedColor write SetSelectedColor;
    property RoomName: string read FChatRoom;
    property User_ID: Integer read FIdUser;
    property User_Name: string read FUserName;
    property AvatarBitmap: TBitmap read GetAvatarBitmap;
    procedure Setup(AIdUser: Integer; AUserName: string; AChatRoom: String; AUnreadCount: Integer; ADate: TDateTime); overload;
    procedure Setup(AIdUser: Integer; AUserName: string; AChatRoom: String; AUnreadCount: Integer; ADate: TDateTime; ABitmap: TBitmap); overload;
    procedure RemoveSelecion;
  end;

implementation

uses
  Util.EasyThead;

{ TChatCardInfo }

constructor TChatCardInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FObjetoPronto  := False;
  ControlStyle   := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop        := False;
  ParentFont     := False;

  FBackColor := $00E6FCD5;
  FSelectedColor:= $0069EEBD;
  Font.Name := 'Segoe UI, default';
  Font.Size := 8;

  Height := 60;
  Width  := 260;
  Align  := alTop;

  BorderSpacing.Top   := 6;
  BorderSpacing.Left  := 6;
  BorderSpacing.Right := 2;
  Constraints.MinWidth := 60;
  Constraints.MaxWidth := 260;

  FIdUser   := 0;
  FUserName := '';
  FChatRoom := '';

  // Avatar
  FAvatar := TImage.Create(Self);
  FAvatar.Parent := Self;
  FAvatar.SetBounds(4, 8, 40, 40);
  FAvatar.Stretch := True;
  FAvatar.Hint := '';
  FAvatar.ShowHint := False;
  FAvatar.Transparent := True;
  FAvatar.OnClick := @OnClickComum;
  FAvatar.OnMouseEnter := @OnMouseEnter;
  FAvatar.OnMouseLeave := @OnMouseLeave;

  // Nome do remetente
  FNameLabel := TLabel.Create(Self);
  FNameLabel.Parent := Self;
  FNameLabel.AutoSize := False;
  FNameLabel.Height := 30;
  FNameLabel.Left := 54;
  FNameLabel.Top := 8;
  FNameLabel.Width := 180;
  FNameLabel.WordWrap := True;
  FNameLabel.Font.Style := [fsBold];
  FNameLabel.OnClick := @OnClickComum;
  FNameLabel.OnMouseEnter := @OnMouseEnter;
  FNameLabel.OnMouseLeave := @OnMouseLeave;

  // data de emissão das mensagens
  FDateLabel := TLabel.Create(Self);
  FDateLabel.Parent := Self;
  FDateLabel.Font.Size := 8;
  FDateLabel.Caption := 'dd/mm/yyyy hh:nn';
  FDateLabel.Left := 54;
  FDateLabel.Top := 40;
  FDateLabel.OnClick := @OnClickComum;
  FDateLabel.OnMouseEnter := @OnMouseEnter;
  FDateLabel.OnMouseLeave := @OnMouseLeave;

  // Msg não lida - círculo
  FUnreadShape := TShape.Create(Self);
  FUnreadShape.Parent := Self;
  FUnreadShape.Shape := stCircle;
  FUnreadShape.Brush.Color := $00A4D0DA; //fundo
  FUnreadShape.Pen.Color := $00B6B6B8; //borda
  FUnreadShape.Left := Width - 24;
  FUnreadShape.Top := 6;
  FUnreadShape.Height := 20;
  FUnreadShape.Width := 20;
  FUnreadShape.Visible := True;
  FUnreadShape.OnClick := @OnClickComum;
  FUnreadShape.OnMouseEnter := @OnMouseEnter;
  FUnreadShape.OnMouseLeave := @OnMouseLeave;

  // Msg não lida - texto
  FUnreadBadge := TLabel.Create(Self);
  FUnreadBadge.Parent := Self;
  FUnreadBadge.Left := FUnreadShape.Left - 4;
  FUnreadBadge.Top := FUnreadShape.Top - 4;
  FUnreadBadge.Height := 28;
  FUnreadBadge.Width := 28;
  FUnreadBadge.Alignment := taCenter;
  FUnreadBadge.AutoSize := False;
  FUnreadBadge.Layout := tlCenter;
  FUnreadBadge.Width := 28;
  FUnreadBadge.Visible := True;
  FUnreadBadge.Font.Size := 8;
  FUnreadBadge.Font.Style := [fsBold];
  FUnreadBadge.Font.Color := $00454591;
  FUnreadBadge.Transparent := True;
  FUnreadBadge.OnClick := @OnClickComum;
  FUnreadBadge.OnMouseEnter := @OnMouseEnter;
  FUnreadBadge.OnMouseLeave := @OnMouseLeave;

  FObjetoPronto := True;
end;

destructor TChatCardInfo.Destroy;
begin
  inherited Destroy;
end;

procedure TChatCardInfo.Resize;
begin
  inherited Resize;

  if FObjetoPronto then begin
    FUnreadShape.Left := Width - 24;
    FUnreadBadge.Left := FUnreadShape.Left - 4;
  end;
end;

procedure TChatCardInfo.Click;
begin
  Selected := True;
  if Assigned(OnClickInfo) then
    OnClickInfo(FChatRoom);
end;

procedure TChatCardInfo.MouseEnter;
begin
  inherited MouseEnter;
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatCardInfo.MouseLeave;
begin
  inherited MouseLeave;
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatCardInfo.Setup(AIdUser: Integer; AUserName: string; AChatRoom: String;
                              AUnreadCount: Integer; ADate: TDateTime);
//configura dados do usuário do banco de dados
var
  et: TEasyThread;
begin
  FIdUser := AIdUser;
  FUserName := AUserName;
  FUnreadCount := AUnreadCount;
  FChatRoom := AChatRoom;

  FNameLabel.Caption := AUserName;
  FUnreadBadge.Caption := IntToStr(AUnreadCount);

  if FormatDateTime('yyyy-mm-dd', ADate) = FormatDateTime('yyyy-mm-dd', now) then
    FDateLabel.Caption := 'Hoje ' + FormatDateTime('hh:nn', ADate)
  else
    FDateLabel.Caption := FormatDateTime('dd/mm/yyyy hh:nn', ADate);

  et := TEasyThread.Create(True);
  et.ExecuteProcedure  := @Operacao_Start;
  et.CallBackProcedure := @Operacao_End;
  et.Start;
end;

procedure TChatCardInfo.Setup(AIdUser: Integer; AUserName: string; AChatRoom: String;
                              AUnreadCount: Integer; ADate: TDateTime; ABitmap: TBitmap);
begin
  FIdUser := AIdUser;
  FUserName := AUserName;
  FUnreadCount := AUnreadCount;
  FChatRoom := AChatRoom;

  FNameLabel.Caption := AUserName;
  FUnreadBadge.Caption := IntToStr(AUnreadCount);

  if FormatDateTime('yyyy-mm-dd', ADate) = FormatDateTime('yyyy-mm-dd', now) then
    FDateLabel.Caption := 'Hoje ' + FormatDateTime('hh:nn', ADate)
  else
    FDateLabel.Caption := FormatDateTime('dd/mm/yyyy hh:nn', ADate);

  FAvatar.Picture.Bitmap.Assign(ABitmap);
end;

procedure TChatCardInfo.RemoveSelecion;
begin
  if not FSelected then Exit;
  FSelected := False;
  Invalidate;
end;

function TChatCardInfo.AlterarCor(AColor: TColor; AEscurecer: Boolean; APercent: byte): TColor;
//escurece ou clareia uma determinada cor
var
  R, G, B: Byte;
begin
  R := Red(AColor);
  G := Green(AColor);
  B := Blue(AColor);

  if AEscurecer then begin
    if (R - APercent >= 0) then R := R - APercent;
    if (G - APercent >= 0) then G := G - APercent;
    if (B - APercent >= 0) then B := B - APercent;
  end
  else begin
    if (R + APercent <= 255) then R := R + APercent;
    if (G + APercent <= 255) then G := G + APercent;
    if (B + APercent <= 255) then B := B + APercent;
  end;

  Result := RGBToColor(R, G, B);
end;

function TChatCardInfo.GetAvatarBitmap: TBitmap;
begin
  if Assigned(FAvatar) then
    Result := FAvatar.Picture.Bitmap
  else
    Result := nil;
end;

procedure TChatCardInfo.Operacao_Start;
//pega dados do usuário no db
begin
  FServiceUsuario := TServiceUsuario.Create;
  FServiceUsuario.Ler(FIdUser);
end;

procedure TChatCardInfo.Operacao_End;
//ler dados do usuário
begin
  if Assigned(FServiceUsuario) and FServiceUsuario.Sucesso then begin
    FUserName := FServiceUsuario.Nome;
    FNameLabel.Caption := FUserName;
    FAvatar.Picture.Bitmap.Assign(FServiceUsuario.Foto.Picture.Bitmap);

    FServiceUsuario.Free;
  end;
end;

procedure TChatCardInfo.OnClickComum(Sender: TObject);
//retorna informações do usuário
begin
  Selected := True;
  if Assigned(OnClickInfo) then
    OnClickInfo(FChatRoom);
end;

procedure TChatCardInfo.OnMouseEnter(Sender: TObject);
begin
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatCardInfo.OnMouseLeave(Sender: TObject);
begin
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatCardInfo.SetBackColor(AValue: TColor);
begin
  if FBackColor = AValue then Exit;
  FBackColor := AValue;
  Invalidate;
end;

procedure TChatCardInfo.SetSelected(AValue: Boolean);
var
  i: Integer;
begin
  if FSelected = AValue then Exit;

  for i := 0 to Parent.ControlCount - 1 do
    if Parent.Components[i] is TChatCardInfo then begin
      if TChatCardInfo( Parent.Components[i] ).Selected then begin
        TChatCardInfo( Parent.Components[i] ).RemoveSelecion;
        Break;
      end;
    end;

  FSelected := AValue;
  Invalidate;
end;

procedure TChatCardInfo.SetSelectedColor(AValue: TColor);
begin
  if FSelectedColor = AValue then Exit;
  FSelectedColor := AValue;
  Invalidate;
end;

procedure TChatCardInfo.Paint;
var
  BubbleRect: TRect;
  BubbleColor: TColor;
begin
  //para evitar "fantasmas" nos cantos
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  BubbleColor := FBackColor;

  if FSelected then BubbleColor := FSelectedColor;

  if FMouseEnter then
    BubbleColor := AlterarCor(BubbleColor, False, 10);

  BubbleRect := Rect(0, 0, Width, Height);

  // Fundo
  Canvas.Brush.Color := BubbleColor;
  Canvas.Pen.Color := BubbleColor;
  Canvas.RoundRect(BubbleRect, 12, 12);

  //borda
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Color := clSilver;
  Canvas.RoundRect(BubbleRect, 12, 12);
end;

end.


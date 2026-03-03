unit ChatUserInfo;

// Card com dados do convidado do chat
// Avatar, nome, status online/offline, quantidade mensagens não lidas e botão remover

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Buttons, Graphics, fpjson,
  LCLType, LCLIntf, Service.Usuario;

type
  TChatUserInfoViewMode = (vmExtended, vmCompact, vmAvatar);
  TChatUserStatus = (usOffline, usOnline, usLeave, usNone);
  TOnClickEvent  = procedure(AIDUser: Integer; ANomeUser: string) of object;

  { TChatUserInfo }

  TChatUserInfo = class(TCustomControl)
  private
    FColorForMe: TColor;
    FColorForOther: TColor;
    FViewMode: TChatUserInfoViewMode;
    FServiceUsuario: TServiceUsuario;
    FAvatar: TImage;
    FImageList: TImageList;
    FImageListIndex: Integer;
    FNameLabel: TLabel;
    FStatusDot: TShape;
    FStatusLabel: TLabel;
    FUnreadShape: TShape;
    FUnreadBadge: TLabel;
    FRemoveBtn: TImage;

    FStatus: TChatUserStatus;
    FUnreadCount: Integer;

    FIdProprietarioChat: Integer;
    FIdUser: Integer;
    FUserNome: string;
    FObjetoPronto: Boolean;
    FMouseEnter: Boolean;
    FDefaultWidth: Integer;
    FPodeExcluir: Boolean;

    FNameLabelDefaultVisible: Boolean;
    FStatusDotDefaultVisible: Boolean;
    FStatusLabelDefaultVisible: Boolean;
    FUnreadShapeDefaultVisible: Boolean;
    FUnreadBadgeDefaultVisible: Boolean;
    FRemoveBtnDefaultVisible: Boolean;

    FStatusDotLeft: Integer;

    function AlterarCor(AColor: TColor; AEscurecer: Boolean; APercent: byte): TColor;
    procedure AjustarPosicoes;
    function GetIsProprietarioChat: Boolean;
    procedure SetColorForMe(AValue: TColor);
    procedure SetColorForOther(AValue: TColor);
    procedure SetImageList(AValue: TImageList);
    procedure SetImageListIndex(AValue: Integer);
    procedure SetStatus(AValue: TChatUserStatus);
    procedure SetUnreadCount(AValue: Integer);
    procedure Operacao_Start;
    procedure Operacao_End;
    procedure OnClickDeleteUser(Sender: TObject);
    procedure OnClickComum(Sender: TObject);
    procedure OnMouseEnter(Sender: TObject);
    procedure OnMouseLeave(Sender: TObject);
    procedure SetViewMode(AValue: TChatUserInfoViewMode);
  protected
    procedure Click; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure Paint; override;
    procedure Resize; override;
  public
    OnClickInfo: TOnClickEvent;
    OnClickDelete: TOnClickEvent;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property ImageList: TImageList read FImageList write SetImageList;
    property ImageListIndex: Integer read FImageListIndex write SetImageListIndex;
    property Status: TChatUserStatus read FStatus write SetStatus;
    property ViewMode: TChatUserInfoViewMode read FViewMode write SetViewMode;
    property UnreadCount: Integer read FUnreadCount write SetUnreadCount;
    property IdProprietarioChat: integer read FIdProprietarioChat;
    property IsProprietarioChat: Boolean read GetIsProprietarioChat;
    property ColorForMe: TColor read FColorForMe write SetColorForMe;
    property ColorForOther: TColor read FColorForOther write SetColorForOther;
    property Usuario_ID: integer read FIdUser;
    property Usuario_Nome: string read FUserNome;
    { carrega dados do usuário manualmente }
    procedure Setup(AIdProprietarioChat, AIdUser: Integer; ANomeUser: string;
                    AAvatar: TBitmap; APodeExcluir: Boolean = False);overload;
    { carrega dados do usuário do banco de dados }
    procedure Setup(AIdProprietarioChat, AIdUser: Integer; ANomeUser: string;
                    AUnreadCount: Integer; AStatus: TChatUserStatus;
                    APodeExcluir: Boolean = False); overload;
    { ajusta status e total de mensagens não lidas }
    procedure AJustaInformacoes(const AStrJson: string);
  end;

implementation

uses
  Util.EasyThead;

{ TChatUserInfo }

constructor TChatUserInfo.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FViewMode      := vmExtended; //card completo
  FObjetoPronto  := False;
  ControlStyle   := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop    := False;
  ParentFont := False;

  FDefaultWidth := 280;

  case FViewMode of
    vmExtended: FDefaultWidth := 280; //completo
    vmCompact: FDefaultWidth := 70;   //avatar, msg não lidas e status
    vmAvatar: FDefaultWidth := 60;    //aó o avatar
  end;

  Font.Name := 'Segoe UI, default';
  Font.Size := 8;

  Height := 60;
  Width  := FDefaultWidth;
  Align  := alTop;

  BorderSpacing.Top   := 6;
  BorderSpacing.Left  := 6;
  BorderSpacing.Right := 6;
  Constraints.MinWidth := 60;
  Constraints.MaxWidth := 360;

  FIdProprietarioChat := 0;
  FIdUser   := 0;
  FUserNome := '';
  FColorForMe := $00E6FCD5;
  FColorForOther := $00F3F4E0;

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

  // Nome
  FNameLabel := TLabel.Create(Self);
  FNameLabel.Parent := Self;
  FNameLabel.AutoSize := False;
  FNameLabel.Height := 30;
  FNameLabel.Left := 54;
  FNameLabel.Top := 8;
  FNameLabel.Width := 200;
  FNameLabel.WordWrap := True;
  FNameLabel.Font.Style := [fsBold];
  FNameLabel.OnClick := @OnClickComum;
  FNameLabel.OnMouseEnter := @OnMouseEnter;
  FNameLabel.OnMouseLeave := @OnMouseLeave;

  FNameLabelDefaultVisible := FNameLabel.Visible;

  // Msg não lida - círculo
  FUnreadShape := TShape.Create(Self);
  FUnreadShape.Parent := Self;
  FUnreadShape.Shape := stCircle;
  FUnreadShape.Brush.Color := $00A4D0DA; //fundo
  FUnreadShape.Pen.Color := $00B6B6B8; //borda
  //FUnreadShape.SetBounds(Width - 4, 6, 20, 20);
  FUnreadShape.Left := Width - 24;
  FUnreadShape.Top := 6;
  FUnreadShape.Height := 20;
  FUnreadShape.Width := 20;
  FUnreadShape.Visible := False;
  FUnreadShape.OnClick := @OnClickComum;
  FUnreadShape.OnMouseEnter := @OnMouseEnter;
  FUnreadShape.OnMouseLeave := @OnMouseLeave;

  FUnreadShapeDefaultVisible := FUnreadShape.Visible;

  // Msg não lida - texto
  FUnreadBadge := TLabel.Create(Self);
  FUnreadBadge.Parent := Self;
  //FUnreadBadge.SetBounds(FUnreadShape.Left - 4, FUnreadShape.Top - 4, 28, 28);
  FUnreadBadge.Left := FUnreadShape.Left - 4;
  FUnreadBadge.Top := FUnreadShape.Top - 4;
  FUnreadBadge.Height := 28;
  FUnreadBadge.Width := 28;
  FUnreadBadge.Alignment := taCenter;
  FUnreadBadge.AutoSize := False;
  FUnreadBadge.Layout := tlCenter;
  FUnreadBadge.Width := 28;
  FUnreadBadge.Visible := False;
  FUnreadBadge.Font.Size := 8;
  FUnreadBadge.Font.Style := [fsBold];
  FUnreadBadge.Font.Color := $00454591;
  FUnreadBadge.Transparent := True;
  FUnreadBadge.OnClick := @OnClickComum;
  FUnreadBadge.OnMouseEnter := @OnMouseEnter;
  FUnreadBadge.OnMouseLeave := @OnMouseLeave;

  FUnreadBadgeDefaultVisible := FUnreadBadge.Visible;

  // Status - círculo
  FStatusDot := TShape.Create(Self);
  FStatusDot.Parent := Self;
  FStatusDot.Shape := stCircle;
  FStatusDot.Brush.Color := $00E0E0E0; //fundo
  FStatusDot.Pen.Color := $00B6B6B8; //borda
  //FStatusDot.SetBounds(54, 40, 14, 14);
  FStatusDot.Left := 54;
  FStatusDot.Top := 40;
  FStatusDot.Height := 14;
  FStatusDot.Hint := '';
  FStatusDot.ShowHint := True;
  FStatusDot.Width := 14;
  FStatusDot.OnClick := @OnClickComum;
  FStatusDot.OnMouseEnter := @OnMouseEnter;
  FStatusDot.OnMouseLeave := @OnMouseLeave;

  FStatusDotLeft := FStatusDot.Left;
  FStatusDotDefaultVisible := FStatusDot.Visible;

  // status - texto
  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := Self;
  FStatusLabel.Font.Size := 8;
  FStatusLabel.Caption := 'desconhecido';
  FStatusLabel.Left := 72;
  FStatusLabel.Top := 40;
  FStatusLabel.OnClick := @OnClickComum;
  FStatusLabel.OnMouseEnter := @OnMouseEnter;
  FStatusLabel.OnMouseLeave := @OnMouseLeave;

  FStatusLabelDefaultVisible := FStatusLabel.Visible;

  // Remover
  FRemoveBtn := TImage.Create(Self);
  FRemoveBtn.Parent := Self;
  FRemoveBtn.Cursor := crHandPoint;
  //FRemoveBtn.SetBounds(Width - 2, 34, 18, 18);
  FRemoveBtn.Left := Width - 24;
  FRemoveBtn.Top := 34;
  FRemoveBtn.Height := 18;
  FRemoveBtn.Width := 18;
  FRemoveBtn.Stretch := True;
  FRemoveBtn.Transparent := True;
  FRemoveBtn.Hint := 'Remover o convidado do chat';
  FRemoveBtn.ShowHint := True;
  FRemoveBtn.Visible := False;
  FRemoveBtn.OnClick := @OnClickDeleteUser;
  FRemoveBtn.OnMouseEnter := @OnMouseEnter;
  FRemoveBtn.OnMouseLeave := @OnMouseLeave;

  FRemoveBtnDefaultVisible := False;

  FObjetoPronto := True;
end;

destructor TChatUserInfo.Destroy;
begin
  inherited Destroy;
end;

procedure TChatUserInfo.Resize;
begin
  inherited Resize;

  AjustarPosicoes;
end;

procedure TChatUserInfo.Click;
begin
  if Assigned(OnClickInfo) then
    OnClickInfo(FIdUser, FUserNome);
end;

procedure TChatUserInfo.MouseEnter;
begin
  inherited MouseEnter;
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatUserInfo.MouseLeave;
begin
  inherited MouseLeave;
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatUserInfo.Setup(AIdProprietarioChat, AIdUser: Integer; ANomeUser: string;
                              AAvatar: TBitmap; APodeExcluir: Boolean);
//configura o usuário manualmente
begin
  FIdProprietarioChat := AIdProprietarioChat;
  FIdUser := AIdUser;
  FUserNome := ANomeUser;
  FStatus := usNone;
  FPodeExcluir := APodeExcluir;

  if Assigned(AAvatar) then
    FAvatar.Picture.Bitmap.Assign(AAvatar);

  FNameLabel.Caption := ANomeUser;
  FAvatar.Hint := ANomeUser;
  FAvatar.ShowHint := (FViewMode <> vmExtended);

  if APodeExcluir then begin
    if Assigned(ImageList) and (FImageListIndex >= 0) then begin
      FRemoveBtn.Images := FImageList;
      FRemoveBtn.ImageIndex := FImageListIndex;
      FRemoveBtn.Visible := True;
      FRemoveBtnDefaultVisible := True;
    end;
  end;

  AjustarPosicoes;
end;

procedure TChatUserInfo.Setup(AIdProprietarioChat, AIdUser: Integer; ANomeUser: string;
                              AUnreadCount: Integer; AStatus: TChatUserStatus;
                              APodeExcluir: Boolean);
//configura dados do usuário do banco de dados
var
  et: TEasyThread;
begin
  FIdProprietarioChat := AIdProprietarioChat;
  FIdUser := AIdUser;
  FUserNome := ANomeUser;
  FUnreadCount := AUnreadCount;
  FStatus := AStatus;
  FPodeExcluir := APodeExcluir and (AIdProprietarioChat <> AIdUser);

  et := TEasyThread.Create(True);
  et.ExecuteProcedure  := @Operacao_Start;
  et.CallBackProcedure := @Operacao_End;
  et.Start;
end;

procedure TChatUserInfo.AJustaInformacoes(const AStrJson: string);
//ajusta status e quantidade de mensagens não lidas
var
  lArrayTo: TJSONArray;
  AJson, lObj: TJSONObject;
  i: Integer;
begin
  if Trim(AStrJson) = '' then Exit;

  AJson := TJSONObject( GetJSON( AStrJson ) );

  try
    lArrayTo := TJSONArray( AJson.Arrays['to'] );

    try
      for i := 0 to lArrayTo.Count - 1 do begin
        lObj := TJSONObject( lArrayTo.Items[i] );

        if (Usuario_ID = lObj.Get('to_id', 0)) then begin
          if (lObj.Booleans['online'] = True) then
            SetStatus( usOnline )
          else
            SetStatus( usOffline );

          SetUnreadCount( lObj.Get('total_unread', 0) );
          Break;
        end; // if
      end; // for
    except
    end;
  finally
    AJson.Free; // também libera o lArrayTo
  end;
end;

procedure TChatUserInfo.SetStatus(AValue: TChatUserStatus);
//usuário online ou offline
begin
   if FStatus = AValue then Exit;
  FStatus := AValue;
  FStatusDot.Hint := '';

  case AValue of
    usOnline:
      begin
        FStatusDot.Brush.Color := clLime;
        FStatusLabel.Caption := 'on-line';
      end;
    usOffline:
      begin
        FStatusDot.Brush.Color := clRed;
        FStatusLabel.Caption := 'off-line';
      end;
    usLeave:
      begin
        FStatusDot.Brush.Color := clYellow;
        FStatusLabel.Caption := 'saiu da sala';
      end;
    usNone:
      begin
        FStatusDot.Brush.Color := $00E0E0E0;
        FStatusLabel.Caption := 'desconhecido';
      end;
  end;

  if FViewMode = vmCompact then
    FStatusDot.Hint := FStatusLabel.Caption;

  Invalidate;
end;

procedure TChatUserInfo.SetImageList(AValue: TImageList);
//define a lista de ícones
begin
  if FImageList = AValue then Exit;
  FImageList := AValue;
end;

procedure TChatUserInfo.SetImageListIndex(AValue: Integer);
//ícone do botão deletar usuário
begin
  if FImageListIndex = AValue then Exit;
  FImageListIndex := AValue;
end;

procedure TChatUserInfo.SetUnreadCount(AValue: Integer);
//mensagens não lidas
begin
  FUnreadCount := AValue;
  FUnreadShape.Visible := (AValue > 0) and not (FViewMode = vmAvatar);
  FUnreadBadge.Visible := (AValue > 0) and not (FViewMode = vmAvatar);
  FUnreadBadge.Caption := AValue.ToString;

  FUnreadShapeDefaultVisible := FUnreadShape.Visible;
  FUnreadBadgeDefaultVisible := FUnreadBadge.Visible;
end;

function TChatUserInfo.AlterarCor(AColor: TColor; AEscurecer: Boolean;
  APercent: byte): TColor;
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

procedure TChatUserInfo.AjustarPosicoes;
//ajuste de coordenadas dos objetos
var
  bCompactMode, bAvatarMode: Boolean;
begin
  if not FObjetoPronto then Exit;

  bCompactMode := (FViewMode = vmCompact);
  bAvatarMode  := (FViewMode = vmAvatar);

  try
    //avatar
    if Assigned(FAvatar) then
      FAvatar.ShowHint := (bAvatarMode or bCompactMode);

    //texto do nome do usuário
    if Assigned(FNameLabel) then begin
      if bAvatarMode or bCompactMode then
        FNameLabel.Visible := False
      else
        FNameLabel.Visible := FNameLabelDefaultVisible;
    end;

    //círculo com indicativo do status do usuário:
    //verde (on-line), vermelho (off-line) ou cinza (desconhecido)
    if Assigned(FStatusDot) then begin
      if bAvatarMode then
        FStatusDot.Visible := False
      else
        FStatusDot.Visible := FStatusDotDefaultVisible;
    end;

    //texto do status do usuário: on-line, off-line ou desconhecido
    if Assigned(FStatusLabel) then begin
      if bAvatarMode or bCompactMode then
        FStatusLabel.Visible := False
      else
        FStatusLabel.Visible := FStatusLabelDefaultVisible;
    end;

    // círculo com a quantidade de mensagens não lidas
    if Assigned(FUnreadShape) then begin
      if bAvatarMode then begin
        FUnreadShape.Visible := False;
      end else begin
        if bCompactMode then
          FUnreadShape.Left := 48
        else
          FUnreadShape.Left := Width - 24;

        FUnreadShape.Visible := FUnreadCount > 0;
      end;
    end;

    // texto com a quantidade de mensagens não lidas
    if Assigned(FUnreadBadge) then begin
      if bAvatarMode then begin
        FUnreadBadge.Visible := False
      end else begin
        FUnreadBadge.Left := FUnreadShape.Left - 4;
        FUnreadBadge.Visible := FUnreadCount > 0;
      end;
    end;

    //botão de excluir o usuário
    if Assigned(FRemoveBtn) then begin
      FRemoveBtn.Left := Width - 24;
      if bAvatarMode or bCompactMode then
        FRemoveBtn.Visible := False
      else
        FRemoveBtn.Visible := FRemoveBtnDefaultVisible;
    end;
  except
  end;
end;

function TChatUserInfo.GetIsProprietarioChat: Boolean;
begin
  Result := (FIdProprietarioChat = FIdUser);
end;

procedure TChatUserInfo.SetColorForMe(AValue: TColor);
begin
  if FColorForMe = AValue then Exit;
  FColorForMe := AValue;
  Invalidate;
end;

procedure TChatUserInfo.SetColorForOther(AValue: TColor);
begin
  if FColorForOther = AValue then Exit;
  FColorForOther := AValue;
  Invalidate;
end;

procedure TChatUserInfo.Operacao_Start;
//pega dados do usuário no db
begin
  FServiceUsuario := TServiceUsuario.Create;
  FServiceUsuario.Ler(FIdUser);
end;

procedure TChatUserInfo.Operacao_End;
//ler dados do usuário
begin
  if Assigned(FServiceUsuario) and FServiceUsuario.Sucesso then begin
    FUserNome := FServiceUsuario.Nome;
    FNameLabel.Caption := FUserNome;
    FAvatar.Picture.Bitmap.Assign(FServiceUsuario.Foto.Picture.Bitmap);
    FStatus := usNone;
    FAvatar.Hint := FUserNome;
    FAvatar.ShowHint := (FViewMode <> vmExtended);

    SetUnreadCount( FUnreadCount );
    SetStatus( FStatus );

    if FPodeExcluir then begin
      if Assigned(ImageList) and (FImageListIndex >= 0) then begin
        FRemoveBtn.Images := FImageList;
        FRemoveBtn.ImageIndex := FImageListIndex;
        FRemoveBtn.Visible := True;
        FRemoveBtnDefaultVisible := True;
      end;
    end;

    AjustarPosicoes;
    FServiceUsuario.Free;
  end;
end;

procedure TChatUserInfo.OnClickDeleteUser(Sender: TObject);
//deletar usuário
begin
  if Assigned(OnClickDelete) then
    OnClickDelete(FIdUser, FUserNome);
end;

procedure TChatUserInfo.OnClickComum(Sender: TObject);
//retorna informações do usuário
begin
  if Assigned(OnClickInfo) then
    OnClickInfo(FIdUser, FUserNome);
end;

procedure TChatUserInfo.OnMouseEnter(Sender: TObject);
begin
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatUserInfo.OnMouseLeave(Sender: TObject);
begin
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatUserInfo.SetViewMode(AValue: TChatUserInfoViewMode);
begin
  if FViewMode = AValue then Exit;
  FViewMode := AValue;

  case FViewMode of
    vmExtended: FDefaultWidth := 280; //completo
    vmCompact: FDefaultWidth := 70;   //avatar, msg não lidas e status
    vmAvatar: FDefaultWidth := 60;    //aó o avatar
  end;

  Width  := FDefaultWidth;
end;

procedure TChatUserInfo.Paint;
var
  BubbleRect: TRect;
  BubbleColor: TColor;
begin
  //para evitar "fantasmas" nos cantos
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  if FIdProprietarioChat = FIdUser then
    BubbleColor := FColorForMe
  else
    BubbleColor := FColorForOther;

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


unit ChatUserSelect;

(*
  Card para seleção de convidado para o chat
  avatar, nome e opção de selecionar (checkbox)
  Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Buttons, Graphics,
  LCLType, LCLIntf, Service.Usuario;

type
  TOnClickEvent  = procedure(AIDUser: Integer; ANomeUser: string; ASelected: Boolean) of object;

  { TChatUserSelect }

  TChatUserSelect = class(TCustomControl)
  private
    FColorOne: TColor;
    FColorTwo: TColor;
    FImageList: TImageList;
    FServiceUsuario: TServiceUsuario;
    FAvatar: TImage;
    FSeletor: TImage;
    FNameLabel: TLabel;

    FIdUser: Integer;
    FObjetoPronto: Boolean;
    FUserNome: string;
    FSelected: Boolean;
    FDefaultColor: TColor;
    FSelectedColor: TColor;
    FIndex: Integer;
    FSucesso: Boolean;
    FMouseEnter: Boolean;

    function AlterarCor(AColor: TColor; AEscurecer: Boolean; APercent: byte): TColor;
    procedure Operacao_Start;
    procedure Operacao_End;
    procedure ChangeStatus;
    procedure OnClickComum(Sender: TObject);
    procedure OnMouseEnter(Sender: TObject);
    procedure OnMouseLeave(Sender: TObject);
    procedure SetColorOne(AValue: TColor);
    procedure SetColorTwo(AValue: TColor);
    procedure SetImageList(AValue: TImageList);
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
    property ImageList: TImageList read FImageList write SetImageList;
    property Usuario_ID: integer read FIdUser;
    property Usuario_Nome: string read FUserNome;
    property Selected: Boolean read FSelected;
    property ColorOne: TColor read FColorOne write SetColorOne;
    property ColorTwo: TColor read FColorTwo write SetColorTwo;
    { carrega dados do usuário do banco de dados }
    procedure Setup(AIdUser, AIndex: Integer);
  end;

implementation

uses
  Util.EasyThead;

{ TChatUserSelect }

constructor TChatUserSelect.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FObjetoPronto  := False;
  ControlStyle   := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop    := False;
  ParentFont := False;

  Height := 60;
  Width  := 260;
  Align  := alTop;

  BorderSpacing.Top   := 6;
  BorderSpacing.Left  := 6;
  BorderSpacing.Right := 6;
  Constraints.MaxWidth := 360; // será ajustado pelo form

  Font.Name := 'Segoe UI, default';
  Font.Size := 8;

  FIdUser   := 0;
  FUserNome := '';
  FSelected := False;
  FIndex    := 0;
  FSucesso := False;
  FMouseEnter := False;
  FColorOne := $00E6FCD5;
  FColorTwo := $00F3F4E0;
  FSelectedColor := $00DFE591;

  // Avatar
  FAvatar := TImage.Create(Self);
  FAvatar.Parent := Self;
  FAvatar.SetBounds(4, 8, 40, 40);
  FAvatar.Stretch := True;
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

  // Seletor
  FSeletor := TImage.Create(Self);
  FSeletor.Parent := Self;
  FSeletor.SetBounds(Width - 42, 20, 30, 30);
  FSeletor.Stretch := True;
  FSeletor.Transparent := True;
  FSeletor.Visible := False;
  FSeletor.OnClick := @OnClickComum;
  FSeletor.OnMouseEnter := @OnMouseEnter;
  FSeletor.OnMouseLeave := @OnMouseLeave;

  FObjetoPronto := True;
end;

destructor TChatUserSelect.Destroy;
begin
  inherited Destroy;
end;

procedure TChatUserSelect.Resize;
begin
  inherited Resize;

  if not FObjetoPronto then Exit;
  try
    if Assigned(FSeletor) then;
      FSeletor.Left := Width - 42;
  except
  end;
end;

procedure TChatUserSelect.Click;
begin
  if FSucesso = False then Exit;

  ChangeStatus;

  if Assigned(OnClickInfo) then
    OnClickInfo(FIdUser, FUserNome, FSelected);
end;

procedure TChatUserSelect.MouseEnter;
begin
  inherited MouseEnter;
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatUserSelect.MouseLeave;
begin
  inherited MouseLeave;
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatUserSelect.Setup(AIdUser, AIndex: Integer);
//configura dados do usuário do banco de dados
var
  et: TEasyThread;
begin
  FIdUser := AIdUser;
  FIndex  := AIndex; //para alternar a cor

  if Assigned(ImageList) then begin
    FSeletor.Images := FImageList;
    FSeletor.ImageIndex := 0;
  end;

  et := TEasyThread.Create(True);
  et.ExecuteProcedure := @Operacao_Start;
  et.CallBackProcedure := @Operacao_End;
  et.Start;

  Invalidate;
end;

function TChatUserSelect.AlterarCor(AColor: TColor; AEscurecer: Boolean; APercent: byte): TColor;
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

procedure TChatUserSelect.Operacao_Start;
//pega dados do usuário no db
begin
  FSucesso := False;
  FServiceUsuario := TServiceUsuario.Create;
  FServiceUsuario.Ler(FIdUser);
end;

procedure TChatUserSelect.Operacao_End;
//ler dados do usuário
begin
  if Assigned(FServiceUsuario) and FServiceUsuario.Sucesso then begin
    FSucesso  := True;
    FUserNome := FServiceUsuario.Nome;
    FNameLabel.Caption := FUserNome;
    FAvatar.Picture.Bitmap.Assign(FServiceUsuario.Foto.Picture.Bitmap);

    if Assigned(ImageList) then begin
      FSeletor.ImageIndex := 0;
      FSeletor.Visible := True;
    end;

    FServiceUsuario.Free;
  end;
end;

procedure TChatUserSelect.ChangeStatus;
//deletar usuário
begin
  if FSucesso = False then Exit;

  FSelected := not FSelected;

  if Assigned(ImageList) then begin
    if FSelected then begin
      FSeletor.ImageIndex := 1;
    end
    else begin
      FSeletor.ImageIndex := 0;
    end;
  end;
end;

procedure TChatUserSelect.OnClickComum(Sender: TObject);
//retorna informações do usuário
begin
  if FSucesso = False then Exit;

  Invalidate;
  ChangeStatus;

  if Assigned(OnClickInfo) then
    OnClickInfo(FIdUser, FUserNome, FSelected);
end;

procedure TChatUserSelect.OnMouseEnter(Sender: TObject);
begin
  FMouseEnter := True;
  Invalidate;
end;

procedure TChatUserSelect.OnMouseLeave(Sender: TObject);
begin
  FMouseEnter := False;
  Invalidate;
end;

procedure TChatUserSelect.SetColorOne(AValue: TColor);
begin
  if FColorOne = AValue then Exit;
  FColorOne := AValue;
  Invalidate;
end;

procedure TChatUserSelect.SetColorTwo(AValue: TColor);
begin
  if FColorTwo = AValue then Exit;
  FColorTwo := AValue;
  Invalidate;
end;

procedure TChatUserSelect.SetImageList(AValue: TImageList);
begin
  if FImageList = AValue then Exit;
  FImageList := AValue;
end;

procedure TChatUserSelect.Paint;
var
  BubbleRect: TRect;
  BubbleColor: TColor;
begin
  //para evitar "fantasmas" nos cantos
  Canvas.Font.Assign(Font);
  Canvas.Brush.Color := Parent.Color;
  Canvas.Brush.Style := bsSolid;
  Canvas.FillRect(ClientRect);

  if FIndex mod 2 = 0 then
    BubbleColor := FColorOne
  else
    BubbleColor := FColorTwo;

  if FSelected then
    BubbleColor := FSelectedColor;

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


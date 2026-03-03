unit Util.MessagePopup; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 


// Exibe mensagem em estilo smartphone 
// 
//ShowPopupMessage(self, 'Sucesso', mptSuccess, mppCenter, mpmGrow); 
//ShowPopupMessage(self, 'Alerta', mptWarning, mppTop, mpmGrow); 
//ShowPopupMessage(self, 'Alerta 2', mptWarning, mppTop, mpmExplode, 50); 
//ShowPopupMessage(self, 'Falhou!' + sLineBreak + 'Corrija o problema.', mptFatal, mppBottom, mpmExplode); 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Controls, ExtCtrls, Graphics, LCLIntf, LCLType, Types, Math; 
 
type 
  TMessagePopupType = (mptSuccess, mptWarning, mptFatal); 
  TMessagePopupPosition = (mppTop, mppCenter, mppBottom); 
  TMessagePopupModel = (mpmGrow, mpmExplode); 
 
  { TMessagePopup } 
 
  TMessagePopup = class(TCustomControl) 
  private 
    FMessage: string; 
    FMessageType: TMessagePopupType; 
    FPopupPosition: TMessagePopupPosition; 
    FModel: TMessagePopupModel; 
    FShowTimer, FAnimTimer, FLineTimer: TTimer; 
    FClosing: Boolean; 
    FTargetHeight: Integer; 
    FTargetWidth: Integer; 
    FFullHeight: Integer; 
    FFullWidth: Integer; 
    AnimationStep: Integer; 
    FStep, FBaseLeft, FBaseTop, FTop: Integer; 
    FLineProgress, FLineProgressWidth: Integer; 
    FFShowTimerInterval: Integer; 
    function CalculateTextHeight(const AText: string): Integer; 
    procedure AnimationGrow; 
    procedure AnimationExplode; 
    procedure DoCloseTimer(Sender: TObject); 
    procedure DoAnimationTimer(Sender: TObject); 
    procedure DoLineTimer(Sender: TObject);     
    procedure DrawIconAt(ACanvas: TCanvas; AX, AY: Integer; AType: TMessagePopupType);  
    procedure StartClose; 
    procedure UpdatePosition; 
  protected 
    procedure Paint; override; 
    procedure Click; override; 
  public 
    constructor Create(AOwner: TComponent); override; 
    procedure ShowMessage(const AMessage: string; AType: TMessagePopupType; 
                          APosition: TMessagePopupPosition; AModel: TMessagePopupModel; 
                          ATop: Integer = 0); 
  end; 
 
procedure ShowPopupMessage(AOwner: TWinControl; const AMessage: string; 
                           AType: TMessagePopupType = mptSuccess; 
                           APosition: TMessagePopupPosition = mppCenter; 
                           AModel: TMessagePopupModel = mpmGrow; 
                           ATop: Integer = 0); 
 
implementation 
 
procedure ShowPopupMessage(AOwner: TWinControl; const AMessage: string; 
                           AType: TMessagePopupType; 
                           APosition: TMessagePopupPosition; 
                           AModel: TMessagePopupModel; 
                           ATop: Integer); 
var 
  Popup: TMessagePopup; 
begin 
  Popup := TMessagePopup.Create(AOwner); 
  Popup.Parent := AOwner; 
  Popup.ShowMessage(AMessage, AType, APosition, AModel, ATop); 
end; 
 
{ TMessagePopup } 
 
constructor TMessagePopup.Create(AOwner: TComponent); 
begin 
  inherited Create(AOwner); 
  DoubleBuffered := True; 
  ControlStyle := ControlStyle + [csOpaque]; 
  Visible := False; 
 
  FShowTimer := TTimer.Create(Self); 
  FShowTimer.Enabled := False; 
  FShowTimer.OnTimer := @DoCloseTimer; 
 
  FAnimTimer := TTimer.Create(Self); 
  FAnimTimer.Interval := 10; 
  FAnimTimer.Enabled := False; 
  FAnimTimer.OnTimer := @DoAnimationTimer; 
 
  FLineTimer := TTimer.Create(Self); 
  FLineTimer.Enabled := False; 
  FLineTimer.Interval := 50; 
  FLineTimer.OnTimer := @DoLineTimer; 
end; 
 
procedure TMessagePopup.ShowMessage(const AMessage: string; AType: TMessagePopupType; 
                                    APosition: TMessagePopupPosition; AModel: TMessagePopupModel; 
                                    ATop: Integer); 
var 
  screenW, screenH: Integer; 
begin 
  FMessage := AMessage; 
  FModel := AModel; 
  FMessageType := AType; 
  FStep := 16; 
  FTop := ATop; 
  FAnimTimer.Interval := 10; 
 
  if FModel = mpmExplode then begin 
    SetBounds(0, 0, 10, 10); 
    FAnimTimer.Interval := 15; 
  end; 
 
 
  FFShowTimerInterval := 30000; 
  if AType = mptSuccess then 
    FFShowTimerInterval := 3800; 
 
 
  if Trim(FMessage) = '' then begin 
    if AType = mptSuccess then 
      FMessage := 'Processo concluído!' 
    else 
      FMessage := 'Algo deu errado!'; 
  end; 
 
  FPopupPosition := APosition; 
  FClosing := False; 
 
  // Dimensões finais 
  FFullWidth := 380; 
  FFullHeight := CalculateTextHeight(FMessage) + 20; 
  FLineProgress := FFullWidth - 20; 
  FLineProgressWidth := FLineProgress; 
 
  Width := 1; 
  Height := 1; 
  FTargetWidth := FFullWidth; 
  FTargetHeight := FFullHeight; 
 
  screenW := Parent.ClientWidth; 
  screenH := Parent.ClientHeight; 
 
  Left := (screenW - FTargetWidth) div 2; 
 
  case FPopupPosition of 
    mppTop: Top := 20 + FTop; 
    mppCenter: Top := (screenH - FTargetHeight) div 2; 
    mppBottom: Top := screenH - FTargetHeight - 10; 
  end; 
 
  //Modelo mpmExplode; 
  AnimationStep := 0; 
  if FModel = mpmExplode then 
    UpdatePosition; 
 
  Visible := True; 
  BringToFront; 
 
  FAnimTimer.Enabled := True; 
end; 
 
procedure TMessagePopup.DoAnimationTimer(Sender: TObject); 
begin 
  if FModel = mpmGrow then 
    AnimationGrow 
  else 
    AnimationExplode; 
end; 
 
procedure TMessagePopup.AnimationGrow; 
//Animação do model Grow 
begin 
  if not FClosing then 
  begin 
    if (Width < FTargetWidth) or (Height < FTargetHeight) then 
    begin 
      Width := Min(Width + FStep, FTargetWidth); 
      Height := Min(Height + FStep, FTargetHeight); 
      Invalidate; 
    end 
    else 
    begin 
      Width := FTargetWidth; 
      Height := FTargetHeight; 
      FAnimTimer.Enabled := False; 
      FShowTimer.Interval:= FFShowTimerInterval; 
      FShowTimer.Enabled := True; 
      FLineTimer.Enabled := True; 
    end; 
  end 
  else 
  begin 
    if (Width > 1) or (Height > 1) then 
    begin 
      Width := Max(Width - FStep, 1); 
      Height := Max(Height - FStep, 1); 
      Invalidate; 
    end 
    else 
    begin 
      FAnimTimer.Enabled := False; 
      FLineTimer.Enabled := False; 
      Visible := False; 
      Free; 
    end; 
  end; 
end; 
 
procedure TMessagePopup.AnimationExplode; 
//Animação do model Explode 
const 
  ANIMATION_STEPS = 10; 
var 
  NewW, NewH: Integer; 
begin 
  Inc(AnimationStep); 
 
  if not FClosing then 
  begin 
    NewW := (FTargetWidth * AnimationStep) div ANIMATION_STEPS; 
    NewH := (FTargetHeight * AnimationStep) div ANIMATION_STEPS; 
    Width := NewW; 
    Height := NewH; 
 
    Left := FBaseLeft - Width div 2; 
    Top := FBaseTop - Height div 2; 
 
    if AnimationStep >= ANIMATION_STEPS then 
    begin 
      FAnimTimer.Enabled := False; 
      Width := FTargetWidth; 
      Height := FTargetHeight; 
      UpdatePosition; 
      FShowTimer.Interval:= FFShowTimerInterval; 
      FShowTimer.Enabled := True; 
      FLineTimer.Enabled := True; 
    end; 
  end 
  else 
  begin 
    NewW := (FTargetWidth * (ANIMATION_STEPS - AnimationStep)) div ANIMATION_STEPS; 
    NewH := (FTargetHeight * (ANIMATION_STEPS - AnimationStep)) div ANIMATION_STEPS; 
    Width := NewW; 
    Height := NewH; 
 
    Left := FBaseLeft - Width div 2; 
    Top := FBaseTop - Height div 2; 
 
    if AnimationStep >= ANIMATION_STEPS then 
    begin 
      FAnimTimer.Enabled := False; 
      Visible := False; 
      Parent := nil; 
      Free; 
    end; 
  end; 
 
  if not (csDestroying in ComponentState) and Visible and HandleAllocated then begin 
    Invalidate; 
  end; 
end; 
 
procedure TMessagePopup.DoLineTimer(Sender: TObject); 
begin 
  if FLineProgress > 0 then 
  begin 
    FLineProgress := FLineProgress - Round(FLineProgressWidth / (FShowTimer.Interval / FLineTimer.Interval)); 
    if FLineProgress < 0 then FLineProgress := 0; 
    Invalidate; 
  end else 
    DoCloseTimer(Sender); 
end; 
 
procedure TMessagePopup.DoCloseTimer(Sender: TObject); 
begin 
  FShowTimer.Enabled := False; 
  FLineTimer.Enabled := False; 
  AnimationStep := 0; 
  StartClose; 
end; 
 
procedure TMessagePopup.Click; 
begin 
  inherited Click; 
  StartClose; 
end; 
 
procedure TMessagePopup.StartClose; 
begin 
  if not FClosing then 
  begin 
    FClosing := True; 
    FAnimTimer.Enabled := True; 
  end; 
end; 
 
procedure TMessagePopup.UpdatePosition; 
begin 
  if Parent = nil then Exit; 
 
  case FPopupPosition of 
    mppTop: 
      begin 
        Left := (Parent.Width - Width) div 2; 
        Top := 20 + FTop; 
      end; 
    mppCenter: 
      begin 
        Left := (Parent.Width - Width) div 2; 
        Top := (Parent.Height - Height) div 2; 
      end; 
    mppBottom: 
      begin 
        Left := (Parent.Width - Width) div 2; 
        Top := Parent.Height - Height - 20; 
      end; 
  end; 
 
  FBaseLeft := Left + Width div 2; 
  FBaseTop := Top + Height div 2; 
end; 
 
procedure TMessagePopup.Paint; 
var 
  R: TRect; 
  flags: Longint; 
  bgColor, lineColor: TColor; 
begin 
  Canvas.Brush.Style := bsSolid; 
 
  case FMessageType of 
    mptSuccess: begin bgColor := $DFFFD6; lineColor := RGBToColor(195,222,186); end; 
    mptWarning: begin bgColor := RGBToColor(255,255,179); lineColor := RGBToColor(217,217,151) ; end; // $FFF4CC; //azul claro 
    mptFatal:   begin bgColor := RGBToColor(255,180,180); lineColor := RGBToColor(214,151,159); end;   // $FFD6D6; // vinho claro 
  end; 
 
  //borda 
  Canvas.Brush.Color := bgColor; 
  Canvas.Pen.Color := lineColor; 
  Canvas.Pen.Width := 2; 
 
  R := ClientRect; 
  R.Top := 1; 
  R.Left := 1; 
  Canvas.RoundRect(R, 12, 12); 
 
  //texto 
  R := Rect(10, 10, Width - 10, Height - 10); 
  flags := DT_CENTER or DT_VCENTER or DT_WORDBREAK; 
  DrawText(Canvas.Handle, PChar(FMessage), Length(FMessage), R, flags); 
 
  //desenha o ícone correspondente 
  DrawIconAt(Canvas, 10, (Height - 30) div 2, FMessageType);   
 
  //progresso decrescente 
  if not FClosing and FShowTimer.Enabled and (FLineProgress > 0) then begin 
    Canvas.Pen.Style := psSolid; 
    Canvas.Pen.Color := clSkyBlue; 
    Canvas.Pen.Width := 4; 
    Canvas.MoveTo(10, Height - 6); 
    Canvas.LineTo(10 + FLineProgress, Height - 6); 
  end; 
end; 
 
function TMessagePopup.CalculateTextHeight(const AText: string): Integer; 
var 
  R: TRect; 
  flags: Longint; 
begin 
  R := Rect(0, 0, FFullWidth - 20, 0); 
  flags := DT_CALCRECT or DT_WORDBREAK; 
  DrawText(GetDC(0), PChar(AText), Length(AText), R, flags); 
  Result := R.Bottom - R.Top + 20; 
end; 
 
procedure TMessagePopup.DrawIconAt(ACanvas: TCanvas; AX, AY: Integer; AType: TMessagePopupType); 
begin 
  ACanvas.Pen.Width := 3; 
  ACanvas.Pen.Style := psSolid; 
  case AType of 
    mptSuccess: 
      begin 
        ACanvas.Pen.Color := clGreen; 
        ACanvas.MoveTo(AX + 5, AY + 15); 
        ACanvas.LineTo(AX + 13, AY + 25); 
        ACanvas.LineTo(AX + 25, AY + 5); 
      end; 
    mptWarning: 
      begin 
        ACanvas.Pen.Color := clOlive; 
        ACanvas.MoveTo(AX + 15, AY + 5); 
        ACanvas.LineTo(AX + 15, AY + 20); 
        ACanvas.MoveTo(AX + 15, AY + 24); 
        ACanvas.LineTo(AX + 15, AY + 26); 
      end; 
    mptFatal: 
      begin 
        ACanvas.Pen.Color := clMaroon; 
        ACanvas.MoveTo(AX + 5, AY + 5); 
        ACanvas.LineTo(AX + 25, AY + 25); 
        ACanvas.MoveTo(AX + 25, AY + 5); 
        ACanvas.LineTo(AX + 5, AY + 25); 
      end; 
  end; 
end;  
 
end. 


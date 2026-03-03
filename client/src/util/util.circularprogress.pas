unit Util.CircularProgress; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

// Circular Progress Bar 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, LCLType, LCLIntf, Controls, Graphics, ExtCtrls, Math; 
 
type 
 
  { TCircularProgress } 
 
  TCircularProgress = class(TCustomControl) 
  private 
    FCircleGradiente: Boolean; 
    FCircleFirstColor: TColor; 
    FCircleSecondColor: TColor; 
    FCircleBackColor: TColor; 
    FIsRunning: Boolean; 
    FSpeed: Single; 
    FThickness: Integer; 
    FAngleArc: Single; 
    FTimer: TTimer; 
    procedure SetCircleGradiente(AValue: Boolean); 
    procedure SetCircleFirstColor(Value: TColor); 
    procedure SetCircleSecondColor(Value: TColor); 
    procedure SetCircleBackColor(AValue: TColor); 
    procedure SetSpeed(AValue: Single); 
    procedure TimerTick(Sender: TObject); 
  protected 
    procedure Paint; override; 
    procedure Resize; override; 
    procedure DrawProgressArc; 
  public 
    constructor Create(AOwner: TComponent); override; 
    destructor Destroy; override; 
    property IsRunning: Boolean read FIsRunning; 
  published 
    property Align; 
    property Anchors; 
    property Color; 
    property Enabled; 
    property Font; 
    property Height; 
    property ParentColor; 
    property ParentFont; 
    property Visible; 
    property Width; 
 
    property CircleFirstColor: TColor read FCircleFirstColor write SetCircleFirstColor default clGreen; 
    property CircleSecondColor: TColor read FCircleSecondColor write SetCircleSecondColor default clLime; 
    property CircleBackColor: TColor read FCircleBackColor write SetCircleBackColor default clSilver; 
    property CircleGradiente: Boolean read FCircleGradiente write SetCircleGradiente default False; 
    property Speed: Single read FSpeed write SetSpeed; 
 
    procedure Start; 
    procedure Stop; 
  end; 
 
implementation 
 
constructor TCircularProgress.Create(AOwner: TComponent); 
begin 
  inherited Create(AOwner); 
  Width  := 100; 
  Height := 100; 
  FCircleFirstColor  := RGBToColor(239, 174, 23); // Laranja //TColor($00EFC317); 
  FCircleSecondColor := RGBToColor(239, 234, 77); // Amarelado claro //TColor($004DEFA4); 
  FCircleBackColor := clSilver; 
  FCircleGradiente := False; 
  FThickness := 10; 
  FAngleArc  := 90; 
  FSpeed := 10.0; 
  FIsRunning := False; 
 
  FTimer := TTimer.Create(Self); 
  FTimer.Interval := 20; 
  FTimer.OnTimer := @TimerTick; 
  FTimer.Enabled := False; 
end; 
 
destructor TCircularProgress.Destroy; 
begin 
  FTimer.Free; 
  inherited Destroy; 
end; 
 
procedure TCircularProgress.Start; 
begin 
  FIsRunning := True; 
  FAngleArc := 90; 
  FTimer.Enabled := True; 
  Invalidate; 
end; 
 
procedure TCircularProgress.Stop; 
begin 
  FIsRunning := False; 
  FTimer.Enabled := False; 
  Invalidate; 
end; 
 
procedure TCircularProgress.SetCircleGradiente(AValue: Boolean); 
begin 
  if FCircleGradiente = AValue then Exit; 
  FCircleGradiente := AValue; 
  Invalidate; 
end; 
 
procedure TCircularProgress.SetCircleFirstColor(Value: TColor); 
begin 
  if FCircleFirstColor = Value then Exit; 
  FCircleFirstColor := Value; 
  Invalidate; 
end; 
 
procedure TCircularProgress.SetCircleSecondColor(Value: TColor); 
begin 
  if FCircleSecondColor = Value then Exit; 
  FCircleSecondColor := Value; 
  Invalidate; 
end; 
 
procedure TCircularProgress.SetCircleBackColor(AValue: TColor); 
begin 
  if FCircleBackColor = AValue then Exit; 
  FCircleBackColor := AValue; 
  Invalidate; 
end; 
 
procedure TCircularProgress.SetSpeed(AValue: Single); 
begin 
  if FSpeed = AValue then Exit; 
  FSpeed := AValue; 
  Invalidate; 
end; 
 
procedure TCircularProgress.TimerTick(Sender: TObject); 
begin 
  FAngleArc := FAngleArc - FSpeed; 
  if FAngleArc <= -360 then FAngleArc := FAngleArc + 360; 
  Invalidate; 
end; 
 
procedure TCircularProgress.DrawProgressArc; 
var 
  Rect: TRect; 
  i, CenterX, CenterY, Radius: Integer; 
  StartAngle, EndAngle, SweepAngle, ArcLength: Single; 
  R1, G1, B1, R2, G2, B2: Byte; 
  R, G, B: Byte; 
begin 
  CenterX := Width div 2; 
  CenterY := Height div 2; 
  Radius := Min(Width, Height) div 2 - (FThickness div 2); 
  Rect := Bounds(CenterX - Radius, CenterY - Radius, Radius * 2, Radius * 2); 
 
  //circulo de fundo 
  Canvas.Pen.Color := FCircleBackColor; 
  Canvas.Pen.Width := FThickness; 
  Canvas.Brush.Style := bsClear; 
  Canvas.Arc(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, 
             CenterX + Radius, CenterY, CenterX + Radius, CenterY); 
 
  Canvas.Pen.Color   := FCircleFirstColor; 
  Canvas.Pen.Width   := FThickness; 
  Canvas.Brush.Style := bsClear; 
 
  if not FCircleGradiente then begin 
    //sem gradiente 
    StartAngle := FAngleArc; 
    SweepAngle := -120; //sentido horário é negativo 
 
    Canvas.Arc(Rect.Left, Rect.Top, Rect.Right, Rect.Bottom, 
      Round(CenterX + Radius * Cos(DegToRad(StartAngle + SweepAngle))), 
      Round(CenterY - Radius * Sin(DegToRad(StartAngle + SweepAngle))), 
      Round(CenterX + Radius * Cos(DegToRad(StartAngle))), 
      Round(CenterY - Radius * Sin(DegToRad(StartAngle)))); 
  end 
  else begin 
    //gradiente 
    // Extrai componentes RGB das cores inicial e final 
    RedGreenBlue(FCircleFirstColor, R1, G1, B1); 
    RedGreenBlue(FCircleSecondColor, R2, G2, B2); 
 
    ArcLength := 90; // Comprimento do arco em graus 
 
    for I := 0 to 29 do begin 
      // Interpola as cores 
      R := R1 + Round((R2 - R1) * (I / 29)); 
      G := G1 + Round((G2 - G1) * (I / 29)); 
      B := B1 + Round((B2 - B1) * (I / 29)); 
 
      Canvas.Pen.Color := RGBToColor(R, G, B); 
      StartAngle := FAngleArc + I * (ArcLength / 30); 
      EndAngle   := StartAngle + (ArcLength / 30); 
 
      Canvas.Arc( 
        CenterX - Radius, CenterY - Radius, 
        CenterX + Radius, CenterY + Radius, 
        Round(Cos(DegToRad(StartAngle)) * Radius + CenterX), 
        Round(-Sin(DegToRad(StartAngle)) * Radius + CenterY), 
        Round(Cos(DegToRad(EndAngle)) * Radius + CenterX), 
        Round(-Sin(DegToRad(EndAngle)) * Radius + CenterY) 
      ); 
    end; 
  end; 
end; 
 
procedure TCircularProgress.Paint; 
begin 
  inherited Paint; 
 
  DrawProgressArc; 
end; 
 
procedure TCircularProgress.Resize; 
begin 
  inherited Resize; 
  if Width < 60 then Width := 60; 
  if Height < 60 then Height := 60; 
  Width := Height; 
  Invalidate; 
end; 
 
end. 


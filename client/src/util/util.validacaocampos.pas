unit Util.ValidacaoCampos; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 


// validação de campos que possuem a propriedade Tag = 1 
 
{ 
 var 
   v : TUtilValidacaoCampos; 
 begin 
   v := TUtilValidacaoCampos.Create(Self); 
   if not v.IsValid then 
     ShowMessage(v.Message); 
   v.Free; 
 end; 
} 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Controls, Forms, StdCtrls, ExtCtrls, ExtDlgs, EditBtn, Spin, Graphics, Dialogs, 
  LCLType, LCLIntf, Types, MaskedEditPlus; 
 
type 
 
  { TUtilValidacaoCampos } 
 
  TUtilValidacaoCampos = class 
    private 
      FIsValid: Boolean; 
      FMessage: string; 
      FCount: Integer; 
      function GetMessage: string; 
      function GetOcorrencias: Integer; 
      procedure Validar(var AContainer: TWinControl); 
    public 
      constructor Create(AOwner: TComponent); 
      property IsValid: Boolean read FIsValid; 
      property Message: string read GetMessage; 
      property Ocorrencias: Integer read GetOcorrencias; 
  end; 
 
implementation 
 
{ TUtilValidacaoCampos } 
 
constructor TUtilValidacaoCampos.Create(AOwner: TComponent); 
begin 
  FCount := 0; 
  FMessage := ''; 
  FIsValid := True; 
  Validar( TWinControl(AOwner) ); 
end; 
 
procedure TUtilValidacaoCampos.Validar(var AContainer: TWinControl); 
//funciona mas ao clicar na tela, a linha vermelha some 
var 
  i: Integer; 
  Ctrl: TControl; 
  lCanvas: TControlCanvas; 
  R: TRect; 
begin 
 
  for i := 0 to AContainer.ControlCount - 1 do begin 
    Ctrl := AContainer.Controls[i]; 
 
    if Ctrl.Tag = 1 then begin 
      if ((Ctrl is TEdit) and (TEdit(Ctrl).Text = '')) or 
         ((Ctrl is TMemo) and (TMemo(Ctrl).Lines.Text = '')) or 
         ((Ctrl is TDateEdit) and (TDateEdit(Ctrl).Text = '')) or 
         ((Ctrl is TRadioGroup) and (TRadioGroup(Ctrl).ItemIndex = -1)) or 
         ((Ctrl is TComboBox) and (TComboBox(Ctrl).Text = '')) or 
         ((Ctrl is TSpinEdit) and (TSpinEdit(Ctrl).Value = 0)) or 
         ((Ctrl is TMaskedEditPlus) and not (TMaskedEditPlus(Ctrl).IsValid)) or 
         ((Ctrl is TMaskedEditPlus) and (TMaskedEditPlus(Ctrl).EditMode =  emCurrency) and (TMaskedEditPlus(Ctrl).CurrencyValue <= 0)) or 
         ((Ctrl is TMaskedEditPlus) and (TMaskedEditPlus(Ctrl).EditMode =  emDefault) and (TMaskedEditPlus(Ctrl).Text = ''))  then 
      begin 
        FIsValid := False; 
        FCount := FCount + 1; 
 
        if Assigned(Ctrl.Parent) then begin 
          lCanvas := TControlCanvas.Create; 
          try 
            lCanvas.Control := Ctrl.Parent; // associa ao Parent 
 
            lCanvas.Pen.Style := psDash; 
            lCanvas.Pen.Color := clRed; 
            lCanvas.Pen.Width := 2; 
 
            // posição relativa ao parent 
            R := Rect(Ctrl.Left, Ctrl.Top, Ctrl.Left + Ctrl.Width, Ctrl.Top + Ctrl.Height); 
 
            lCanvas.MoveTo(R.Left+1, R.Bottom + 1); 
            lCanvas.LineTo(R.Right-1, R.Bottom + 1); 
          finally 
            lCanvas.Free; 
          end; 
        end; 
      end; 
    end; 
 
    if Ctrl is TWinControl then 
      Validar(TWinControl(Ctrl)); 
  end; 
end; 
 
function TUtilValidacaoCampos.GetMessage: string; 
begin 
  if FCount = 0 then 
    Result := '' 
  else if FCount = 1 then 
    Result := 'Um campo requerido, marcado em vermelho!' 
  else 
    Result := 'Tem ' + IntToStr(FCount) + ' campos requeridos, marcados em vermelho!'; 
end; 
 
function TUtilValidacaoCampos.GetOcorrencias: Integer; 
begin 
  Result := FCount; 
end; 
 
end. 
 


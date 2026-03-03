unit Util.ComboBoxItemData; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

{ 
  //alimenta a combobox com itens: nome e seu id 
  cboCidades.Items.Clear; 
  cboCidades.Items.AddObject('Barretos', TComboBoxItemData.Create(1)); 
  cboCidades.Items.AddObject('Bebedouro', TComboBoxItemData.Create(20)); 
 
  //retorna o id do item selecionado 
  idCidade := TComboBoxItemData.ComboBox_GetValue( cboCidades); //-1 se não achou 
 
  //seleciona um item da combobox conforme o id indicado 
  TComboBoxItemData.ComboBox_Select( cboCidades, idCidade ); 
 
  //retorna o index da combobox de acordo com o id 
  index := TComboBoxItemData.ComboBox_GetIndexByValue(cboCidades, idCidade); //-1 se não achou 
} 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Controls, StdCtrls; 
 
type 
 
  { TComboBoxItemData } 
 
  TComboBoxItemData = class(TObject) 
    Value: Integer; 
    public 
      constructor Create(AValue: Integer); 
      class procedure ComboBox_Select(var cbox: TComboBox; AValue: Integer); 
      class function ComboBox_GetValue(var cbox: TComboBox): Integer; 
      class function ComboBox_GetIndexByValue(cbox: TComboBox; AValue: Integer): Integer; 
  end; 
 
implementation 
 
{ TComboBoxItemData } 
 
constructor TComboBoxItemData.Create(AValue: Integer); 
begin 
  Value := AValue; 
end; 
 
class procedure TComboBoxItemData.ComboBox_Select(var cbox: TComboBox; AValue: Integer); 
// Seleciona o item na combobox conforme o AValue/ID indicado 
var 
  i: Integer; 
begin 
  for i := 0 to cbox.Items.Count -1 do begin 
    if TComboBoxItemData( cbox.Items.Objects[i] ).Value = AValue then begin 
      cbox.ItemIndex := i; 
      Break; 
    end; 
  end; 
end; 
 
class function TComboBoxItemData.ComboBox_GetValue(var cbox: TComboBox): Integer; 
// Retorna o Value/ID do item selecionado na combobox 
begin 
  Result := -1; 
 
  if cbox.Items.Count > 0 then begin 
     try 
       Result := TComboBoxItemData( cbox.Items.Objects[ cbox.ItemIndex ] ).Value; 
     except 
     end; 
  end; 
end; 
 
class function TComboBoxItemData.ComboBox_GetIndexByValue(cbox: TComboBox; AValue: Integer): Integer; 
// Retorna o indice do item conforme o AValue/ID a ser pesquisado 
var 
  i: Integer; 
begin 
  Result := -1; 
 
  try 
    for i := 0 to cbox.Items.Count -1 do 
      if TComboBoxItemData( cbox.Items.Objects[ i ] ).Value = AValue then begin 
         Result := i; 
         Break; 
      end; 
  except 
  end; 
 
end; 
 
end. 


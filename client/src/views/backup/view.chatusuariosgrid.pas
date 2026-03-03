unit View.ChatUsuariosGrid; 

{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Buttons,
  DBGrids, DB, DBGridPlus, MaskedEditPlus; 
 
type 
 
  { TfrmChatUsuariosGrid } 
 
  TfrmChatUsuariosGrid = class(TForm) 
    btnRetornar: TSpeedButton;
    dbgUsuarios: TDBGridPlus;
    edtPesquisar: TMaskedEditPlus; 
    lblPesquisa: TLabel; 
    lblPesquisaRecQde: TLabel; 
    lblPesquisaRec: TLabel; 
    lblLineTop: TLabel;
    lblTitulo1: TLabel;
    lblTitulo2: TLabel;
    panTitulo: TPanel; 
    procedure btnRetornarClick(Sender: TObject); 
    procedure dbgUsuariosCellClick(Column: TColumn);
    procedure dbgUsuariosUserCheckboxState(Sender: TObject; Column: TColumn; var AState: TCheckboxState);
    procedure edtPesquisarChange(Sender: TObject); 
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject); 
  private
    FExcludedListID: string;
    RecList: TBookmarklist;
    FListaConvidadosID: TStringList;
    FSelecionou: Boolean; 
    FCodigoID: Integer; 
    FTextoSelecionado, FCampoPesquisa: string; 
    procedure CarregaGrid; 
  public 
    property CampoPesquisa: string read FCampoPesquisa write FCampoPesquisa; 
    property Selecionou: Boolean read FSelecionou;
    property ListaConvidados: TStringList read FListaConvidadosID;
    property ExcludedListID: string read FExcludedListID write FExcludedListID;
  end; 
 
var 
  frmChatUsuariosGrid: TfrmChatUsuariosGrid; 
 
implementation 
 
Uses 
  Service.Usuario;
 
{$R *.lfm} 
 
{ TfrmChatUsuariosGrid } 

procedure TfrmChatUsuariosGrid.FormCreate(Sender: TObject);
begin
  RecList := TBookmarkList.Create(dbgUsuarios);
  FListaConvidadosID := TStringList.Create;
  FListaConvidadosID.Sorted := True;
end;

procedure TfrmChatUsuariosGrid.FormDestroy(Sender: TObject);
begin
  if Assigned(RecList) then RecList.Free;
  FListaConvidadosID.Free;
end;

procedure TfrmChatUsuariosGrid.FormShow(Sender: TObject); 
begin 
  FCodigoID := 0; 
  FTextoSelecionado := '';
  FSelecionou := False; 
  CarregaGrid; 
end;

procedure TfrmChatUsuariosGrid.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if (dbgUsuarios.DataSource <> nil) and (dbgUsuarios.DataSource.DataSet <> nil) then
    dbgUsuarios.DataSource.DataSet.Close;
  if not FSelecionou then begin
    FCodigoID := 0;
    FTextoSelecionado := '';
  end;
end;

procedure TfrmChatUsuariosGrid.edtPesquisarChange(Sender: TObject);
begin
 CarregaGrid;
end;
 
procedure TfrmChatUsuariosGrid.btnRetornarClick(Sender: TObject); 
begin 
  if FListaConvidadosID.Count < 1 then begin
    ShowMessage('Selecione um usuário na grid!');
    Exit; 
  end; 
 
  ModalResult := mrOK; 
  FSelecionou := True; 
  Close; 
end; 
 
procedure TfrmChatUsuariosGrid.dbgUsuariosCellClick(Column: TColumn);
var
  lIDAtual, lNomeUser: string;
  idx: Integer;
  bAchou: Boolean;
begin
  if Column.Index = 6 then begin
    RecList.CurrentRowSelected := not RecList.CurrentRowSelected;
    lIDAtual  := dbgUsuarios.DataSource.DataSet.FieldByName('idusuario').AsString;
    lNomeUser := dbgUsuarios.DataSource.DataSet.FieldByName('nome').AsString;
    
    bAchou := FListaConvidadosID.Find(lNomeUser + '|' + lIDAtual, idx); //idx = 1,2,..,n

    if (RecList.CurrentRowSelected) and (not bAchou) then
      FListaConvidadosID.Add(lNomeUser + '|' + lIDAtual)
    else if idx > 0 then
      FListaConvidadosID.Delete(idx);
  end;
end;

procedure TfrmChatUsuariosGrid.dbgUsuariosUserCheckboxState(Sender: TObject; Column: TColumn; var AState: TCheckboxState);
begin
  if RecList.CurrentRowSelected then
    AState := cbChecked
  else
    AState := cbUnchecked;
end;
 
procedure TfrmChatUsuariosGrid.CarregaGrid; 
begin 
  dbgUsuarios.ClearRows;

  with TServiceUsuario.Create() do Begin 
    dbgUsuarios.DataSource := DataSetGridChatUsuarios( Trim(edtPesquisar.Text), FExcludedListID );
  end;

  if (dbgUsuarios.DataSource <> nil) and (dbgUsuarios.DataSource.DataSet <> nil) then begin
    try 
      lblPesquisaRecQde.Caption := dbgUsuarios.DataSource.DataSet.RecordCount.ToString;
    except 
    end; 
  end else 
    lblPesquisaRecQde.Caption := '0'; 
end; 
 
end. 


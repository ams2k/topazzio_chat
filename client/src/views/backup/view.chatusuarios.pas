unit View.ChatUsuarios; 

{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, Buttons,
  DB, ChatLayoutManager;
 
type 
 
  { TfrmChatUsuarios } 
 
  TfrmChatUsuarios = class(TForm)
    imgIcons30: TImageList;
    panTitulo: TPanel;
    lblTitulo1: TLabel;
    lblTitulo2: TLabel;
    lblLineTop: TLabel;
    scrConvidados: TScrollBox;
    btnRetornar: TSpeedButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure scrConvidadosResize(Sender: TObject);
    procedure btnRetornarClick(Sender: TObject);
  private
    ConvidadosLayout: TChatLayoutManager;
    FListaExcluidosID: string;
    FListaConvidadosID: TStringList;
    FSelecionou: Boolean; 
    FCampoPesquisa: string;
    procedure CarregaLista;
    procedure ClickEvent(AIDUser: Integer; ANomeUser: string; ASelected: Boolean);
  public 
    property CampoPesquisa: string read FCampoPesquisa write FCampoPesquisa; 
    property Selecionou: Boolean read FSelecionou;
    property ListaConvidados: TStringList read FListaConvidadosID;
    property ListaExcluidos: string read FListaExcluidosID write FListaExcluidosID; //1,2,3
  end; 
 
var 
  frmChatUsuarios: TfrmChatUsuarios; 
 
implementation 
 
Uses 
  Service.Usuario, ChatUserSelect;
 
{$R *.lfm} 
 
{ TfrmChatUsuarios } 

procedure TfrmChatUsuarios.FormCreate(Sender: TObject);
begin
  ConvidadosLayout := TChatLayoutManager.Create(scrConvidados);
  FListaConvidadosID := TStringList.Create;
end;

procedure TfrmChatUsuarios.FormDestroy(Sender: TObject);
begin
  FListaConvidadosID.Free;
  ConvidadosLayout.Free;
end;

procedure TfrmChatUsuarios.FormShow(Sender: TObject); 
begin 
  FSelecionou := False; 
  CarregaLista;
end;

procedure TfrmChatUsuarios.scrConvidadosResize(Sender: TObject);
begin
  ConvidadosLayout.RecalculateLayout;
end;

procedure TfrmChatUsuarios.btnRetornarClick(Sender: TObject); 
begin 
  if FListaConvidadosID.Count < 1 then begin
    ShowMessage('Selecione um usuário na lista!');
    Exit; 
  end; 

  ModalResult := mrOK; 
  FSelecionou := True; 
  Close; 
end; 

procedure TfrmChatUsuarios.CarregaLista;
//exibe a lista de convidados
var
  FDados: TDataSource;
  u: TChatUserSelect;
  i: Integer;
begin
  with TServiceUsuario.Create() do Begin 
    FDados := DataSetGridChatUsuarios( '', FListaExcluidosID );
    i := 0;
    while not FDados.DataSet.EOF do begin
      u := TChatUserSelect.Create(scrConvidados);
      u.Parent := scrConvidados;
      u.ImageList := imgIcons30;
      u.OnClickInfo := @ClickEvent;
      U.Setup( FDados.DataSet.FieldByName('idusuario').AsInteger, i );

      ConvidadosLayout.AddUserSelect( u );
      i := 1 - i; //para alternar a cor dos objetos
      FDados.DataSet.Next;
    end;
  end;
end;

procedure TfrmChatUsuarios.ClickEvent(AIDUser: Integer; ANomeUser: string; ASelected: Boolean);
//click num dos usuários da lista
var
  idx: Integer;
  bAchou: Boolean;
begin
  FListaConvidadosID.Sorted := True;
  bAchou := FListaConvidadosID.Find(ANomeUser + '|' + AIDUser.ToString, idx); //idx = 1,2,..,n

  if ASelected and not bAchou then
    FListaConvidadosID.Add(ANomeUser + '|' + AIDUser.ToString)
  else if idx > 0 then
    FListaConvidadosID.Delete(idx);
end;
 
end. 


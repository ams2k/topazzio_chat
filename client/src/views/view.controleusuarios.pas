unit View.ControleUsuarios; 
 
(*
 Tela de controle de usuários
 Aldo Márcio Soares | ams2kg@gmail.com  | 2025-12-31
*)

// controle de usuários 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, Buttons, 
  StdCtrls, ExtDlgs, DBGrids, DB, DBGridPlus, MaskedEditPlus, CheckBoxPlus; 
 
type 
 
  { TfrmControleUsuarios } 
 
  TfrmControleUsuarios = class(TForm) 
    btnCarregarFoto: TSpeedButton; 
    btnExcluir: TSpeedButton; 
    btnLimparFoto: TSpeedButton; 
    btnNovo: TSpeedButton; 
    btnSalvar: TSpeedButton; 
    chkIsAdmin: TCheckBoxPlus; 
    chkIsAtivo: TCheckBoxPlus; 
    dbgUsuarios: TDBGridPlus; 
    edtIdUsuario: TMaskedEditPlus; 
    edtSenha: TMaskedEditPlus; 
    edtLogin: TMaskedEditPlus; 
    edtNome: TMaskedEditPlus; 
    edtPesquisa: TEdit; 
    edtEmail: TMaskedEditPlus; 
    imgFoto: TImage; 
    lblEmail: TLabel; 
    lblLinha: TLabel; 
    lblLogin: TLabel; 
    lblSenha: TLabel; 
    lblNome: TLabel; 
    lblPesquisaProduto: TLabel; 
    lblPesquisaRec: TLabel; 
    lblPesquisaRecQde: TLabel;
    lblTitulo1: TLabel;
    lblTitulo2: TLabel;
    panFoto: TPanel; 
    panTitulo: TPanel; 
    procedure btnCarregarFotoClick(Sender: TObject); 
    procedure btnExcluirClick(Sender: TObject); 
    procedure btnLimparFotoClick(Sender: TObject); 
    procedure btnNovoClick(Sender: TObject); 
    procedure btnSalvarClick(Sender: TObject); 
    procedure dbgUsuariosCellClick(Column: TColumn); 
    procedure edtPesquisaChange(Sender: TObject); 
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormShow(Sender: TObject); 
  private 
    FUsuarioID: Integer;
    FCriarAvatar: Boolean;
    FDataChanged: Boolean;
    function ChecaCamposRequeridos: string; 
    procedure LimparUsuario; 
    procedure CarregarUsuario(AId: integer); 
    procedure SalvarUsuario(AId: integer); 
    procedure ExcluirUsuario(AId: integer); 
    procedure CarregaGrid;
    procedure DataChanged(Sender: TObject);
  public 
    Avatar_ID: Integer; 
    Avatar_Alterado: Boolean; 
  end; 
 
var 
  frmControleUsuarios: TfrmControleUsuarios; 
 
implementation 
 
Uses 
  Service.Usuario, Util.MessagePopup, Util.ValidacaoCampos, 
  View.MessageQuery, Util.Imagem; 
 
{$R *.lfm} 
 
{ TfrmControleUsuarios } 
 
 
procedure TfrmControleUsuarios.FormClose(Sender: TObject; var CloseAction: TCloseAction); 
begin 
  if (dbgUsuarios.DataSource<>nil) and (dbgUsuarios.DataSource.DataSet<>nil) then 
    dbgUsuarios.DataSource.DataSet.Close; 
end;

procedure TfrmControleUsuarios.FormShow(Sender: TObject); 
begin
  FCriarAvatar := True;
  LimparUsuario; 
  CarregaGrid; 
end; 
 
procedure TfrmControleUsuarios.btnSalvarClick(Sender: TObject); 
var 
  msg, titulo: string; 
begin 
  { validação dos campos necessários: TAG = 1 } 
  msg := ChecaCamposRequeridos; 
  if msg <> '' then begin 
    if ShowMessageQuery(self,'Campos requeridos', msg, 'Corrigir', 'Ignorar','',icQuestion) = mrYes then 
      Exit; 
  end; 
 
  Invalidate; 
 
  if FUsuarioID < 1 then begin 
    titulo := 'Inclusão'; 
    msg := 'Confirma a inclusão deste novo usuário ?'; 
  end else begin 
    titulo := 'Alteração'; 
    msg := 'Confirma as alterações deste usuário ?'; 
  end; 
 
  if ShowMessageQuery(self,titulo, msg, 'Sim','Não','',icQuestion) <> mrYes then 
     Exit; 
 
  SalvarUsuario(FUsuarioID); 
end; 
 
procedure TfrmControleUsuarios.btnExcluirClick(Sender: TObject); 
begin 
  if FUsuarioID < 1 then begin 
    ShowMessageQuery(self,'Atenção', 'Não há um usuário selecionado para excluir!', 'OK','','',icWarning); 
    Exit; 
  end; 
 
  if ShowMessageQuery(self,'Atenção', 'Deseja excluir este usuário ?', 'Sim','Não','',icQuestion) <> mrYes then 
     Exit; 
 
  ExcluirUsuario(FUsuarioID); 
end; 
 
procedure TfrmControleUsuarios.btnNovoClick(Sender: TObject); 
begin 
  if FDataChanged then begin
    case ShowMessageQuery(self,'Sair do Sistema','Dados alterados não salvos!' + sLineBreak + sLineBreak +
                          'Salvar dados agora ?','Sim','Não','Cancelar',icQuestion) of
      mrYes: btnSalvarClick(btnSalvar);
      mrCancel: Exit;
    end;
  end;
  LimparUsuario;
  edtNome.SetFocus; 
end; 
 
procedure TfrmControleUsuarios.btnCarregarFotoClick(Sender: TObject); 
begin 
  with TOpenPictureDialog.Create(self) do begin 
    if Execute then 
      if FileName<>'' then begin
        if FCriarAvatar then
          TUtilImagem.CreateAvatarFromFile(imgFoto, FileName, imgFoto.Width - 2)
        else
          imgFoto.Picture.LoadFromFile(FileName);
        TUtilImagem.ResizeToImageBox(imgFoto);
      end; 
    Free; 
  end; 
 
  if imgFoto.Picture <> nil then 
    imgFoto.Stretch := (imgFoto.Picture.Bitmap.Width > imgFoto.Width); 
end; 
 
procedure TfrmControleUsuarios.btnLimparFotoClick(Sender: TObject); 
begin 
  imgFoto.Picture := nil; 
end; 
 
procedure TfrmControleUsuarios.dbgUsuariosCellClick(Column: TColumn); 
begin 
  if (dbgUsuarios.DataSource = nil) or (dbgUsuarios.DataSource.DataSet.RecordCount < 1) then Exit; 
  edtIdUsuario.Text := dbgUsuarios.Data_GetField('idusuario').AsString; 
  FUsuarioID := dbgUsuarios.Data_GetField('idusuario').AsInteger; 
  CarregarUsuario(FUsuarioID); 
end; 
 
procedure TfrmControleUsuarios.edtPesquisaChange(Sender: TObject); 
begin 
  if (dbgUsuarios.DataSource = nil) or (dbgUsuarios.DataSource.DataSet = nil) then Exit; 
 
  try 
    with dbgUsuarios.DataSource.DataSet do begin 
      FilterOptions := [foCaseInsensitive]; //Uses DB 
      Filtered := False; 
      Filter   := ' nome+login like ' + QuotedStr('*' + edtPesquisa.Text + '*'); 
      Filtered := True; 
      lblPesquisaRecQde.Caption := RecordCount.ToString; 
    end; 
  except 
  end; 
end; 
 
function TfrmControleUsuarios.ChecaCamposRequeridos: string; 
//checa se os campos requeridos são válidos 
var 
  v: TUtilValidacaoCampos; 
begin 
  v := TUtilValidacaoCampos.Create(Self); 
  Result := v.Message; 
  v.Free; 
 
  if Result <> '' then 
    Result := Result + sLineBreak + sLineBreak + 'Ignorar ou Corrigir os campos ?'; 
end; 
 
procedure TfrmControleUsuarios.CarregarUsuario(AId: integer); 
//ler dados de um usuário 
var 
  u: TServiceUsuario; 
begin 
  LimparUsuario; 
 
  u := TServiceUsuario.Create; 
  u.Ler(AId); 
 
  if u.Sucesso then begin 
    FUsuarioID := AId; 
    edtIdUsuario.Text  := AId.ToString; 
    chkIsAdmin.Checked := u.IsAdmin; 
    chkIsAdmin.Checked := u.IsAtivo; 
    edtNome.Text  := u.Nome; 
    edtLogin.Text := u.Login; 
    edtSenha.Text := u.Senha; 
    edtEmail.Text := u.Email; 
    imgFoto.Picture.Assign( u.Foto.Picture ); 
 
    if imgFoto.Picture <> nil then 
      imgFoto.Stretch := (imgFoto.Picture.Bitmap.Width > imgFoto.Width); 
  end else 
    ShowPopupMessage(self, u.GetMensagem, mptFatal); 
 
  u.Free; 
end; 
 
procedure TfrmControleUsuarios.SalvarUsuario(AId: integer); 
//cadastra ou altera um usuário 
var 
  u: TServiceUsuario; 
begin 
  u := TServiceUsuario.Create; 
 
  u.IsAdmin := chkIsAdmin.Checked; 
  u.IsAtivo := chkIsAdmin.Checked; 
  u.Nome    := Trim(edtNome.Text); 
  u.Login   := Trim(edtLogin.Text); 
  u.Senha   := Trim(edtSenha.Text); 
  u.Email   := Trim(edtEmail.Text); 
  u.Foto.Picture.Assign( imgFoto.Picture ); 
 
  u.Salvar(AId); 
 
  if u.Sucesso then begin 
    if u.IdUsuario > 0 then begin 
      FUsuarioID := u.IdUsuario; 
      edtIdUsuario.Text := u.IdUsuario.ToString;
      FDataChanged := False;
    end else 
      LimparUsuario; 
 
    if AId = Avatar_ID then Avatar_Alterado := True; 
    CarregaGrid; 
    ShowPopupMessage(self, u.GetMensagem, mptSuccess); 
  end else 
    ShowPopupMessage(self, u.GetMensagem, mptFatal); 
 
  u.Free; 
end; 
 
procedure TfrmControleUsuarios.ExcluirUsuario(AId: integer); 
//exclui o usuário 
var 
  u: TServiceUsuario; 
begin 
  u := TServiceUsuario.Create; 
  u.Excluir(AId); 
 
  if u.Sucesso then begin 
    LimparUsuario; 
    CarregaGrid; 
    ShowPopupMessage(self, u.GetMensagem, mptSuccess); 
  end else 
    ShowPopupMessage(self, u.GetMensagem, mptFatal); 

  u.Free; 
end; 
 
procedure TfrmControleUsuarios.LimparUsuario; 
begin 
  Invalidate; 
  FUsuarioID := 0; 
  edtIdUsuario.Clear; 
  edtNome.Clear; 
  edtLogin.Clear; 
  edtSenha.Clear; 
  edtEmail.Clear; 
  imgFoto.Picture := nil;
  FDataChanged := False;
end; 
 
procedure TfrmControleUsuarios.CarregaGrid; 
//carrega a grid com os usuários 
begin 
  dbgUsuarios.ClearRows; 
 
  with TServiceUsuario.Create do begin 
    dbgUsuarios.DataSource := DataSetGrid(''); 
  end; 
 
  if (dbgUsuarios.DataSource <> nil) and (dbgUsuarios.DataSource.DataSet <> nil) then begin 
    try 
      lblPesquisaRecQde.Caption := dbgUsuarios.DataSource.DataSet.RecordCount.ToString; 
    except 
    end; 
  end else 
    lblPesquisaRecQde.Caption := '0'; 
end;

procedure TfrmControleUsuarios.DataChanged(Sender: TObject);
// algum maskededitplus alterado
begin
  FDataChanged := True;
end;
 
end. 
 


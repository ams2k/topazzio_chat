unit View.Login; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, 
  StdCtrls, Buttons, MaskedEditPlus;
 
type 
 
  { TfrmLogin } 
 
  TfrmLogin = class(TForm) 
    btnErroDesistir: TSpeedButton; 
    btnSenhaDesistir: TSpeedButton; 
    btnLoginEntrar: TSpeedButton; 
    btnLoginDesistir: TSpeedButton; 
    btnBemVindoProsseguir: TSpeedButton; 
    btnAlterarSenha: TSpeedButton; 
    edtNovaSenhaRepetir: TMaskedEditPlus; 
    edtLoginUsuario: TMaskedEditPlus; 
    edtLoginSenha: TMaskedEditPlus; 
    edtNovaSenha: TMaskedEditPlus; 
    imgErro: TImage; 
    imgLogin: TImage; 
    imgBemVindo: TImage; 
    imgNovaSenha: TImage; 
    imgLogo: TImage; 
    lblAlterarSenha: TLabel; 
    lblLogin1: TLabel; 
    lblRepetirNovaSenha: TLabel; 
    lblLoginUsuario: TLabel; 
    lblBemVindoUltimoAcesso: TLabel; 
    lblErro: TLabel; 
    lblLogin: TLabel; 
    lblBemVindo: TLabel; 
    lblLoginSenha: TLabel; 
    lblNovaSenha: TLabel; 
    lblNomeProjeto: TLabel; 
    Notebook1: TNotebook; 
    PageAlterarSenha: TPage; 
    PageBemVindo: TPage; 
    PageLogin: TPage; 
    PageErro: TPage; 
    panNovaSenha: TPanel; 
    panErro: TPanel; 
    panEmpresa: TPanel; 
    btnErroTentar: TSpeedButton; 
    panLogin: TPanel; 
    panBemVindo: TPanel; 
    Timer1: TTimer; 
    procedure btnAlterarSenhaClick(Sender: TObject); 
    procedure btnBemVindoProsseguirClick(Sender: TObject); 
    procedure btnErroDesistirClick(Sender: TObject); 
    procedure btnErroTentarClick(Sender: TObject); 
    procedure btnLoginDesistirClick(Sender: TObject); 
    procedure btnLoginEntrarClick(Sender: TObject); 
    procedure btnSenhaDesistirClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject); 
    procedure lblAlterarSenhaClick(Sender: TObject); 
    procedure Timer1Timer(Sender: TObject); 
  private 
    FExibeErro, FExibeLogin, FExibeBoasVindas, FExibirAlterarSenha: Boolean; 
    MaxWidth, FSpeed :Integer; 
    procedure ValidaLogin; 
    procedure ChecaUsuarios; 
    procedure AlterarSenha; 
  public 
    Usuario_ID: Integer; 
    class function new(): TfrmLogin; 
  end; 
 
var 
  frmLogin: TfrmLogin; 
 
implementation 
 
uses 
  Service.Usuario, Util.Imagem, View.MessageQuery; 
 
{$R *.lfm} 
 
{ TfrmLogin } 
 
class function TfrmLogin.new(): TfrmLogin; 
begin 
  Result := TfrmLogin.Create(nil); 
end;  
 
procedure TfrmLogin.FormShow(Sender: TObject); 
begin
  FSpeed := 12; 
  Notebook1.PageIndex := 1; 
  imgNovaSenha.Picture := imgLogin.Picture; 
  Usuario_ID := 0; 
  FExibeErro := False; 
  FExibeLogin := False; 
  FExibeBoasVindas := False; 
  FExibirAlterarSenha := False; 
  MaxWidth := 402; 
  ChecaUsuarios; 
end; 
 
procedure TfrmLogin.Timer1Timer(Sender: TObject); 
begin 
  if FExibeErro then begin 
    panErro.Width := panErro.Width + FSpeed; 
    if panErro.Width >= MaxWidth then begin 
      panErro.Width := MaxWidth; 
      FExibeErro := False; 
    end; 
  end; 
  if FExibeLogin then begin 
    panLogin.Width := panLogin.Width + FSpeed; 
    if panLogin.Width >= MaxWidth then begin 
       panLogin.Width := MaxWidth; 
       FExibeLogin := False; 
    end; 
  end; 
  if FExibeBoasVindas then begin 
    panBemVindo.Width := panBemVindo.Width + FSpeed; 
    if panBemVindo.Width >= MaxWidth then begin 
      panBemVindo.Width := MaxWidth; 
      FExibeBoasVindas := False; 
    end; 
  end; 
  if FExibirAlterarSenha then begin 
    panNovaSenha.Width := panNovaSenha.Width + FSpeed; 
    if panNovaSenha.Width >= MaxWidth then begin 
      panNovaSenha.Width := MaxWidth; 
      FExibirAlterarSenha := False; 
    end; 
  end; 
end; 
 
procedure TfrmLogin.ValidaLogin; 
//verifica se as credencias são válidas 
var 
  u: TServiceUsuario; 
  nome: string; 
begin 
  u := TServiceUsuario.Create; 
  u.FazerLogin(edtLoginUsuario.Text, edtLoginSenha.Text); 
 
  if u.Sucesso then begin 
    nome := u.Nome.Split([' '], TStringSplitOptions.ExcludeEmpty)[0]; 
    Usuario_ID := u.IdUsuario; 
    imgBemVindo.Picture.Bitmap := u.Foto.Picture.Bitmap; 
 
    if imgBemVindo.Picture <> nil then begin
      TUtilImagem.AvatarBorder(imgBemVindo, clSilver, 4);
      //TUtilImagem.ResizeToImageBox(imgBemVindo); 
      //imgBemVindo.Stretch := (imgBemVindo.Picture.Bitmap.Width > imgBemVindo.Width); 
    end; 
 
    lblBemVindo.Caption := 'Olá, ' + nome + '!' + sLineBreak + 'Bem vindo(a).'; 
 
    if u.DataUltimoLogin > 0 then 
      lblBemVindoUltimoAcesso.Caption := 'Seu último acesso foi em' + sLineBreak + 
                                         FormatDateTime('dd/mm/yyyy hh:nn:ss', u.DataUltimoLogin) 
    else 
      lblBemVindoUltimoAcesso.Caption := 'Este é seu primeiro acesso.'; 
 
    //ir para a tela de boas vindas 
    panBemVindo.Width := 1; 
    Notebook1.PageIndex := 2; 
    FExibeBoasVindas := True; 
  end 
  else begin 
    panErro.Width := 1; 
    Notebook1.PageIndex := 0; 
    FExibeErro := True; 
  end; 
 
  u.Free; 
end; 
 
procedure TfrmLogin.ChecaUsuarios; 
//verifica se tem apenas o usuario inicial 
begin 
  with TServiceUsuario.Create do begin 
    if TotalUsuarios <= 1 then begin 
      edtLoginUsuario.Text := Login; 
      edtLoginSenha.Text := Senha; 
    end; 
    Free; 
  end; 
  edtLoginUsuario.SetFocus; 
end; 
 
procedure TfrmLogin.btnErroTentarClick(Sender: TObject); 
//tentar login novamente 
begin 
  panLogin.Width := 1; 
  Notebook1.PageIndex := 1; 
  FExibeLogin := True; 
end; 
 
procedure TfrmLogin.btnLoginDesistirClick(Sender: TObject); 
begin 
  if ShowMessageQuery(self,'LOGIN', 'Desistir de entrar no sistema ?', 'Sim', 'Não','',icQuestion) <> mrYes then 
    Exit; 
 
  ModalResult := mrNo; 
  Close; 
end; 
 
procedure TfrmLogin.btnLoginEntrarClick(Sender: TObject); 
//validação do usuário 
begin 
  ValidaLogin; 
end; 
 
procedure TfrmLogin.btnSenhaDesistirClick(Sender: TObject); 
//desistir de alterar a senha 
begin 
  panBemVindo.Width := 1; 
  Notebook1.PageIndex := 2; 
  FExibeBoasVindas := True; 
end;

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  KeyPreview := True;
end;
 
procedure TfrmLogin.btnErroDesistirClick(Sender: TObject); 
//falha na autenticação, desistir 
begin 
  ModalResult := mrNo; 
  Close; 
end; 
 
procedure TfrmLogin.btnBemVindoProsseguirClick(Sender: TObject); 
//concluir, abrindo a tela principal 
begin 
  ModalResult := mrOK; 
  Close; 
end; 
 
procedure TfrmLogin.lblAlterarSenhaClick(Sender: TObject); 
//exibir painel para alterar a senha 
begin 
  panNovaSenha.Width := 1; 
  Notebook1.PageIndex := 3; 
  FExibirAlterarSenha := True; 
end; 
 
procedure TfrmLogin.btnAlterarSenhaClick(Sender: TObject); 
//alterar a senha 
begin 
  if (Trim(edtNovaSenha.Text) = '') or (edtNovaSenha.Text = edtLoginSenha.Text) then begin 
    ShowMessageSimple(self, 'Informe uma nova senha!', icWarning); 
    Exit; 
  end; 
 
  if Trim(edtNovaSenha.Text) <> Trim(edtNovaSenhaRepetir.Text) then begin 
    ShowMessageSimple(self, 'As senhas não coincidem!', icNegative); 
    Exit; 
  end; 
 
  if ShowMessageQuery(self,'Alterar Senha', 'Confirma a alteração da senha ?', 'Sim','Não','',icQuestion) <> mrYes then 
    Exit; 
 
  AlterarSenha; 
end; 
 
procedure TfrmLogin.AlterarSenha; 
//altera a senha no banco de dados 
var 
  u: TServiceUsuario; 
begin 
  u := TServiceUsuario.Create; 
  u.AlterarSenha(Usuario_ID, Trim(edtNovaSenha.Text)); 
 
  if u.Sucesso then begin 
    ShowMessageSimple(self, u.GetMensagem, icPositive); 
    panBemVindo.Width := 1; 
    Notebook1.PageIndex := 2; 
    FExibeBoasVindas := True; 
  end else 
    ShowMessageSimple(self, u.GetMensagem, icNegative); 
 
  u.Free; 
end; 
 
end. 
 


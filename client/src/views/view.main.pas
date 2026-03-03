unit View.Main;

(*
   Demo para o Topazzio Chat
   Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    btnChatHistorico: TSpeedButton;
    lblTitulo1: TLabel;
    lblTitulo2: TLabel;
    btnControleUsuarios: TSpeedButton;
    imgMenuItens: TImageList;
    lblLineTop: TLabel;
    panStatus: TPanel;
    panTopo: TPanel;
    imgLoginDM: TImage;
    lblNomeUsuarioDM: TLabel;
    lblLoginLogoff: TLabel;    

    { chat }
    scrChatUnreadMessages: TScrollBox;
    TimerChat: TTimer;
    imgChatIcons: TImageList;
    imgChatMsg: TImage;
    lblChatStatus: TLabel;
    lblChatLoginStatus: TLabel;

    procedure btnControleUsuariosClick(Sender: TObject);
    procedure btnChatHistoricoClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure lblLoginLogoffClick(Sender: TObject);
    { chat }
    procedure imgChatMsgClick(Sender: TObject);
    procedure TimerChatTimer(Sender: TObject);
  private
    FSair: Boolean;
    bAlterado: Boolean;
    Usuario_ID: Integer;
    Usuario_Nome: String;
    Usuario_Login: String;
    Usuario_Admin: Boolean;
    procedure Autenticar;
    procedure CarregaUsuario;
    procedure ChatManager(ACreate: Boolean);
  public
    property GetUsuario_ID: Integer read Usuario_ID;
    property GetUsuario_Nome: string read Usuario_Nome;
    property GetUsuario_Login: string read Usuario_Login;
    { chat }
    procedure ChatConnectionStatus(AMessage: string; AOnline: Boolean);
    procedure ChatLoginStatus(AMessage: String; ALogged: Boolean);
    //procedure ListaUsuarios(AStrArrayUsers: string);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ChatModule,
  View.Login, View.Chat, View.MessageQuery, View.ControleUsuarios,
  Service.Usuario;

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  KeyPreview := True;
  FSair := False;
  Usuario_ID := 0;
  Usuario_Nome := '';
  Usuario_Admin:= False;

  // chat
  lblChatStatus.Caption := '';
  lblChatLoginStatus.Caption := '';
  ChatManager(True);

  //f := TfrmSplash.Create(nil);
  //f.ShowModal;
  //f.Destroy;

  //autenticação do usuário
  Autenticar;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if not FSair then begin
    CanClose := False;
    lblLoginLogoffClick(lblLoginLogoff);
    Exit;
  end;
end;

procedure TfrmMain.ChatConnectionStatus(AMessage: string; AOnline: Boolean);
//status da conexão com o chat server
begin
  if Application.Terminated then Exit;
  if not Assigned(ChatClient) then Exit;
  lblChatStatus.Hint := AMessage;
  if AOnline then begin
    lblChatStatus.Caption := 'Chat Server ON';
    imgChatMsg.ImageIndex := 0;
    imgChatMsg.Hint := 'Chat Server Conectado';

    if Usuario_ID > 0 then //tenta efetua login no chat
      ChatClient.LogIn(Usuario_ID, Usuario_Nome);
  end else begin
    lblChatStatus.Caption := 'Chat Server OFF';
    imgChatMsg.ImageIndex := 2;
    imgChatMsg.Hint := AMessage;
  end;
end;

procedure TfrmMain.ChatLoginStatus(AMessage: String; ALogged: Boolean);
//status do login no chat server
begin
  if Application.Terminated then Exit;
  lblChatLoginStatus.Hint := AMessage;
  if ALogged then begin
    lblChatLoginStatus.Caption := 'Logado no Chat';
    imgChatMsg.ImageIndex := 1;
    imgChatMsg.Hint := 'Iniciar uma conversa';
  end else begin
    lblChatLoginStatus.Caption := 'Não Logado no Chat';
    imgChatMsg.ImageIndex := 0;
    imgChatMsg.Hint := AMessage;
  end;
end;

procedure TfrmMain.imgChatMsgClick(Sender: TObject);
//iniciar um novo chat
begin
  if not Assigned(ChatClient) then Exit;
  if (Usuario_ID > 0) and (ChatClient.IsLogged()) then begin
    ChatClient.Chat_Open('', '', False);
  end else begin
    ShowMessageSimple(Self, 'Não Logado/conectado no servidor do chat!' +
                      sLineBreak + ChatClient.GetErroServidor, icWarning);
    if (Usuario_ID > 0) and (ChatClient.IsConectado()) then //tenta efetua login no chat
      ChatClient.LogIn(Usuario_ID, Usuario_Nome);
  end;
end;

procedure TfrmMain.TimerChatTimer(Sender: TObject);
//se cair a conexão do chat, tenta conectar novamente
begin
  if Assigned(ChatClient) then begin
    if not ChatClient.IsConectado() then
      ChatClient.Conectar
    else if not ChatClient.IsLogged() and (Usuario_ID > 0) then
      ChatClient.LogIn(Usuario_ID, Usuario_Nome);
  end;
end;

procedure TfrmMain.btnControleUsuariosClick(Sender: TObject);
//cadastro de usuários
var
  f: TfrmControleUsuarios;
begin
  f := TfrmControleUsuarios.Create(Self);
  f.Avatar_ID := Usuario_ID;
  f.ShowModal;
  bAlterado := f.Avatar_Alterado;
  f.Free;
  if bAlterado then CarregaUsuario;
end;

procedure TfrmMain.btnChatHistoricoClick(Sender: TObject);
// tela de historico do chat do usuário
begin
  if ChatClient.IsConectado() then
    ChatClient.ChatHistory_Control('')
  else
    ShowMessageSimple(Self, 'Você não está conectado no chat server!', icWarning);
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ChatManager(False);
end;

procedure TfrmMain.lblLoginLogoffClick(Sender: TObject);
//fazer login ou logoff
begin
  FSair := False;
  case ShowMessageQuery(self,'Sair do Sistema','Sair do Sistema ou fazer LogOff ?','Sair','LogOff','Cancelar',icQuestion) of
    mrYes:
     begin
       FSair := True;
       ChatManager(False);
       Application.Terminate;
     end;
    mrNo:
     begin
       Hide;
       Autenticar;
    end;
  end;
end;

procedure TfrmMain.CarregaUsuario;
//carrega dados do usuário
var
  u: TServiceUsuario;
begin
  u := TServiceUsuario.Create;
  u.Ler(Usuario_ID);

  if u.Sucesso then begin
    Usuario_Admin := u.IsAdmin;
    Usuario_Nome  := u.Nome;
    Usuario_Login := u.Login;

    lblNomeUsuarioDM.Caption := u.Nome.Split([' '], TStringSplitOptions.ExcludeEmpty)[0];
    lblNomeUsuarioDM.Hint := u.Nome;
    lblLoginLogoff.Hint := 'Fazer LogOff ou Sair do Sistema.';
    imgLoginDM.Visible := True;
    imgLoginDM.Picture.Bitmap.Assign( u.Foto.Picture.Bitmap );

    if (imgLoginDM.Picture = nil) or (imgLoginDM.Picture.Bitmap.Width<1) then
      imgLoginDM.Picture.Assign( TfrmLogin.new().imgLogo.Picture ); //logo Lazarus

    //efetua login no chat
    if Assigned(ChatClient) and ChatClient.IsConectado() then
      ChatClient.LogIn(Usuario_ID, Usuario_Nome);
  end;

  u.Free;
end;

procedure TfrmMain.ChatManager(ACreate: Boolean);
// cria ou destroi o módulo do chat
begin
  if ACreate and not Assigned(ChatClient) then begin
    scrChatUnreadMessages.BorderStyle := bsNone;
    ChatClient := TChatModule.Create(scrChatUnreadMessages );
    ChatClient.OnYourConnectionStatus := @ChatConnectionStatus;
    ChatClient.OnLogginStatus := @ChatLoginStatus;
    //ChatClient.OnListUsers := @ListaUsuarios;
    ChatClient.Conectar;
    if Assigned(TimerChat) then TimerChat.Enabled := True;
  end
  else if not ACreate and Assigned(ChatClient) then begin
    if Assigned(TimerChat) then TimerChat.Enabled := False;
    ChatClient.Desconectar;
    ChatClient.Free;
  end;
end;

procedure TfrmMain.Autenticar;
//faz autenticação do usuário
var
  login: TfrmLogin;
begin
  //logoff do chat
  if Assigned(ChatClient) and ChatClient.IsLogged() then ChatClient.LogOut;

  Usuario_ID    := 0;
  Usuario_Nome  := '';
  Usuario_Login := '';
  lblLoginLogoff.Hint := '';
  login := TfrmLogin.Create(nil);
  login.ShowModal;
  Usuario_ID := login.Usuario_ID;
  login.Destroy;

  if Usuario_ID < 1 then begin
    ChatManager(False);
    Application.Terminate;
  end
  else begin
    CarregaUsuario;
    Show;
  end;
end;

end.


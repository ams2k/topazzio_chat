unit ChatModule;

// Módulo de controle de eventos do Chat
// Required Packages: Inetbase
// Aldo Márcio Soares - ams2kg@gmail.com - 2025-12-25

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ExtCtrls, Dialogs, lNet, fpjson, jsonparser, IniFiles ;

type
  TOnMessageReceived = procedure(AFromID: Integer; AFromName: string; AMsg: string) of object;
  TOnYourConnectionChanged = procedure(AMessage: string; AOnline: Boolean) of object;
  TOnOtherConnectionChanged = procedure(AFromID: Integer; AMessage: string; AOnline: Boolean) of object;
  TOnListUsersReceived = procedure(AUsers: TJSONArray) of object;
  TOnListMessagesReceived = procedure(AMessages: TJSONArray) of object;
  TOnLogginStatusReceived = procedure(AMessage: String; ALogged: Boolean) of object;

  { TThreadChatRun }

  TThreadChatRun = class(TThread)
    // procedure de retorno
    CallBackProcedure: procedure(AEvento: string) of object;
  private
    FMsg: string;
    procedure ChamaCallBack;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
  end;

  { TDMChatCliente }

  TDMChatCliente = class
  private
    FTCPClient: TLTCP;
    FThread: TThreadChatRun;
    FChats: TStringList;

    FErroServidor, FErroUsuario, FErroChat: string;
    FSucessoServidor, FConectado: Boolean;
    FSucessoUsuario, FUserLogged: Boolean;
    FServer_IP: string;
    FServer_Porta: Integer;
    FMeu_ID: Integer;
    FMeu_Nome: string;
    { Analisa o evento recebido do chat server }
    procedure AnalisaEventos(AMsg: string);
    { Envia o seu evento para o chat server }
    function SendToServer(AMsg: string): string;

    procedure OnAccept(aSocket: TLSocket);
    procedure OnConnect(aSocket: TLSocket);
    procedure OnDisconnect(aSocket: TLSocket);
    procedure OnError(const msg: string; aSocket: TLSocket);
    procedure OnReceive(aSocket: TLSocket);

    procedure LerConfig;
  public
    OnYourConnectionStatus: TOnYourConnectionChanged;
    OnOtherConnectionStatus: TOnOtherConnectionChanged;
    OnLogginStatus: TOnLogginStatusReceived;
    OnChat: TOnMessageReceived;
    OnListUsers: TOnListUsersReceived;
    OnListMessages: TOnListMessagesReceived;

    constructor Create;
    destructor Destroy; override;

    property Meu_ID: Integer read FMeu_ID;
    property Meu_Nome: string read FMeu_Nome;
    property GetErroServidor: string read FErroServidor;
    property GetErroUsuario: string read FErroUsuario;
    property GetErroChat: string read FErroChat;
    property SucessoServidor: Boolean read FSucessoServidor;
    property SucessoUsuario: Boolean read FSucessoUsuario;

    { Efetua a conexão com chat server }
    procedure Conectar;
    { Checa se sua aplicação está conectada no chat server }
    function IsConectado(): Boolean;
    { Desconecta do chat server }
    procedure Desconectar;
    { Efetua login do seu usuário no chat server }
    procedure LogIn(AMeu_ID: Integer; AMeu_Nome: string);
    { Desconecta seu usuário do chat server }
    procedure LogOut;
    { Checa se seu usuário está logado no chat server }
    function IsLogged(): Boolean;
    { Cria uma identificação para a sala do seu chat com o(s) destinatário(s) }
    function NewRoom(AFromID: Integer): string;
    { Envia sua mensagem para o(s) destinatário(s) da sua sala de chat }
    procedure EnviarConversa(APara_ID: Integer; APara_Nome, ASala, ATexto: string);
    { Lista de usuários conectados e logados no chat server }
    procedure GetListaUsers;
    { Adiciona a sala de identificação da tela de chat  }
    procedure Identificacao_Add(ASala: string);
    { Remove a sala de identificação da tela de chat  }
    procedure Identificacao_Del(ASala: string);
    { Cria a tela de chat }
    procedure OpenChat(AChatRoom: string; AJSon: TJSONObject);
  end;

var
  DMChatCliente: TDMChatCliente;

implementation

uses
  View.Chat;

{ TThreadChatRun }

constructor TThreadChatRun.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  FMsg := '';
  inherited Create(CreateSuspended);
end;

procedure TThreadChatRun.Execute;
begin
   while (not Terminated) do begin
      try
        DMChatCliente.FTCPClient.CallAction;
        Sleep(10);
        //Synchronize(@ChamaCallBack);
      except
        Terminate;
      end;
    end;
end;

procedure TThreadChatRun.ChamaCallBack;
begin
  //CallBackProcedure( FMsg ); //Lá no DMChatCliente
end;

{ TDMChatCliente }

constructor TDMChatCliente.Create;
begin
  FConectado    := False;
  FUserLogged   := False;
  LerConfig;

  FTCPClient := TLTcp.Create(nil);
  FTCPClient.OnAccept     := @OnAccept;
  FTCPClient.OnConnect    := @OnConnect;
  FTCPClient.OnDisconnect := @OnDisconnect;
  FTCPClient.OnError      := @OnError;
  FTCPClient.OnReceive    := @OnReceive;
  FTCPClient.Timeout      := 100;
  FTCPClient.ReuseAddress := True;

  // instancia a thread de monitoramento dos eventos recebidos do servidor
  FThread := TThreadChatRun.Create(True);
  FThread.CallBackProcedure := nil;// @AnalisaEventos;
  FThread.Start;

  FChats := TStringList.Create;
end;

destructor TDMChatCliente.Destroy;
begin
  if Assigned(FChats) then FChats.Free;

  try
    if Assigned(FTCPClient) then FTCPClient.Free;
  except
    on E: Exception do begin
      //nada
    end;
  end;

  inherited Destroy;
end;

procedure TDMChatCliente.OnAccept(aSocket: TLSocket);
begin
  ShowMessage('Conexão aceita');
end;

procedure TDMChatCliente.OnConnect(aSocket: TLSocket);
begin
  FConectado := True;
  if Assigned(OnYourConnectionStatus) then
    OnYourConnectionStatus('Conectado do servidor do chat!', True);
end;

procedure TDMChatCliente.OnDisconnect(aSocket: TLSocket);
begin
  FConectado := False;
  FUserLogged := False;

  if Assigned(OnYourConnectionStatus) then
    OnYourConnectionStatus('Desconectado do servidor do chat!', False);

  if Assigned(OnLogginStatus) then
    OnLogginStatus('Efetuado logoff do seu usuário, desconectado do servidor do chat!', False);
end;

procedure TDMChatCliente.OnError(const msg: string; aSocket: TLSocket);
begin
  ShowMessage('OnError: ' + msg);
end;

procedure TDMChatCliente.OnReceive(aSocket: TLSocket);
//mensagem chegando aqui
var
  Msg: string;
begin
  if aSocket.GetMessage(Msg) < 1 then Exit;

  AnalisaEventos( Msg ); //enviar para a análise do conteúdo recebido
end;

procedure TDMChatCliente.LerConfig;
//ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_config.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  try
    FServer_IP    := ArqINI.ReadString('chat_server','host', '192.168.1.100');
    FServer_Porta := ArqINI.ReadInteger('chat_server','port', 9022);
  finally
    ArqINI.Free;
  end;
end;

function TDMChatCliente.IsLogged(): Boolean;
begin
  Result := FUserLogged;
end;

function TDMChatCliente.SendToServer(AMsg: string): string;
//envia o evento para o servidor do chat
begin
  if not Assigned(FTCPClient) or not FTCPClient.Connected then begin
    FErroChat := 'Servidor indisponível!';
    Result := FErroChat;
    Exit;
  end;

  FErroChat := '';

  try
    FTCPClient.SendMessage( AMsg );
  except
    on E: Exception do begin
      FErroChat := E.Message;
    end;
  end;

  Result := FErroChat;
end;

procedure TDMChatCliente.AnalisaEventos(AMsg: string);
//Eventos recebidos do Servidor do Chat
var
  J: TJSONObject;
  lData: TJSONData;
  evento, erro: string;
begin
  lData := GetJSON(AMsg);

  try
    J := TJSONObject(lData);
    evento := LowerCase( J.Get('event', '') );
    erro := J.Get('error', '');

    if erro <> '' then ShowMessage(erro);

    if (evento = 'chat_retorno') then begin
      //
    end;

    if (evento = 'server_error') then begin
      FUserLogged := False;
      FConectado := False;
      Desconectar;
      OnLogginStatus(J.Strings['message'], False);
      OnYourConnectionStatus(J.Strings['message'], False);
    end
    else if (evento = 'connection') and Assigned(OnYourConnectionStatus) then
       OnYourConnectionStatus(J.Strings['message'], True)
    else if (evento = 'disconnection') and Assigned(OnYourConnectionStatus) then
       OnYourConnectionStatus(J.Strings['message'], False)
    else if (evento = 'user_online') and Assigned(OnOtherConnectionStatus) then
       OnOtherConnectionStatus(0, J.Strings['message'], True)
    else if (evento = 'user_offline') and Assigned(OnOtherConnectionStatus) then
       OnOtherConnectionStatus(0, J.Strings['message'], False)
    else if (evento = 'chat') and Assigned(OnChat) then
      OnChat(J.Integers['from_id'], J.Strings['from_name'], J.Strings['msg'])
    else if (evento = 'get_users') and Assigned(OnListUsers) then
      OnListUsers(J.Arrays['users'])
    else if (evento = 'login') and Assigned(OnLogginStatus) then
      OnLogginStatus(J.Strings['message'], True)
    else if (evento = 'logoff') then
      OnLogginStatus(J.Strings['message'], False);

  finally
    lData.Free;
  end;
end;

procedure TDMChatCliente.Conectar;
//Conecta no servidor do Chat
begin
  if not Assigned(FTCPClient) then Exit;
  FErroServidor   := '';
  FTCPClient.Host := FServer_IP;
  FTCPClient.Port := FServer_Porta;

  try
    if not FTCPClient.Connected then
      FConectado := FTCPClient.Connect(FServer_IP, FServer_Porta);
  except
    on E: Exception do begin
      FErroServidor := E.Message;

      if Assigned(OnYourConnectionStatus) then
        OnYourConnectionStatus('Erro ao conectar: ' + E.Message, False);
    end;
  end;
end;

function TDMChatCliente.IsConectado(): Boolean;
begin
  Result := FConectado;
end;

procedure TDMChatCliente.Desconectar;
//desconecta do servidor
begin
  if not Assigned(FTCPClient) then Exit;
  FErroServidor := '';

  try
    if FTCPClient.Connected then begin
      FTCPClient.Disconnect;

      FConectado  := False;
      FUserLogged := False;

      if Assigned(OnYourConnectionStatus) then
        OnYourConnectionStatus('Desconectado do servidor do chat!', False);

      if Assigned(OnLogginStatus) then
        OnLogginStatus('Efetuado logoff do seu usuário, desconectado do servidor do chat!', False);
    end;
  except
    on E: Exception do
      FErroServidor := E.Message;
  end;
end;

procedure TDMChatCliente.LogIn(AMeu_ID: Integer; AMeu_Nome: string);
//Conecta no servidor do Chat
var
  lLogin: TJSONObject;
begin
  FSucessoUsuario := False;
  FUserLogged  := False;
  FErroUsuario := '';
  FMeu_ID   := AMeu_ID;
  FMeu_Nome := AMeu_Nome;

  lLogin := TJSONObject.Create;

  try
    lLogin.Add('event', 'login');
    lLogin.Add('from_id', FMeu_ID);
    lLogin.Add('from_name', FMeu_Nome);

    FErroUsuario := SendToServer( lLogin.AsJSON );

    if (FErroUsuario = '') then begin
      FSucessoUsuario := True;
      FUserLogged := True;
    end;
  finally
    lLogin.Free;
  end;
end;

procedure TDMChatCliente.LogOut;
//efetua o logout do chat, não do servidor
var
  lLogOut: TJSONObject;
begin
  if not Assigned(FTCPClient) or not FTCPClient.Connected then Exit;

  FUserLogged := False;
  lLogOut := TJSONObject.Create;

  try
    lLogOut.Add('event', 'logoff');
    lLogOut.Add('from_id', FMeu_ID);
    lLogOut.Add('from_name', FMeu_Nome);

    SendToServer( lLogOut.AsJSON );
  finally
    lLogOut.Free;
  end;
end;

procedure TDMChatCliente.EnviarConversa(APara_ID: Integer; APara_Nome, ASala, ATexto: string);
//envia a mensagem ao Servidor do Chat
var
  lMsg, lDest: TJSONObject;
  lDestinatarios: TJSONArray;
begin
  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'chat');
    lMsg.Add('from_id', Meu_ID);
    lMsg.Add('from_name', Meu_Nome);
    lMsg.Add('room_name', ASala);
    lMsg.Add('msg', ATexto);

    //destinatários
    lDestinatarios := TJSONArray.Create;

    lDest := TJSONObject.Create;
    lDest.Add('to_id', APara_ID);
    lDest.Add('to_name', APara_Nome);

    lDestinatarios.Add( lDest );

    lMsg.Add('to', lDestinatarios);

    SendToServer( lMsg.AsJSON );
  finally
    lMsg.Free; //lDestinatarios será liberado também
  end;
end;

function TDMChatCliente.NewRoom(AFromID: Integer): string;
//gera um nome único para a sala
begin
  Result := Format('%d-%d', [AFromID, GetTickCount64]);
end;

procedure TDMChatCliente.GetListaUsers;
begin
  SendToServer( '{"event":"get_users"}' );
end;

procedure TDMChatCliente.Identificacao_Add(ASala: string);
begin
  //
end;

procedure TDMChatCliente.Identificacao_Del(ASala: string);
begin
  //
end;

procedure TDMChatCliente.OpenChat(AChatRoom: string; AJSon: TJSONObject);
//abre a tela do chat quando chegar mensagem
var
  F: TfrmChat;
  Idx: Integer = -1;
begin
  if (AChatRoom = '') then
    AChatRoom := NewRoom(FMeu_ID)
  else
    Idx := FChats.IndexOf(AChatRoom);

  if Idx < 0 then begin
    F := TfrmChat.Create(nil);
    F.ChatRoom := AChatRoom;
    F.Show;
    FChats.AddObject(AChatRoom, F);
  end
  else
    F := TfrmChat( FChats.Objects[Idx] );

  //F.AppendMessage(J);
end;

end.


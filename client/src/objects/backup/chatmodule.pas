unit ChatModule;

(*
  Módulo de controle de eventos do Chat - Não requer LIB/DLL
  Required Packages: lNet ( Inetbase )
  Aldo Márcio Soares - ams2kg@gmail.com - 2025-12-31
*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, lNet, fpjson, jsonparser,
  IniFiles, DateUtils, LCLIntf;

type
  TOnMessageReceived = procedure(AFromID: Integer; AFromName: string; AMsg: string) of object;
  TOnYourConnectionChanged = procedure(AMessage: string; AOnline: Boolean) of object;
  TOnListUsersReceived = procedure(AStrArrayUsers: string) of object;
  TOnListMessagesReceived = procedure(AMessages: string) of object;
  TOnLogginStatusReceived = procedure(AMessage: String; ALogged: Boolean) of object;

  { TThreadChatRun }

  TThreadChatRun = class(TThread)
    // procedure a ser executada
    ExecuteProcedure: procedure of object;
    // procedure de retorno
    CallBackProcedure: procedure of object;
  private
    FChat: TLTcp;
    FMsg: string;
    procedure ChamaCallBack;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
    procedure SetChatObj(var AChat: TLTcp);
  end;

  { TChatModule }

  TChatModule = class
  private
    FTCPClient: TLTCP;
    FThread: TThreadChatRun;
    FMsgQueue: TThreadList;
    FChats, FChatHistory: TStringList;
    FBoxUnreadMessages: TScrollBox;

    FErroServidor, FErroUsuario, FErroChat: string;
    FConectado: Boolean;
    FUserLogged: Boolean;
    FServer_IP: string;
    FServer_Porta: Integer;
    FMeu_ID: Integer;
    FMeu_Nome: string;

    procedure OnAccept(aSocket: TLSocket);
    procedure OnConnect(aSocket: TLSocket);
    procedure OnDisconnect(aSocket: TLSocket);
    procedure OnError(const msg: string; aSocket: TLSocket);
    procedure OnReceive(aSocket: TLSocket);

    { Analisa o evento recebido do chat server }
    procedure AnalisaEventos(AMsg: string);
    { Envia o seu evento para o chat server }
    function SendToServer(AMsg: string): string;
    { leitura do arqivo .INI com configurações do chat }
    procedure LerConfig;
    { verifica se a sala é minha }
    function IsMinhaSala(AChatRoom: string): Boolean;
    { processa a fila de mensagens }
    procedure ProcessaFila;
    { processa a fila de mensagens da thread }
    procedure ProcessaFilaAsync(AData: PtrInt);
  public
    { evento de conexão com o server chat chamando uma procedure no main form }
    OnYourConnectionStatus: TOnYourConnectionChanged;
    { evento de login chamando uma procedure no main form }
    OnLogginStatus: TOnLogginStatusReceived;
    { evento de retorno da lista de usuários online no chat }
    OnListUsers: TOnListUsersReceived;
    OnListMessages: TOnListMessagesReceived;

    constructor Create(ABoxUnreadMessages: TScrollBox);
    destructor Destroy; override;

    property Meu_ID: Integer read FMeu_ID write FMeu_ID;
    property Meu_Nome: string read FMeu_Nome write FMeu_Nome;
    property GetErroServidor: string read FErroServidor;
    property GetErroUsuario: string read FErroUsuario;
    property GetErroChat: string read FErroChat;

    { Força eventos do Chat}
    procedure DoPoll;

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
    { Envia sua mensagem para a sua sala de chat }
    procedure SendMessage(AMessageJson: String);
    { Obtém a lista de mensagens para a sala indicada }
    procedure GetMessages(AChatRoom: string);
    { Lista de usuários conectados e logados no chat server }
    procedure GetOnlineUsers;
    { Cria a tela de chat }
    procedure Chat_Open(AChatRoom, AStrJSon: string; AGetMessages: Boolean);
    { avisos diversos nas telas de chat que estiverem abertas }
    procedure Chat_Aviso(AChatRoom: string; AStrJSon: string);
    { Fecha a tela de chat }
    procedure Chat_Close(AChatRoom: string);
    { Envia eventos para a tela de histórico do chat }
    procedure ChatHistory_Control(AStrJson: string);
    { Destroy a tela de histórico do chat }
    procedure ChatHistory_Close;
    { Lista de Salas com mensagens não lidas }
    procedure RoomUnaredMessage_Get;
    { processa as mensagens não lidas das salas }
    procedure RoomUnaredMessage_Processa(AStrJson: string);
    { abre a tela de chat para exibir as mensagens não lidas com base na lista }
    procedure RoomUnaredMessage_Open(ARoomName: string);
    { remove a sala da lista de mensagens não lidas }
    procedure RoomUnaredMessage_Remove(ARoomName: string);
    { remove todos os objetos da scrollbox }
    procedure RoomUnreadMessage_Clear;
  end;

var
  ChatClient: TChatModule;

implementation

uses
  View.Chat, View.ChatHistory, ChatCardInfo;

{ TThreadChatRun }

constructor TThreadChatRun.Create(CreateSuspended: boolean);
begin
  // FreeOnTerminate := True;
  FMsg := '';
  inherited Create(CreateSuspended);
end;

procedure TThreadChatRun.SetChatObj(var AChat: TLTcp);
begin
  FChat := AChat;
end;

procedure TThreadChatRun.Execute;
begin
  while (not Terminated) do begin
    try
      FChat.CallAction;
      Sleep(10);
      //Synchronize(@ChamaCallBack);
    except
      Terminate;
    end;
  end;
end;

procedure TThreadChatRun.ChamaCallBack;
begin
  if Assigned(CallBackProcedure) then
    CallBackProcedure;
end;

{ TChatModule }

constructor TChatModule.Create(ABoxUnreadMessages: TScrollBox);
begin
  FChats := TStringList.Create;
  FChats.OwnsObjects := False;
  FChats.Sorted := True;
  FChatHistory := TStringList.Create;
  FChatHistory.Sorted := True;
  FMsgQueue := TThreadList.Create;
  FBoxUnreadMessages := ABoxUnreadMessages; //para exibir
  FConectado := False;
  FUserLogged := False;
  FMeu_ID := 0;
  FMeu_Nome := '';

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
  FThread.SetChatObj(FTCPClient);
  FThread.Start;
end;

destructor TChatModule.Destroy;
begin
  RoomUnreadMessage_Clear;

  if Assigned(FThread) then begin
    FThread.Terminate;
    FThread.WaitFor;
    FThread.Free;
  end;

  if Assigned(FTCPClient) then FTCPClient.Free;
  if Assigned(FMsgQueue) then FMsgQueue.Free;
  if Assigned(FChats) then FChats.Free;
  if Assigned(FChatHistory) then FChatHistory.Free;

  inherited Destroy;
end;

procedure TChatModule.DoPoll;
//força eventos do servidor chat
begin
  FTCPClient.CallAction;
end;

procedure TChatModule.OnAccept(aSocket: TLSocket);
begin
  FErroServidor := '';
end;

procedure TChatModule.OnConnect(aSocket: TLSocket);
begin
  FConectado := True;
  FErroServidor := '';
  FErroUsuario := '';
  FErroChat := '';
  FMeu_ID := 0;
  FMeu_Nome := '';

  if Assigned(OnYourConnectionStatus) then
    OnYourConnectionStatus('Conectado do servidor do chat!', True);

  // LogIn(FMeu_ID, FMeu_Nome);
end;

procedure TChatModule.OnDisconnect(aSocket: TLSocket);
begin
  FConectado := False;
  FUserLogged := False;
  FErroServidor := '';
  FErroUsuario := '';
  FErroChat := '';
  FMeu_ID := 0;
  FMeu_Nome := '';

  if Assigned(OnYourConnectionStatus) then
    OnYourConnectionStatus('Desconectado do servidor do chat!', False);

  if Assigned(OnLogginStatus) then
    OnLogginStatus('Efetuado logoff do seu usuário, desconectado do servidor do chat!', False);
end;

procedure TChatModule.OnError(const msg: string; aSocket: TLSocket);
begin
  FErroServidor := msg;

  if not FTCPClient.Connected then begin
    if Assigned(OnYourConnectionStatus) then
      OnYourConnectionStatus(msg, False);

    if FUserLogged then begin
      FUserLogged := False;
      if Assigned(OnLogginStatus) then
        OnLogginStatus('Você foi desconectado do servidor do chat!', False);
    end;
  end;
end;

procedure TChatModule.OnReceive(aSocket: TLSocket);
// mensagem chegando aqui
var
  lMsg: string;
begin
  if aSocket.GetMessage(lMsg) < 1 then Exit;

  // força a conversão para UTF8 para funcionar acentuação e EMOJI
  if StringCodePage(lMsg) = 0 then
    lMsg := UTF8Encode( lMsg );

  // Adiciona na fila (thread-safe)
  FMsgQueue.Add(Pointer(StrNew(PChar(lMsg))));

  // Agenda processamento na main thread
  Application.QueueAsyncCall(@ProcessaFilaAsync, 0);
end;

procedure TChatModule.LerConfig;
// ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_config.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  try
    if not FileExists(FArquivoINI) then begin
      ArqINI.WriteString('chat_server','host', '192.168.1.100');
      ArqINI.WriteInteger('chat_server','port', 9022);
    end;

    FServer_IP    := ArqINI.ReadString('chat_server','host', '192.168.1.100');
    FServer_Porta := ArqINI.ReadInteger('chat_server','port', 9022);
  finally
    ArqINI.Free;
  end;
end;

function TChatModule.IsLogged(): Boolean;
begin
  Result := FUserLogged;
end;

function TChatModule.SendToServer(AMsg: string): string;
// envia o evento para o servidor do chat
begin
  if not FTCPClient.Connected then begin
    FErroChat := 'Servidor indisponível!';
    Result := FErroChat;
    Exit;
  end;

  FErroChat := '';

  try
    FTCPClient.SendMessage( AMsg );
  except
    on E: Exception do
      FErroChat := E.Message;
  end;

  Result := FErroChat;
end;

procedure TChatModule.AnalisaEventos(AMsg: string);
// Eventos recebidos do Servidor do Chat
var
  J: TJSONObject;
  evento: string;
begin
  J := TJSONObject( GetJSON( AMsg ) );

  try
    evento := LowerCase( J.Get('event', '') );

    if (evento = 'chat_error') and (J.Get('from_id', 0) = FMeu_ID) then begin
      Chat_Aviso(J.Get('room_name', ''), AMsg);
    end
    else if (evento = 'json_error') then begin
      Chat_Aviso(J.Get('message', ''), '');
    end
    else if (evento = 'server_error') then begin
      Desconectar;
      OnLogginStatus(J.Strings['message'], False);
      OnYourConnectionStatus(J.Strings['message'], False);
    end
    else if (evento = 'server_down') then begin
      //servidor offline
      Desconectar;
      OnLogginStatus(J.Strings['message'], False);
      OnYourConnectionStatus(J.Strings['message'], False);
      Chat_Aviso('', AMsg);
    end
    else if (evento = 'connection') and Assigned(OnYourConnectionStatus) then
      OnYourConnectionStatus(J.Strings['message'], True)
    else if (evento = 'disconnection') and Assigned(OnYourConnectionStatus) then
      OnYourConnectionStatus(J.Strings['message'], False)
    else if (evento = 'user_online') then
      Chat_Aviso('', AMsg)
    else if (evento = 'user_offline') or (evento = 'disconnected') then
      Chat_Aviso('', AMsg)
    else if (evento = 'chat') then
      Chat_Open(J.Get('room_name', ''), AMsg, True)
    else if (evento = 'get_messages') then
      Chat_Aviso(J.Get('room_name', ''), AMsg)
    else if (evento = 'attention') or (evento = 'writing') then
      Chat_Aviso(J.Get('room_name', ''), AMsg)
    else if (evento = 'get_users') and Assigned(OnListUsers) then
      OnListUsers(AMsg)
    else if (evento = 'login') and Assigned(OnLogginStatus) then begin
      FUserLogged := True;
      OnLogginStatus(J.Get('message',''), True);
      Chat_Aviso('', AMsg);  // envia a todas as telas de chat abertas
      RoomUnaredMessage_Get; // lista de salas com mensagens não lidas
    end
    else if (evento = 'login_duplicate') and Assigned(OnLogginStatus) then begin
      FUserLogged := False;
      OnLogginStatus(J.Strings['message'] + sLineBreak + J.Strings['ip'] + sLineBreak + J.Strings['data'], False);
    end
    else if (evento = 'logoff') then begin
      FUserLogged := False;
      OnLogginStatus(J.Strings['message'], False);
      Chat_Aviso('', AMsg); // envia a todas as telas de chat abertas
    end
    else if (evento = 'room_guests') then begin
      Chat_Aviso(J.Get('room_name', ''), AMsg); //notifica apenas tela desta sala
    end
    else if (evento = 'room_enter') then begin
      // alguém entrou na sala do chat / abriu a tela
      Chat_Aviso(J.Get('room_name', ''), AMsg);
    end
    else if (evento = 'room_leave') then begin
      // alguém saiu da sala do chat / fechou a tela
      Chat_Aviso(J.Get('room_name', ''), AMsg);
    end
    else if (evento = 'chat_delete') then begin
      // marcou a mensagem como deletada ?
      Chat_Aviso(J.Get('room_name', ''), AMsg);
    end
    else if (evento = 'room_change') then begin
      // houve alterações dos integrantes da sala
      Chat_Aviso(J.Get('room_name', ''), AMsg);
    end
    else if (evento = 'history_rooms') or (evento = 'history_messages') then begin
      // eventos para a tela do histórico do chat
      ChatHistory_Control(AMsg);
    end
    else if (evento = 'messages_unread') then begin
      RoomUnaredMessage_Processa(AMsg);
    end;
  finally
    J.Free;
  end;
end;

procedure TChatModule.Conectar;
// Conecta no servidor do Chat
begin
  if not Assigned(FTCPClient) then Exit;
  FErroServidor := '';
  FErroUsuario := '';
  FErroChat := '';
  FConectado := False;
  FUserLogged := False;
  FTCPClient.Host := FServer_IP;
  FTCPClient.Port := FServer_Porta;

  try
    if not FTCPClient.Connected then
      FTCPClient.Connect(FServer_IP, FServer_Porta);
  except
    on E: Exception do begin
      FErroServidor := E.Message;

      if Assigned(OnYourConnectionStatus) then
        OnYourConnectionStatus('Erro ao conectar: ' + E.Message, False);
    end;
  end;
end;

procedure TChatModule.Desconectar;
// desconecta do servidor
begin
  if not Assigned(FTCPClient) then Exit;
  FErroServidor := '';
  FErroUsuario := '';
  FErroChat := '';
  FConectado := False;
  FUserLogged := False;
  FMeu_ID := 0;
  FMeu_Nome := '';

  try
    if FTCPClient.Connected then begin
      FTCPClient.Disconnect(True);

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

function TChatModule.IsConectado(): Boolean;
begin
  Result := FTCPClient.Connected;
  FConectado := Result;
end;

procedure TChatModule.LogIn(AMeu_ID: Integer; AMeu_Nome: string);
// Conecta no servidor do Chat
var
  lLogin: TJSONObject;
begin
  if not FTCPClient.Connected then begin
    Conectar;
    Sleep(300);
  end;

  FUserLogged := False;
  FErroUsuario := '';
  FMeu_ID := AMeu_ID;
  FMeu_Nome := AMeu_Nome;

  lLogin := TJSONObject.Create;

  try
    lLogin.Add('event', 'login');
    lLogin.Add('from_id', FMeu_ID);
    lLogin.Add('from_name', FMeu_Nome);

    SendToServer( lLogin.AsJSON );
  finally
    lLogin.Free;
  end;
end;

procedure TChatModule.LogOut;
// efetua o logout do chat, não do servidor
var
  lLogOut: TJSONObject;
begin
  if not FTCPClient.Connected then Exit;

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

  FMeu_ID := 0;
  FMeu_Nome := '';
end;

procedure TChatModule.SendMessage(AMessageJson: String);
// envia a mensagem ao Servidor do Chat
begin
  SendToServer( AMessageJson ); // AMessageJson deve estar em formato JSON
end;

procedure TChatModule.GetMessages(AChatRoom: string);
// obtém a lista de mensagens da sala indicada
var
  lJSON: TJSONObject;
begin
  if not FTCPClient.Connected then Exit;
  if AChatRoom <> '' then begin
    lJSON := TJSONObject.Create;
    try
      lJSON.Add('event', 'get_messages');
      lJSON.Add('room_name', AChatRoom);
      lJSON.Add('to_id', FMeu_ID);

      SendToServer( lJSON.AsJSON );
    finally
      lJSON.Free;
    end;
  end;
end;

function TChatModule.NewRoom(AFromID: Integer): string;
// gera um nome único para a sala
begin
  // Result := Format('%d-%d', [AFromID, GetTickCount64]);
  Result := Format('%d-%d', [AFromID, DateTimeToUnix(Now)]);
end;

procedure TChatModule.GetOnlineUsers;
// lista de usuários conectados no chat server
begin
  SendToServer( '{"event":"get_users"}' );
end;

procedure TChatModule.Chat_Open(AChatRoom, AStrJSon: string; AGetMessages: Boolean);
// abre a tela do chat quando chegar mensagem
var
  F: TfrmChat;
  Idx: Integer;
begin
  if not Assigned(FChats) then begin
    FChats := TStringList.Create;
    FChats.Sorted := True;
  end;

  Idx := -1;

  if (AChatRoom = '') then
    AChatRoom := NewRoom( FMeu_ID )
  else
    Idx := FChats.IndexOf( AChatRoom );

  if Idx < 0 then begin
    // cria uma nova tela de chat
    F := TfrmChat.Create(Application);
    F.ChatRoom := AChatRoom;

    FChats.AddObject(AChatRoom, F);

    F.Show;

    // remove da lista de mensagens não lidas
    if AStrJSon = '' then
      RoomUnaredMessage_Remove( AChatRoom );

    // obter a lista de mensagens
    if AGetMessages then begin
      GetMessages( AChatRoom );
    end;
  end
  else begin
    // envia a mensagem para a tela de chat existente
    try
      F := TfrmChat( FChats.Objects[Idx] );
      F.ChatEventos( AChatRoom, AStrJSon );
    except
    end;
  end;
end;

procedure TChatModule.Chat_Close(AChatRoom: string);
// remove da lista a tela do chat
var
  Idx: Integer = -1;
begin
  if (AChatRoom <> '') and Assigned(FChats) then begin
    try
      Idx := FChats.IndexOf( AChatRoom );
      if Idx >= 0 then
        FChats.Delete(Idx);
    except
    end;
  end;
end;

procedure TChatModule.ChatHistory_Control(AStrJson: string);
// envio de eventos para a tela de histórico de chat
var
  F: TfrmChatHistory;
  Idx: Integer;
begin
  if not Assigned(FChatHistory) then begin
    FChatHistory := TStringList.Create;
    FChatHistory.Sorted := True;
  end;

  Idx := FChatHistory.IndexOf( 'frmChatHistory' );

  if Idx < 0 then begin
    // cria a tela de histórico de mensagens
    F := TfrmChatHistory.Create(Application);

    FChatHistory.AddObject('frmChatHistory', F);

    F.Show;
  end
  else begin
    try
      F := TfrmChatHistory( FChatHistory.Objects[Idx] );
      F.ChatEventos( AStrJSon );
    except
    end;
  end;
end;

procedure TChatModule.ChatHistory_Close;
// destroi a tela de histórico de chat
var
  Idx: Integer = -1;
begin
  if Assigned(FChatHistory) then begin
    try
      Idx := FChatHistory.IndexOf( 'frmChatHistory' );
      if Idx >= 0 then
        FChatHistory.Delete(Idx);
    except
    end;
  end;
end;

procedure TChatModule.Chat_Aviso(AChatRoom: string; AStrJSon: string);
// notifica as telas de chat que estiverem abertas
var
  F: TfrmChat;
  i, idx: Integer;
begin
  if Trim(AStrJSon) = '' then Exit;
  if not Assigned(FChats) then Exit;

  idx := -1;

  for i := 0 to FChats.Count - 1 do begin
    if (AChatRoom <> '') then begin
      // notifica apenas para a sala informada
      idx := FChats.IndexOf( AChatRoom );

      if idx >= 0 then begin
        try
          F := TfrmChat( FChats.Objects[idx] );
          F.ChatAvisos( AStrJSon );
          Break;
        except
        end;
      end;
    end
    else begin
      // notifica para todas as salas
      try
        F := TfrmChat( FChats.Objects[i] );
        F.ChatAvisos( AStrJSon );
      except
      end;
    end;
  end;
end;

procedure TChatModule.RoomUnaredMessage_Get;
// obtém a lista de salas com mensagens não lidas deste usuário
var
  lJSON: TJSONObject;
begin
  if not FTCPClient.Connected then Exit;
  if FMeu_ID > 0 then begin
    lJSON := TJSONObject.Create;
    try
      lJSON.Add('event', 'messages_unread');
      lJSON.Add('to_id', FMeu_ID);

      SendToServer( lJSON.AsJSON );
    finally
      lJSON.Free;
    end;
  end;
end;

procedure TChatModule.RoomUnaredMessage_Processa(AStrJson: string);
// processa as mensagens não lidas de cada sala
var
  c: TChatCardInfo;
  lJson, lJsonTemp: TJSONObject;
  lArrayMsg: TJSONArray;
  i: integer;
  from_id, total_unread: integer;
  from_name, room_name, msg_date: string;
  ldate: TDateTime;
  FMargin, FSpacing, FNextTop: Integer;
begin
  if Assigned(FBoxUnreadMessages) then begin
    FMargin  := 6;
    FSpacing := 8;
    FNextTop := FMargin;
    RoomUnreadMessage_Clear;

    try
      lJson := TJSONObject( GetJSON( AStrJson ) );
      lArrayMsg := TJSONArray( lJson.Arrays['messages'] );

      if lArrayMsg.Count * (60 + FSpacing) > FBoxUnreadMessages.ClientHeight then
        FBoxUnreadMessages.Width := 290
      else
        FBoxUnreadMessages.Width := 270;

      FBoxUnreadMessages.Left := FBoxUnreadMessages.Parent.Width - FBoxUnreadMessages.Width;

      for i := 0 to lArrayMsg.Count - 1 do begin
        lJsonTemp := TJSONObject( lArrayMsg.Objects[i] );

        room_name    := lJsonTemp.Get('room_name', '');
        from_id      := lJsonTemp.Get('from_id', 0);
        from_name    := lJsonTemp.Get('from_name', '');
        msg_date     := lJsonTemp.Get('last_message_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', now));
        ldate        := ISO8601ToDate( msg_date, True );
        total_unread := lJsonTemp.Get('total_unread', 0);

        if (room_name <> '') and (from_id > 0) then begin
          c := TChatCardInfo.Create( FBoxUnreadMessages );
          c.Parent := FBoxUnreadMessages;
          c.Left := FMargin;
          c.Top := FNextTop;
          c.OnClickInfo := @RoomUnaredMessage_Open;
          c.Setup(from_id, from_name, room_name, total_unread, ldate);

          Inc(FNextTop, c.Height + FSpacing);
        end; // if
      end; // for

      FBoxUnreadMessages.Visible := (FBoxUnreadMessages.ControlCount > 0);
      // auto-scroll
      //FBoxUnreadMessages.VertScrollBar.Position := FBoxUnreadMessages.VertScrollBar.Range;
    finally
      lJson.Free;
    end;
  end;
end;

procedure TChatModule.RoomUnaredMessage_Open(ARoomName: string);
// click na sala para abrir as mensagens não lidas
begin
  Chat_Open(ARoomName, '', True);
end;

procedure TChatModule.RoomUnaredMessage_Remove(ARoomName: string);
// Remove a sala da lista de mensagens não lidas
var
  c: TChatCardInfo;
  i: Integer;
begin
  if Trim(ARoomName) = '' then Exit;

  if Assigned(FBoxUnreadMessages) then begin
    // eliminar da lista
    try
      for i := 0 to FBoxUnreadMessages.ControlCount - 1 do begin
        if FBoxUnreadMessages.Controls[i] is TChatCardInfo then begin
          c := TChatCardInfo( FBoxUnreadMessages.Controls[i] );
          if c.RoomName = ARoomName then begin
            FBoxUnreadMessages.RemoveControl( FBoxUnreadMessages.Controls[i] );
            //  Auto-scroll
            FBoxUnreadMessages.VertScrollBar.Position := FBoxUnreadMessages.VertScrollBar.Range;
            Break;
          end;
        end; // if
      end; // for
    except
    end; // try
  end; // if
end;

procedure TChatModule.RoomUnreadMessage_Clear;
// remove todos os objetos
var
  i: Integer;
begin
  if Assigned(FBoxUnreadMessages) then begin
    try
      for i := FBoxUnreadMessages.ControlCount - 1 downto 0 do
        FBoxUnreadMessages.Controls[i].Free;
    except
    end;
  end;
end;

function TChatModule.IsMinhaSala(AChatRoom: string): Boolean;
// sou o dono/criador da sala ?
begin
  Result := False;
  if Trim(AChatRoom) <> '' then begin
    try
      Result := (FMeu_ID = StrToIntDef( AChatRoom.Split(['-'], TStringSplitOptions.ExcludeEmpty)[0], 0 ) );
    finally
    end;
  end;
end;

procedure TChatModule.ProcessaFila;
//processa a fila de mensagens
var
  Lista: TList;
  i: Integer;
  P: PChar;
  Msg: string;
begin
  Lista := FMsgQueue.LockList;

  try
    for i := 0 to Lista.Count - 1 do begin
      P := PChar(Lista[i]);
      Msg := string(P);
      StrDispose(P);

      AnalisaEventos(Msg);
    end;

    Lista.Clear;
  finally
    FMsgQueue.UnlockList;
  end;
end;

procedure TChatModule.ProcessaFilaAsync(AData: PtrInt);
//processa as mensagens armazenadas na fila FMsgQueue (OnReceive)
begin
  ProcessaFila;
end;

end.


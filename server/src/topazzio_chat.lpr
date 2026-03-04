program topazzio_chat;

{
 Topazzio Chat Server
 Requesito: Package lNet e ZeosDBO
 Aldo Márcio Soares - ams2kg@gmail.com - 2025-12-31
}

{$mode objfpc}{$H+}
{$Codepage UTF8}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes, Crt, SysUtils, CustApp, StrUtils, DateUtils, IniFiles,
  lNet, fpjson, jsonparser, Contnrs,
  DM.Server, Service.Mensagem, Service.Idioma;

type
  { TClientInfo }

  TClientInfo = class
  public
    Socket: TLSocket;
    OutQueue: TStringList;
    User_Id: Integer;
    User_Nome: string;
    User_IP: string;
    User_Data: string;
    constructor Create(ASocket: TLSocket);
    destructor Destroy; override;
  end;

  { TTopazzioChatServer }

  TTopazzioChatServer = class(TCustomApplication)
  private
    FServer: TLTCP;
    FClients: TObjectList;
    FLogAtivado, FServerEnding, FAppTerminado: Boolean;
    FServer_IP: string;
    FServer_Porta: Integer;
    FLanguage: string;
    FOnlineUsers: string;

    // eventos
    procedure OnAccept(aSocket: TLSocket);
    procedure OnDisconnect(aSocket: TLSocket);
    procedure OnError(const AMsg: string; aSocket: TLSocket);
    procedure OnReceive(aSocket: TLSocket);

    // controles do servidor
    procedure CreateServer;
    procedure LerServerConfig;
    procedure Log(const Msg: string);
    procedure WriteHelp; virtual;

    // controles de usuários
    { Encontra um cliente na lista conforme seu socket }
    function FindClient(aSocket: TLSocket): TClientInfo;
    { enviar a mensagem do cliente para uma fila }
    procedure SendToClient(ACli: TClientInfo; AMsg: string; AForcedUTF8: Boolean);
    { enviar a mensgem para os clientes, para uma fila }
    procedure Broadcast(const Msg: string; AExceptSock: TLSocket);
    { processa a entrega de mensagens contidas na fila }
    procedure FlushQueues;

    // banco dados
    function SalvarMensagem(AFromId: Integer; AFromName, ASala, AMsg, AFileName, AFileSize, AFileSizeExt: string): Integer;
    procedure SalvarMensagemTarget(AIdChat: Integer; ASala: string; AGuest, AToId: Integer; AToName: string);
    procedure MarcarMensagemLida(ACli: TClientInfo; ARoomName: string; AToId: Integer; AListIdChat: string);

    // eventos
    procedure Evento_Login(ACli: TClientInfo; AStrJson: string);
    procedure Evento_Logout(ACli: TClientInfo; AStrJson: string);
    procedure Evento_Chat(ACli: TClientInfo; AStrJson: string);
    procedure Evento_Delete(ACli: TClientInfo; AStrJson: string);
    procedure Evento_Writing(AStrJson: string);
    procedure Evento_Attention(AStrJson: string);
    procedure Evento_GetMessages(ACli: TClientInfo; AStrJson: string);
    procedure Evento_GetUsers(ACli: TClientInfo);
    procedure Evento_GetRoomGuests(ACli: TClientInfo; AStrJson: string);
    procedure Evento_RoomEnter(ACli: TClientInfo; AStrJson: string);
    procedure Evento_RoomLeave(ACli: TClientInfo; AStrJson: string);
    procedure Evento_RoomChange(ACli: TClientInfo; AStrJson: string);
    procedure Evento_SalasComMensagensNaoLidas(ACli: TClientInfo; AStrJson: string);
    procedure Evento_HistoryRooms(ACli: TClientInfo; AStrJson: string);
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ TClientInfo }

constructor TClientInfo.Create(ASocket: TLSocket);
begin
  Socket    := ASocket;
  OutQueue  := TStringList.Create;
  User_Id   := 0;
  User_Nome := '';
  User_IP   := '';
  User_Data := '';
end;

destructor TClientInfo.Destroy;
begin
  Socket.Free;
  OutQueue.Free;
  inherited Destroy;
end;

{ TTopazzioChatServer }

constructor TTopazzioChatServer.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;

  FClients := TObjectList.Create(True);

  FLogAtivado   := False;
  FServerEnding := False;
  FLanguage     := 'br';
  FOnlineUsers  := '';
  FAppTerminado := False;

  // Instanciar o DataModule (Banco dados)
  DMServer := TDMServer.Create(nil);
end;

destructor TTopazzioChatServer.Destroy;
var
  i: Integer;
  jMsg: string;
begin
  FServerEnding := True;
  Log(TUtilIdioma.EncerrandoServidor_Msg1(FLanguage));

  // Mensagem de encerramento
  jMsg := Format('{"event":"server_down","message":"%s"}', [TUtilIdioma.EncerrandoServidor_Msg2(FLanguage)]);

  if Assigned(FClients) then begin
    // encaminha as mensagens da fila
    FlushQueues;

    // notifica a todos
    if FClients.Count > 0 then begin
      WriteLn('');
      for i := FClients.Count - 1 downto 0 do begin
        try
          TClientInfo( FClients[i] ).Socket.SendMessage(jMsg);
        except
        end;
        Write('.');
      end;
      WriteLn('');

      // libera todos os clients
      for i := FClients.Count - 1 downto 0 do begin
        try
         TClientInfo( FClients[i] ).Free ;
        except
        end;
      end;
    end;

    try
      FClients.Free;
    except
    end;
  end;

  if Assigned(FServer) then
    FreeAndNil(FServer);

  // Destruir o DataModule por último
  if Assigned(DMServer) then
    FreeAndNil(DMServer);

  if FAppTerminado then
    Log(TUtilIdioma.EncerrandoServidor_Msg3(FLanguage));

  Log('');

  inherited Destroy;
end;

procedure TTopazzioChatServer.DoRun;
// ponto de execução deste servidor
var
  lparams, sLang: string;
  i: integer;
begin
  // parâmetros da linha de comando
  lparams := '';

  for i := 1 to ParamCount do
    lparams := lparams + ' ' + LowerCase( ParamStr(i) );

  if (lparams <> '') then begin
    if (lparams.Contains('--help')) then begin
      WriteHelp;
      FAppTerminado := False;
      Terminate;
      Exit;
    end;

    FLogAtivado := (lparams.Contains('--log')); // liga o LOG (para debug)

    if HasOption('lang') then begin
      sLang := LowerCase( GetOptionValue('lang') );
      if (IndexStr(sLang, ['br', 'en', 'es']) >= 0) then FLanguage := sLang;
    end;
  end;

  // pega IP e porta para este server
  FServer_IP    := '0.0.0.0';
  FServer_Porta := 9022;
  LerServerConfig;

  // Cria e inicializa o servidor
  CreateServer;

  FServer.Port := FServer_Porta;

  if not FServer.Listen(FServer_Porta, FServer_IP) then begin
    // conferir:
    // ss -ltnp | grep 9022
    // ou
    // netstat -tulpn | grep 9022

    Log(Format(TUtilIdioma.DoRun_Msg1(FLanguage), [FServer_IP, FServer_Porta]));
    Terminate;
    Exit;
  end;

  Log('');
  Log(TUtilIdioma.DoRun_Thanks(FLanguage));
  Log(TUtilIdioma.DoRun_Msg2(FLanguage));
  Log('V 1.0 | ams2kg@gmail.com | 2025-12-31');
  Log(TUtilIdioma.Help_Msg3(FLanguage));
  Log(Format('IP: %s, Port: %d', [FServer_IP, FServer_Porta]));

  if DMServer.IsConnected then
    // Log('Database Conectado: ' + DMServer.GetVersaoServidor)
    Log(TUtilIdioma.DoRun_Msg3(FLanguage) + ' [' + DMServer.GetDBType.ToUpper + ']')
  else
    Log(TUtilIdioma.DoRun_Msg4(FLanguage) + DMServer.GetMsgErro);

  if FLogAtivado then
    Log(TUtilIdioma.DoRun_Msg5(FLanguage));

  Log(TUtilIdioma.DoRun_Msg6(FLanguage));

  while not Terminated do begin
    FServer.CallAction;  // força eventos do lNet
    FlushQueues; // envia as mensagens na fila
    Sleep(10); // evita 100% CPU
    if KeyPressed then
      case ReadKey of
        'q','Q': begin
               FAppTerminado := True;
               Break;
             end;
      end;
  end; // while

  // termina o loop do programa
  Terminate;
end;

procedure TTopazzioChatServer.OnAccept(aSocket: TLSocket);
// usuário conectando neste server
// não enviar mensagem nenhuma para o client, porque o socket ainda não está pronto
// e vai interromper o servidor (shutdown)
var
  Cli: TClientInfo;
begin
  if FServerEnding then begin
    aSocket.Disconnect();
    Exit;
  end;

  // adiciona o socket na lista de clientes
  Cli := TClientInfo.Create(aSocket);
  Cli.User_Id   := 0;
  Cli.User_Nome := '';
  Cli.User_Data := '';
  Cli.User_IP   := aSocket.PeerAddress;

  // armazena na lista de clientes/sockets
  FClients.Add(Cli);

  if FLogAtivado then
    Log(Format(TUtilIdioma.OnAccept_Msg1(FLanguage), [aSocket.PeerAddress]));
end;

procedure TTopazzioChatServer.OnDisconnect(aSocket: TLSocket);
// usuário desconectando deste server
var
  Cli: TClientInfo;
  s, resposta: string;
begin
  Cli := FindClient(aSocket);

  if (Cli <> nil) then begin
    if Cli.User_Id > 0 then begin
      resposta := Format('{"event":"disconnected","user_id":%d,"message":"%s %s!"}', [Cli.User_Id, Cli.User_Nome, TUtilIdioma.Evento_Logout_Msg1(FLanguage)]);

      FOnlineUsers := FOnlineUsers.Replace(Format('[%d],', [Cli.User_Id]), '');

      if FLogAtivado and (Trim(FOnlineUsers) <> '') then Log(FOnlineUsers);

      s := Format(TUtilIdioma.OnDisconnect_Msg1(FLanguage), [Cli.User_Nome, aSocket.PeerAddress]);

      Broadcast( resposta,  aSocket);
    end
    else
      s := Format(TUtilIdioma.OnDisconnect_Msg2(FLanguage), [aSocket.PeerAddress]);

    // Libera o objeto de sessão deste usuário
    FClients.Remove(Cli);

    if FLogAtivado then Log(s);
  end;
end;

procedure TTopazzioChatServer.OnError(const AMsg: string; aSocket: TLSocket);
begin
  try
    // client windows causa "Falha de segmentação" quando fecha a conexão
    // Shutdown error [107]: Transport endpoint is not connected
    // Get error [104]: Connection reset by peer

    if FLogAtivado then
      Log('OnError: ' + AMsg);
  except
  end;
end;

procedure TTopazzioChatServer.OnReceive(aSocket: TLSocket);
// eventos recebidos do usuário
var
  lCli: TClientInfo;
  lMsg, evento: string;
  lData: TJSONData;
  lJSON: TJSONObject;
begin
  // servidor sendo encerrado
  if FServerEnding then begin
    try
      aSocket.SendMessage( TUtilIdioma.OnReceive_Msg1( FLanguage ) );
      Exit;
    except
    end;
  end;

  // tem mensagens enviada pelo client ?
  if aSocket.GetMessage( lMsg ) < 1 then Exit;

  // para ver o que está chegando
  if FLogAtivado then Log( lMsg );

  // força a conversão para UTF8 para funcionar acentuação e EMOJI
  //if StringCodePage(lMsg) = 0 then
  lMsg := UTF8Encode( lMsg );

  if FLogAtivado then
    Log(Format('CodePage: %d', [StringCodePage(lMsg)])); // se for 0, não é UTF8

  // detecta HTTP / WebSocket (incompatível com lNet)
  if Pos('GET ', lMsg) = 1 then begin
    aSocket.Disconnect;
    Exit;
  end;

  // tenta encontrar o usuário
  lCli := FindClient( aSocket );
  if lCli = nil then Exit;

  // eventos e mensagens do usuário

  try
    lData := GetJSON( lMsg );
  except
    lJSON := TJSONObject.Create;
    lJSON.Add('event', 'json_error');
    lJSON.Add('message', TUtilIdioma.OnReceive_Msg2(FLanguage));
    SendToClient(lCli, lJSON.AsJSON, False);
    lJSON.Free;
    Exit;
  end;

  try
    lJSON := TJSONObject( lData );

    evento := LowerCase( lJSON.Get('event', '') );

    { PROCESSA OS EVENTOS PROVOCADOS PELO USUÁRIO }


    { EFETUA LOGIN }

    if (evento = 'login') then begin
      //usuário fazendo login
      Evento_Login(lCli, lMsg);
    end

    { EFETUA LOGOFF }

    else if (evento = 'logoff') then begin
      // usuário fazendo logoff
      Evento_Logout(lCLI, lMsg);
    end

    { ENVIO DE MENSAGEM }

    else if (evento = 'chat') then begin
      // mensagens enviadas pelo usuário
      Evento_Chat(lCLI, lMsg);
    end

    { DELETA MENSAGEM }

    else if (evento = 'chat_delete') then begin
      // marca a mensagem como deletada
      Evento_Delete(lCLI, lMsg);
    end

    { USUÁRIO ESCREVENDO }

    else if (evento = 'writing') then begin
      // usuário está escrevendo
      Evento_Writing(lMsg);
    end

    { USUÁRIO CHAMANDO A ATENÇÃO }

    else if (evento = 'attention') then begin
      // usuário está chamando a atenção
      Evento_Attention(lMsg);
    end

    { RETORNA LISTA DE MENSAGENS }

    else if (evento = 'get_messages') or (evento = 'history_messages') then begin
      //lista de mensagens da sala: 'room_name' e 'to_id'
      Evento_GetMessages(lCLI, lMsg);
    end

    { RETORNA LISTA DE CONVIDADOS DA SALA }

    else if (evento = 'room_guests') then begin
      // lista de convidados da sala
      Evento_GetRoomGuests(lCLI, lMsg);
    end

    { NOTIFICA AOS CONVIDADOS A SUA ENTRADA NA SALA }

    else if (evento = 'room_enter') then begin
      // informa que saiu da sala
      Evento_RoomEnter(lCLI, lMsg);
    end

    { NOTIFICA AOS CONVIDADOS A SUA SAÍDA DA SALA }

    else if (evento = 'room_leave') then begin
      // informa que saiu da sala
      Evento_RoomLeave(lCLI, lMsg);
    end

    { NOTIFICA AOS CONVIDADOS QUE HOUVE ALTERAÇÃO DOS INTEGRANTES DA SALA }

    else if (evento = 'room_change') then begin
      // informa que houve alteração dos integrantes da sala
      Evento_RoomChange(lCLI, lMsg);
    end

    { Marca a mensagem do chat como lida pelo destinatário }

    else if (evento = 'mark_read') then begin
       MarcarMensagemLida(lCLI, lJSON.Get('room_name', ''), lJSON.Get('to_id', 0), lJSON.Get('list_idchat', ''));
    end

    { SALAS COM MENSAGENS NÂO LIDAS DO DESTINATŔIO }

    else if (evento = 'messages_unread') then begin
       Evento_SalasComMensagensNaoLidas(lCli, lMsg);
    end

    { HISTÓRICO DE SALAS COM MENSAGENS DO DESTINATŔIO }

    else if (evento = 'history_rooms') then begin
       Evento_HistoryRooms(lCli, lMsg);
    end

    { RETORNA LISTA DE USUÁRIOS CONECTADOS }

    else if (evento = 'get_users') then begin
      // lista de usuários online
      Evento_GetUsers(lCLI);
    end;
  finally
    lData.Free; // isso libera o lJSON também
  end;
end;

procedure TTopazzioChatServer.CreateServer;
// Cria e o servidor
begin
  FServer              := TLTCP.Create(nil);
  FServer.OnAccept     := @OnAccept;
  FServer.OnDisconnect := @OnDisconnect;
  FServer.OnError      := @OnError;
  FServer.OnReceive    := @OnReceive;
  FServer.Timeout      := 100;
  FServer.ReuseAddress := True;
end;

procedure TTopazzioChatServer.Broadcast(const Msg: string; AExceptSock: TLSocket);
// envia para todos
var
  i: Integer;
  Cli: TClientInfo;
begin
  for i := FClients.Count - 1 downto 0 do begin
    Cli := TClientInfo( FClients[i] );

    if not (Cli = nil) then begin
      if not (AExceptSock = nil) and (Cli.Socket <> AExceptSock) then
        Cli.OutQueue.Add( Msg )
      else
        Cli.OutQueue.Add( Msg );
    end;
  end; // for
end;

procedure TTopazzioChatServer.FlushQueues;
// encaminha as mensagens na lista
var
  i: Integer;
  Cli: TClientInfo;
begin
  for i := FClients.Count - 1 downto 0 do begin
    Cli := TClientInfo( FClients[i] );

    if (Cli = nil) or (Cli.Socket = nil) then begin
      // socket morto
      FClients.Delete(i);
      Continue;
    end;

    try
      while Cli.OutQueue.Count > 0 do begin
        if Cli.Socket.SendMessage(Cli.OutQueue[0]) > 0 then
          Cli.OutQueue.Delete(0)
        else
          Break; // buffer cheio, tenta no próximo loop
      end; // while
    except
    end; // try
  end; // for
end;

function TTopazzioChatServer.FindClient(aSocket: TLSocket): TClientInfo;
// encontra o client de acordo com o socket
var
  i: Integer;
  C: TClientInfo;
begin
  Result := nil;
  for i := FClients.Count - 1 downto 0 do begin
    C := TClientInfo( FClients[i] );
    if not (C = nil) and (C.Socket = aSocket) then begin
      Result := C;
      Exit;
    end;
  end;
end;

procedure TTopazzioChatServer.LerServerConfig;
// ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_config.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  try
    if not FileExists(FArquivoINI) then begin
      ArqINI.WriteString('config','ip', FServer_IP);
      ArqINI.WriteInteger('config','port', FServer_Porta);
    end;

    FServer_IP    := ArqINI.ReadString('config','ip', FServer_IP);
    FServer_Porta := ArqINI.ReadInteger('config','port', FServer_Porta);
  finally
    ArqINI.Free;
  end;

  if FServer_Porta < 1000 then FServer_Porta := 9022;
end;

procedure TTopazzioChatServer.Log(const Msg: string);
begin
  if Trim(Msg) <> '' then
    WriteLn(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' [LOG] ' + Msg)
  else
    WriteLn(' ');
end;

procedure TTopazzioChatServer.SendToClient(ACli: TClientInfo; AMsg: string; AForcedUTF8: Boolean);
// envia a mensagem para o queue/lista de espera
begin
  if AForcedUTF8 then AMsg := UTF8Encode( AMsg );
  ACli.OutQueue.Add( AMsg );
end;

/// Usuário fazendo login
/// procedure TTopazzioChatServer.Evento_Login(ACli: TClientInfo; AStrJson: string);
/// request: {"event":"login","from_id": 4,"from_name":"Maria Eduarda"}
/// response para você:
/// {"event":"login","message": "Login efetuado com sucesso"}
/// response para os outros:
/// {"event":"user_online","user_id":12,"message": "Maria Eduarda está online"}
procedure TTopazzioChatServer.Evento_Login(ACli: TClientInfo; AStrJson: string);
// usuário fazendo login
var
  AJson: TJSONObject;
  resposta, lnome: string;
  i, id_user: Integer;
  lUser: TClientInfo;
begin
  if ACli.User_Id = 0 then begin
    AJson := TJSONObject( GetJSON( AStrJson ) );
    id_user := AJson.Get('from_id', 0);
    lnome := AJson.Get('from_name', '');

    if (Pos(Format('[%d],',[id_user]), FOnlineUsers) > 0) then begin
      //já está logado em outra instância ?
      for i := FClients.Count - 1 downto 0 do begin
        lUser := TClientInfo( FClients[i] );

        if not (lUser = nil) and (lUser.User_Id = id_user) then begin
          resposta := Format('{"event":"login_duplicate","user_id":%d,"ip":"%s","data":"%s","message":"%s!"}', [id_user, lUser.User_IP, lUser.User_Data, TUtilIdioma.Evento_Login_Msg4(FLanguage)]);
          // notifica o próprio usuário
          SendToClient(ACli, resposta, False);
          Break;
        end; // if
      end; // for
    end else begin
      //registra o login e notifica usuário de demais usuários
      ACli.User_Id   := AJson.Get('from_id', 0);
      ACli.User_Nome := lnome;
      ACli.User_Data := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

      // adiciona à lista de usuários online
      FOnlineUsers := FOnlineUsers + Format('[%d],', [ACli.User_Id]);
      if FLogAtivado then Log(FOnlineUsers);

      if FLogAtivado then
        Log(Format(TUtilIdioma.Evento_Login_Msg1(FLanguage), [lnome]));

      resposta := Format('{"event":"user_online","user_id":%d,"message":"%s %s!"}', [ACli.User_Id, lnome, TUtilIdioma.Evento_Login_Msg2(FLanguage)]);

      // notifica o próprio usuário
      SendToClient(ACli, Format('{"event":"login","message":"%s"}',[TUtilIdioma.Evento_Login_Msg3(FLanguage)]), False);

      // notifica a todos, exceto este usuário
      Broadcast(resposta, ACli.Socket);
    end;

    AJson.Free;
  end;
end;

/// Usuário fazendo logout, sem desconectar do servidor
/// procedure TTopazzioChatServer.Evento_Logout(ACli: TClientInfo; AStrJson: string);
/// request: {"event":"logoff","from_id": 4,"from_name":"Maria Eduarda"}
/// response para você:
/// {"event":"logoff","message": "Logoff efetuado com sucesso"}
/// response para os outros:
/// {"event":"user_offline","user_id":12,"message":"Maria Eduarda está offline"}
procedure TTopazzioChatServer.Evento_Logout(ACli: TClientInfo; AStrJson: string);
// usuário fazendo logout, sem desconectar do servidor
var
  AJson: TJSONObject;
  resposta, lnome: string;
begin
  if ACli.User_Id > 0 then begin
    AJson := TJSONObject( GetJSON( AStrJson ) );

    lnome := AJson.Get('from_name', '');
    resposta := Format('{"event":"user_offline","user_id":%d,"message":"%s %s!"}', [ACli.User_Id, lnome, TUtilIdioma.Evento_Logout_Msg1(FLanguage)]);

    // remove da lista de usuários online
    FOnlineUsers := FOnlineUsers.Replace(Format('[%d],', [ACli.User_Id]), '');

    SendToClient(ACli, Format('{"event":"logoff","message":"%s"}', [TUtilIdioma.Evento_Logout_Msg2(FLanguage)]), False);

    // notifica a todos, exceto este usuário
    Broadcast(resposta, ACli.Socket);

    // limpa informações do usuário
    ACli.User_Id   := 0;
    ACli.User_Nome := '';
    ACli.User_Data := '';

    AJson.Free;
  end;
end;

/// Envia de mensaem no chat
/// procedure TTopazzioChatServer.Evento_Chat(ACli: TClientInfo; AStrJson: string);
/// request:
/// {
///   "event": "chat",
///   "from_id": 8,
///   "from_name": "Carlos de Souza",
///   "room_name": "8-3487234874",
///   "msg": "Olá mundo",
///   "file_name": "",
///   "file_size": "0",
///   "file_size_ext": "",
///   "to": [
///     {
///       "guest": 1,
///       "to_id": 3,
///       "to_name": "Jose da Silva"
///     },
///     {
///       "guest": 1,
///       "to_id": 10,
///       "to_name": "Pedro Oliveira"
///     }
///   ]
/// }
///
/// response:
/// {
///   "event": "chat",
///   "idchat": 49,
///   "from_id": 8,
///   "from_name": "Carlos de Souza",
///   "room_name": "8-3487234874",
///   "msg": "Olá mundo",
///   "file_name": "",
///   "file_size": "0",
///   "file_size_ext": "",
///   "to": [
///     {
///       "guest": 1,
///       "to_id": 3,
///       "to_name": "Jose da Silva"
///     },
///     {
///       "guest": 1,
///       "to_id": 10,
///       "to_name": "Pedro Oliveira"
///     }
///   ]
/// }
procedure TTopazzioChatServer.Evento_Chat(ACli: TClientInfo; AStrJson: string);
// mensagens enviadas pelo usuário
var
  resposta: string;
  i, j, idChat: Integer;
  AJson, lChat, lJsonTemp: TJSONObject;
  lArrayTo: TJSONArray;
  User: TClientInfo;
begin
  try
    idChat := 0;
    AJson  := TJSONObject( GetJSON( AStrJson ) );
    lArrayTo := TJSONArray( AJson.Arrays['to'] );

    if lArrayTo.Count > 0 then begin
      // salva no db para este usuário remetente
      idChat := SalvarMensagem(AJson.Get('from_id', 0),
                               AJson.Get('from_name', ''),
                               AJson.Get('room_name', ''),
                               AJson.Get('msg', ''),
                               AJson.Get('file_name', ''),
                               AJson.Get('file_size', ''),
                               AJson.Get('file_size_ext', '')
                               );

      if idChat > 0 then begin

        // salva no db para cada destinatário
        for i := 0 to lArrayTo.Count - 1 do begin
          lJsonTemp := TJSONObject( lArrayTo.Items[i] );

          // salva o destinatário
          SalvarMensagemTarget(idChat,
                               AJson.Get('room_name', ''),
                               lJsonTemp.Get('guest', 0),
                               lJsonTemp.Get('to_id', 0),
                               lJsonTemp.Get('to_name', '')
                              );

        end; // for

        // Notifica os destinatários via evento
        lChat := TJSONObject.Create;
        lChat.Add('event', 'chat');
        lChat.Add('idchat', idChat);
        lChat.Add('from_id', AJson.Get('from_id', 0));
        lChat.Add('from_name', AJson.Get('from_name', ''));
        lChat.Add('room_name', AJson.Get('room_name', ''));
        lChat.Add('msg', AJson.Get('msg', ''));
        lChat.Add('file_name', AJson.Get('file_name', ''));
        lChat.Add('file_size', AJson.Get('file_size', '0'));
        lChat.Add('file_size_ext', AJson.Get('file_size_ext', ''));
        lChat.Add('deleted', False);
        lChat.Add('to', lArrayTo);

        resposta := lChat.AsJSON;

        // notifica cada destinatário via evento
        for i := 0 to lArrayTo.Count - 1 do begin
          lJsonTemp := TJSONObject( lArrayTo.Items[i] );

          try
            for j := FClients.Count - 1 downto 0 do begin
              User := TClientInfo( FClients[j] );

              if (User.User_Id = lJsonTemp.Get('to_id', 0)) then begin
                // User.Socket <> ACli.Socket
                SendToClient(User, resposta, False);
                Break;
              end;
            end; // for FClients
          finally
          end;

        end; // for lArrayTo

        lChat.Free;
      end else begin
        // notifica o rementente que a mensagem não foi distribuída
        lChat := TJSONObject.Create;
        lChat.Add('event', 'chat_error');
        lChat.Add('message', TUtilIdioma.Evento_Chat_Msg1(FLanguage));
        lChat.Add('from_id', AJson.Get('from_id', 0));
        lChat.Add('room_name', AJson.Get('room_name', ''));
        lChat.Add('msg', AJson.Get('msg', ''));

        resposta := lChat.AsJSON;

        SendToClient(ACli, resposta, False);

        lChat.Free;
      end; // if idchat

    end; // if lArrayTo.Count
  finally
    // AJson.Free;
  end; // try
end;

/// Marca a mensagem como deletada
/// procedure TTopazzioChatServer.Evento_Delete(ACli: TClientInfo; AStrJson: string);
/// Request:
/// {
///   "event": "chat_delete",
///   "room_name": "9-34872394824",
///   "from_id": 9,
///   "idchat": 120,
///   "file_name": "dados.txt",
/// }
///
/// Response:
/// {
///   "event": "chat_delete",
///   "room_name": "9-34872394824",
///   "from_id": 9,
///   "idchat": 120,
///   "file_name": "dados.txt",
///   "deleted": true
/// }
procedure TTopazzioChatServer.Evento_Delete(ACli: TClientInfo; AStrJson: string);
// marca a mensagem como deletada
var
  AJson: TJSONObject;
  lService: TServiceMensagem;
  resposta: string;
  idChat: Integer;
  bDeletou: Boolean;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  idChat := AJson.Get('idchat', 0);

  // marca como deletado no banco
  lService := TServiceMensagem.Create( FLanguage, FLogAtivado );
  bDeletou := lService.Deletar( idChat );
  lService.Free;

  AJson.Add('deleted', bDeletou);

  resposta := AJson.AsJSON;

  AJson.Free;

  // notifica o remetente
  SendToClient(ACli, resposta, False);

  // notifica os outros da sala
  Broadcast(resposta, ACli.Socket);
end;

/// Chama a atenção dos convidados da sala
/// procedure TTopazzioChatServer.Evento_Writing(AStrJson: string);
/// request:
/// {
///  "event": "writing",
///  "from_id", 8,
///  "from_name": "Carlos de Souza",
///  "room_name": "8-3487234874",
///  "to": [
///    {
///      "guest": 1,
///      "to_id": 3,
///      "to_name": "Jose da Silva"
///    },
///    {
///      "guest": 1,
///      "to_id": 10,
///      "to_name": "Pedro Oliveira"
///    }
///  ]
/// }
///
/// response:
/// {
///   "event" : "writing",
///   "from_id": 8,
///   "from_name": "Carlos de Souza",
///   "room_name": "8-3487234874",
///   "to": [
///    {
///      "guest": 1,
///      "to_id": 3,
///      "to_name": "Jose da Silva"
///    },
///    {
///      "guest": 1,
///      "to_id": 10,
///      "to_name": "Pedro Oliveira"
///    }
///   ]
/// }
procedure TTopazzioChatServer.Evento_Writing(AStrJson: string);
// usuário está escrevendo
var
  resposta: string;
  i, j: Integer;
  AJson, lChat, lJsonTemp: TJSONObject;
  lArrayTo: TJSONArray;
  User: TClientInfo;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );

  // Notifica os destinatários via evento
  lChat := TJSONObject.Create;
  lChat.Add('event', 'writing');
  lChat.Add('from_id', AJson.Get('from_id', 0));
  lChat.Add('from_name', AJson.Get('from_name', ''));
  lChat.Add('room_name', AJson.Get('room_name', ''));

  resposta := lChat.AsJSON;

  try
    lArrayTo := TJSONArray( AJson.Arrays['to'] );

    if lArrayTo.Count > 0 then begin

        // notifica cada destinatário via evento
        for i := 0 to lArrayTo.Count - 1 do begin
          lJsonTemp := TJSONObject( lArrayTo.Items[i] );

          for j := FClients.Count - 1 downto 0 do begin
            User := TClientInfo( FClients[j] );

            if (User.User_Id = lJsonTemp.Get('to_id', 0)) then begin
              SendToClient(User, resposta, False);
              Break;
            end;
          end; // for FClients
        end; // for lArrayTo

    end; // if lArrayTo.Count

    // lArrayTo.Free; { não faça isso para evitar EAccessViolation }
  finally;
    lChat.Free;
    // AJson.Free; //libera também o lArrayTo
  end; // try
end;

/// Chama a atenção dos convidados da sala
/// procedure TTopazzioChatServer.Evento_Attention(AStrJson: string);
/// request:
/// {
///  "event": "attention",
///  "from_id", 8,
///  "from_name": "Carlos de Souza",
///  "room_name": "8-3487234874",
///  "to": [
///    {
///      "guest": 1,
///      "to_id": 3,
///      "to_name": "Jose da Silva"
///    },
///    {
///      "guest": 1,
///      "to_id": 10,
///      "to_name": "Pedro Oliveira"
///    }
///  ]
/// }
///
/// response:
/// {
///   "event" : "attention",
///   "from_id": 8,
///   "from_name": "Carlos de Souza",
///   "room_name": "8-3487234874"
/// }
procedure TTopazzioChatServer.Evento_Attention(AStrJson: string);
// usuário chamando a atenção
var
  resposta: string;
  i, j: Integer;
  AJson, lChat, lJsonTemp: TJSONObject;
  lArrayTo: TJSONArray;
  User: TClientInfo;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );

  // Notifica os destinatários via evento
  lChat := TJSONObject.Create;
  lChat.Add('event', 'attention');
  lChat.Add('from_id', AJson.Get('from_id', 0));
  lChat.Add('from_name', AJson.Get('from_name', ''));
  lChat.Add('room_name', AJson.Get('room_name', ''));

  resposta := lChat.AsJSON;

  try
    lArrayTo := TJSONArray( AJson.Arrays['to'] );

    if lArrayTo.Count > 0 then begin

        // notifica cada destinatário via evento
        for i := 0 to lArrayTo.Count - 1 do begin
          lJsonTemp := TJSONObject( lArrayTo.Items[i] );

          for j := FClients.Count - 1 downto 0 do begin
              User := TClientInfo( FClients[j] );

              if (User.User_Id = lJsonTemp.Get('to_id', 0)) then begin
                SendToClient(User, resposta, False);
                Break;
              end;
           end; // for FClients
        end; // for lArrayTo
    end; // if lArrayTo.Count

    // lArrayTo.Free; { não faça isso para evitar EAccessViolation }
  finally
    lChat.Free;
    // AJson.Free; //libera também o lArrayTo
  end; // try
end;

/// Lista de mensagens da sala indicada
/// procedure TTopazzioChatServer.Evento_GetMessages(ACli: TClientInfo; AEvent, AStrJson: string);
/// request: {"event":"get_messages","room_name":"16-2387237234847","to_id":40}
/// request: {"event":"history_messages","room_name":"16-2387237234847","to_id":40}
/// response:
/// {
///   "event":"get_messages",
///   "room_name":"16-2387237234847",
///   "to":[
///     {
///       "guest": 0,
///       "to_id": 8,
///       "to_name": "Maria Eduarda".
///       "total_unread": 0,
///       "online": true
///     },
///     {
///       "guest": 1,
///       "to_id": 5,
///       "to_name": "Maria Eduarda".
///       "total_unread": 3,
///       "online": true
///     }
///   ],
///   "messages":[
///     {
///       "idchat": 1,
///       "from_id": 8,
///       "from_name": "José da Silva",
///       "msg": "Olá mundo",
///       "file_name": "",
///       "file_size": "0",
///       "file_size_ext": "",
///       "msg_date": "2026-02-06 14:30:22"
///     },
///     {
///       "idchat": 2,
///       "from_id": 8,
///       "from_name": "José da Silva",
///       "msg": "",
///       "file_name": "arquivo_dados.pdf",
///       "file_size": "2097152",
///       "file_size_ext": "2MB",
///       "msg_date": "2026-02-06 14:32:17"
///     }
///   ]
/// }
procedure TTopazzioChatServer.Evento_GetMessages(ACli: TClientInfo; AStrJson: string);
// retorna a lista de mensagens do DB, conforme sala e destinatário
var
  resposta: string;
  lService: TServiceMensagem;
begin
  lService := TServiceMensagem.Create( FLanguage, FLogAtivado );
  resposta := lService.ListaMensagens( AStrJson, FOnlineUsers );

  SendToClient(ACli, resposta, False);
  lService.Free;
end;

/// Lista de usuários online
/// procedure TTopazzioChatServer.Evento_GetUsers(ACli: TClientInfo);
/// request: {"event":"get_users"}
/// response:
/// {
///   "event":"get_users",
///   "users": [
///     {
///       "id": 16,
///       "name": "Maria da Silva",
///       "connected_since": "2026-02-05 14:30:05",
///       "ip": "192.168.1.122"
///     }
///   ]
/// }
procedure TTopazzioChatServer.Evento_GetUsers(ACli: TClientInfo);
// retorna a lista de usuários online
var
  resposta: string;
  lJSON, lUserJson: TJSONObject;
  lArrayTo: TJSONArray;
  i: Integer;
  User: TClientInfo;
begin
  lJSON  := TJSONObject.Create;
  lArrayTo := TJSONArray.Create;

  try
    lJSON.Add('event', 'get_users');

    try
      // Percorre a lista de usuários online
      for i := FClients.Count - 1 downto 0 do begin
        User := TClientInfo( FClients[i] );
        if User.User_Id > 0 then begin
          lUserJson := TJSONObject.Create;
          lUserJson.Add('id', User.User_Id);
          lUserJson.Add('name', User.User_Nome);
          lUserJson.Add('connected_since', User.User_Data);
          lUserJson.Add('ip', User.User_IP);

          lArrayTo.Add( lUserJson );
        end;
      end;
    except
    end;

    lJSON.Add('users', lArrayTo);

    resposta := lJSON.AsJSON;

    if FLogAtivado then
      Log(resposta);

    // Envia de volta apenas para quem pediu
    SendToClient(ACli, resposta, False);
  finally
    lJSON.Free; // Isso libera o lArrayTo e os lUser internos automaticamente
    resposta := '';
  end;
end;

/// Lista de salas com mensagens pendentes do destinatário
/// procedure TTopazzioChatServer.Evento_SalasComMensagensNaoLidas(ACli: TClientInfo; AStrJson: string);
/// Request: {"event":"messages_unread","to_id":100}
/// Response:
/// {
///  "event": "messages_unread",
///  "to_id": 100,
///  "messages": [
///   {
///     "room_name": "21-23847823479834",
///     "from_id": 11,
///     "from_name": "dono da sala",
///     "last_message_date": "2026-02-15 14:07:30",
///     "total_unread": 5
///   }
///  ]
/// }
procedure TTopazzioChatServer.Evento_SalasComMensagensNaoLidas(
  ACli: TClientInfo; AStrJson: string);
// Lista de salas com mensagens pendentes do destinatário
var
  resposta: string;
  lService: TServiceMensagem;
begin
  lService := TServiceMensagem.Create( FLanguage, FLogAtivado );
  resposta := lService.SalasComMensagensNaoLidas( AStrJson );

  SendToClient(ACli, resposta, False);
  lService.Free;
end;

/// Histórico de mensagens da sala indicada
/// procedure TTopazzioChatServer.Evento_HistoryRooms(ACli: TClientInfo; AStrJson: string);
/// request: {"event":"history_rooms","to_id":16,"has_files":true,"search":"maria"}
/// response:
/// {
///   "event":"history_rooms",
///   "to_id":16,
///   "to":[
///   "messages":[
///     {
///       "room_name": "1-28723473847",
///       "from_id": 8,
///       "from_name": "José da Silva",
///       "date": "2026-02-10 11:30:22",
///       "total_msg": 15
///     },
///     {
///       "room_name": "6-98384029840",
///       "from_id": 3,
///       "from_name": "Maria Helena",
///       "date": "2026-02-11 14:05:17",
///       "total_msg": 6
///     }
///   ]
/// }
procedure TTopazzioChatServer.Evento_HistoryRooms(ACli: TClientInfo; AStrJson: string);
// histórico de salas de conversas
var
  resposta: string;
  lService: TServiceMensagem;
begin
  lService := TServiceMensagem.Create( FLanguage, FLogAtivado );
  resposta := lService.HistoryRooms( AStrJson );

  SendToClient(ACli, resposta, False);
  lService.Free;
end;

/// Retorna a lista de convidados da sala indicada com status online e quantidade de msg não lida
/// procedure Evento_GetRoomGuests(ACli: TClientInfo; AStrJson: string)
/// Request: {"event":"room_guests","room_name":"1-74236487624","to":[{"guest":0,"to_id":10,"to_name":"nome convidado"}]}
/// Response:
/// {
///  "event": "room_guests",
///  "room_name": "1-74236487624",
///  "to": [
///   {
///     "guest": 0,
///     "to_id": 18,
///     "to_name": "guest name",
///     "online": true,
///     "total_unread": 5
///   }
///  ]
/// }
procedure TTopazzioChatServer.Evento_GetRoomGuests(ACli: TClientInfo; AStrJson: string);
// retorna a lista de convidados da sala, status online e qde msg não lida
var
  resposta: string;
  lService: TServiceMensagem;
begin
  lService := TServiceMensagem.Create( FLanguage, FLogAtivado );
  resposta := lService.ListaRoomConvidados( AStrJson, FOnlineUsers );

  SendToClient(ACli, resposta, False);
  lService.Free;
end;

/// Notifica os convidados da sala que você entrou, abriu a tela
/// procedure TTopazzioChatServer.Evento_RoomEnter(ACli: TClientInfo; AStrJson: string);
/// Request e Response:
/// {
///  "event": "room_leave",
///  "room_name": "31-74236487624",
///  "from_id": 31,
///  "from_name": "Mariana Oliveira"
/// }
procedure TTopazzioChatServer.Evento_RoomEnter(ACli: TClientInfo; AStrJson: string);
// Informa ao convidados da sala que você entrou, abriu a tela
var
  j: Integer;
  User: TClientInfo;
begin
  try
    for j := FClients.Count - 1 downto 0 do begin
      User := TClientInfo( FClients[j] );

      if not (User = nil) then begin
        SendToClient(User, UTF8Decode(AStrJson), False);
      end;
   end; // for FClients
  except
  end; // try
end;

/// Notifica os convidados da sala que você saiu, fechou a tela
/// procedure TTopazzioChatServer.Evento_RoomLeave(ACli: TClientInfo; AStrJson: string);
/// Request e Response:
/// {
///  "event": "room_leave",
///  "room_name": "31-74236487624",
///  "from_id": 31,
///  "from_name": "Mariana Oliveira"
///  "to": [
///    {
///      "guest": 1,
///      "to_id": 3,
///      "to_name": "Jose da Silva"
///    },
///    {
///      "guest": 1,
///      "to_id": 10,
///      "to_name": "Pedro Oliveira"
///    }
///  ]
/// }
procedure TTopazzioChatServer.Evento_RoomLeave(ACli: TClientInfo; AStrJson: string);
// Informa ao convidados da sala que você saiu, fechou a tela
var
  i, j: Integer;
  AJson, lJsonUser: TJSONObject;
  lArrayTo: TJSONArray;
  User: TClientInfo;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  lArrayTo := TJSONArray( AJson.Arrays['to'] );

  try
    if lArrayTo.Count > 0 then begin
      // notifica cada destinatário via evento
      for i := 0 to lArrayTo.Count - 1 do begin
        lJsonUser := TJSONObject( lArrayTo.Items[i] );

        for j := FClients.Count - 1 downto 0 do begin
            User := TClientInfo( FClients[j] );

            if not (User = nil) and (User.User_Id = lJsonUser.Get('to_id', 0)) then begin
              SendToClient(User, UTF8Decode(AStrJson), False);
              Break;
            end;
         end; // for FClients
      end; // for lArrayTo
    end; // if lArrayTo.Count

    // lArrayTo.Free; { não faça isso para evitar EAccessViolation }
  finally
    AJson.Free; // libera também o lArrayTo
  end; // try
end;

/// Alteração dos convidados da sala (adicionados ou removidos)
/// procedure TTopazzioChatServer.Evento_RoomChange(ACli: TClientInfo; AStrJson: string);
/// Request e Response:
/// {
///  "event": "room_change",
///  "room_name": "4-74236487624",
///  "to": [
///    {
///      "guest": 1,
///      "to_id": 3,
///      "to_name": "Jose da Silva"
///    },
///    {
///      "guest": 1,
///      "to_id": 10,
///      "to_name": "Pedro Oliveira"
///    }
///  ]
/// }
procedure TTopazzioChatServer.Evento_RoomChange(ACli: TClientInfo; AStrJson: string);
// notifica sobre alteração dos convidados da sala
begin
  Broadcast( UTF8Decode(AStrJson), ACli.Socket);
end;

procedure TTopazzioChatServer.WriteHelp;
begin
  { add your help code here }
  WriteLn(' ');
  WriteLn('Help - Topazzio Chat Server');
  WriteLn('--help     --> Help');
  WriteLn('--log      --> ' + TUtilIdioma.Help_Msg1(FLanguage));
  WriteLn('--lang=br  --> ' + TUtilIdioma.Help_Msg2(FLanguage));
  WriteLn(' ');
end;

function TTopazzioChatServer.SalvarMensagem(AFromId: Integer; AFromName, ASala, AMsg,
                                            AFileName, AFileSize, AFileSizeExt: string): Integer;
// salva a mensagem no banco
var
  m: TServiceMensagem;
begin
  Result := 0;

  m := TServiceMensagem.Create( FLanguage, FLogAtivado );
  m.FromId      := AFromId;
  m.FromName    := AFromName;
  m.RoomName    := ASala;
  m.Msg         := AMsg;
  m.FileName    := AFileName;
  m.FileSize    := AFileSize;
  m.FileSizeExt := AFileSizeExt;
  m.Salvar(0);

  if m.Sucesso then Result := m.IdChat;

  m.Free;
end;

procedure TTopazzioChatServer.SalvarMensagemTarget(AIdChat: Integer; ASala: string; AGuest, AToId: Integer; AToName: string);
// salva o destinatário da mensagem no banco
begin
  with TServiceMensagem.Create( FLanguage, FLogAtivado ) do begin
    SalvarDestinatario(AIdChat, ASala, AGuest, AToId, AToName);

    // se estiver on line, marca a mensagem como lida
    if (Pos(Format('[%d],',[AToId]), FOnlineUsers) > 0) then
      MarcarComoLida(ASala, AToId, IntToStr(AIdChat));
  end;
end;

procedure TTopazzioChatServer.MarcarMensagemLida(ACli: TClientInfo; ARoomName: string; AToId: Integer; AListIdChat: string);
// marca a mensagem como lida
// AListIdChat = 1,2,3,..,n  OU  AListIdChat = '' para todas as mensagens da sala
var
  resposta: string;
begin
  with TServiceMensagem.Create( FLanguage, FLogAtivado ) do begin
    resposta := MarcarComoLida(ARoomName, AToId, AListIdChat);
    SendToClient(ACli, resposta, False);
  end;
end;


//-----------[ Start do APP ]-----------

var
  Application: TTopazzioChatServer;

{$R *.res}

begin
  Application := TTopazzioChatServer.Create(nil);
  Application.Title := 'Topazzio Chat Server';

  try
    Application.Run;
  finally
    Application.Free;
  end;
end.


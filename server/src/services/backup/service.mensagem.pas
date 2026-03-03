unit Service.Mensagem;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, ZDataset, fpjson, DateUtils;

type

  { TServiceMensagem }

  TServiceMensagem = class
    private
      FLanguage: string;
      FFileName: string;
      FFileSize: string;
      FFileSizeExt: string;
      FIsConectado: Boolean;
      FSucesso: Boolean;
      FMensagem: string;
      FLogAtivado: Boolean;

      //campos da tabela
      FIdChat: Integer;
      FFromId: Integer;
      FFromName: string;
      FRoomName: string;
      FMsg: string;
      FMsgDate: TDateTime;

      function GetRoomConvidados(ARoomName, AOnLine: string): string;
      function ListaMessagensDestinatarios(ARoomName: string; AToID: integer): TJSONArray;
      function ListaMessagensNaoLidas(ARoomName, AOnLine: string; AToID: integer): TJSONArray;
      procedure Log(const Msg: string);
    public
      constructor Create(ALang: string; ALogAtivado: Boolean);
      destructor Destroy; override;
      property GetMensagem: string read FMensagem;
      property Sucesso: Boolean read FSucesso;

      // campos da tabela
      property IdChat: Integer read FIdChat;
      property FromId: Integer read FFromId write FFromId;
      property FromName: string read FFromName write FFromName; // 50
      property RoomName: string read FRoomName write FRoomName; // 50
      property Msg: string read FMsg write FMsg; // Mensagem
      property FileName: string read FFileName write FFileName; // text (arquivo.ext)
      property FileSize: string read FFileSize write FFileSize; // 50 (4194304) bytes
      property FileSizeExt: string read FFileSizeExt write FFileSizeExt; // 50 (4MB)
      property MsgDate: TDateTime read FMsgDate; // só leitura

      // operações

      // mensagens
      procedure Salvar(AId: integer);
      function Deletar(AIdChat: Integer): Boolean;
      function ListaMensagens(AStrJson, AOnLine: string): string;
      function SalasComMensagensNaoLidas(AStrJson: string): string;

      // destinatários
      function MarcarComoLida(ARoomName: string; AToId: Integer; AListIdChat: string): string;
      procedure SalvarDestinatario(AIdChat: Integer; ARoomName: string; AGuest, AToId: Integer; AToName: string);

      // convidados da sala
      procedure SalvarRoomGuests(ARoomName: string; AGuest, AToId: Integer;AToName: string);
      function ListaRoomConvidados(AStrJson, AOnLine: string): string;

      // history de salas de mensagens
      function HistoryRooms(AStrJson: string): string;
  end;

implementation

uses
  DM.Server, Service.Idioma;

{ TServiceMensagem }

constructor TServiceMensagem.Create(ALang: string; ALogAtivado: Boolean);
begin
  FLanguage := ALang;
  FMensagem := '';
  FSucesso  := True;
  FIsConectado := True;
  FLogAtivado := ALogAtivado;

  if not DMServer.IsConnected then
  begin
    FMensagem := TUtilIdioma.ServiceMensagem_Msg1(ALang);
    FSucesso  := False;
    FIsConectado := False;
  end;
end;

destructor TServiceMensagem.Destroy;
begin
  inherited Destroy;
end;

procedure TServiceMensagem.Salvar(AId: integer);
// salva a mensagem
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;
  FMensagem := '';
  FSucesso  := False;
  if FileSize = '' then FileSize := '0';

  try
    q := DMServer.NewQuery();

    if AId < 1 then
    begin
      q.SQL.Add('INSERT INTO chat_messages ');
      q.SQL.Add('(from_id, from_name, room_name, msg, file_name, file_size, file_size_ext) ');
      q.SQL.Add('VALUES(');
      q.SQL.Add(':from_id, :from_name, :room_name, :msg, :file_name, :file_size, :file_size_ext ');
      q.SQL.Add(') ');
      q.SQL.Add('RETURNING idchat as id; '); // postgresql
    end
    else begin
      q.SQL.Add('UPDATE chat_messages SET ');
      q.SQL.Add('from_id = :from_id, from_name = :from_name, ');
      q.SQL.Add('room_name = :room_name, msg = :msg, ');
      q.SQL.Add('file_name = :file_name, file_size = :file_size, ');
      q.SQL.Add('file_size_ext = :file_size_ext ');
      q.SQL.Add('WHERE idchat = ' + IntToStr(AId));
    end;

    q.ParamByName('from_id').AsInteger  := FromId;
    q.ParamByName('from_name').AsString := FromName;
    q.ParamByName('room_name').AsString := RoomName;
    q.ParamByName('msg').AsString       := Msg;
    q.ParamByName('file_name').AsString := FileName;
    q.ParamByName('file_size').AsString := FileSize;
    q.ParamByName('file_size_ext').AsString := FileSizeExt;

    DMServer.TransactionPrepare;

    if AId < 1 then
    begin
      q.Open;
      FIdChat := q.FieldByName('id').AsInteger;
      FMensagem := TUtilIdioma.ServiceMensagem_Msg2(FLanguage);
    end
    else begin
      q.ExecSQL;
      FIdChat := AId;
      FMensagem := TUtilIdioma.ServiceMensagem_Msg3(FLanguage);
    end;

    DMServer.TransactionCommit;

    FSucesso := True;
    if AId < 1 then q.Close; // por causa do Returning idchat
    q.Free;
  except
    on E: Exception do begin
      FIdChat := 0;
      FSucesso  := False;
      FMensagem := E.Message;
      DMServer.TransactionRollback;
      Log('TServiceMensagem.Salvar' + sLineBreak + E.Message);
      q.Free;
    end;
  end;
end;

function TServiceMensagem.Deletar(AIdChat: Integer): Boolean;
// marca a mensagem como deletada
var
  q: TZQuery;
begin
  Result := False;
  if (not FIsConectado) or (AIdChat = 0) then Exit;

  FMensagem := '';
  FSucesso  := False;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('UPDATE chat_messages SET ');
    q.SQL.Add('deleted = 1 ');
    q.SQL.Add('WHERE idchat = ' + IntToStr(AIdChat));

    DMServer.TransactionPrepare;

    q.ExecSQL;

    DMServer.TransactionCommit;

    FSucesso  := True;
    Result := True;
    q.Free;
  except
    on E: Exception do begin
      Result := False;
      FSucesso := False;
      FMensagem := E.Message;
      DMServer.TransactionRollback;
      Log('TServiceMensagem.Deletar' + sLineBreak + E.Message);
      q.Free;
    end;
  end;
end;

function TServiceMensagem.ListaMensagens(AStrJson, AOnLine: string): string;
// lista de mensagens para a sala
var
  q: TZQuery;
  AJson, lJSON, lMsg: TJSONObject;
  lArrayTo, lArrayMsg: TJSONArray;
  lEvent, lRoomName, ldados: string;
  lTo_Id: Integer;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  lEvent := AJson.Get('event', 'get_messages');
  lRoomName := AJson.Get('room_name', '');
  lTo_Id := AJson.Get('to_id', 0);
  Result := Format('{"event":"%s","room_name":"%s", "to":[], "messages":[]}', [lEvent, lRoomName]);
  if not FIsConectado or (lRoomName = '') then Exit;

  lJSON := TJSONObject.Create;

  // marca as mensagens do destinatário como lidas
  if (lTo_Id > 0) then
    MarcarComoLida(lRoomName, lTo_Id, '');

  try
    try
      q := DMServer.NewQuery();

      q.SQL.Add('SELECT ');
      q.SQL.Add('  m.idchat, m.from_id, m.from_name, ');
      q.SQL.Add('  m.room_name, m.msg, m.file_name, ');
      q.SQL.Add('  m.file_size, m.file_size_ext, ');
      q.SQL.Add('  m.msg_date, m.deleted ');
      q.SQL.Add('FROM ');
      q.SQL.Add('  chat_messages m ');
      q.SQL.Add('WHERE ');
      q.SQL.Add('  m.room_name = :room_name ');
      q.SQL.Add('ORDER BY ');
      q.SQL.Add('  m.idchat ASC; ');

      q.ParamByName('room_name').AsString := lRoomName;

      q.Open;

      if (q.RecordCount > 0) then begin
        ldados := GetRoomConvidados(lRoomName, AOnLine);
        lArrayTo := TJSONArray( GetJSON( ldados ) );
        lArrayMsg := TJSONArray.Create;

        lJSON.Add('event', lEvent);
        lJSON.Add('room_name', lRoomName);
        lJSON.Add('to', lArrayTo);

        while not q.EOF do begin
          lMsg := TJSONObject.Create;

          lMsg.Add('idchat', q.FieldByName('idchat').AsInteger);
          lMsg.Add('from_id', q.FieldByName('from_id').AsInteger);
          lMsg.Add('from_name', q.FieldByName('from_name').AsString);
          lMsg.Add('msg', q.FieldByName('msg').AsString);
          lMsg.Add('file_name', q.FieldByName('file_name').AsString);
          lMsg.Add('file_size', q.FieldByName('file_size').AsString);
          lMsg.Add('file_size_ext', q.FieldByName('file_size_ext').AsString);
          lMsg.Add('msg_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', q.FieldByName('msg_date').AsDateTime));
          lMsg.add('deleted', q.FieldByName('deleted').AsInteger = 1);
          lArrayMsg.Add( lMsg );

          q.Next;
        end;

        lJSON.Add('messages', lArrayMsg);

        Result := lJSON.AsJSON;
      end; // if

      q.Close;
      q.Free;
    except
      on E: Exception do begin
        Log('TServiceMensagem.ListaMensagens' + sLineBreak + E.Message);
        q.Free;
      end;
    end; // try
  finally
    lJSON.Free; // Isso libera o lArrayTo também
    // AJson.Free;
  end;
end;

function TServiceMensagem.SalasComMensagensNaoLidas(AStrJson: string): string;
// lista de salas em que há mensagens não lidas pelo destinatário
// Request: {"event":"messages_unread","to_id":100}
var
  q: TZQuery;
  AJson, lJSON, lMsg: TJSONObject;
  lArrayMsg: TJSONArray;
  lTo_Id: Integer;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  lTo_Id := AJson.Get('to_id', 0);
  Result := Format('{"event":"messages_unread","to_id":%d,"messages":[]}', [lTo_Id]);
  if not FIsConectado or (lTo_Id < 1) then Exit;

  lJSON := TJSONObject.Create;
  lArrayMsg := TJSONArray.Create;

  try
    try
      q := DMServer.NewQuery();

      q.SQL.Add('SELECT ');
      q.SQL.Add('  DISTINCT room_name, from_id, from_name, msg_date, total_unread ');
      q.SQL.Add('FROM ( ');
      q.SQL.Add('  SELECT '); // dono da sala
      q.SQL.Add('    t.room_name, t.to_id as from_id, t.to_name as from_name, d.total_unread, dt.msg_date ');
      q.SQL.Add('  FROM chat_targets t, ');
      q.SQL.Add('  LATERAL ( '); // total de mensagens não lidas do destinatário na sala
      q.SQL.Add('    SELECT COALESCE(COUNT(ct.msg_read), 0) AS total_unread ');
      q.SQL.Add('    FROM chat_targets ct ');
      q.SQL.Add('    INNER JOIN chat_messages g ON g.idchat = ct.idchat AND g.deleted = 0 ');
      q.SQL.Add('    WHERE ct.room_name = t.room_name AND ct.msg_read = 0 ');
      q.SQL.Add('      AND ct.to_id <> t.to_id AND ct.to_id = :to_id ');
      q.SQL.Add('  ) d, ');
      q.SQL.Add('  LATERAL ( '); // data da última mensagem da sala
      q.SQL.Add('    SELECT cm.msg_date ');
      q.SQL.Add('    FROM chat_messages cm ');
      q.SQL.Add('    WHERE cm.room_name = t.room_name ');
      q.SQL.Add('    ORDER BY cm.msg_date DESC ');
      q.SQL.Add('    LIMIT 1 ');
      q.SQL.Add('  ) dt ');
      q.SQL.Add('  WHERE t.guest = 0 ');
      q.SQL.Add(') ');
      q.SQL.Add('WHERE total_unread > 0 ');
      q.SQL.Add('ORDER BY msg_date ASC; ');

      q.ParamByName('to_id').AsInteger := lTo_Id;

      q.Open;

      if (q.RecordCount > 0) then begin
        lJSON.Add('event', 'messages_unread');
        lJSON.Add('to_id', lTo_Id);

        while not q.EOF do begin
          lMsg := TJSONObject.Create;

          lMsg.Add('room_name', q.FieldByName('room_name').AsString);
          lMsg.Add('from_id', q.FieldByName('from_id').AsInteger);
          lMsg.Add('from_name', q.FieldByName('from_name').AsString);
          lMsg.Add('last_message_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', q.FieldByName('msg_date').AsDateTime));
          lMsg.Add('total_unread', q.FieldByName('total_unread').AsInteger);

          lArrayMsg.Add( lMsg );

          q.Next;
        end;

        lJSON.Add('messages', lArrayMsg);

        Result := lJSON.AsJSON;
      end;

      q.Close;
      q.Free;
    except
      on E: Exception do begin
        Log('TServiceMensagem.SalasComMensagensNaoLidas' + sLineBreak + E.Message);
        q.Free;
      end;
    end;
  finally
    lJSON.Free;
    // AJson.Free;
  end;
end;

function TServiceMensagem.ListaMessagensDestinatarios(ARoomName: string; AToID: integer): TJSONArray;
// lista de mensagens do remetente e sala
var
  q: TZQuery;
  lObj: TJSONObject;
begin
  Result := TJSONArray.Create;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('SELECT ');
    q.SQL.Add('  t.idtarget, t.idchat, t.guest, t.to_id, t.to_name, t.msg_read, t.read_date ');
    q.SQL.Add('FROM ');
    q.SQL.Add('  chat_targets t ');
    q.SQL.Add('WHERE ');
    q.SQL.Add('  t.room_name = :room_name ');

    if (AToID > 0) then
      q.SQL.Add('AND t.to_id = ' + IntToStr(AToID) + ' ');

    q.SQL.Add('ORDER BY ');
    q.SQL.Add('  t.idtarget ASC; ');

    q.ParamByName('room_name').AsString := ARoomName;

    q.Open;

    while not q.EOF do begin
      lObj := TJSONObject.Create;

      lObj.Add('guest', q.FieldByName('guest').AsInteger);
      lObj.Add('to_id', q.FieldByName('to_id').AsInteger);
      lObj.Add('to_name', q.FieldByName('to_name').AsString);
      lObj.Add('idchat', q.FieldByName('idchat').AsInteger);
      lObj.Add('msg_read', (q.FieldByName('msg_read').AsInteger = 1));
      lObj.Add('read_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', q.FieldByName('read_date').AsDateTime));

      Result.Add( lObj );

      q.Next;
    end;

    q.Close;
    q.Free;
  except
    on E: Exception do begin
      Log('TServiceMensagem.ListaMessagensDestinatarios' + sLineBreak + E.Message);
      q.Free;
    end;
  end; // try
end;

function TServiceMensagem.ListaMessagensNaoLidas(ARoomName, AOnLine: string; AToID: integer): TJSONArray;
// lista de mensagens do remetente e sala
var
  q: TZQuery;
  lObj: TJSONObject;
begin
  Result := TJSONArray.Create;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('SELECT ');
    q.SQL.Add('  t.idtarget, t.idchat, t.guest, t.to_id, t.to_name, t.msg_read, t.read_date ');
    q.SQL.Add('FROM ');
    q.SQL.Add('  chat_targets t ');
    q.SQL.Add('WHERE ');
    q.SQL.Add('  t.room_name = :room_name AND t.msg_read = 0 ');

    if (AToID > 0) then
      q.SQL.Add('AND t.to_id = ' + IntToStr(AToID) + ' ');

    q.SQL.Add('ORDER BY ');
    q.SQL.Add('  t.idtarget ASC; ');

    q.ParamByName('room_name').AsString := ARoomName;

    q.Open;

    while not q.EOF do begin
      lObj := TJSONObject.Create;

      lObj.Add('guest', q.FieldByName('guest').AsInteger);
      lObj.Add('to_id', q.FieldByName('to_id').AsInteger);
      lObj.Add('to_name', q.FieldByName('to_name').AsString);
      lObj.Add('idchat', q.FieldByName('idchat').AsInteger);
      lObj.Add('msg_read', (q.FieldByName('msg_read').AsInteger = 1));
      lObj.Add('read_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', q.FieldByName('read_date').AsDateTime));
      lObj.Add('online', (Pos(Format('[%d],',[q.FieldByName('to_id').AsInteger]), AOnLine) > 0));

      Result.Add( lObj );

      q.Next;
    end;

    q.Close;
    q.Free;
  except
    on E: Exception do begin
      Log('TServiceMensagem.ListaMessagensNaoLidas' + sLineBreak + E.Message);
      q.Free;
    end;
  end; // try
end;

function TServiceMensagem.HistoryRooms(AStrJson: string): string;
// lista de salas em que há mensagens do/para o destinatário
// Request: {"event":"history","to_id":100,"has_files":true,"search":"maria"}
var
  q: TZQuery;
  AJson, lJSON, lMsg: TJSONObject;
  lArrayMsg: TJSONArray;
  lTo_Id: Integer;
  lHas_files: Boolean;
  lSearch: string;
  lDataInicial: TDateTime;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  lTo_Id := AJson.Get('to_id', 0); // ID do participante do chat
  lHas_files := AJson.Get('has_files', False); // True: contém arquivos
  lSearch := Trim(AJson.Get('search', '')); // pesquisa nome de convidado
  Result := Format('{"event":"history_rooms","to_id":%d,"messages":[]}', [lTo_Id]);
  if not FIsConectado or (lTo_Id < 1) then Exit;

  lJSON := TJSONObject.Create;
  lArrayMsg := TJSONArray.Create;

  lDataInicial := IncDay(Now, -7); // Now - 7;

  try
    try
      q := DMServer.NewQuery();

      q.SQL.Add('SELECT ');
      q.SQL.Add('  DISTINCT c.room_name, dt.from_id, dt.from_name, dt.msg_date AS data, ct.total_msg ');
      q.SQL.Add('FROM chat_messages c, ');
      q.SQL.Add('LATERAL ( ');
      q.SQL.Add('    SELECT cm.msg_date, t.to_id AS from_id, t.to_name AS from_name ');
      q.SQL.Add('    FROM chat_messages cm  ');
      q.SQL.Add('    INNER join chat_targets t ON t.room_name = cm.room_name AND t.guest = 0 ');
      q.SQL.Add('    WHERE cm.room_name = c.room_name ');
      q.SQL.Add('    ORDER BY cm.msg_date DESC LIMIT 1  ');
      q.SQL.Add(') dt, ');
      q.SQL.Add('LATERAL ( ');
      q.SQL.Add('    SELECT COALESCE(COUNT(t.to_id), 0) AS total_msg ');
      q.SQL.Add('    FROM chat_targets t  ');
      q.SQL.Add('    WHERE t.room_name = c.room_name AND t.to_id = :to_id ');
      q.SQL.Add(') ct ');
      q.SQL.Add('WHERE c.msg_date >= Date(:data_inicial) and ct.total_msg > 0 '); // c.msg_date >= (CURRENT_DATE - 7)

      if lSearch <> '' then begin
        // busca por nome de participante
        q.SQL.Add('AND EXISTS(SELECT 1 FROM chat_targets r ');
        q.SQL.Add('WHERE UNACCENT(r.to_name) ILIKE UNACCENT(:search) AND r.room_name = c.room_name) ');
        q.ParamByName('search').AsString := '%' + lSearch + '%';
      end;

      if lHas_files then
        q.SQL.Add('AND c.file_name <> '''' ');

      q.SQL.Add('ORDER BY data ASC; ');

      q.ParamByName('to_id').AsInteger := lTo_Id;
      q.ParamByName('data_inicial').AsString := FormatDateTime('yyyy-mm-dd', lDataInicial);

      q.Open;

      if (q.RecordCount > 0) then begin
        lJSON.Add('event', 'history_rooms');
        lJSON.Add('to_id', lTo_Id);

        while not q.EOF do begin
          lMsg := TJSONObject.Create;

          lMsg.Add('room_name', q.FieldByName('room_name').AsString);
          lMsg.Add('from_id', q.FieldByName('from_id').AsInteger);
          lMsg.Add('from_name', q.FieldByName('from_name').AsString);
          lMsg.Add('date', FormatDateTime('yyyy-mm-dd hh:nn:ss', q.FieldByName('data').AsDateTime));
          lMsg.Add('total_msg', q.FieldByName('total_msg').AsInteger);

          lArrayMsg.Add( lMsg );

          q.Next;
        end;

        lJSON.Add('messages', lArrayMsg);

        Result := lJSON.AsJSON;
      end;

      q.Close;
      q.Free;
    except
      on E: Exception do begin
        Log('TServiceMensagem.ChatHistory' + sLineBreak + E.Message);
        q.Free;
      end;
    end;
  finally
    lJSON.Free;
    // AJson.Free;
  end;
end;

procedure TServiceMensagem.SalvarDestinatario(AIdChat: Integer; ARoomName: string; AGuest, AToId: Integer; AToName: string);
// salva o destinatário da mensagem
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('INSERT INTO chat_targets (idchat, room_name, guest, to_id, to_name) ');
    q.SQL.Add('VALUES(:idchat, :room_name, :guest, :to_id, :to_name) ');

    q.ParamByName('idchat').AsInteger := AIdChat;
    q.ParamByName('room_name').AsString := ARoomName;
    q.ParamByName('guest').AsInteger := AGuest; // guest: 0 = dono da sala, 1 = convidado
    q.ParamByName('to_id').AsInteger := AToId;
    q.ParamByName('to_name').AsString := AToName;

    DMServer.TransactionPrepare;

    q.ExecSQL;

    DMServer.TransactionCommit;

    q.Free;

    // cria a sala com os convidados
    SalvarRoomGuests(ARoomName, AGuest,AToId, AToName);
  except
    on E: Exception do begin
      DMServer.TransactionRollback;
      Log('TServiceMensagem.SalvarDestinatario' + sLineBreak + E.Message);
      q.Free;
    end;
  end;
end;

procedure TServiceMensagem.SalvarRoomGuests(ARoomName: string; AGuest, AToId: Integer; AToName: string);
// salva o destinatário da sala
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('INSERT INTO ');
    q.SQL.Add('chat_room_guests (room_name, guest, to_id, to_name) ');
    q.SQL.Add('VALUES(:room_name, :guest, :to_id, :to_name) ');
    q.SQL.Add('ON CONFLICT (room_name, to_id) DO NOTHING; ');

    q.ParamByName('room_name').AsString := ARoomName;
    q.ParamByName('guest').AsInteger := AGuest; // guest: 0 = dono da sala, 1 = convidado
    q.ParamByName('to_id').AsInteger := AToId;
    q.ParamByName('to_name').AsString := AToName;

    DMServer.TransactionPrepare;

    q.ExecSQL;

    DMServer.TransactionCommit;

    q.Free;
  except
    on E: Exception do begin
      DMServer.TransactionRollback;
      Log('TServiceMensagem.SalvarRoomGuests' + sLineBreak + E.Message);
      q.Free;
    end;
  end;
end;

function TServiceMensagem.ListaRoomConvidados(AStrJson, AOnLine: string): string;
// lista de convidados da sala
var
  q: TZQuery;
  AJson, lJSON, lJsonTemp, lMsg: TJSONObject;
  lArray, lArrayTo: TJSONArray;
  i: Integer;
  lRoomName: string;
begin
  AJson := TJSONObject( GetJSON(AStrJson) );
  lRoomName := AJson.Get('room_name', '');
  Result := Format('{"event":"room_guests","room_name":"%s", "to":[]}', [lRoomName]);
  if not FIsConectado then Exit;

  lJSON := TJSONObject.Create;
  lArray := TJSONArray.Create;
  lArrayTo := TJSONArray( AJson.Arrays['to'] );

  try
    try
      q := DMServer.NewQuery();

      q.SQL.Add('SELECT ');
      q.SQL.Add('  g.guest, g.to_id, g.to_name, ');
      q.SQL.Add('  COUNT(t.idchat) AS total_unread ');
      q.SQL.Add('FROM ');
      q.SQL.Add('  chat_room_guests g ');
      q.SQL.Add('LEFT JOIN chat_targets t ON t.to_id = g.to_id AND t.msg_read = 0 AND t.room_name = g.room_name ');
      q.SQL.Add('WHERE ');
      q.SQL.Add('  g.room_name = :room_name ');
      q.SQL.Add('GROUP BY ');
      q.SQL.Add('  g.guest, g.to_id, g.to_name ');
      q.SQL.Add('ORDER BY ');
      q.SQL.Add('  g.guest ASC, g.to_name ASC; '); //guest = 0 (dono da sala, convidado = 1)

      q.ParamByName('room_name').AsString := lRoomName;

      q.Open;

      // prepara o retorno
      lJSON.Add('event', 'room_guests');
      lJSON.Add('room_name', lRoomName);

      if (q.RecordCount > 0) then begin
        while not q.EOF do begin
          lMsg := TJSONObject.Create;

          lMsg.Add('guest', q.FieldByName('guest').AsInteger);
          lMsg.Add('to_id', q.FieldByName('to_id').AsInteger);
          lMsg.Add('to_name', q.FieldByName('to_name').AsString);
          lMsg.Add('total_unread', q.FieldByName('total_unread').AsInteger);
          lMsg.Add('online', (Pos(Format('[%d],',[q.FieldByName('to_id').AsInteger]), AOnLine) > 0));

          lArray.Add( lMsg );

          q.Next;
        end;
      end else begin
        for i := 0 to lArrayTo.Count - 1  do begin
          lJsonTemp := TJSONObject( lArrayTo.Items[i] );
          lMsg := TJSONObject.Create;

          lMsg.Add('guest', lJsonTemp.Get('guest', 0));
          lMsg.Add('to_id', lJsonTemp.Get('to_id', 0));
          lMsg.Add('to_name', UTF8Encode(lJsonTemp.Get('to_name', '')) );
          lMsg.Add('total_unread', 0);
          lMsg.Add('online', (Pos(Format('[%d],',[lJsonTemp.Get('to_id', 0)]), AOnLine) > 0));

          lArray.Add( lMsg );
        end;
      end;

      lJSON.Add('to', lArray);

      Result := lJSON.AsJSON;

      q.Close;
      q.Free;
    except
      on E: Exception do begin
        Log('TServiceMensagem.ListaRoomConvidados' + sLineBreak + E.Message);
        q.Free;
      end;
    end; // try
  finally
    lJSON.Free; // Isso libera também o lArray
    // AJson.Free; // libera também o lArrayTo
  end;
end;

function TServiceMensagem.GetRoomConvidados(ARoomName, AOnLine: string): string;
// convidados da sala
var
  q: TZQuery;
  lObj: TJSONObject;
  lArrayTo: TJSONArray;
begin
  Result := '[]';
  if not FIsConectado or (ARoomName = '') then Exit;

  q := DMServer.NewQuery();
  lArrayTo := TJSONArray.Create;

  try
    try
      q.SQL.Add('SELECT ');
      q.SQL.Add('  g.guest, g.to_id, g.to_name, ');
      q.SQL.Add('  COUNT(t.idchat) AS total_unread ');
      q.SQL.Add('FROM ');
      q.SQL.Add('  chat_room_guests g ');
      q.SQL.Add('LEFT JOIN chat_targets t ON t.to_id = g.to_id AND t.msg_read = 0 AND t.room_name = g.room_name ');
      q.SQL.Add('WHERE ');
      q.SQL.Add('  g.room_name = :room_name ');
      q.SQL.Add('GROUP BY ');
      q.SQL.Add('  g.guest, g.to_id, g.to_name ');
      q.SQL.Add('ORDER BY ');
      q.SQL.Add('  g.guest ASC, g.to_name ASC; '); // guest = 0 (dono da sala, convidado = 1)

      q.ParamByName('room_name').AsString := ARoomName;

      q.Open;

      if (q.RecordCount > 0) then begin

        while not q.EOF do begin
          lObj := TJSONObject.Create;

          lObj.Add('guest', q.FieldByName('guest').AsInteger);
          lObj.Add('to_id', q.FieldByName('to_id').AsInteger);
          lObj.Add('to_name', q.FieldByName('to_name').AsString);
          lObj.Add('total_unread', q.FieldByName('total_unread').AsInteger);
          lObj.Add('online', (Pos(Format('[%d],',[q.FieldByName('to_id').AsInteger]), AOnLine) > 0));

          lArrayTo.Add( lObj );

          q.Next;
        end;

        Result := lArrayTo.AsJSON;
      end; // if

      q.Close;
      q.Free;
    except
      on E: Exception do begin
        Log('TServiceMensagem.GetRoomConvidados' + sLineBreak + E.Message);
        q.Free;
      end;
    end;

  finally
    lArrayTo.Free;
  end;
end;

function TServiceMensagem.MarcarComoLida(ARoomName: string; AToId: Integer; AListIdChat: string): string;
// marca a mensagem do destinatário como lida ou vista
// AListIdChat = 1,2,3,..,n
var
  q: TZQuery;
begin
  Result := Format('{"event":"mark_read","success":false,"room_name":"%s"}', [ARoomName]);
  if not FIsConectado then Exit;
  if (AToId = 0) or (ARoomName = '') then Exit;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('UPDATE chat_targets SET ');
    q.SQL.Add('read_date = :read_date, msg_read = 1 ');
    q.SQL.Add('WHERE room_name = :room_name AND msg_read = 0 AND to_id = :to_id ');

    if (AListIdChat <> '') then
      q.SQL.Add('AND idchat IN(' + Alistidchat + ') ');

    q.ParamByName('room_name').AsString := ARoomName;
    q.ParamByName('read_date').AsDateTime := Now;
    q.ParamByName('to_id').AsInteger := AToId;

    DMServer.TransactionPrepare;

    q.ExecSQL;

    DMServer.TransactionCommit;

    q.Free;

    FSucesso := True;
    Result := Format('{"event":"mark_read","success":true,"room_name":"%s"}', [ARoomName]);
  except
    on E: Exception do begin
      Log('TServiceMensagem.MarcarComoLida' + sLineBreak + E.Message);
      q.Free;
    end;
  end;
end;

procedure TServiceMensagem.Log(const Msg: string);
// exibe Log para debug
begin
  if not FLogAtivado then Exit;
  if Trim(Msg) <> '' then
    WriteLn(FormatDateTime('yyyy-mm-dd hh:nn:ss', Now) + ' [LOG] ' + Msg)
  else
    WriteLn(' ');
end;

end.


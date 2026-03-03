unit Services.MensagemTargets;

// Controle de destinatários das mensagens do chat

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, DB, ZDataset, fpjson;

type

  { TServiceMensagemTarget }

  TServiceMensagemTarget = class
    private
      FIsConectado: Boolean;
      FSucesso: Boolean;
      FMensagem: string;

      FIdChat: Integer;
      FToId: Integer;
      FToName: string;
      FMsgRead: Boolean;
      FReadDate: TDateTime;
    public
      constructor Create;
      destructor Destroy; override;
      property GetMensagem: string read FMensagem;
      property Sucesso: Boolean read FSucesso;

      // campos da tabela
      property IdChat: Integer read FIdChat;
      property ToId: Integer read FToId write FToId;
      property ToName: string read FToName write FToName; //50
      property MsgRead: Boolean read FMsgRead; //só leitura (integer no DB)
      property ReadDate: TDateTime read FReadDate; //só leitura

      //operações
      procedure Salvar(AId: integer);
      procedure Excluir(AId: integer);
      procedure Ler(AId: Integer; AIdTo: Integer);
      procedure MarcarComoLida(AIdChat: Integer; AIdTo: Integer);
  end;

implementation

uses
  DM.SQLServer;

{ TServiceMensagemTarget }

constructor TServiceMensagemTarget.Create;
begin
  FMensagem := '';
  FSucesso  := True;
  FIsConectado := True;

  if not DMServer.IsConnected then
  begin
    FMensagem := 'Não está conectado ao servidor!';
    FSucesso  := False;
    FIsConectado := False;
  end;
end;

destructor TServiceMensagemTarget.Destroy;
begin
  inherited Destroy;
end;

procedure TServiceMensagemTarget.Salvar(AId: integer);
//salva o destinatário da mensagem
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;
  FMensagem := '';
  FSucesso  := False;

  try
    q := DMServer.NewQuery();

    if AId < 1 then
    begin
      q.SQL.Add('INSERT INTO chat_targets (idchat, to_id, to_name) ');
      q.SQL.Add('VALUES(:idchat, :to_id, :to_name) ');
    end
    else
    begin
      q.SQL.Add('UPDATE chat_targets SET ');
      q.SQL.Add('from_id = :from_id, from_name = :from_name, ');
      q.SQL.Add('to_id = :to_id, to_name = :to_name, ');
      q.SQL.Add('room_name = :room_name, msg = :msg ');
      q.SQL.Add('WHERE idchat = ' + IntToStr(AId));
    end;

    q.ParamByName('from_id').AsInteger := FromId;
    q.ParamByName('from_name').AsString := FromName;
    q.ParamByName('to_id').AsInteger := ToId;
    q.ParamByName('to_name').AsString := ToName;
    q.ParamByName('room_name').AsString := RoomName;
    q.ParamByName('msg').AsString := Msg;

    DMServer.TransactionPrepare;

    if AId < 1 then
    begin
      q.Open;
      FIdChat := q.FieldByName('id').AsInteger;
      FMensagem := 'Nova mensagem cadastrada do sucesso';
    end
    else
    begin
      q.ExecSQL;
      FIdChat := AId;
      FMensagem := 'Mensagem atualizada com sucesso';
    end;

    DMServer.TransactionCommit;

    FSucesso := True;
    if AId < 1 then q.Close; //por causa do Returning idchat
    q.Free;
  except
    on E: Exception do
    begin
      FIdChat := 0;
      FSucesso  := False;
      FMensagem := E.Message;
      DMServer.TransactionRollback;
      q.Free;
    end;
  end;
end;

procedure TServiceMensagemTarget.Excluir(AId: integer);
//deleta a mensagem
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;
  FMensagem := '';
  FSucesso  := False;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('DELETE FROM chat_targets ');
    q.SQL.Add('WHERE idchat = ' + IntToStr(AId));

    DMServer.TransactionPrepare;

    q.ExecSQL;

    DMServer.TransactionCommit;

    FSucesso  := True;
    FMensagem := 'Mensagem excluída com sucesso';
    q.Free;
  except
    on E: Exception do
    begin
      FSucesso  := False;
      FMensagem := E.Message;
      DMServer.TransactionRollback;
      q.Free;
    end;
  end;
end;

procedure TServiceMensagemTarget.Ler(AId: Integer; AIdTo: Integer);
//ler dados do registro conforme id
var
  q: TZQuery;
begin
  if not FIsConectado then Exit;
  FMensagem := '';
  FSucesso  := False;

  try
    q := DMServer.NewQuery();

    q.SQL.Add('SELECT ');
    q.SQL.Add('m.idchat, m.from_id, m.from_name, m.to_id, ');
    q.SQL.Add('m.to_name, m.room_name, m.msg, m.msg_read, m.msg_date ');
    q.SQL.Add('FROM chat_targets m ');
    q.SQL.Add('WHERE m.idchat = ' + IntToStr(AId));

    q.Open;

    if not q.EOF then
    begin
      FIdChat   := AId;
      FFromId   := q.FieldByName('from_id').AsInteger;
      FFromName := q.FieldByName('from_name').AsString;
      FToId     := q.FieldByName('to_id').AsInteger;
      FToName   := q.FieldByName('to_name').AsString;
      FRoomName := q.FieldByName('room_name').AsString;
      FMsg      := q.FieldByName('msg').AsString;
      FMsgRead  := q.FieldByName('msg_read').AsInteger = 1;
      FMsgDate  := q.FieldByName('msg_date').AsDateTime;

      FSucesso  := True;
      FMensagem := 'Mensagem carregada com sucesso';
    end
    else
    begin
      FMensagem := 'Mensagem não encontrada!';
      FSucesso  := False;
    end;

    q.Close;
    q.Free;
  except
    on E: Exception do
    begin
      FSucesso  := False;
      FMensagem := E.Message;
      q.Free;
    end;
  end;
end;

procedure TServiceMensagemTarget.MarcarComoLida(AIdChat: Integer; AIdTo: Integer);
//marca a mensagem do remetente como lida
var
  q: TZQuery;
begin
  try
    q := DMServer.NewQuery();

    q.SQL.Add('UPDATE chat_targets SET ');
    q.SQL.Add('read_date = :read_date, msg_read = :msg_read ');
    q.SQL.Add('WHERE idchat = :idchat AND to_id = :to_id AND msg_read = 0 ');

    q.ParamByName('idchat').AsInteger := AIdChat;
    q.ParamByName('to_id').AsInteger := AIdTo;
    q.ParamByName('read_date').AsDateTime := Now;
    q.ParamByName('msg_read').AsInteger := 1; //usuário viu as mensagem

    DMServer.TransactionPrepare;

    if AId < 1 then
    begin
      q.Open;
      FIdChat := q.FieldByName('id').AsInteger;
      FMensagem := 'Nova mensagem cadastrada do sucesso';
    end
    else
    begin
      q.ExecSQL;
      FIdChat := AId;
      FMensagem := 'Mensagem atualizada com sucesso';
    end;

    DMServer.TransactionCommit;

    FSucesso := True;
    if AId < 1 then q.Close; //por causa do Returning idchat
    q.Free;
  finally
    Result := lJSON.AsJSON;
    lJSON.Free; // Isso libera o lArray também
  end; //try
end;

end.



unit DM.Server;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, ZConnection, ZDataset, DB, SQLDB, ZDatasetUtils, IniFiles;

type

  { TDMServer }

  TDMServer = class(TDataModule)
    Connection: TZConnection;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FMsgErro, FVersao: string;
    FPathDLL, FPathBanco, FHost: String;
    FProtocolo, FBanco, FUsername, FSenha, FOdbc: String;
    FPorta: Integer;
    FCriarTabelas: Boolean;
    procedure LerConfig;
    procedure GetVersao;
    procedure createTables;
  public
    property GetMsgErro: string read FMsgErro;
    property GetVersaoServidor: string read FVersao;
    procedure Conectar;
    procedure Desconectar;
    procedure Reconectar;
    procedure ChecaConexao;
    procedure TransactionPrepare;
    procedure TransactionCommit;
    procedure TransactionRollback;
    function IsConnected: Boolean;
    function LastInsertedID(APrimaryKey, ATable: string): Integer;
    function NewQuery(): TZQuery;
  end;

var
  DMServer: TDMServer;

implementation

{$R *.lfm}

{ TDMServer }

procedure TDMServer.DataModuleCreate(Sender: TObject);
begin
  Conectar;
end;

procedure TDMServer.DataModuleDestroy(Sender: TObject);
begin
  Desconectar;
end;

procedure TDMServer.Conectar;
//estabelece a conexão
begin
  FMsgErro      := '';
  FVersao       := '';
  LerConfig;
  FPathBanco    := ExtractFileDir( ParamStr(0) ) + PathDelim;
  FPathDLL      := FPathBanco; //windows
  FCriarTabelas := not FileExists( FPathBanco );

  if (FProtocolo.Contains('sqlite')) and not (FBanco.Contains(PathDelim)) then
    FBanco := FPathBanco + FBanco;

  try
    with Connection do begin
     HostName   := FHost;
     Protocol   := FProtocolo;
     Database   := FBanco;
     User       := FUsername;
     Password   := FSenha;
     Port       := FPorta;
     AutoCommit := True;

     {$IFDEF WINDOWS}
        if Protocol.Contains('sqlite') then
          LibraryLocation := FPathDLL + 'sqlite3.dll';
        if Protocol.Contains('firebird') then
          LibraryLocation := FPathDLL + 'fbclient.dll';
        if Protocol.Contains('mariadb') then
          LibraryLocation := FPathDLL + 'libmariadb.dll'; // 32 bits
        if Protocol.Contains('mysql') then
          LibraryLocation := FPathDLL + 'libmysql.dll';  // 32 bits
        if Protocol.Contains('postgresql') then
          LibraryLocation := FPathDLL + 'libpq-15.dll'; //ou libpq.dll
        if Protocol.Contains('oracle') then
          LibraryLocation := FPathDLL + 'oci.dll';
        if Protocol.Contains('mssql') then
          //driver: libsybdb-5.dll ou ntwdblib.dll ou dblib.dll ou libsybdb.so (linux) ou libsybdb.dylib (macos)
          //Database := 'Provider=SQLOLEDB.1;Persist Security Info=True;Data Source=' + p.HostServidor +','+ p.Porta + '; Initial Catalog=' + p.BancoDados+ '; User ID=' +  p.Username + ';password=' + p.Senha;
          //Protocol := 'ado';
          LibraryLocation := FPathDLL + 'dblib.dll';
     {$ENDIF}

     Connect;
     GetVersao;
     createTables;
    end;

  except
    on E: Exception do
       FMsgErro := E.Message;
  end;
end;

procedure TDMServer.Desconectar;
// desconecta do banco de dados
begin
  try
    if Connection.Connected then
       Connection.Disconnect;
  except
    on e: Exception do
      FMsgErro := e.Message;
  end;
end;

procedure TDMServer.Reconectar;
//reconectar
begin
  try
    if Connection.Connected then Connection.Disconnect;
    Conectar;
  except
  end;
end;

procedure TDMServer.ChecaConexao;
// se a conexão não estiver aberta, então tenta conectar no servidor/banco
begin
   FMsgErro := '';

   try
     if not Connection.Connected then
       Reconectar;
   except
    on e: Exception do
      FMsgErro := e.Message;
   end;
end;

procedure TDMServer.TransactionPrepare;
//inicia o transatction
begin
  Connection.AutoCommit := False;
  if not Connection.InTransaction then
    Connection.StartTransaction;
end;

procedure TDMServer.TransactionCommit;
//comita o transaction
begin
  if Connection.InTransaction then
    Connection.Commit;
  Connection.AutoCommit := True;
end;

procedure TDMServer.TransactionRollback;
//rolback do transaction
begin
  if Connection.InTransaction then
    Connection.Rollback;
  Connection.AutoCommit := True;
end;

function TDMServer.IsConnected: Boolean;
//Está conectado
begin
  Result := Connection.Connected;
end;

function TDMServer.LastInsertedID(APrimaryKey, ATable: string): Integer;
// retorna o último ID inserido, independente da tabela
// sqlite: select last_insert_rowid() as id;
// mysql/mariadb: SELECT LAST_INSERT_ID() as id;
begin
  Result := 0;

  try
    with NewQuery() do begin
      SQL.Add(Format('select max(%s) as id from %s ', [APrimaryKey, ATable]));
      Open;

      if RecordCount > 0 then
         Result := FieldByName('id').AsInteger;

      Close;
    end;
  except
  end;
end;

function TDMServer.NewQuery(): TZQuery;
// retorna a instância de uma nova query
begin
  ChecaConexao;

  Result := TZQuery.Create(nil);

  if FMsgErro.IsEmpty then begin
    try
      Result.Connection := Connection;
      Result.Close;
      Result.SQL.Clear;
    except
      on e: Exception do
        FMsgErro := e.Message;
    end;
  end;
end;

procedure TDMServer.LerConfig;
//ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_db.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  FHost      := '';
  FPorta     := 0;
  FProtocolo := '';
  FBanco     := '';
  FUsername  := '';
  FSenha     := '';
  FOdbc      := '';

  try
    FHost      := ArqINI.ReadString('dbinfo','server', '');
    FPorta     := ArqINI.ReadInteger('dbinfo','port', 0);
    FProtocolo := ArqINI.ReadString('dbinfo','protocol', '');
    FBanco     := ArqINI.ReadString('dbinfo','db', '');
    FUsername  := ArqINI.ReadString('dbinfo','user', '');
    FSenha     := ArqINI.ReadString('dbinfo','password', '');
    FOdbc      := ArqINI.ReadString('dbinfo','odbc', '');
  finally
    ArqINI.Free;
  end;
end;

procedure TDMServer.GetVersao;
//obtém a versão do servidor sql
var
  lSql, lNome: string;
begin
  FVersao := '';
  lSql  := 'select version() as versao ';

  if lSql <> '' then begin
    try
      with NewQuery() do begin
        SQL.Add( lSql );
        Open;

        if RecordCount > 0 then
           FVersao := FieldByName('versao').AsString;

        Close;
      end;
    except
    end;
  end;
end;

procedure TDMServer.createTables;
//cria as tabelas e índices, se não existirem
begin
  Connection.ExecuteDirect('create table if not exists chat_messages ( ' +
    'idchat bigint generated always as identity primary key, ' +
    'from_id integer not null, ' +
    'from_name varchar(50), ' +
    'room_name varchar(50) not null, ' +
    'msg text not null, ' +
    'msg_date timestamp without time zone default current_timestamp ' +
    '); '
  );

  Connection.ExecuteDirect('create table if not exists chat_targets ( ' +
    'idtarget bigint generated always as identity primary key, ' +
    'idchat INTEGER REFERENCES chat_messages (idchat) ON DELETE CASCADE NOT NULL, ' +
    'room_name varchar(50) not null, ' +
    'to_id integer not null, ' +
    'to_name varchar(50), ' +
    'read_date timestamp null, ' +
    'msg_read integer not null default (0), ' +
    'CONSTRAINT chat_targets_unicos UNIQUE (room_name, to_id) ' +
    '); '
  );

  //indices da tabela chat_messages
  Connection.ExecuteDirect('create index if not exists idx_chat_msg_data on chat_messages (idchat, msg_date desc); ');
  Connection.ExecuteDirect('create index if not exists idx_chat_msg_from on chat_messages (from_id, room_name); ');

  //indices da tabela chat_targets
  Connection.ExecuteDirect('create index if not exists idx_chat_targets_id on chat_targets (idtarget, idchat); ');
  Connection.ExecuteDirect('create index if not exists idx_chat_targets_to on chat_targets (idchat, to_id); ');
  Connection.ExecuteDirect('create index if not exists idx_chat_targets_room on chat_targets (room_name, to_id); ');
end;

end.


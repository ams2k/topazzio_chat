unit Usuario.Database; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

// Acesso ao banco de dados de usuários 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, FileUtil, DB, SQLDB, ZConnection, ZDataset, ZDatasetUtils; 
 
type 
 
  { TUsuarioDatabase } 
 
  TUsuarioDatabase = class(TDataModule) 
  private 
    Connection: TZConnection; 
    FMsgErro: string; 
    FPathDLL, FPathBanco, FBanco: String; 
    FCriarTabelas: Boolean; 
    procedure CriaTabelas; 
  public 
    constructor Create; 
    destructor Destroy; override; 
    property GetMsgErro: string read FMsgErro; 
    procedure Conectar; 
    procedure Desconectar; 
    procedure Reconectar; 
    procedure ChecaConexao; 
    procedure TransactionPrepare; 
    procedure TransactionCommit; 
    procedure TransactionRollback; 
    function IsConnected: Boolean; 
    function LastInsertedID: Integer; 
    function NewQuery(): TZQuery; 
  end; 
 
implementation 
 
{ TUsuarioDatabase } 
 
constructor TUsuarioDatabase.Create; 
begin 
  Connection := TZConnection.Create(nil); 
  Connection.ControlsCodePage := cCP_UTF8; 
  Connection.DisableSavepoints := False; 
  Conectar; 
end; 
 
destructor TUsuarioDatabase.Destroy; 
begin 
  Desconectar; 
  Connection.Free; 
  inherited Destroy; 
end; 
 
procedure TUsuarioDatabase.Conectar; 
//estabelece a conexão 
begin 
  FMsgErro      := ''; 
  FPathBanco    := ExtractFileDir( ParamStr(0) ) + PathDelim; 
  FPathDLL      := FPathBanco; //windows 
  FBanco        := FPathBanco + 'usuarios.db'; 
  FCriarTabelas := not FileExists( FBanco ); 
 
  try 
    with Connection do begin 
     HostName   := ''; 
     Protocol   := 'sqlite'; 
     Database   := FBanco; 
     User       := ''; 
     Password   := ''; 
     Port       := 0; 
     AutoCommit := True; 
 
     {$IFDEF WINDOWS} 
     LibraryLocation := FPathDLL + 'sqlite3.dll'; 
     {$ENDIF} 
 
     Connect; 
    end; 
 
    if FCriarTabelas then 
      CriaTabelas; 
 
  except 
    on E: Exception do 
      FMsgErro := E.Message; 
  end; 
end; 
 
procedure TUsuarioDatabase.Desconectar; 
// desconecta do banco de dados 
begin 
  try 
    if Connection.Connected then 
      Connection.Disconnect; 
  except 
  end; 
end; 
 
procedure TUsuarioDatabase.ChecaConexao; 
// se a conexão não estiver aberta 
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
 
procedure TUsuarioDatabase.Reconectar; 
//reconectar 
begin 
  try 
    if Connection.Connected then Connection.Disconnect; 
    Conectar; 
  except 
  end; 
end; 
 
procedure TUsuarioDatabase.TransactionPrepare; 
//inicia o transatction 
begin 
  Connection.AutoCommit := False; 
  if not Connection.InTransaction then 
    Connection.StartTransaction; 
end; 
 
procedure TUsuarioDatabase.TransactionCommit; 
//comita o transaction 
begin 
  if Connection.InTransaction then 
    Connection.Commit; 
  Connection.AutoCommit := True; 
end; 
 
procedure TUsuarioDatabase.TransactionRollback; 
//rolback do transaction 
begin 
  if Connection.InTransaction then 
    Connection.Rollback; 
  Connection.AutoCommit := True; 
end; 
 
function TUsuarioDatabase.IsConnected: Boolean; 
//retorna se está conectado no banco 
begin 
  Result := Connection.Connected; 
end; 
 
function TUsuarioDatabase.NewQuery(): TZQuery; 
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
 
function TUsuarioDatabase.LastInsertedID: Integer; 
// retorna o último ID inserido 
begin 
  Result := 0; 
 
  try 
    with NewQuery() do begin 
      SQL.Add('select last_insert_rowid() as id '); 
      Open; 
 
      if RecordCount > 0 then 
         Result := FieldByName('id').AsInteger; 
 
      Close; 
    end; 
  except 
  end; 
end; 
 
procedure TUsuarioDatabase.CriaTabelas; 
begin 
  if IsConnected and FCriarTabelas then begin 
    Connection.ExecuteDirect( 
      'CREATE TABLE IF NOT EXISTS usuario ('+ 
      'idusuario INTEGER PRIMARY KEY AUTOINCREMENT, '+ 
      'ativo INTEGER NOT NULL DEFAULT (1), '+ 
      'isadmin INTEGER NOT NULL DEFAULT (0), '+ 
      'nome VARCHAR(50) NOT NULL, '+ 
      'login VARCHAR(50) NOT NULL UNIQUE, '+ 
      'senha VARCHAR(50) NOT NULL, ' + 
      'email VARCHAR(100) NOT NULL, ' + 
      'data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' + 
      'ultimo_login TIMESTAMP, ' + 
      'foto blob '+ 
      '); ' 
    ); 
 
    Connection.ExecuteDirect('CREATE INDEX IF NOT EXISTS idx_usuario ON usuario (idusuario);'); 
 
    Connection.ExecuteDirect( 
    'insert into usuario (ativo,isadmin,nome,login,senha,email) ' + 
    'values(1, 1, ''Administrador'', ''admin'', ''admin'', ''admin@example.com''); ' 
    ); 
  end; 
end; 
 
end. 
 


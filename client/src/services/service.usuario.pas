unit Service.Usuario; 
 
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

// controle de usuários 
 
{$mode ObjFPC}{$H+} 
 
interface 
 
uses 
  Classes, SysUtils, Controls, StdCtrls, ExtCtrls, Graphics, ZDataset, DB, SQLDB, 
  Usuario.Database; 
 
type 
 
  { TServiceUsuario } 
 
  TServiceUsuario = class 
    private 
      Conn: TUsuarioDatabase; 
      FIsConectado: Boolean; 
      FMensagem: string; 
      FSucesso: Boolean; 
 
      FIdUsuario: Integer; 
      FIsAdmin: Boolean; 
      FIsAtivo: Boolean; 
      FLogin: string; 
      FNome: string; 
      FSenha: string; 
      FEmail: string; 
      FFoto: TImage; 
 
      FDataCriacao: TDateTime; 
      FDataUltimoLogin: TDateTime;
    public 
      constructor Create; 
      destructor Destroy; override; 
      property IdUsuario: Integer read FIdUsuario; 
      property IsAtivo: Boolean read FIsAtivo write FIsAtivo; 
      property IsAdmin: Boolean read FIsAdmin write FIsAdmin; 
      property Nome: string read FNome write FNome; 
      property Login: string read FLogin write FLogin; 
      property Senha: string read FSenha write FSenha; 
      property Email: string read FEmail write FEmail; 
      property Foto: TImage read FFoto write FFoto; 
      property DataCriacao: TDateTime read FDataCriacao; 
      property DataUltimoLogin: TDateTime read FDataUltimoLogin; 
      property GetMensagem: string read FMensagem; 
      property Sucesso: Boolean read FSucesso; 
      procedure Salvar(AId: integer); 
      procedure Excluir(AId: integer); 
      procedure Ler(AId: integer); 
      function DataSetGrid(APesquisa: String): TDataSource;
      function DataSetGridChatUsuarios(APesquisa: String; AExcludeListID: string): TDataSource;
      function TotalUsuarios: Integer; 
      procedure FazerLogin(ALogin, ASenha: string); 
      procedure RegistrarAcesso(AId: integer); 
      procedure AlterarSenha(AId: Integer; ANovaSenha: string); 
  end; 
 
implementation 
 
uses 
  Util.Imagem; 
 
{ TServiceUsuario } 
 
constructor TServiceUsuario.Create; 
begin 
  FMensagem := ''; 
  FSucesso  := True; 
  FIsConectado := True; 
  FFoto := TImage.Create(nil); 
  Conn := TUsuarioDatabase.Create; 
 
  if not Conn.IsConnected then 
  begin 
    FMensagem := 'Não está conectado no banco de dados!'; 
    FSucesso  := False; 
    FIsConectado := False; 
  end; 
end; 
 
destructor TServiceUsuario.Destroy; 
begin 
  Conn.Free; 
  if Assigned(FFoto) then 
    FFoto.Free; 
  inherited Destroy; 
end; 
 
procedure TServiceUsuario.Salvar(AId: integer); 
//salva o registro 
var 
  q: TZQuery; 
begin 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := False; 
 
  try 
    q := Conn.NewQuery(); 
 
    if AId < 1 then 
    begin 
      q.SQL.Add('INSERT INTO usuario '); 
      q.SQL.Add('( '); 
      q.SQL.Add('ativo, isadmin, nome, login, senha, email, foto '); 
      q.SQL.Add(') '); 
      q.SQL.Add('VALUES('); 
      q.SQL.Add(':ativo, :isadmin, :nome, :login, :senha, :email, :foto '); 
      q.SQL.Add(') '); 
    end 
    else 
    begin 
      q.SQL.Add('UPDATE usuario SET '); 
      q.SQL.Add('ativo = :ativo, isadmin = :isadmin, nome = :nome, login = :login, '); 
      q.SQL.Add('senha = :senha, email = :email, foto = :foto '); 
      q.SQL.Add('WHERE idusuario = ' + IntToStr(AId)); 
    end; 
 
    q.ParamByName('ativo').AsInteger   := Ord(IsAtivo); 
    q.ParamByName('isadmin').AsInteger := Ord(IsAdmin); 
    q.ParamByName('nome').AsString     := Nome; 
    q.ParamByName('login').AsString    := Login; 
    q.ParamByName('senha').AsString    := Senha; // criptografar... 
    q.ParamByName('email').AsString    := Email; 
 
    TUtilImagem.GetStream(FFoto, q, 'foto'); //carrega a imagem no zquery
 
    Conn.TransactionPrepare; 
 
    q.ExecSQL; 
 
    Conn.TransactionCommit; 
 
    if AId < 1 then 
    begin 
      FIdUsuario := Conn.LastInsertedID; 
      FMensagem := 'Novo usuário cadastrado do sucesso'; 
    end 
    else 
    begin 
      FIdUsuario := AId; 
      FMensagem := 'Registro do usuário atualizado com sucesso'; 
    end; 
 
    FSucesso := True; 
    q.Free; 
  except 
    on E: Exception do 
    begin 
      FSucesso  := False; 
      FMensagem := E.Message; 
      Conn.TransactionRollback; 
      q.Free; 
    end; 
  end; 
end; 
 
procedure TServiceUsuario.Excluir(AId: integer); 
//exclui o registro informado 
var 
  q: TZQuery; 
begin 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := False; 
 
  try 
    q := Conn.NewQuery(); 
 
    q.SQL.Add('DELETE FROM usuario '); 
    q.SQL.Add('WHERE idusuario = ' + IntToStr(AId)); 
 
    Conn.TransactionPrepare; 
 
    q.ExecSQL; 
 
    Conn.TransactionCommit; 
 
    FSucesso  := True; 
    FMensagem := 'Usuário excluído com sucesso'; 
    q.Free; 
  except 
    on E: Exception do 
    begin 
      FSucesso  := False; 
      FMensagem := E.Message; 
      Conn.TransactionRollback; 
      q.Free; 
    end; 
  end; 
end; 
 
procedure TServiceUsuario.Ler(AId: integer); 
//ler dados do registro conforme id 
var 
  q: TZQuery; 
begin 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := False; 
 
  try 
    q := Conn.NewQuery(); 
 
    q.SQL.Add('SELECT '); 
    q.SQL.Add('ativo, isadmin, nome, login, senha, email, foto, data_criacao, ultimo_login '); 
    q.SQL.Add('FROM usuario '); 
    q.SQL.Add('WHERE idusuario = ' + IntToStr(AId)); 
 
    q.Open; 
 
    if not q.EOF then 
    begin 
      FIdUsuario := AId; 
      IsAtivo    := q.FieldByName('ativo').AsInteger = 1; 
      IsAdmin    := q.FieldByName('isadmin').AsInteger = 1; 
      Nome       := q.FieldByName('nome').AsString; 
      Login      := q.FieldByName('login').AsString; 
      Senha      := q.FieldByName('senha').AsString; 
      Email      := q.FieldByName('email').AsString; 
      TUtilImagem.GetImage(FFoto, q, 'foto');
      FDataCriacao     := q.FieldByName('data_criacao').AsDateTime; 
      FDataUltimoLogin := q.FieldByName('ultimo_login').AsDateTime; 
 
      FSucesso  := True; 
      FMensagem := 'Usuário carregado com sucesso'; 
    end 
    else 
    begin 
      FMensagem := 'Usuário não encontrado!'; 
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
 
function TServiceUsuario.DataSetGrid(APesquisa: String): TDataSource; 
//dataset de tabelas para dbgrid 
var 
  q: TZQuery; 
begin 
  Result    := TDataSource.Create(nil); 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := True; 
 
  try 
    q := Conn.NewQuery(); 
 
    q.SQL.Add('SELECT '); 
    q.SQL.Add('idusuario, nome, login, email, '); 
    q.SQL.Add('(case ativo when 1 then ''S'' else ''N'' end) as ativo, '); 
    q.SQL.Add('(case isadmin when 1 then ''S'' else ''N'' end) as admin '); 
    q.SQL.Add('FROM usuario '); 
 
    if APesquisa.Trim <> '' then 
    begin 
      q.SQL.Add('WHERE nome+login LIKE :pesquisa '); 
      q.ParamByName('pesquisa').AsString := '%' + APesquisa.Trim + '%'; 
    end; 
 
    q.SQL.Add('ORDER BY nome ASC '); 
 
    q.Open; 
    Result.DataSet := q; 
    // fechar lá no destino/cliente 
  except 
    on E: Exception do 
    begin 
      FMensagem := E.Message; 
      FSucesso  := False; 
      q.Free; 
    end; 
  end; 
end;

function TServiceUsuario.DataSetGridChatUsuarios(APesquisa: String; AExcludeListID: string): TDataSource;
//dataset de tabelas para dbgrid para selecionar convidados do chat
var
  q: TZQuery;
begin
  Result    := TDataSource.Create(nil);
  if not FIsConectado then Exit;
  FMensagem := '';
  FSucesso  := True;

  try
    q := Conn.NewQuery();

    q.SQL.Add('SELECT ');
    q.SQL.Add('idusuario, nome, login, email, ');
    q.SQL.Add('(case isadmin when 1 then ''S'' else ''N'' end) as admin ');
    q.SQL.Add('FROM usuario ');
    q.SQL.Add('WHERE ativo = 1 ');

    if APesquisa.Trim <> '' then
    begin
      q.SQL.Add('AND nome+login LIKE :pesquisa ');
      q.ParamByName('pesquisa').AsString := '%' + APesquisa.Trim + '%';
    end;

    if AExcludeListID.Trim <> '' then
      q.SQL.Add('AND NOT idusuario IN(' + AExcludeListID + ') ');

    q.SQL.Add('ORDER BY nome ASC ');

    q.Open;
    Result.DataSet := q;
    // fechar lá no destino/cliente
  except
    on E: Exception do
    begin
      FMensagem := E.Message;
      FSucesso  := False;
      q.Free;
    end;
  end;
end;
 
function TServiceUsuario.TotalUsuarios: Integer; 
//quantidade de usuarios 
begin 
  Result := 0; 
  if not FIsConectado then Exit; 
 
  try 
    with Conn.NewQuery() do begin 
      SQL.Add('SELECT count(*) as qde, login, senha FROM usuario '); 
      Open; 
 
      if not EOF then 
      begin 
        Result := FieldByName('qde').AsInteger; 
        Login := FieldByName('login').AsString; 
        Senha := FieldByName('senha').AsString; 
      end; 
 
      Close; 
      Free; 
    end; 
  except 
  end; 
end; 
 
procedure TServiceUsuario.FazerLogin(ALogin, ASenha: string); 
//usuário fazendo login... 
var 
  q: TZQuery; 
begin 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := False; 
 
  try 
    q := Conn.NewQuery(); 
 
    q.SQL.Add('SELECT '); 
    q.SQL.Add('idusuario, ativo, isadmin, nome, login, senha, email, '); 
    q.SQL.Add('foto, data_criacao, ultimo_login '); 
    q.SQL.Add('FROM usuario '); 
    q.SQL.Add('WHERE login = :login AND senha = :senha '); 
 
    q.ParamByName('login').AsString := ALogin; 
    q.ParamByName('senha').AsString := ASenha; 
 
    q.Open; 
 
    if not q.EOF then 
    begin 
      if q.FieldByName('ativo').AsInteger = 1 then 
      begin 
        FIdUsuario := q.FieldByName('idusuario').AsInteger; 
        IsAtivo    := q.FieldByName('ativo').AsInteger = 1; 
        IsAdmin    := q.FieldByName('isadmin').AsInteger = 1; 
        Nome       := q.FieldByName('nome').AsString; 
        Login      := q.FieldByName('login').AsString; 
        Senha      := q.FieldByName('senha').AsString; 
        Email      := q.FieldByName('email').AsString; 
        TUtilImagem.GetImage(FFoto, q, 'foto'); 
        FDataCriacao     := q.FieldByName('data_criacao').AsDateTime; 
        FDataUltimoLogin := q.FieldByName('ultimo_login').AsDateTime; 
 
        //registra este acesso do usuário 
        RegistrarAcesso(FIdUsuario); 
 
        FSucesso  := True; 
        FMensagem := 'Usuário logado com sucesso'; 
      end 
      else 
      begin 
        FSucesso  := False; 
        FMensagem := 'Login não permitido. Procure seu supervisor.'; 
      end; 
    end 
    else 
    begin 
      FMensagem := 'Usuário ou senha inválida!'; 
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
 
procedure TServiceUsuario.RegistrarAcesso(AId: integer); 
//registra acesso login do usuário 
begin 
  if not FIsConectado then Exit; 
 
  try 
    with Conn.NewQuery() do 
    begin 
      SQL.Add('UPDATE usuario SET '); 
      SQL.Add('ultimo_login = :ultimo_login '); 
      SQL.Add('WHERE idusuario = ' + IntToStr(AId)); 
 
      ParamByName('ultimo_login').AsDateTime := Now; 
 
      Conn.TransactionPrepare; 
      ExecSQL; 
      Conn.TransactionCommit; 
      Free; 
    end; 
  except 
  end; 
end; 
 
procedure TServiceUsuario.AlterarSenha(AId: Integer; ANovaSenha: string); 
//altera a senha do usuário 
begin 
  if not FIsConectado then Exit; 
  FMensagem := ''; 
  FSucesso  := False; 
 
  try 
    with Conn.NewQuery() do 
    begin 
      SQL.Add('UPDATE usuario SET '); 
      SQL.Add('senha = :senha '); 
      SQL.Add('WHERE idusuario = ' + IntToStr(AId)); 
 
      ParamByName('senha').AsString := ANovaSenha; 
 
      Conn.TransactionPrepare; 
      ExecSQL; 
      Conn.TransactionCommit; 
      Free; 
 
      FSucesso := True; 
      FMensagem := 'Senha alterada com sucesso!'; 
    end; 
  except 
    on E: Exception do 
    begin 
      FSucesso  := False; 
      FMensagem := 'Falhou a alteração da senha.' + sLineBreak + sLineBreak + E.Message; 
    end; 
  end; 
end; 
 
end. 
 


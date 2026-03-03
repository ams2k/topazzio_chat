unit Util.FTPClient;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, lNet, lFTP, IniFiles;

type
  //TFTPProgressEvent = procedure(Sender: TObject; Bytes: Integer) of object;
  TFTPProgressEvent = procedure(const ACurrent, AMax, APercent: Integer) of object;
  TFTPLogEvent      = procedure(const AMsg: string) of object;
  TFTPDoneEvent     = procedure(const AFileName: string; ATotalBytes: Int64) of object;
  TFTPErrorEvent    = procedure(const AError: string) of object;

  { TThreadFTP }

  TThreadFTP = class(TThread)
    // procedure a ser executada
    ExecuteProcedure: procedure of object;
    // procedure de retorno
    CallBackProcedure: procedure of object;
  private
    procedure ChamaCallBack;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
  end;

  { TFTPClient }

  TFTPClient = class
  private
    FFTP: TLFTPClient;
    FThread: TThreadFTP;
    FFile: TFileStream; // file stream to save "GET" files into
    FList: TStringList;

    FMaxFileSize: Int64;
    FUploading: Boolean;
    FDownloading: Boolean;
    FLocalFile, FRemoteFile: string;
    FTransferConcluded: Boolean;

    FTotalBytes: Int64;
    FTransferred: Int64;
    FDirListing: string;

    FMessage: string;
    FSuccess: Boolean;
    FConnected: Boolean;
    FAuthenticated: Boolean;
    FWaitingSize: Boolean;
    FServer_Host: string;
    FServer_Port: Integer;
    FServer_User: string;
    FServer_Pwd: string;
    FServer_Folder: string;

    { eventos internos }
    procedure DoConnect(aSocket: TLSocket);
    procedure DoReceive(aSocket: TLSocket);
    procedure DoControl(aSocket: TLSocket);
    procedure DoSent(aSocket: TLSocket; const ABytes: Integer);
    procedure DoError(const Amsg: string; aSocket: TLSocket);
    procedure DoSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
    procedure LerConfig;
    procedure GetRemoteFileSize(const ARemoteFile: string);
    procedure SetMaxFileSize(AValue: Int64);
    procedure ConnectFTP;
    procedure DoList(const AFileName: string);
  public
    { eventos no lado do cliente }
    OnProgress : TFTPProgressEvent;
    OnLog      : TFTPLogEvent;
    OnDone     : TFTPDoneEvent;
    OnError    : TFTPErrorEvent;

    constructor Create;
    destructor Destroy; override;
    class function New: TFTPClient; static;

    procedure Connect(AHost: string; APort: Word; ALogin, APassword: string); overload;
    procedure Connect; overload;
    procedure Disconnect;
    procedure DoPoll;
    procedure Start;

    procedure Upload(const ALocalFile, ARemoteFile: string);
    procedure Download(const ARemoteFile, ALocalFile: string);
    procedure ChangRemoteDir(ADir: string);
    procedure RenameRemoteFile(const ACurrentFileName, ANewFileName: string);
    procedure DeleteFile(AFileName: string);
    function GetFileSizeText(AValue: Int64): string;
    function GetLocalFileSize(const AFileName: string): Int64;
    function IsAllDone(): Boolean;

    property GetMessage: string read FMessage;
    property Success: Boolean read FSuccess;
    property IsConnected: Boolean read FConnected;
    property IsAuthenticated: Boolean read FAuthenticated;
    property MaxFileSize: Int64 read FMaxFileSize write SetMaxFileSize;
    property IsTransferConcluded: Boolean read FTransferConcluded;
  end;

implementation

{ TThreadFTP }

constructor TThreadFTP.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

procedure TThreadFTP.Execute;
begin
  while (not Terminated) do begin
    try
      //TFTPClient.FFTP.CallAction;
      ExecuteProcedure;
      Sleep(10);
      //Synchronize(@ChamaCallBack);
    except
      Terminate;
    end;
  end;

  //Synchronize(@ChamaCallBack);
end;

procedure TThreadFTP.ChamaCallBack;
begin
  //CallBackProcedure; //Lá no TFTPClient
end;

{ TFTPClient }

constructor TFTPClient.Create;
begin
  FSuccess       := False;
  FMessage       := '';
  FConnected     := False;
  FAuthenticated := False;
  FTotalBytes    := 1;
  FTransferred   := 0;
  FMaxFileSize   := 1024 * 1024 * 4; //4Mb
  FTransferConcluded := True;
end;

destructor TFTPClient.Destroy;
begin
  Disconnect;
  FreeAndNil(FFile);
  FreeAndNil(FFTP);
  FreeAndNil(FList);
  inherited Destroy;
end;

class function TFTPClient.New: TFTPClient;
begin
  Result := TFTPClient.Create;
end;

procedure TFTPClient.Start;
//cria o server e inicia o processo
begin
  if Assigned(FFTP) then Exit;

  FList := TStringList.Create;

  FFTP := TLFTPClient.Create(nil);
  FFTP.Timeout   := 50;
  FFTP.TransferMethod := ftPassive;
  FFTP.OnConnect := @DoConnect; //conexão estabelecida
  FFTP.OnReceive := @DoReceive; //dados recebidos
  FFTP.OnControl := @DoControl; //mensagens recebidas
  FFTP.OnSent    := @DoSent;    //dados enviados
  FFTP.OnError   := @DoError;
  FFTP.OnSuccess := @DoSuccess;

  // instancia a thread de que força o monitoramento dos eventos
  FThread := TThreadFTP.Create(True);
  FThread.ExecuteProcedure := @DoPoll;
  //FThread.CallBackProcedure := @DoPoll;
  FThread.Start;
end;

procedure TFTPClient.DoConnect(aSocket: TLSocket);
//conexão estabelecida
var
  msg: string;
begin
  FConnected := True;
  FSuccess := True;
  msg := '';

  if Assigned(OnLog) then
    OnLog('Conectado com sucesso no servidor FTP');

  if FFTP.Authenticate(FServer_User, FServer_Pwd) then begin //autentica o usuário
    FFTP.Binary := True;
    FAuthenticated := True;
    //FFTP.ListFeatures;
    //DoList('');
  end else begin
    FFTP.GetMessage(msg);

    if Length(msg) = 0 then msg := 'Falha na autenticação do usuário';

    if Assigned(OnError) and (msg <> '') then
      OnError(msg);
  end;
end;

procedure TFTPClient.DoReceive(aSocket: TLSocket);
//Este método será chamado quando quaisquer dados forem recebidos do servidor
//e monitoramos o progresso.
var
  Buf: array[0..65535] of Byte;
  N: Integer;
  s: string;
begin
  if FFTP.CurrentStatus = fsRetr then begin
    N := FFTP.GetData(Buf, SizeOf(Buf));

    if (N = 0) and (not FFTP.DataConnection.Connected) then begin
      // acabou o download ou foi desconectado
      FreeAndNil(FFile);  // fecha o arquivo
      FDownloading := False;
      FTransferConcluded := True;
      DoList('');

      // força o 100%
      if Assigned(OnProgress) then
        OnProgress(FTotalBytes, FTotalBytes, 100);

      // informa que o recebimento foi concluído
      if Assigned(OnDone) then
        OnDone(FLocalFile, FTotalBytes);
    end else begin
      // escreve os dados no arquivo
      FFile.Write(Buf, N);
      Inc(FTransferred, N);

      if Assigned(OnProgress) then
        OnProgress(FTransferred, FTotalBytes, Round(FTransferred / FTotalBytes * 100));
    end;
  end else begin
    //obtendo a lista de arquivos
    s := FFTP.GetDataMessage;

    if Length(s) > 0 then begin
      FDirListing := FDirListing + s;
      if Assigned(OnLog) then
        OnLog( s );
    end else begin
      FList.Text  := FDirListing;
      FDirListing := '';
      FList.Clear;
    end;
  end;
end;

procedure TFTPClient.DoControl(aSocket: TLSocket);
//controle de mensagens recebidas
var
  s: string;
begin
  if FFTP.GetMessage(s) > 0 then begin

    if FWaitingSize then begin
      // resposta padrão do FTP para SIZE
      // 213 153245
      // 550 Could not get file size
      if (Pos('213', s) = 1) then
        FTotalBytes := StrToInt64Def(Trim(Copy(s, 4, Length(s))), 0);

      FWaitingSize := False;
    end;

    if Assigned(OnLog) then
      OnLog(s);
  end;
end;

procedure TFTPClient.DoSent(aSocket: TLSocket; const ABytes: Integer);
//Este método será chamado quando dados estão sendo enviados
//para o servidor e monitoramos o progresso.
var
  s, sFile: string;
begin
  if ABytes > 0 then begin
    Inc(FTransferred, ABytes);

    if Assigned(OnProgress) then
      OnProgress(FTransferred, FTotalBytes, Round(FTransferred / FTotalBytes * 100));

    if FUploading and not FFTP.DataConnection.Connected then begin
      FUploading := False;
      FTransferConcluded := True;

      //renomeia no servidor
      sFile := ExtractFileName(FLocalFile);
      if (sFile <> '') and (FRemoteFile <> '') and (FRemoteFile <> sFile) then
        FFTP.Rename(ExtractFileName(FLocalFile), FRemoteFile);

      //força o 100%
      if Assigned(OnProgress) then
        OnProgress(FTotalBytes, FTotalBytes, 100);

      //informa que o envio foi concluído
      if Assigned(OnDone) then
        OnDone(FLocalFile, FTotalBytes);
    end;
  end else begin
    s := FFTP.GetDataMessage;
    DoList('');

    if Assigned(OnLog) and (s <> '') then
      OnLog( s );
  end;
end;

procedure TFTPClient.DoError(const Amsg: string; aSocket: TLSocket);
//Ocorreu algum erro de rede, como ECONNRESET
begin
  if Assigned(OnError) then
    OnError(Amsg);
end;

procedure TFTPClient.DoSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
begin
  //
end;

procedure TFTPClient.ConnectFTP;
var
  msg: string;
begin
  FConnected := False;
  FAuthenticated := False;
  FSuccess := False;
  FMessage := '';
  msg := '';

  if not FFTP.Connect(FServer_Host, FServer_Port) then begin
    FFTP.GetMessage(msg);
    if Length(msg) = 0 then msg := 'Não foi possível conectar ao FTP';
    if Assigned(OnError) and (msg <> '') then
      OnError(msg);
  end;

  Sleep(500);
end;

procedure TFTPClient.DoList(const AFileName: string);
begin
  FDirListing := '';
  FFTP.List(AFileName);
end;

procedure TFTPClient.Connect(AHost: string; APort: Word; ALogin, APassword: string);
begin
  if (AHost = '') or (ALogin = '') or (APassword = '') then
    LerConfig
  else begin
    FServer_Host := AHost;
    FServer_Port := APort;
    FServer_User := ALogin;
    FServer_Pwd  := APassword;
  end;

  ConnectFTP;
end;

procedure TFTPClient.Connect;
begin
  Disconnect;
  LerConfig;
  ConnectFTP;
end;

procedure TFTPClient.Disconnect;
begin
  try
    if FFTP.Connected then begin
      FFTP.Disconnect;
      FConnected := False;
      FAuthenticated := False;
    end;
  except
  end;
end;

procedure TFTPClient.DoPoll;
//força os eventos do FFTP
begin
  try
    if Assigned(FFTP) then
      FFTP.CallAction;
  except
  end;
end;

procedure TFTPClient.Upload(const ALocalFile, ARemoteFile: string);
//envio de arquivos
var
  s: string;
begin
  if FConnected then begin

    if not FileExists(ALocalFile) then begin
      if Assigned(OnError) then
        OnError('Upload: Arquivo não encontrado ( ' + ExtractFileName(ALocalFile) + ' )');
      Exit;
    end;

    FTotalBytes  := GetLocalFileSize(ALocalFile); //caminho e nome do arquivo
    FTransferred := 0;
    FLocalFile   := ExtractFileName(ALocalFile);//fica apenas no nome do arquivo
    FRemoteFile  := ARemoteFile;

    if (FTotalBytes > FMaxFileSize) then begin
      if Assigned(OnError) then
        OnError('Upload reprovado. O arquivo tem ' + GetFileSizeText(FTotalBytes) +
                ' e excede o tamanho permitido de ' + GetFileSizeText(FMaxFileSize));
      Exit;
    end;

    FUploading := True;
    FTransferConcluded := False;

    //remove barras duplas (\\ ou //)
    s := StringReplace(ALocalFile, PathDelim + PathDelim, PathDelim, [rfReplaceAll]);

    //envia o arquivo
    FFTP.Put( s ); //monitorar em DoSent
  end
  else
    if Assigned(OnError) then
      OnError('Falha no Upload. Não conectado/não autenticado');
end;

procedure TFTPClient.Download(const ARemoteFile, ALocalFile: string);
//download do arquivo do servidor
var
  t: QWord;
begin
  FTotalBytes  := 0;
  FTransferred := 0;
  FFile := nil;

  if FFTP.Connected and FAuthenticated then begin
    FWaitingSize := True;
    t := GetTickCount64;
    GetRemoteFileSize(ARemoteFile);

    while FWaitingSize and ((GetTickCount64 - t) < 5) do begin
      DoPoll;
    end;

    if FTotalBytes < 1 then FTotalBytes := 1;

    FLocalFile := ALocalFile;
    FDownloading := True;
    FTransferConcluded := False;

    //cria o arquivo para receber o download
    FreeAndNil(FFile);
    FFile := TFileStream.Create(ALocalFile, fmOpenWrite or fmCreate);

    //faz a requisição do arquivo junto ao servidor ftp
    FFTP.Retrieve(ARemoteFile); //monitorar em DoReceive
  end
  else
    if Assigned(OnError) then
      OnError('Falha no Download. Não conectado/não autenticado');
end;

procedure TFTPClient.ChangRemoteDir(ADir: string);
begin
  FFTP.ChangeDirectory(ADir);
  DoList('');
end;

procedure TFTPClient.RenameRemoteFile(const ACurrentFileName, ANewFileName: string);
//renomeia o arquivo no servidor
begin
  if FConnected then
    FFTP.Rename(ACurrentFileName, ANewFileName)
  else
    if Assigned(OnError) then
      OnError('Falha ao renomear o arquivo remoto. Não conectado/não autenticado');
end;

procedure TFTPClient.DeleteFile(AFileName: string);
begin
  FFTP.DeleteFile(AFileName);
  DoList('');
end;

procedure TFTPClient.LerConfig;
//ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_config.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  try
    FServer_Host   := ArqINI.ReadString('chat_ftp','host', '127.0.0.1');
    FServer_Port   := ArqINI.ReadInteger('chat_ftp','port', 21);
    FServer_User   := ArqINI.ReadString('chat_ftp','user', '');
    FServer_Pwd    := ArqINI.ReadString('chat_ftp','pwd', '');
    FServer_Folder := ArqINI.ReadString('chat_ftp','folder', '');
  finally
    ArqINI.Free;
  end;

  if FServer_Folder = PathDelim then FServer_Folder := '';
end;

procedure TFTPClient.GetRemoteFileSize(const ARemoteFile: string);
//retorna o total de bytes do arquivo remoto
begin
  FTotalBytes  := 0;
  FWaitingSize := True;

  if FFTP.Connected then
    FFTP.SendMessage('SIZE ' + ARemoteFile + #13#10); //retorna em DoControl '213 423942847'
end;

procedure TFTPClient.SetMaxFileSize(AValue: Int64);
begin
  if FMaxFileSize = AValue then Exit;
  FMaxFileSize := AValue;
end;

function TFTPClient.GetFileSizeText(AValue: Int64): string;
var
  lkb, lmb, lgb: Int64;
begin
  lkb := 1024;
  lmb := 1024 * lkb;
  lgb := 1024 * lmb;

  if (AValue < lkb) then
    Result := FormatFloat('0 Bytes', AValue)
  else if (AValue < lmb) then
    Result := FormatFloat('0.0 KB', AValue / lkb)
  else if (AValue < lgb) then
    Result := FormatFloat('0.0 MB', AValue / lmb)
  else
    Result := FormatFloat('0.0 GB', AValue / lgb);
end;

function TFTPClient.GetLocalFileSize(const AFileName: string): Int64;
//obtém o total de bytes do arquivo local
var
  FS: TFileStream;
begin
  Result := 0;
  if not FileExists(AFileName) then Exit;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := FS.Size;
  finally
    FS.Free;
  end;
end;

function TFTPClient.IsAllDone(): Boolean;
//se estiver conectado e autenticado, tudo ok
begin
  Result := Assigned(FFTP) and FConnected and FAuthenticated;
end;

end.


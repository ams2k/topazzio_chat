unit Util.FTP;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, lNet, lFTP, IniFiles;

type
  // Callback para atualizar a UI (ProgressBar)
  TOnProgress       = procedure(const ACurrent, AMax, APercent: Integer) of object;
  TFTPStatusEvent   = procedure(const AMsg: string; ASucesso: Boolean) of object;
  TFTPErrorEvent    = procedure(const AMsg: string) of object;

  { TThreadChatRun }

  TThreadFTP = class(TThread)
    // procedure de retorno
    CallBackProcedure: procedure(AEvento: string) of object;
  private
    procedure ChamaCallBack;
  protected
    procedure Execute; override;
  public
    constructor Create(CreateSuspended: boolean);
  end;

  { TFTPLNet }

  TFTPLNet = class
  private
    FFTP: TLFTPClient;
    FThread: TThreadFTP;

    FOnProgress: TOnProgress;
    FOnStatus: TFTPStatusEvent;
    FOnError: TFTPErrorEvent;
    FTotalBytes: Int64;
    FTransferred: Int64;

    FMessage: string;
    FSuccess: Boolean;
    FConnected: Boolean;
    FServer_Host: string;
    FServer_Port: Integer;
    FServer_User: string;
    FServer_Pwd: string;
    FServer_Folder: string;

    procedure DoProgress;
    procedure FTPConnect(aSocket: TLSocket);
    procedure FTPSent(aSocket: TLSocket; const ABytes: Integer);
    procedure FTPReceive(aSocket: TLSocket);
    procedure FTPError(const AMsg: string; aSocket: TLSocket);
    function GetFileSize(const AFileName: string): Int64;
    procedure LerConfig;
  public
    constructor Create;
    destructor Destroy; override;


    property OnStatus: TFTPStatusEvent read FOnStatus write FOnStatus;
    property OnError: TFTPErrorEvent read FOnError write FOnError;
    property OnProgress: TOnProgress read FOnProgress write FOnProgress;

    procedure Connect();
    procedure Disconnect;

    // Upload e Download
    function SendFile(const ALocalPath, ARemotePath: string): Boolean;
    function DownloadFile(const ARemotePath, ALocalPath: string): Boolean;

    property GetMessage: string read FMessage;
    property Success: Boolean read FSuccess;
  end;

implementation

{ TThreadFTP }

procedure TThreadFTP.ChamaCallBack;
begin
  //CallBackProcedure( ... ); //Lá no TFTPLNet
end;

procedure TThreadFTP.Execute;
begin
  while (not Terminated) do begin
      try
        TFTPLNet.FFTP.CallAction;
        Sleep(10);
        //Synchronize(@ChamaCallBack);
      except
        Terminate;
      end;
    end;
end;

constructor TThreadFTP.Create(CreateSuspended: boolean);
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

{ TFTPLNet }

constructor TFTPLNet.Create;
begin
  FSuccess    := False;
  FConnected  := False;
  FMessage    := '';
  FTotalBytes := 0;
  FTransferred:= 0;

  FFTP := TLFTPClient.Create(nil);
  FFTP.Timeout := 10000; // 10 segundos
  FFTP.OnConnect    := @FTPConnect;
  FFTP.OnSent       := @FTPSent;
  FFTP.OnReceive    := @FTPReceive;
  FFTP.OnError      := @FTPError;

  // instancia a thread de que força o monitoramento dos eventos
  FThread := TThreadFTP.Create(True);
  FThread.CallBackProcedure := nil;
  FThread.Start;
end;

destructor TFTPLNet.Destroy;
begin
  FFTP.Free;
  inherited Destroy;
end;

procedure TFTPLNet.DoProgress;
var
  Percent: Integer;
begin
  if FTotalBytes > 0 then
  begin
    Percent := Round((FTransferred / FTotalBytes) * 100);
    if Assigned(FOnProgress) then
      FOnProgress(FTransferred, FTotalBytes, Percent);
  end;
end;

procedure TFTPLNet.FTPConnect(aSocket: TLSocket);
//conectado no host com sucesso
begin
  FConnected := True;
  FSuccess   := True;
  if Assigned(FOnStatus) then
    FOnStatus('Conectado ao servidor FTP', True);
end;

procedure TFTPLNet.FTPSent(aSocket: TLSocket; const ABytes: Integer);
begin
  Inc(FTransferred, ABytes);
  DoProgress;
end;

procedure TFTPLNet.FTPReceive(aSocket: TLSocket);
//Este método será chamado quando quaisquer dados forem recebidos
//no fluxo (stream) de dados
var
  S: string;
begin
  if aSocket.GetMessage(S) > 0 then
  begin
    Inc(FTransferred, Length(S));
    DoProgress;
  end;
end;

procedure TFTPLNet.FTPError(const AMsg: string; aSocket: TLSocket);
begin
  FSuccess := False;
  FMessage := AMsg;

  if Assigned(FOnError) then
    FOnError(AMsg);
end;

function TFTPLNet.GetFileSize(const AFileName: string): Int64;
var
  FS: TFileStream;
begin
  Result := 0;
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    Result := FS.Size;
  finally
    FS.Free;
  end;
end;

procedure TFTPLNet.LerConfig;
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
end;

procedure TFTPLNet.Connect;
begin
  if Assigned(FOnStatus) then
    FOnStatus('Conectando ao servidor FTP...', True);

  FConnected := False;
  LerConfig;
  FFTP.Host := FServer_Host;
  FFTP.Port := FServer_Port;

  try
    if FFTP.Connect then begin
      FConnected := True;

      if Assigned(FOnStatus) then
         FOnStatus('Conectando ao servidor FTP...', True);

      if FFTP.Authenticate(FServer_User, FServer_Pwd) then begin
        if Assigned(FOnStatus) then
         FOnStatus('Usuário autenticado com sucesso', True);
      end
      else begin
        if Assigned(FOnStatus) then
         FOnStatus('Falhou a autenticação do usuário', False);
      end;
    end
    else begin
      if Assigned(FOnStatus) then
         FOnStatus('Falhou a conexão com o servidor de FTP', False);
    end;
  except
    on E: Exception do begin
      FMessage := E.Message;
      FConnected := False;
    end;
  end;
end;

procedure TFTPLNet.Disconnect;
begin
  FConnected := False;

  try
    if FFTP.Connected then FFTP.Disconnect;
  except
  end;
end;

function TFTPLNet.SendFile(const ALocalPath, ARemotePath: string): Boolean;
var
  FS: TFileStream;
begin
  if not FileExists(ALocalPath) then
  begin
    if Assigned(FOnError) then
      FOnError('Arquivo local não encontrado');
    Exit;
  end;

  FTotalBytes := GetFileSize(ALocalPath);
  FTransferred := 0;

  if Assigned(FOnStatus) then
    FOnStatus('Iniciando upload...', True);

  FFTP.Put(ALocalPath, ARemotePath);
end;

function TFTPLNet.DownloadFile(const ARemotePath, ALocalPath: string): Boolean;
begin
  FTransferred := 0;
  FTotalBytes  := 0; // pode ser obtido via comando SIZE

  if Assigned(FOnStatus) then
    FOnStatus('Iniciando download...', True);

  FFTP.Get(ARemotePath, ALocalPath);
end;

end.


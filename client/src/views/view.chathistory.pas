unit View.ChatHistory;

(*
  Tela de histórico de conversas
  Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, DateUtils, Buttons, LCLType, LCLIntf, ComCtrls, IniFiles,
  lNetComponents, lNet, lFTP, fpjson, jsonparser,
  ChatLayoutManager, ChatCardInfo, ChatCardMessage, ChatCardFile, ChatUserInfo;

type
  TTransferFiles = (tfUpload, tfDownload, tfNone);

  { TfrmChatHistory }

  TfrmChatHistory = class(TForm)
    btnRoomsSearch: TSpeedButton;
    chkRoomsFiles: TCheckBox;
    edtRoomSearch: TEdit;
    FTP: TLFTPClientComponent;
    imgChatIcones: TImageList;
    imgIcons20: TImageList;
    lblLineTop: TLabel;
    lblPanTitulo1: TLabel;
    lblPanTitulo2: TLabel;
    lblRoomSearch: TLabel;
    lblRoomsTitulo: TLabel;
    lblConversasTitulo: TLabel;
    lblTituloChat: TLabel;
    lblTituloConvidados: TLabel;
    panChat: TPanel;
    panConversas: TPanel;
    panConvidados: TPanel;
    panRooms: TPanel;
    panTitulo: TPanel;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    scrChat: TScrollBox;
    scrConvidados: TScrollBox;
    scrRooms: TScrollBox;
    Timer1: TTimer;
    procedure btnRoomsSearchClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FTPConnect(aSocket: TLSocket);
    procedure FTPControl(aSocket: TLSocket);
    procedure FTPError(const msg: string; aSocket: TLSocket);
    procedure FTPFailure(aSocket: TLSocket; const aStatus: TLFTPStatus);
    procedure FTPReceive(aSocket: TLSocket);
    procedure FTPSent(aSocket: TLSocket; const Bytes: Integer);
    procedure FTPSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
    procedure scrChatResize(Sender: TObject);
    procedure scrConvidadosResize(Sender: TObject);
    procedure scrRoomsResize(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    ChatRoom: string;
    FProcessando: Boolean;
    FClosingForm: Boolean;
    FFile: TFileStream;
    RoomsLayout: TChatLayoutManager;
    ConvidadosLayout: TChatLayoutManager;
    ChatLayout: TChatLayoutManager;

    FTotalBytes, FTransferred: Int64;
    FTotalArquivos, FTotalArquivosTransferidos: Integer;
    FConnected: Boolean;
    FAuthenticated: Boolean;
    FWaitingSize: Boolean;
    FTransferConcluded: Boolean;
    FServer_Host: string;
    FServer_Port: Integer;
    FServer_User: string;
    FServer_Pwd: string;
    FServer_Folder: string;
    FFtpErroMsg: string;
    FCreateFilePath, FCurrentFileName, FOpenFilePath, FDirectoryToDownload: string;
    FDirListing: string;
    procedure AdicionarCardFile(AIdChat: Integer; AFileName: string;
      ASize: Int64; ATime: TDateTime; AIsMine: Boolean; ASentBy: string;
      AIsDeleted: Boolean; AStatus: TChatCardFileStatus);
    procedure AdicionarCardMessage(AIdChat, ASenderID: Integer; ASenderName,
      AMessage: string; ATime: TDateTime; AIsMine, AIsDeleted: Boolean;
      AStatus: TChatCardMessageStatus);
    procedure AdicionarCardMessageInicial(ADate: TDateTime);
    procedure AdicionarConvidado(AIdOwner, AIdUser: Integer; ANome: string;
                                 AUnreadCount: Integer; AStatus: TChatUserStatus);
    procedure CarregarArquivoBaixado(AFilePath: string);
    procedure CarregaRoomsHistory(const AStrJson: string);
    procedure CarregaListaConvidados(const AStrJson: string);
    procedure CarregaListaMensagens(const AStrJson: string);
    procedure ConectarFTP;
    procedure DesconectarFTP;
    procedure DoList(const AFileName: string);
    function IdDonoSala(): Integer;
    procedure LerConfig;
    function GetFileSizeText(AValue: Int64): string;
    function GetLocalFileSize(const AFileName: string): Int64;
    function GetFileTotalBytes(AData: string): Int64;
    procedure CardFileClick(AChatID: Integer; AArquivo: string; ASize: Int64);
  public
    procedure ChatEventos(AStrJson: string);
    procedure RoomMessage_Open(ARoomName: string);
  end;

var
  frmChatHistory: TfrmChatHistory;

implementation

uses
  ChatModule, View.MessageQuery, Util.MessagePopup;

{$R *.lfm}

{ TfrmChatHistory }

procedure TfrmChatHistory.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FClosingForm := True;
  ChatClient.ChatHistory_Close;
  FreeAndNil(RoomsLayout);
  FreeAndNil(ChatLayout);
  FreeAndNil(ConvidadosLayout);
  FreeAndNil(FFile);
end;

procedure TfrmChatHistory.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TfrmChatHistory.FormCreate(Sender: TObject);
begin
  RoomsLayout := TChatLayoutManager.Create( scrRooms );
  ConvidadosLayout := TChatLayoutManager.Create( scrConvidados );
  ChatLayout := TChatLayoutManager.Create( scrChat );

  ChatRoom := '';
  FTotalBytes := 0;
  FTransferred := 0;
  FTotalArquivos := 0;
  FTotalArquivosTransferidos := 0;
  FConnected := False;
  FAuthenticated := False;
  FFtpErroMsg := '';
  FTransferConcluded := False;
  FCreateFilePath := '';
  FCurrentFileName := '';
  FDirectoryToDownload := '';
  FDirListing := '';
  FClosingForm := False;

  LerConfig;
end;

procedure TfrmChatHistory.FormShow(Sender: TObject);
begin
  ConectarFTP;
end;

procedure TfrmChatHistory.FTPConnect(aSocket: TLSocket);
// conectou no host
var
  msg: string;
begin
  FConnected := True;
  FAuthenticated := False;
  msg := '';

  if FTP.Authenticate(FServer_User, FServer_Pwd) then begin
    // autentica o usuário
    FTP.Binary := True;
    FAuthenticated := True;

    if (FServer_Folder <> '') and (FServer_Folder <> '/') then
      FTP.ChangeDirectory(FServer_Folder);

    FTP.ListFeatures;
  end else begin
    FTP.GetMessage(msg);
    if Length(msg) = 0 then msg := 'Falha na autenticação do usuário';
  end;
end;

procedure TfrmChatHistory.FTPControl(aSocket: TLSocket);
// retorno do FTP.SendMessage(... + #13#10)
var
  s: string;
begin
  if FTP.GetMessage(s) > 0 then begin

    if FWaitingSize and (Pos('213', s) = 1) then begin
      // FTP.SendMessage('SIZE arquivo.ext' + FLE)
      // resposta padrão do FTP para SIZE
      // 213 153245
      // 550 Could not get file size
      FTotalBytes := StrToInt64Def(Trim(Copy(s, 4, Length(s))), 0);
      FWaitingSize := False;
    end;

  end;
end;

procedure TfrmChatHistory.FTPError(const msg: string; aSocket: TLSocket);
begin
  if not FTP.Connected then
    DesconectarFTP;
  FCreateFilePath := '';
  FOpenFilePath := '';
end;

procedure TfrmChatHistory.FTPFailure(aSocket: TLSocket; const aStatus: TLFTPStatus);
begin
  if aStatus = fsRetr then
    FOpenFilePath := '';
end;

procedure TfrmChatHistory.FTPReceive(aSocket: TLSocket);
// download
var
  Buf: array[0..65535] of Byte;
  N: Integer;
  s: string;
begin
  if FTP.CurrentStatus = fsRetr then begin
    N := FTP.GetData(Buf, SizeOf(Buf));
    Inc(FTransferred, N);

    if N > 0 then begin
      // download em andamento
      if Length(FCreateFilePath) > 0 then begin
        FFile := TFileStream.Create(FCreateFilePath, fmCreate or fmOpenWrite);
        FOpenFilePath := FCreateFilePath;
        FCreateFilePath := '';
        FTransferConcluded := False;
        ProgressBar1.Position := 100;
      end;

      // salva os bytes recebidos no arquivo
      FFile.Write(Buf, N);
    end
    else if not FTP.DataConnection.Connected then begin
      // download concluído
      FreeAndNil(FFile);  // fecha o arquivo
    end;

    // atualiza a barra de progresso
    ProgressBar1.Position := Integer( Round(FTransferred / FTotalBytes * 100) );
  end else begin
    // listagem aqui:
    // FTP.List('gotify.png') => '-rw-r--r--    1 1003     1004        15750 Jan 18 17:16 gotify.png'
    // FTP.FeatureList;
    s := FTP.GetDataMessage;

    if Length(s) > 0 then
      // lendo a informação
      FDirListing := FDirListing + s
    else begin
      // leitura concluída
      //edtLogs.Lines.Append( FDirListing );

      if FWaitingSize then begin
         FTotalBytes := GetFileTotalBytes( FDirListing );
         FWaitingSize := False;
      end;

      FDirListing := '';
    end;
  end;
end;

procedure TfrmChatHistory.FTPSent(aSocket: TLSocket; const Bytes: Integer);
begin
  //
end;

procedure TfrmChatHistory.FTPSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
begin
  if aStatus = fsRetr then begin
    // download com sucesso, abrir o arquivo ?
    FTransferConcluded := True;
    FCreateFilePath := '';
    ProgressBar1.Position := 100;
    Sleep(1000);
    ProgressBar1.Position := 0;
    CarregarArquivoBaixado( FOpenFilePath );
  end;
end;

procedure TfrmChatHistory.scrChatResize(Sender: TObject);
begin
  if FClosingForm then Exit;
  ChatLayout.RecalculateLayout;
end;

procedure TfrmChatHistory.scrConvidadosResize(Sender: TObject);
begin
  if FClosingForm then Exit;
  ConvidadosLayout.RecalculateLayout;
end;

procedure TfrmChatHistory.scrRoomsResize(Sender: TObject);
begin
  if FClosingForm then Exit;
  RoomsLayout.RecalculateLayout;
end;

procedure TfrmChatHistory.Timer1Timer(Sender: TObject);
begin
  FProcessando := False;
  Timer1.Enabled := False;
end;

procedure TfrmChatHistory.btnRoomsSearchClick(Sender: TObject);
// solicita dados de histórico do chat para o cusuário atual
var
  j: TJSONObject;
begin
  if FProcessando then Exit;
  btnRoomsSearch.Enabled := False;
  FProcessando := True;
  Timer1.Enabled := True;

  j := TJSONObject.Create;
  j.Add('event', 'history_rooms');
  j.Add('to_id', ChatClient.Meu_ID);
  j.Add('has_files', chkRoomsFiles.Checked);
  j.Add('search', Trim(edtRoomSearch.Text));

  ChatClient.SendMessage(j.AsJSON);

  j.Free;
end;

procedure TfrmChatHistory.RoomMessage_Open(ARoomName: string);
// busca no servidor a lista de mensagens da sala e seus integrantes
var
  j: TJSONObject;
begin
  if FProcessando then Exit;
  if (ARoomName = '') or (ChatRoom = ARoomName) then Exit;

  ChatRoom := ARoomName;
  FProcessando := True;
  Timer1.Enabled := True;

  j := TJSONObject.Create;
  j.Add('event', 'history_messages');
  j.Add('room_name', ARoomName);
  j.Add('to_id', ChatClient.Meu_ID);

  ChatClient.SendMessage( j.AsJSON );

  j.Free;
end;

procedure TfrmChatHistory.AdicionarConvidado(AIdOwner, AIdUser: Integer;
        ANome: string; AUnreadCount: Integer; AStatus: TChatUserStatus);
// adiciona um convidado à lista para o chat
var
  u: TChatUserInfo;
begin
  u := TChatUserInfo.Create(scrConvidados);
  u.Parent := scrConvidados;
  u.ImageList := nil;
  u.ImageListIndex := -1; //lixeira
  u.OnClickInfo := nil;
  u.OnClickDelete := nil;
  u.Setup(AIdOwner, AIdUser, ANome, AUnreadCount, AStatus, False);

  ConvidadosLayout.AddConvidado(u);
end;

procedure TfrmChatHistory.CarregaRoomsHistory(const AStrJson: string);
// carrega lista de salas de conversas
var
  c: TChatCardInfo;
  lJson, lJsonTemp: TJSONObject;
  lArrayMsg: TJSONArray;
  i, from_id, total_msg, lcount: integer;
  from_name, room_name, msg_date: string;
  ldate: TDateTime;
begin
  lcount := 0;
  lblRoomsTitulo.Caption := 'HISTÓRICO';
  RoomsLayout.Clear; // limpa a lista

  try
    lJson := TJSONObject( GetJSON( AStrJson ) );
    lArrayMsg := TJSONArray( lJson.Arrays['messages'] );
    lcount := lArrayMsg.Count;

    for i := 0 to lArrayMsg.Count - 1 do begin
      lJsonTemp := TJSONObject( lArrayMsg.Objects[i] );

      room_name := lJsonTemp.Get('room_name', '');
      from_id   := lJsonTemp.Get('from_id', 0);
      from_name := lJsonTemp.Get('from_name', '');
      msg_date  := lJsonTemp.Get('date', FormatDateTime('yyyy-mm-dd hh:nn:ss', now));
      ldate     := ISO8601ToDate( msg_date, True );
      total_msg := lJsonTemp.Get('total_msg', 0);

      if (room_name <> '') and (from_id > 0) then begin
        c := TChatCardInfo.Create( scrRooms );
        c.Parent := scrRooms;
        c.OnClickInfo := @RoomMessage_Open;
        c.Setup(from_id, from_name, room_name, total_msg, ldate);

        RoomsLayout.AddCardRoom(c);
      end; // if
    end; // for
  finally
    lJson.Free;
  end;

  // auto-scroll
  scrRooms.VertScrollBar.Position := scrRooms.VertScrollBar.Range;

  if lcount > 0 then
    lblRoomsTitulo.Caption := Format('HISTÓRICO (%d)', [lcount])
  else
    ShowMessageSimple(Self, 'Nenhuma ocorrência foi encontrada!', icWarning);
end;

procedure TfrmChatHistory.ConectarFTP;
begin
  if FTP.Connected and FAuthenticated then Exit;
  DesconectarFTP;
  FTP.Connect(FServer_Host, FServer_Port);
end;

procedure TfrmChatHistory.DesconectarFTP;
begin
  FTP.Disconnect;
  FConnected := False;
  FAuthenticated := False;
end;

procedure TfrmChatHistory.DoList(const AFileName: string);
begin
  FDirListing := '';
  FTP.List( AFileName );
end;

procedure TfrmChatHistory.ChatEventos(AStrJson: string);
// processa eventos recebidos do servidor
var
 evento: string;
 AJson: TJSONObject;
begin
  btnRoomsSearch.Enabled := True;
  FProcessando := False;

  if FClosingForm then Exit;
  if Trim(AStrJson) = '' then Exit;

  try
    AJson := TJSONObject( GetJSON( AStrJson ) );

    evento := LowerCase( AJson.Get('event', '') );

    if (evento = 'history_rooms') then begin
      // histórico de salas de conversa
      CarregaRoomsHistory( AStrJson );
    end
    else if (evento = 'history_messages') then begin
      // histórico de mensagens da sala selecionada
      CarregaListaConvidados( AStrJson );
      CarregaListaMensagens( AStrJson );
    end;
  finally
    AJson.Free;
  end;
end;

procedure TfrmChatHistory.LerConfig;
// ler configurações do servidor
var
  ArqINI: TIniFile;
  FArquivoINI: String;
begin
  FArquivoINI := ExtractFileDir( ParamStr(0) ) + PathDelim + 'chat_config.ini';
  ArqINI := TIniFile.Create(FArquivoINI);

  try
    if not FileExists(FArquivoINI) then begin
      ArqINI.WriteString('chat_ftp','host', '127.0.0.1');
      ArqINI.WriteInteger('chat_ftp','port', 21);
      ArqINI.WriteString('chat_ftp','user', 'ftpuser');
      ArqINI.WriteString('chat_ftp','pwd', 'pwd196');
      ArqINI.WriteString('chat_ftp','folder', '');
    end;

    FServer_Host   := ArqINI.ReadString('chat_ftp','host', '127.0.0.1');
    FServer_Port   := ArqINI.ReadInteger('chat_ftp','port', 21);
    FServer_User   := ArqINI.ReadString('chat_ftp','user', 'ftpuser');
    FServer_Pwd    := ArqINI.ReadString('chat_ftp','pwd', 'pwd196');
    FServer_Folder := ArqINI.ReadString('chat_ftp','folder', '');
  finally
    ArqINI.Free;
  end;

  if FServer_Folder = PathDelim then FServer_Folder := '';
end;

function TfrmChatHistory.GetFileSizeText(AValue: Int64): string;
// tamanho do arquivo em formato string: 10Kb, 2Mb, etc
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

function TfrmChatHistory.GetLocalFileSize(const AFileName: string): Int64;
// obtém o total de bytes do arquivo local
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

function TfrmChatHistory.GetFileTotalBytes(AData: string): Int64;
// tenta obter o tamanho do arquivo
//                           0             1 2        3           4     5   6  7     8
// FTP.List('gotify.png') => '-rw-r--r--    1 1003     1004        15750 Jan 18 17:16 gotify.png'
var
  f: array of string;
begin
  Result := 0;
  f := AData.Split([' '], TStringSplitOptions.ExcludeEmpty);

  try
    if High(f) > 7 then
      Result := StrToInt64Def(f[4], 0);
  finally
    SetLength(f, 0);
  end;
end;

procedure TfrmChatHistory.CarregarArquivoBaixado(AFilePath: string);
//abre o arquivo baixado
var
  sArquivo: string;
begin
  if AFilePath = '' then Exit;
  sArquivo := ExtractFileName(AFilePath);
  if FileExists(AFilePath) then begin
    if ShowMessageQuery(Self, 'Abrir arquivo', 'Quer abrir o arquivo ?' + sLineBreak + sArquivo, 'Sim', 'Não', '', icQuestion) <> mrYes then Exit;
    OpenDocument( AFilePath );
  end else
    ShowMessageSimple(Self, 'Arquivo não encontrado!' + sLineBreak + sArquivo);
end;

procedure TfrmChatHistory.CarregaListaConvidados(const AStrJson: string);
// adicionar convidados à lista
var
  AJson: TJSONObject;
  lObj: TJSONObject;
  lArray: TJSONArray;
  i, idOwnerUser, idGuestUser, lguest, total_unread: Integer;
  bOnLine: Boolean;
  lStatus: TChatUserStatus;
  user_name: string;
begin
  if AStrJson = '' then Exit;

  try
    ConvidadosLayout.Clear; // limpa a lista de convidados, se houver
    idOwnerUser := IdDonoSala;
    AJson  := TJSONObject( GetJSON( AStrJson ) );
    lArray := TJSONArray( AJson.Arrays['to'] );

    // exibe os convidados da lista
    for i := 0 to lArray.Count - 1 do begin
      lObj         := TJSONObject( lArray.Items[i] );
      lguest       := lObj.Get('guest', 0); // guest = 0 (dono da sala, convidado = 1)
      idGuestUser  := lObj.Get('to_id', 0);
      user_name    := lObj.Get('to_name', '');
      total_unread := lObj.Get('total_unread', 0);
      bOnLine      := lObj.Get('online', False);

      if bOnLine then lStatus := usOnline else lStatus := usOffline;

      // adiciona o convidado do chat
      AdicionarConvidado(idOwnerUser, idGuestUser, user_name, total_unread, lStatus);
    end; // for lArray
  finally
    AJson.Free;
  end;

  ConvidadosLayout.RecalculateLayout(False);
end;

procedure TfrmChatHistory.CarregaListaMensagens(const AStrJson: string);
// carrega a lista de mensagens da sala
// {"event":"get_messages","room_name":"%s", "to":[], "messages":[]}
var
  AJson: TJSONObject;
  lObj: TJSONObject;
  lArray: TJSONArray;
  i, idchat, from_id: Integer;
  from_name, msg, file_name, msg_date: string;
  file_size: Int64;
  ldate: TDateTime;
  is_mine, is_deleted: Boolean;
begin
  if (AStrJson = '') then Exit;

  try
    ChatLayout.Clear; // limpa a lista de mensagens, se houver
    AJson := TJSONObject( GetJSON( AStrJson ) );
    lArray := TJSONArray( AJson.Arrays['messages'] );

    for i := 0 to lArray.Count - 1 do begin
      lObj          := TJSONObject( lArray.Items[i] );
      idchat        := lObj.Get('idchat', 0);
      from_id       := lObj.Get('from_id', 0);
      from_name     := lObj.Get('from_name', '');
      msg           := lObj.Get('msg', '');
      file_name     := lObj.Get('file_name', '');
      file_size     := StrToInt64Def('0' + lObj.Get('file_size', '0'), 0 );
      // file_size_ext := lObj.Get('file_size_ext', '');
      msg_date      := lObj.Get('msg_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', now));
      ldate         := ISO8601ToDate( msg_date, True );
      is_mine       := (from_id = ChatClient.Meu_ID);
      is_deleted    := lObj.Get('deleted', False);

      if (file_name = '') then // conversa
        AdicionarCardMessage(idchat, from_id, from_name, msg, ldate, is_mine, is_deleted,
                             TChatCardMessageStatus.msRead)
      else // informações de arquivo
        AdicionarCardFile(idchat, file_name, file_size, ldate, is_mine, from_name, is_deleted,
                          TChatCardFileStatus.msRead);
    end; // for lArray
  finally
    AJson.Free;
  end;

  // Auto-scroll
  scrChat.VertScrollBar.Position := scrChat.VertScrollBar.Range;
end;

procedure TfrmChatHistory.AdicionarCardMessageInicial(ADate: TDateTime);
// exibe a data inicial do chat
var
  CardMsg: TChatCardMessage;
begin
  try
    CardMsg := TChatCardMessage.Create(scrChat);
    CardMsg.Parent := scrChat;
    CardMsg.CanDelete := False;
    CardMsg.InitialDate(ADate);

    ChatLayout.AddCardMessage(CardMsg);
  except
  end;
end;

procedure TfrmChatHistory.AdicionarCardMessage(AIdChat, ASenderID: Integer; ASenderName, AMessage: string; ATime: TDateTime; AIsMine, AIsDeleted: Boolean; AStatus: TChatCardMessageStatus);
// adiciona a mensagem na lista
var
  CardMsg: TChatCardMessage;
begin
  if scrChat.ControlCount = 0 then
    AdicionarCardMessageInicial(ATime);

  try
    CardMsg := TChatCardMessage.Create(scrChat);
    CardMsg.Parent := scrChat;
    CardMsg.ImageList := nil; // imgIcons20;
    CardMsg.ImageListIndex := -1; // 0 = lixeira
    CardMsg.OnClickDeleteMessage := nil;
    CardMsg.CanDelete := False; // AIsMine;
    CardMsg.Setup(AIdChat, ASenderID, ASenderName, AMessage, ATime, AIsMine, AIsDeleted, AStatus);

    ChatLayout.AddCardMessage(CardMsg);
  except
  end;
end;

procedure TfrmChatHistory.AdicionarCardFile(AIdChat: Integer;
                                    AFileName: string;
                                    ASize: Int64;
                                    ATime: TDateTime;
                                    AIsMine: Boolean;
                                    ASentBy: string;
                                    AIsDeleted: Boolean;
                                    AStatus: TChatCardFileStatus);
// adiciona a mensagem de remessa de arquivo
var
  CardFile: TChatCardFile;
begin
  if scrChat.ControlCount = 0 then
    AdicionarCardMessageInicial(ATime);

  try
    CardFile := TChatCardFile.Create(scrChat);
    CardFile.Parent := scrChat;
    CardFile.ImageFileList := imgChatIcones; // ícones doas tipos de arquivo
    CardFile.ImageDeleteList := nil;  // ícone da lixeira
    CardFile.ImageDeleteListIndex := -1; // 0 = lixeira
    CardFile.OnClickDownloadEvent := @CardFileClick;
    CardFile.OnClickDeleteMessage := nil;
    CardFile.CanDelete := False; // AIsMine;
    CardFile.Setup(AIdChat, AFileName, ASize, ATime, AIsMine, ASentBy, AIsDeleted, AStatus);

    ChatLayout.AddCardFile(CardFile);
  except
  end;
end;

procedure TfrmChatHistory.CardFileClick(AChatID: Integer; AArquivo: string; ASize: Int64);
// baixar arquivo clicado no chat
var
 sFile, sArquivo: string;
 t: QWord;
begin
  ProgressBar1.Position := 0;

  if not FTP.Connected or not FAuthenticated then begin
    ConectarFTP;
    Sleep(100);
  end;

  FWaitingSize := False;
  sArquivo := ChatRoom + '_' + AArquivo;

  if (AArquivo = '') or not FAuthenticated then begin
    ShowMessageSimple(Self, 'Nome de arquivo inválido ou FTP não conectado!', icWarning);
    Exit;
  end;

  FTotalBytes  := 0;
  FTransferred := 0;
  FFile := nil;
  FWaitingSize := True;

  // obtém o tamanho do arquivo a ser baixado
  // FTP.SendMessage('SIZE ' + ChatRoom + '_' + AArquivo + #13+#10);
  DoList(sArquivo); //retorna em DoReceive (também funciona)

  t := GetTickCount64; //milissegundos

  while FWaitingSize do begin
    Application.ProcessMessages;
    if ((GetTickCount64 - t) > 5000) then Break; // 5 segundos
  end;

  // tenta encontrar o arquivo sem o nome da sala
  if (FTotalBytes <= 0) then begin
    sArquivo := AArquivo;
    FWaitingSize := True;
    DoList(sArquivo); // retorna em DoReceive
    t := GetTickCount64; // milissegundos
    while FWaitingSize do begin
      Application.ProcessMessages;
      if ((GetTickCount64 - t) > 5000) then Break; // 5 segundos
    end;
  end;

  if (FTotalBytes <= 0) then begin
    ShowMessageSimple(Self, 'Não foi possível obter informações do arquivo!' +
                      sLineBreak + sLineBreak + AArquivo, icNegative);
    Exit;
  end;

  // local onde salvar o arquivo
  sFile := AArquivo;

  if FDirectoryToDownload <> '' then
    sFile := FDirectoryToDownload + PathDelim + AArquivo;

  with SaveDialog1 do begin
    FileName := sFile;
    if Execute then
      sFile := FileName
    else
      Exit;
  end;

  FTotalArquivos :=  1;

  if FAuthenticated then begin
    FCreateFilePath := sFile;
    FDirectoryToDownload := ExtractFileDir(sFile);

    // download via FTP - Monitore no evento OnReceive
    FTP.Retrieve( sArquivo );
  end
end;

function TfrmChatHistory.IdDonoSala(): Integer;
// retorna o id do dono/criado da sala
begin
  Result := ChatClient.Meu_ID;

  try
    Result := StrToIntDef( ChatRoom.Split(['-'], TStringSplitOptions.ExcludeEmpty)[0], ChatClient.Meu_ID );
  except
  end;
end;

end.


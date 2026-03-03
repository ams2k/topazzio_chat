unit View.Chat;

(*
  Tela de conversas
  Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, DateUtils,
  Buttons, LCLType, LCLIntf, ComCtrls, IniFiles, lNetComponents, lNet, lFTP,
  fpjson, jsonparser, ChatLayoutManager, ChatCardMessage, ChatCardFile, ChatUserInfo;

type
  TTransferFiles = (tfUpload, tfDownload, tfNone);

  { TfrmChat }

  TfrmChat = class(TForm)
    btnAdidcionaConvidados: TSpeedButton;
    btnChamarAtencao: TSpeedButton;
    btnEnviarArquivo: TSpeedButton;
    btnEnviarMsg: TSpeedButton;
    btnShowHide: TSpeedButton;
    edtMsg: TMemo;
    FTP: TLFTPClientComponent;
    imgChatIcones: TImageList;
    lblLineTop: TLabel;
    lblStatus: TLabel;
    lblPanArquivoClose: TLabel;
    lblLogOpen: TLabel;
    lblLogTitulo: TLabel;
    lblPanArquivoNome: TLabel;
    lblPanArq1: TLabel;
    lblPanArq2: TLabel;
    lblPanArquivoSize: TLabel;
    lblPanArquivoCount: TLabel;
    lblTituloChat: TLabel;
    lblTituloConvidados: TLabel;
    edtLogs: TMemo;
    lblTituloEmoji: TLabel;
    ListBoxEmojis: TListBox;
    OpenDialog1: TOpenDialog;
    panArquivo: TPanel;
    panConvidados: TPanel;
    panChat: TPanel;
    panWriting: TPanel;
    panLog: TPanel;
    panTitulo: TPanel;
    lblPanTitulo1: TLabel;
    lblPanTitulo2: TLabel;
    ProgressBar1: TProgressBar;
    SaveDialog1: TSaveDialog;
    imgIcons20: TImageList;
    scrChat: TScrollBox;
    scrConvidados: TScrollBox;
    Timer1: TTimer;

    procedure btnChamarAtencaoClick(Sender: TObject);
    procedure btnShowHideClick(Sender: TObject);
    procedure edtMsgKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const AFileNames: array of string);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FTPConnect(aSocket: TLSocket);
    procedure FTPControl(aSocket: TLSocket);
    procedure FTPError(const msg: string; aSocket: TLSocket);
    procedure FTPFailure(aSocket: TLSocket; const aStatus: TLFTPStatus);
    procedure FTPReceive(aSocket: TLSocket);
    procedure FTPSent(aSocket: TLSocket; const ABytes: Integer);
    procedure FTPSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
    procedure lblLogOpenClick(Sender: TObject);
    procedure lblLogOpenMouseEnter(Sender: TObject);
    procedure lblLogOpenMouseLeave(Sender: TObject);
    procedure lblPanArquivoCloseClick(Sender: TObject);
    procedure scrChatResize(Sender: TObject);
    procedure scrConvidadosResize(Sender: TObject);
    procedure btnAdidcionaConvidadosClick(Sender: TObject);
    procedure btnEnviarArquivoClick(Sender: TObject);
    procedure btnEnviarMsgClick(Sender: TObject);
    procedure ListBoxEmojisClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    FFile: TFileStream;
    ChatLayout: TChatLayoutManager;
    ConvidadosLayout: TChatLayoutManager;
    Usuario_clicado: integer;
    FTotalBytes, FTransferred: Int64;
    FTotalArquivos, FTotalArquivosTransferidos: Integer;
    ListaIDS, OldListaIDS: string;
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
    FFilesToSend: array of string;
    FFileCurrentIndex: Integer;
    FFileCurrentSize: Int64;
    FCreateFilePath, FCurrentFileName, FOpenFilePath, FDirectoryToDownload: string;
    FMaxFileSize: Int64;
    FDirListing: string;
    bAnimarLog, bLogAberto: Boolean;
    AnimarDirecao: Integer;
    AnimarVelocidade: Integer;
    FConvidados_List: TJSONArray;
    FAttention: Boolean;
    FAttentionPeriod, FAttentionCount, FAttentionSequence, FAttentionShakeCount: Integer;
    FWriting: Boolean;
    FWritingPeriod, FWritingCount, FWritingSequence: Integer;
    FDefaultColor: TColor;
    FDigitandoCount: Integer;
    FWidth, FpanConvidadosWidth: Integer;
    FIsMinhaSala: Boolean;
    FIdDonoSala: Integer;
    FGetToUsersBloqueio: Boolean;
    FBuscandoStatusConvidados: Boolean;
    FCarregandoMensagens: Boolean;
    FEstouNaListaConvidados: Boolean;
    FClosingForm: Boolean;
    FOldLeft, FOldTop: Integer;
    FAtualizaStatus: Boolean;

    procedure AdicionarCardMessage(AIdChat, ASenderID: Integer; ASenderName,
                                   AMessage: string; ATime: TDateTime; AIsMine, AIsDeleted: Boolean;
                                   AStatus: TChatCardMessageStatus);
    procedure AdicionarCardFile(AIdChat: Integer; AFileName: string; ASize: Int64;
                                ATime: TDateTime; AIsMine: Boolean; ASentBy: string; AIsDeleted: Boolean;
                                AStatus: TChatCardFileStatus);
    procedure AdicionarCardMessageInicial(ADate: TDateTime);
    procedure AdicionarConvidado(AIdOwner, AIdUser: Integer; ANome: string;
                                 AUnreadCount: Integer; AStatus: TChatUserStatus);
    procedure AtualizarListaConvidados(const AStrJson: string);
    procedure CarregarArquivoBaixado(AFilePath: string);
    procedure Convidados_AtualizaStatus(AStrJson: string; AValidarConvidados: Boolean);
    procedure Convidados_AtualizaStatusByID(AIdUser: Integer; AStatus: TChatUserStatus);
    procedure Convidados_BuscarStatus;
    procedure ChamarAtencao;
    procedure ConvidadoAlteraStatus(AIdUser: Integer; AStatus: Boolean);
    procedure ConvidadoMsgNaoLidas(AIdUser, AQdeNaoLida: Integer);
    procedure DoList(const AFileName: string);
    procedure EnviarArquivos(const AFileNames: array of string);
    procedure EnviarMensagem(AMessage, AFileName, AFileSize, AFileSizeExt: string);
    procedure ExibeMensagem(const AStrJson: string);
    function GetFileSizeText(AValue: Int64): string;
    function GetLocalFileSize(const AFileName: string): Int64;
    function GetFileTotalBytes(AData: string): Int64;
    procedure GetToUsers;
    procedure CardFileClick(AChatID: Integer; AArquivo: string; ASize: Int64);
    procedure ConvidadoClickDelete(AIDUser: Integer; ANomeUser: string);
    procedure ConvidadoClickInfo(AIDUser: Integer; ANomeUser: string);
    procedure NotificaDigitacao;
    function PodeEnviarMensagem(): Boolean;
    procedure ControleElementos(AEnabled: Boolean);
    procedure LerConfig;
    procedure ConectarFTP;
    procedure DesconectarFTP;
    function RecriarListaConvidados(AStrJson: string): Boolean;
    procedure EntrandoNaSala;
    procedure SaindoDaSala;
    procedure SendFile;
    function IsMinhaSala(): Boolean;
    function IdDonoSala(): Integer;
    procedure ResetAttention;
    procedure ResetWriting;
    procedure ResizeObjects;
    procedure CarregaListaConvidados(const AStrJson: string);
    procedure CarregaListaMensagens(const AStrJson: string);
    procedure ShowStatus(AMsg: string);
    procedure Chat_ApagouMensagem(AStrJson: string);
    procedure NotificaAlteracaoConvidados;
    { evento para deletar mensagem }
    procedure CHatDeletar(AIdChat: Integer; AFileName: string);
  public
    ChatRoom: string;
    { apenas o evento 'chat' }
    procedure ChatEventos(AChatRoom: string; AStrJson: string);
    { avisos como: logoff de usuáro, entre outras mensagens }
    procedure ChatAvisos(AStrJson: string);
  end;

var
  frmChat: TfrmChat;

implementation

uses
  ChatModule, View.MessageQuery, View.ChatUsuarios, Util.MessagePopup;

{$R *.lfm}

{ TfrmChat }

procedure TfrmChat.FormCreate(Sender: TObject);
begin
  Self.AllowDropFiles := True;
  ChatRoom := ChatClient.NewRoom( ChatClient.Meu_ID );
  ChatLayout := TChatLayoutManager.Create( scrChat );
  ConvidadosLayout := TChatLayoutManager.Create( scrConvidados );
  FpanConvidadosWidth := panConvidados.Width;
  ListaIDS := '';
  OldListaIDS := '';
  FTotalBytes := 0;
  FTransferred := 0;
  FTotalArquivos := 0;
  FTotalArquivosTransferidos := 0;
  FConnected := False;
  FAuthenticated := False;
  FFtpErroMsg := '';
  FTransferConcluded := False;
  FFileCurrentIndex := -1;
  FCreateFilePath := '';
  FCurrentFileName := '';
  FDirectoryToDownload := '';
  FDirListing := '';
  FMaxFileSize := 1024 * 1024 * 4; //4Mb
  FDefaultColor := panTitulo.Color;
  ResetAttention;
  ResetWriting;
  FDigitandoCount := 0;
  bLogAberto := False;
  FGetToUsersBloqueio := False;
  FBuscandoStatusConvidados := False;
  FCarregandoMensagens:= False;
  FEstouNaListaConvidados := False;
  FClosingForm := False;
  FAtualizaStatus := False;

  FConvidados_List := TJSONArray.Create;
  LerConfig;

  // Emojis
  ListBoxEmojis.Font.Name := 'Segoe UI Emoji';
  ListBoxEmojis.Items.AddStrings([
    '😀','😃','😄','😁','😆','😅',
    '😂','🙂','😉','😊','😍','😘',
    '😜','😎','😢','😭','😡','😱',
    '😴','😇','🤩','🥰','😫','🤮',
    '❤️','💔','👍','👎','👌','🙌',
    '👏','⭐','🔥','💡','✔' ,'❌',
    '⚠' ,'⚡','⏰','🍀','📩','📤',
    '📎','📞','🇧🇷','🇺🇲','🇪🇸','💩',
    '👋', '🫡'
  ]);
end;

procedure TfrmChat.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  FClosingForm := True;
  SaindoDaSala;
  ChatClient.Chat_Close(ChatRoom);
  FreeAndNil(ChatLayout);
  FreeAndNil(ConvidadosLayout);
  FreeAndNil(FFile);

  edtLogs.Lines.SaveToFile('chatlog.txt');

  if Assigned(FFilesToSend) then
    SetLength(FFilesToSend, 0);

  if Assigned(FConvidados_List) then
    FConvidados_List.Free;
end;

procedure TfrmChat.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TfrmChat.FormDropFiles(Sender: TObject; const AFileNames: array of string);
// arrastando e soltando os arquivos
var
  P: TPoint;
begin

  // posição do mouse no momento em que os arquivos foram soltos
  P := ScreenToClient(Mouse.CursorPos);

  // Verifica se o controle é a ScrollBox do chat
  if (PtInRect(panChat.BoundsRect, P)) then
    EnviarArquivos(AFileNames);
end;

procedure TfrmChat.FormResize(Sender: TObject);
begin
  if Assigned(panLog) and not FClosingForm then begin
    try
      panLog.Left := Width - 14;
      panLog.Width := Width - 4;
    except
    end;
  end;
end;

procedure TfrmChat.FormShow(Sender: TObject);
const
  OFFSET = 60;
begin
  Randomize;
  Left := (Screen.WorkAreaWidth - Width) div 2 + Random(OFFSET * 2 + 1) - OFFSET;
  Top  := (Screen.WorkAreaHeight - Height) div 2 + Random(OFFSET * 2 + 1) - OFFSET;

  lblStatus.Caption := '';
  FWidth := Width;
  panLog.Left := Width - 14;
  FOldLeft := Left;
  FOldTop := Top;

  IsMinhaSala();
  IdDonoSala();
  btnAdidcionaConvidados.Visible := FIsMinhaSala;
  ConectarFTP;
  EntrandoNaSala;
end;

procedure TfrmChat.Timer1Timer(Sender: TObject);
const
  OFFSET = 40;
begin
  if FClosingForm then Exit;

  // exibe ou esconde a tela de log
  if bAnimarLog then begin
    if AnimarDirecao = -1 then begin
      // exibir Logs
      if (panLog.Left < 200) then AnimarVelocidade := 10;
      if panLog.Left > 4 then
        panLog.Left := panLog.Left - AnimarVelocidade;
      if panLog.Left <= 4 then begin
        panLog.left := 4;
        bAnimarLog := False;
        bLogAberto := True;
      end;
    end else if AnimarDirecao = 1 then begin
      // ocultar Logs
      if (panLog.Left > Self.Width - 200) then AnimarVelocidade := 10;
      if panLog.Left < (Self.Width - 14) then
        panLog.Left := panLog.Left + AnimarVelocidade;
      if panLog.Left >= (Self.Width - 14) then begin
        panLog.Left := Self.Width - 14;
        bAnimarLog := False;
        bLogAberto := False;
      end;
    end;
  end;

  // alguém chamando a atenção
  if FAttention then begin
    if FAttentionSequence = 0 then
      WindowState := wsNormal;

    if (FAttentionPeriod = 1) then begin
      // sacode a tela 8 vezes
      if (FAttentionShakeCount < 8) then begin
        try
          Left := (Screen.WorkAreaWidth - Width) div 2 + Random(OFFSET * 2 + 1) - OFFSET;
          Top  := (Screen.WorkAreaHeight - Height) div 2 + Random(OFFSET * 2 + 1) - OFFSET;
        except
        end;

        FAttentionShakeCount := FAttentionShakeCount + 1;

        if FAttentionShakeCount >= 8 then begin
          // posição original
          Left := FOldLeft;
          Top := FOldTop;
        end;
      end;
    end; // if

    if FAttentionPeriod = 1 then begin
      panTitulo.Color := clRed;
      FAttentionCount := FAttentionCount + 1;
      if FAttentionCount > 14 then begin
        panTitulo.Color := clYellow;
        FAttentionCount := 0;
        FAttentionPeriod := 2;
        FAttentionSequence := FAttentionSequence + 1;
      end;
    end else if FAttentionPeriod = 2 then begin
      FAttentionCount := FAttentionCount + 1;
      if FAttentionCount > 14 then begin
        FAttentionCount := 0;
        FAttentionPeriod := 1;
        FAttentionSequence := FAttentionSequence + 1;
      end;
    end;
    if FAttentionSequence > 8 then begin
      ResetAttention;
    end;
  end; // if FAttention

  // convidado escrevendo
  if FWriting and not bLogAberto then begin
    if FWritingSequence = 0 then begin
      panWriting.Left := panChat.Left + 3;
      panWriting.Top := 459;
      panWriting.Visible := True;
      panWriting.BringToFront;
      panWriting.Refresh;
    end;
    if FWritingPeriod = 1 then begin
      FWritingCount := FWritingCount + 1;
      if FWritingCount > 15 then begin
        panWriting.Visible := False;
        FWritingCount := 0;
        FWritingPeriod := 2;
        FWritingSequence := FWritingSequence + 1;
      end;
    end else if FWritingPeriod = 2 then begin
      FWritingCount := FWritingCount + 1;
      if FWritingCount > 10 then begin
        panWriting.Visible := True;
        FWritingCount := 0;
        FWritingPeriod := 1;
        FWritingSequence := FWritingSequence + 1;
      end;
    end;
    if FWritingSequence > 8 then begin
      ResetWriting;
    end;
  end; // if FWritting
end;

procedure TfrmChat.FTPConnect(aSocket: TLSocket);
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

procedure TfrmChat.FTPControl(aSocket: TLSocket);
// retorno do FTP.SendMessage(... + #13#10)
var
  s: string;
begin
  if FTP.GetMessage(s) > 0 then begin
    edtLogs.Lines.Append(s);

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

procedure TfrmChat.FTPError(const msg: string; aSocket: TLSocket);
begin
  edtLogs.Lines.Append(msg);
  if not FTP.Connected then begin
    DesconectarFTP;
  end;
  FCreateFilePath := '';
  FOpenFilePath := '';
end;

procedure TfrmChat.FTPFailure(aSocket: TLSocket; const aStatus: TLFTPStatus);
begin
  edtLogs.Lines.Append('Failure');
  if aStatus = fsRetr then begin
    FOpenFilePath := '';
    panArquivo.Visible := False;
  end;
end;

procedure TfrmChat.FTPReceive(aSocket: TLSocket);
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
      edtLogs.Lines.Append( FDirListing );

      if FWaitingSize then begin
         FTotalBytes := GetFileTotalBytes( FDirListing );
         FWaitingSize := False;
      end;

      FDirListing := '';
    end;
  end;
end;

procedure TfrmChat.FTPSent(aSocket: TLSocket; const ABytes: Integer);
// upload
begin
  if ABytes > 0 then begin
    Inc(FTransferred, ABytes);
    ProgressBar1.Position := Integer( Round(FTransferred / FTotalBytes * 100) );
  end
  else begin
    FWaitingSize := False;
    DoList(ChatRoom + '*.*');
    Sleep(100);
    SendFile; // próximo arquivo da lista
  end;
end;

procedure TfrmChat.FTPSuccess(aSocket: TLSocket; const aStatus: TLFTPStatus);
begin
  if aStatus = fsRetr then begin
    // download com sucesso, abrir o arquivo ?
    FTransferConcluded := True;
    FCreateFilePath := '';
    panArquivo.Visible := True;
    ProgressBar1.Position := 100;
    ProgressBar1.Refresh;
    Sleep(1000);
    panArquivo.Visible := False;
    CarregarArquivoBaixado( FOpenFilePath );
  end;
end;

procedure TfrmChat.btnChamarAtencaoClick(Sender: TObject);
// pedir atenção aos participamentes da sala
begin
  if not PodeEnviarMensagem() then Exit;
  if ShowMessageQuery(self, 'Pedir atenção','Pedir atenção aos participantes da sala ?','Sim','Não','',icQuestion) <> mrYes then Exit;
  ChamarAtencao;
end;

procedure TfrmChat.btnShowHideClick(Sender: TObject);
begin
  ResizeObjects;
end;

procedure TfrmChat.edtMsgKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
// se estou escrevendo, notifico a todos da sala
begin
  FDigitandoCount := FDigitandoCount + 1;
  if FDigitandoCount > 5 then begin
    FDigitandoCount := 0;
    NotificaDigitacao;
  end;
end;

procedure TfrmChat.lblLogOpenClick(Sender: TObject);
// exibir ou acultar a tela de Logs
begin
  bAnimarLog := True;
  AnimarVelocidade := 120;

  if AnimarDirecao = -1 then begin
    AnimarDirecao := 1;
    lblLogOpen.Hint := 'Exibir';
    lblStatus.Visible := True;
  end
  else begin
    AnimarDirecao := -1;
    lblLogOpen.Hint := 'Ocultar';
    lblStatus.Visible := False;
  end;
end;

procedure TfrmChat.lblLogOpenMouseEnter(Sender: TObject);
begin
  lblLogOpen.Color := clSkyBlue;
end;

procedure TfrmChat.lblLogOpenMouseLeave(Sender: TObject);
begin
  lblLogOpen.Color := clGray;
end;

procedure TfrmChat.lblPanArquivoCloseClick(Sender: TObject);
begin
  panArquivo.Visible := False;
end;

procedure TfrmChat.ListBoxEmojisClick(Sender: TObject);
begin
  edtMsg.Text := edtMsg.Text + ListBoxEmojis.GetSelectedText;
end;

procedure TfrmChat.scrChatResize(Sender: TObject);
// ajusta os elementos dentro do scrollview para ajustá-los
// quando a barra de rolagem surgir
begin
  if FClosingForm then Exit;
  ChatLayout.RecalculateLayout;
end;

procedure TfrmChat.scrConvidadosResize(Sender: TObject);
// ajusta os elementos dentro do scrollview para ajustá-los
// quando a barra de rolagem surgir
begin
  if FClosingForm then Exit;
  ConvidadosLayout.RecalculateLayout;
end;

procedure TfrmChat.btnEnviarMsgClick(Sender: TObject);
begin
  if Trim(edtMsg.Text) = '' then Exit;
  if not PodeEnviarMensagem() then Exit;

  EnviarMensagem(Trim(edtMsg.Text) + ' ', '', '0', '');

  FDigitandoCount := 0;
  edtMsg.Clear;
  edtMsg.SetFocus;
end;

procedure TfrmChat.btnAdidcionaConvidadosClick(Sender: TObject);
// adicionar convidados ao chat
var
  f: TfrmChatUsuarios;
  i, iduser: Integer;
  nome: string;
begin
  if Trim(ListaIDS) = '' then
    ListaIDS := ChatClient.Meu_ID.ToString;

  // abrir a tela para selecionar convidados
  f := TfrmChatUsuarios.Create(Self);
  f.ListaExcluidos := ListaIDS;
  f.ShowModal;

  if f.Selecionou then begin
    // te adiciona como dono do chat
    if scrConvidados.ControlCount < 1 then
      AdicionarConvidado(ChatClient.Meu_ID, ChatClient.Meu_ID, ChatClient.Meu_Nome, 0, usOnline);

    for i := 0 to f.ListaConvidados.Count - 1 do begin
      try
        nome := f.ListaConvidados[i].Split(['|'], TStringSplitOptions.ExcludeEmpty)[0];
        iduser := StrToIntDef( f.ListaConvidados[i].Split(['|'], TStringSplitOptions.ExcludeEmpty)[1], 0 );

        if (iduser > 0) and (iduser <> ChatClient.Meu_ID) then
          AdicionarConvidado(ChatClient.Meu_ID, iduser, nome, 0, usNone);
      except
      end;
    end; // for
  end; // if

  f.Free;

  ConvidadosLayout.RecalculateLayout;

  Sleep(200);

  // lista de convidados
  GetToUsers;

  // busca no servidor, status e quantidade de mensagens não lidas de cada convidado
  Convidados_BuscarStatus;
end;

procedure TfrmChat.btnEnviarArquivoClick(Sender: TObject);
var
  lArquivos: array of String;
  i: integer;
  bOK: Boolean;
begin
  if not PodeEnviarMensagem() then Exit;
  if not FTP.Connected or not FAuthenticated then begin
    ConectarFTP;
    Sleep(100);
  end;

  bOK := False;
  SetLength(lArquivos, 0);

  with OpenDialog1 do begin
    if Execute then
      if (Files.Count > 0) then begin
        SetLength(lArquivos, Files.Count);
        bOK := True;
        for i := 0 to Files.Count - 1 do
          lArquivos[i] := Files[i];
      end;
  end;

  if bOK then
    EnviarArquivos(lArquivos);

  SetLength(lArquivos, 0);
end;

procedure TfrmChat.ConvidadoAlteraStatus(AIdUser: Integer; AStatus: Boolean);
// altera o status (on/off line) do convidado
var
  i: Integer;
  U: TChatUserInfo;
begin
  if AIdUser < 1 then Exit;

  try
    for i := 0 to scrConvidados.ComponentCount - 1 do begin
      U := TChatUserInfo(scrConvidados.Components[i]);
      if U.Usuario_ID = AIdUser then begin
        if AStatus then
          U.Status := usOnline
        else
          U.Status := usOffline;
        Break;
      end;
    end;
  except
  end;
end;

procedure TfrmChat.ConvidadoMsgNaoLidas(AIdUser, AQdeNaoLida: Integer);
// altera msg não lida do convidado
var
  i: Integer;
  U: TChatUserInfo;
begin
  if AIdUser < 1 then Exit;

  try
    for i := 0 to scrConvidados.ComponentCount - 1 do begin
      U := TChatUserInfo(scrConvidados.Components[i]);
      if U.Usuario_ID = AIdUser then begin
        U.UnreadCount := AQdeNaoLida;
        Break;
      end;
    end;
  except
  end;
end;

procedure TfrmChat.DoList(const AFileName: string);
// retorna em DoReceive
// Se AFileName for  vazio, lista os arquivos no FTP Server
// Se AFileName for informado, traz dados específicos do arquivo
// FTP.List('gotify.png') => '-rw-r--r--    1 1003     1004        15750 Jan 18 17:16 gotify.png'
begin
  FDirListing := '';
  FTP.List( AFileName );
end;

procedure TfrmChat.AdicionarCardMessageInicial(ADate: TDateTime);
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

procedure TfrmChat.AdicionarCardMessage(AIdChat, ASenderID: Integer; ASenderName, AMessage: string; ATime: TDateTime; AIsMine, AIsDeleted: Boolean; AStatus: TChatCardMessageStatus);
// adiciona a mensagem na lista
var
  CardMsg: TChatCardMessage;
begin
  if scrChat.ControlCount = 0 then
    AdicionarCardMessageInicial(ATime);

  try
    CardMsg := TChatCardMessage.Create(scrChat);
    CardMsg.Parent := scrChat;
    CardMsg.ImageList := imgIcons20;
    CardMsg.ImageListIndex := 0; // lixeira
    CardMsg.OnClickDeleteMessage := @CHatDeletar;
    CardMsg.CanDelete := AIsMine;
    CardMsg.Setup(AIdChat, ASenderID, ASenderName, AMessage, ATime, AIsMine, AIsDeleted, AStatus);

    ChatLayout.AddCardMessage(CardMsg);
  except
  end;
end;

procedure TfrmChat.AdicionarCardFile(AIdChat: Integer;
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
    CardFile.ImageDeleteList := imgIcons20;  // ícone da lixeira
    CardFile.ImageDeleteListIndex := 0; // lixeira
    CardFile.OnClickDownloadEvent := @CardFileClick;
    CardFile.OnClickDeleteMessage := @CHatDeletar;
    CardFile.CanDelete := AIsMine;
    CardFile.Setup(AIdChat, AFileName, ASize, ATime, AIsMine, ASentBy, AIsDeleted, AStatus);

    ChatLayout.AddCardFile(CardFile);
  except
  end;
end;

procedure TfrmChat.CardFileClick(AChatID: Integer; AArquivo: string; ASize: Int64);
// baixar arquivo clicado no chat
var
 sFile, sArquivo: string;
 t: QWord;
begin
  panArquivo.Visible := False;

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
  lblPanArq1.Caption := 'DOWNLOAD';
  lblPanArq2.Caption := lblPanArq1.Caption;
  lblPanArquivoCount.Caption := '';
  lblPanArquivoNome.Caption  := AArquivo;
  lblPanArquivoSize.Caption  := GetFileSizeText( FTotalBytes );
  ProgressBar1.Position := 0;
  panArquivo.Left := (Self.Width - panArquivo.Width) div 2;

  if FAuthenticated then begin
    panArquivo.Visible := True;
    FCreateFilePath := sFile;
    FDirectoryToDownload := ExtractFileDir(sFile);

    edtLogs.Lines.Append('download: ' + sArquivo);

    // download via FTP - Monitore no evento OnReceive
    FTP.Retrieve( sArquivo );
  end
end;

procedure TfrmChat.ConvidadoClickDelete(AIDUser: Integer; ANomeUser: string);
// remove o convidado do chat
var
  i: integer;
  U: TChatUserInfo;
begin
  Usuario_clicado := AIDUser;

  if ShowMessageQuery(self,'Remover Convidado','Remover o convidado do chat ?' +
                      sLineBreak + sLineBreak + ANomeUser,'Sim','Não','',icQuestion) = mrYes then
  begin
    for i := 0 to scrConvidados.ControlCount - 1 do
      if scrConvidados.Controls[i] is TChatUserInfo then begin
        U := TChatUserInfo(scrConvidados.Controls[i]);

        if U.Usuario_ID = AIDUser then begin
          scrConvidados.RemoveControl(scrConvidados.Controls[i]);
          Break;
        end;
      end; // if

      // lista de convidados em formato JSON
      GetToUsers;
  end; // if ShowMessageQuery
end;

procedure TfrmChat.ConvidadoClickInfo(AIDUser: Integer; ANomeUser: string);
begin
  Usuario_clicado := AIDUser;
end;

procedure TfrmChat.AdicionarConvidado(AIdOwner, AIdUser: Integer; ANome: string; AUnreadCount: Integer; AStatus: TChatUserStatus);
// adiciona um convidado à lista para o chat
var
  u: TChatUserInfo;
begin
  u := TChatUserInfo.Create(scrConvidados);
  u.Parent := scrConvidados;
  u.ImageList := imgIcons20;
  u.ImageListIndex := 0; //lixeira
  u.OnClickInfo := @ConvidadoClickInfo;
  u.OnClickDelete := @ConvidadoClickDelete;
  u.Setup(AIdOwner, AIdUser, ANome, AUnreadCount, AStatus, ChatClient.Meu_ID = AIdOwner);

  ConvidadosLayout.AddConvidado(u);
end;

function TfrmChat.PodeEnviarMensagem(): Boolean;
// precisa ao menos um convidado para enviar Mensagem ou Arquivo
begin
  if FClosingForm then Exit(False);
  if not FEstouNaListaConvidados then begin
    ShowMessageSimple(Self,'Você não está na lista de Convidados do chat!',icWarning);
    Exit(False);
  end;
  if scrConvidados.ComponentCount < 2 then begin
    ShowMessageSimple(Self,'Adicione um Convidado ao chat!',icWarning);
    Exit(False);
  end;
  if not ChatClient.IsConectado() then begin
    ShowMessageSimple(Self,'Você não está conectado no servidor de chat!',icWarning);
    Exit(False);
  end;

  Result := True;
end;

function TfrmChat.GetFileTotalBytes(AData: string): Int64;
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

procedure TfrmChat.ControleElementos(AEnabled: Boolean);
// ativa/destiva elementos conforme exibição do Panel de Upload/Download de arquivos
begin
  scrConvidados.Enabled := AEnabled;
  btnAdidcionaConvidados.Enabled := AEnabled;
  scrChat.Enabled := AEnabled;
  ListBoxEmojis.Enabled := AEnabled;
  edtMsg.Enabled := AEnabled;
  btnEnviarMsg.Enabled := AEnabled;
  btnEnviarArquivo.Enabled := AEnabled;
end;

procedure TfrmChat.LerConfig;
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

procedure TfrmChat.ConectarFTP;
begin
  if FTP.Connected and FAuthenticated then Exit;
  DesconectarFTP;
  FTP.Connect(FServer_Host, FServer_Port);
end;

procedure TfrmChat.DesconectarFTP;
begin
  FTP.Disconnect;
  FConnected := False;
  FAuthenticated := False;
end;

procedure TfrmChat.SendFile;
// envia o arquivo conforme o AIndex
var
  lBytes: Int64;
  sFile, sSize: string;
begin
  if (FFileCurrentIndex < 0) or (Low(FFilesToSend) < 0) or (High(FFilesToSend) < 0) then begin
    panArquivo.Visible := False;
    Exit;
  end;

  if (FCurrentFileName <> '') and (FFileCurrentIndex >= 0) then begin
    // renomeia o arquivo no servidor para vinculá-lo à sala do chat
    FTP.Rename( FCurrentFileName, ChatRoom + '_' + FCurrentFileName );

    // próximo arquivo
    FFileCurrentIndex := FFileCurrentIndex + 1;

    // envia a mensagem com dados do arquivo
    EnviarMensagem('', FCurrentFileName, IntToStr(FFileCurrentSize), GetFileSizeText(FFileCurrentSize));
  end;

  if (FFileCurrentIndex > High(FFilesToSend)) then begin
    FTransferConcluded := True;
    panArquivo.Visible := True;
    ProgressBar1.Position := 100;
    ProgressBar1.Refresh;
    FFileCurrentIndex := -1;
    FCurrentFileName := '';
    FFileCurrentSize := 0;
    Sleep(1000);
    panArquivo.Visible := False;
    FTransferred := 0;
    FTotalBytes := 0;
    Exit;
  end;

  lBytes := GetLocalFileSize( FFilesToSend[FFileCurrentIndex] );
  sSize  := GetFileSizeText( lBytes );
  sFile  := StringReplace( FFilesToSend[FFileCurrentIndex], PathDelim + PathDelim, PathDelim, [rfReplaceAll] );
  FCurrentFileName   := ExtractFileName( sFile );
  FFileCurrentSize   := lBytes;
  lblPanArquivoCount.Caption := Format('%d de %d',[FFileCurrentIndex+1, High(FFilesToSend)+1]);
  lblPanArquivoNome.Caption  := FCurrentFileName;
  lblPanArquivoSize.Caption  := sSize;
  panArquivo.Visible := True;
  panArquivo.Refresh;

  // envia o arquivo - monitore no evento OnSent
  if FTP.Connected then
    FTP.Put( sFile );
end;

function TfrmChat.IsMinhaSala(): Boolean;
// sou o dono/criador da sala ?
begin
  Result := False;

  try
    Result := ( ChatClient.Meu_ID = StrToIntDef( ChatRoom.Split(['-'], TStringSplitOptions.ExcludeEmpty)[0], 0 ) );
  finally
  end;

  FIsMinhaSala := Result;
end;

function TfrmChat.IdDonoSala(): Integer;
// retorna o id do dono/criado da sala
begin
  Result := ChatClient.Meu_ID;

  try
    Result := StrToIntDef( ChatRoom.Split(['-'], TStringSplitOptions.ExcludeEmpty)[0], ChatClient.Meu_ID );
  except
  end;

  FIdDonoSala := Result;
end;

procedure TfrmChat.ResetAttention;
begin
  FAttention := False;
  panTitulo.Color := FDefaultColor;
  FAttentionSequence := 0; //até 10
  FAttentionCount := 0;
  FAttentionPeriod := 1;
  FAttentionShakeCount := 0;
  FOldLeft := Left;
  FOldTop := Top;
end;

procedure TfrmChat.ResetWriting;
begin
  FWriting := False;
  panWriting.Visible := False;
  FWritingSequence := 0; //até 10
  FWritingCount := 0;
  FWritingPeriod := 1;
end;

procedure TfrmChat.ResizeObjects;
// encolhe/espande a janela
var
  ldx: integer;
begin
  ldx := 90;

  if scrConvidados.VertScrollBar.Range > scrConvidados.ClientHeight then
    ldx := ldx + 25;

  if panConvidados.Width > ldx then begin
    // encolhe
    ConvidadosLayout.RecalculateLayout_UserInfo( TChatUserInfoViewMode.vmCompact );
    panConvidados.Tag := 2;
    panConvidados.Width := ldx;
    btnShowHide.ImageIndex := 6;
    lblTituloConvidados.Caption := 'CONV.';
    btnAdidcionaConvidados.Visible := False;
    Width := FWidth - FpanConvidadosWidth + ldx;
    panArquivo.Left := panChat.Left + ((scrChat.Width - panArquivo.Width) div 2);
    btnShowHide.Width := panConvidados.Width;
  end else begin
    // expande
    ConvidadosLayout.RecalculateLayout_UserInfo( TChatUserInfoViewMode.vmExtended );
    btnShowHide.Width := 48;
    panConvidados.Tag := 1;
    btnShowHide.ImageIndex := 5;
    Width := FWidth;
    panConvidados.Width := FpanConvidadosWidth;
    lblTituloConvidados.Caption := 'CONVIDADOS';
    btnAdidcionaConvidados.Visible := FIsMinhaSala;
    panArquivo.Left := (Self.Width - panArquivo.Width) div 2;
  end;

  scrConvidados.Invalidate;
end;

procedure TfrmChat.CarregaListaConvidados(const AStrJson: string);
// carrega a lista de convidados
// {"event":"get_messages","room_name":"%s", "to":[], "messages":[]}
begin
  if Trim(AStrJson) = '' then Exit;
  if RecriarListaConvidados( AStrJson ) then
    AtualizarListaConvidados( AStrJson )
  else
    Convidados_AtualizaStatus( AStrJson, False ); //atualiza status dos convidados da sala
end;

procedure TfrmChat.AtualizarListaConvidados(const AStrJson: string);
// adicionar convidados à lista
var
  AJson: TJSONObject;
  lObj: TJSONObject;
  lArray: TJSONArray;
  i, idOwnerUser, idGuestUser, lguest, total_unread, lQdeUsers: Integer;
  bOnLine: Boolean;
  lStatus: TChatUserStatus;
  user_name: string;
begin
  if AStrJson = '' then Exit;

  try
    AJson  := TJSONObject( GetJSON( AStrJson ) );
    lArray := TJSONArray( AJson.Arrays['to'] );

    ConvidadosLayout.Clear; // limpa a lista de convidados, se houver

    ChatRoom := AJson.Get('room_name', ChatRoom);
    IsMinhaSala();
    idOwnerUser := IdDonoSala();
    btnAdidcionaConvidados.Visible := FIsMinhaSala;
    lQdeUsers := 0;
    FEstouNaListaConvidados := False;

    // exibe os convidados da lista
    for i := 0 to lArray.Count - 1 do begin
      lObj         := TJSONObject( lArray.Items[i] );
      lguest       := lObj.Get('guest', 0); // guest = 0 (dono da sala, convidado = 1)
      idGuestUser  := lObj.Get('to_id', 0);
      user_name    := lObj.Get('to_name', '');
      total_unread := lObj.Get('total_unread', 0);
      bOnLine      := lObj.Get('online', False);

      if (idGuestUser = ChatClient.Meu_ID) then FEstouNaListaConvidados := True;
      if bOnLine then lStatus := usOnline else lStatus := usOffline;

      // adiciona o convidado do chat
      AdicionarConvidado(idOwnerUser, idGuestUser, user_name, total_unread, lStatus);

      lQdeUsers := lQdeUsers + 1;
    end; // for lArray
  finally
    AJson.Free;
  end;

  // Auto-scroll
  scrConvidados.VertScrollBar.Position := scrConvidados.VertScrollBar.Range;

  Sleep(200);

  // lista Json de convidados
  GetToUsers;

  if lQdeUsers > 0 then begin
    if not FIsMinhaSala then begin
      if panConvidados.Tag = 1 then
        ResizeObjects
      else
        ConvidadosLayout.RecalculateLayout_UserInfo( TChatUserInfoViewMode.vmCompact );

      if not FEstouNaListaConvidados then
        ShowMessageSimple(Self, 'Você foi removido da sala!', icWarning);
    end;

    Convidados_BuscarStatus;
  end;
end;

procedure TfrmChat.CarregaListaMensagens(const AStrJson: string);
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
  if (AStrJson = '') or FCarregandoMensagens then Exit;
  FCarregandoMensagens := True;

  try
    AJson := TJSONObject( GetJSON( AStrJson ) );

    ChatLayout.Clear; // limpa a lista de mensagens, se houver

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
  FCarregandoMensagens := False;
end;

procedure TfrmChat.ShowStatus(AMsg: string);
begin
  lblStatus.Caption := FormatDateTime('hh:nn:ss', Now) + ' ' + AMsg;
end;

procedure TfrmChat.Chat_ApagouMensagem(AStrJson: string);
//apagou alguma mensagem ?
var
  CardMsg: TChatCardMessage;
  CardFile: TChatCardFile;
  AJson: TJSONObject;
  i, idchat, from_id: Integer;
  lRoomName, lFileName: string;
  bApagou: Boolean;
begin
  AJson := TJSONObject( GetJSON( AStrJson ) );
  lRoomName := AJson.Get('room_name', '');
  from_id := AJson.Get('from_id', 0);
  idchat := AJson.Get('idchat', 0);
  lFileName := Trim(AJson.Get('file_name', ''));
  bApagou := AJson.Get('deleted', False);

  try
    if bApagou then begin
      for i := 0 to scrChat.ControlCount - 1 do begin
         if scrChat.Controls[i] is TChatCardMessage then begin
           CardMsg := TChatCardMessage( scrChat.Controls[i] );
           if CardMsg.ChatID = idchat then
             CardMsg.Deleted := bApagou;
         end else if scrChat.Controls[i] is TChatCardFile then begin
           CardFile := TChatCardFile(  scrChat.Controls[i] );
           if CardFile.ChatID = idchat then
             CardFile.Deleted := bApagou;
         end;
      end; // for

      // apaga o arquivo no servidor FTP
      if lFileName <> '' then
        FTP.DeleteFile( lRoomName + '_' + lFileName);
    end
    else if (from_id = ChatClient.Meu_ID) then begin
      // não pode marcar a mensagem como deletada
      ShowMessageSimple(Self, 'Não foi possível apagar a mensagem!', icNegative);
    end;
  finally
    AJson.Free;
  end;
end;

procedure TfrmChat.NotificaAlteracaoConvidados;
// notifica aos convidados pela mudança nos integrantes da sala
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );

  if (lTo.Count < 1) then begin
    lTo.Free;
    Exit;
  end;

  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'room_change');
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.ChatEventos(AChatRoom: string; AStrJson: string);
// recebe os eventos do servidor do chat
var
  evento: string;
  AJson: TJSONObject;
begin
  if FClosingForm then Exit;

  if (scrConvidados.ControlCount < 1) or (AStrJson = '') then begin
    ChatClient.GetMessages( AChatRoom );
    Exit;
  end;

  AJson := TJSONObject( GetJSON( AStrJson ) );

  evento := LowerCase( AJson.Get('event', '') );

  if ChatRoom <> AChatRoom then begin
    ChatRoom := AChatRoom;
    IsMinhaSala();
    IdDonoSala();
  end;

  // Se estiver na conversa com FromID, adiciona o balão

  if (evento = 'chat') then begin
    ExibeMensagem( AStrJson );
  end;

  AJson.Free;
end;

procedure TfrmChat.ChatAvisos(AStrJson: string);
// avisos diversos recebidos
var
 evento, msg: string;
 AJson: TJSONObject;
begin
  if FClosingForm then Exit;
  if Trim(AStrJson) = '' then Exit;

  try
    AJson := TJSONObject( GetJSON( AStrJson ) );

    evento := LowerCase( AJson.Get('event', '') );

    if (evento = 'chat_error') and (AJson.Get('from_id', 0) = ChatClient.Meu_ID) then begin
      msg := AJson.Get('message','');
      if msg <> '' then
        ShowMessageSimple(Self, msg, icNegative);
    end
    else if (evento = 'server_down') then begin
      //servidor offline
      ShowStatus( AJson.Get('message', '') );
      Convidados_AtualizaStatusByID(0, usOffline);
    end
    else if (evento = 'server_up') then begin
      //servidor offline
      ShowStatus( AJson.Get('message', '') );
      Convidados_BuscarStatus;
    end
    else if (evento = 'logoff') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_BuscarStatus;
    end
    else if (evento = 'attention') then begin
      // alguém chamando sua atenção
      if (AJson.Get('from_id', 0) <> ChatClient.Meu_ID) and not FAttention then begin
        ResetAttention;
        FAttention := True;
        ShowStatus( Format('%s está pedindo atenção!', [AJson.Get('from_name', '')]) );
      end;
    end
    else if (evento = 'writing') then begin
      if (AJson.Get('from_id', 0) <> ChatClient.Meu_ID) and not FWriting then begin
        ResetWriting;
        FWriting := True;
      end;
    end
    else if (evento = 'connection') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_BuscarStatus;
    end
    else if (evento = 'disconnection') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_BuscarStatus;
    end
    else if (evento = 'disconnected') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_AtualizaStatusByID(AJson.Get('user_id', 0), usOffline);
    end
    else if (evento = 'user_online') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_AtualizaStatusByID(AJson.Get('user_id', 0), usOnline);
    end else if (evento = 'user_offline') then begin
      ShowStatus( AJson.Get('message', '') );
      Convidados_AtualizaStatusByID(AJson.Get('user_id', 0), usOffline);
    end
    else if (evento = 'get_messages') then begin
      CarregaListaConvidados( AStrJson );
      CarregaListaMensagens( AStrJson );
    end
    else if (evento = 'room_enter') then begin
      // alguém entrou na sala do chat / abriu a tela
      if (AJson.Get('from_id',0)<>ChatClient.Meu_ID) then
        ShowStatus( AJson.Get('from_name', '') + ' entrou na sala' );
      Convidados_AtualizaStatusByID(AJson.Get('from_id', 0), usOnline);
    end
    else if (evento = 'room_leave') then begin
      //alguém saiu da sala ou fechou a tela de chat
      if (AJson.Get('from_id',0)<>ChatClient.Meu_ID) then
        ShowStatus( AJson.Get('from_name', '') + ' saiu da sala' );
      Convidados_AtualizaStatusByID(AJson.Get('from_id', 0), usLeave);
    end
    else if (evento = 'chat_delete') then begin
      // deletou uma mensagem do chat ?
      Chat_ApagouMensagem( AStrJson );
    end
    else if (evento = 'room_change') and (AJson.Get('from_id', 0) <> ChatClient.Meu_ID) then begin
      // houve alterações dos integrantes da sala
      AtualizarListaConvidados( AStrJson );
    end
    else if (evento = 'room_guests') then begin
      // lista de usuários da sala, com total de mensagens não lidas e status online/offline
      Convidados_AtualizaStatus( AStrJson, False );
    end;

  finally
    AJson.Free;
  end;
end;

procedure TfrmChat.CHatDeletar(AIdChat: Integer; AFileName: string);
// marcar a mensagem como deletada ?
var
 AJson: TJSONObject;
begin
  if ShowMessageQuery(self, 'Apagar Mensagem','Deseja APAGAR esta mensagem ?','Sim','Não','',icQuestion) <> mrYes then Exit;

  AJson := TJSONObject.Create;

  try
    AJson.Add('event', 'chat_delete');
    AJson.Add('room_name', ChatRoom);
    AJson.Add('from_id', ChatClient.Meu_ID);
    AJson.Add('idchat', AIdChat);
    AJson.Add('file_name', AFileName);

    ChatClient.SendMessage( AJson.AsJSON );
  finally
    AJson.Free;
  end;
end;

procedure TfrmChat.EnviarArquivos(const AFileNames: array of string);
// envia arquivos ao servidor
var
  i, lQdeArquivos: integer;
  s: string;
  lTotalBytes, lBytes: Int64;
  bArquivoInvalido: Boolean;
begin
  panArquivo.Visible := False;
  bArquivoInvalido := False;

  // não aceita arquivos na rede
  for i := Low(AFileNames) to High(AFileNames) do begin
    if ((AFileNames[i]).IndexOf('@') >= 0) or
       ((AFileNames[i]).IndexOf('fish') >= 0) or
       ((AFileNames[i]).IndexOf('//') >= 0)  or
       ((AFileNames[i]).IndexOf('\\') >= 0) then begin
      bArquivoInvalido := True;
      Break;
    end;
  end;

  if bArquivoInvalido then begin
    ShowMessageSimple(Self, 'Arquivos na rede não é permitido!', icWarning);
    Exit;
  end;

  if not FTP.Connected or not FAuthenticated then begin
    ConectarFTP;
    Sleep(100);
  end;

  FTotalBytes  := 0;
  FTransferred := 0;
  FTotalArquivos := 0;
  FTotalArquivosTransferidos := 0;
  FFileCurrentSize := 0;
  FCurrentFileName := '';
  FDirListing := '';

  if not PodeEnviarMensagem() then Exit;

  lTotalBytes  := 0; // somatório de bytes de todos os arquivos
  lQdeArquivos := 4; // máximo de arquivos permitidos por vez

  if (Low(AFileNames) < 0) or (High(AFileNames)+1 > lQdeArquivos) then begin
   ShowMessageSimple(Self, Format('Permitido até %d arquivos!', [lQdeArquivos]), icWarning);
   Exit;
  end;

  // valida o tamanho dos arquivos individualemente
  s := '';

  for i := Low(AFileNames) to High(AFileNames) do begin
    lBytes := GetLocalFileSize( AFileNames[i] );
    lTotalBytes := lTotalBytes + lBytes;

    if (lBytes > FMaxFileSize) then begin
      if s <> '' then s := s + sLineBreak;
      s := s + ExtractFileName( AFileNames[i] ) +
           ' ( ' + GetFileSizeText( lBytes )  + ' )';
    end;
  end;

  if s <> '' then begin
    s := 'Arquivos excedem o tamanho máximo permitido de ' +
          GetFileSizeText( FMaxFileSize ) + sLineBreak + sLineBreak + s;
    ShowMessageSimple(Self, s, icWarning);
    Exit;
  end;

  // tudo ok
  if High(AFileNames)>0 then // mais de um arquivo
    s := Format('Confirma o envio de %d arquivos ?', [High(AFileNames)+1])
  else
    s := 'Confirma o envio do arquivo ?' + sLineBreak + sLineBreak + ExtractFileName(AFileNames[0]);

  if ShowMessageQuery(self, 'Enviar Arquivos',s,'Sim','Não','',icQuestion) <> mrYes then Exit;

  // Vamos enviar os arquivos
  FTotalBytes    := lTotalBytes; // total de bytes dos arquivos
  FTotalArquivos := High(AFileNames) + 1;
  lblPanArq1.Caption := 'UPLOAD';
  lblPanArq2.Caption := lblPanArq1.Caption;
  ProgressBar1.Position := 0;
  panArquivo.Left := (Self.Width - panArquivo.Width) div 2;

  if FAuthenticated then begin
    panArquivo.Visible := True;
    //FFilesToSend := @AFileNames;
    SetLength(FFilesToSend, Length(AFileNames));
    for i := 0 to High(AFileNames) do
      FFilesToSend[i] := AFileNames[i];

    FFileCurrentIndex := 0;
    SendFile;
  end
  else
    ShowMessageSimple(Self, 'Servidor FTP não está pronto!' + sLineBreak + sLineBreak + FFtpErroMsg, icNegative);
end;

function TfrmChat.GetFileSizeText(AValue: Int64): string;
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

function TfrmChat.GetLocalFileSize(const AFileName: string): Int64;
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

procedure TfrmChat.GetToUsers;
// destinatários do chat, contidos na scrollbox (scrConvidados)
var
  i, guest: Integer;
  u: TChatUserInfo;
begin
  if FGetToUsersBloqueio then Exit;

  if Assigned(FConvidados_List) then FConvidados_List.Free;
  FGetToUsersBloqueio := True;
  FEstouNaListaConvidados := False;
  FConvidados_List := TJSONArray.Create;
  OldListaIDS := ListaIDS;
  ListaIDS := '';

  try
    for i := 0 to scrConvidados.ControlCount - 1 do begin
      if scrConvidados.Controls[i] is TChatUserInfo then begin
        u := TChatUserInfo( scrConvidados.Controls[i] );

        if u.IsProprietarioChat then guest := 0 else guest := 1;
        if u.Usuario_ID = ChatClient.Meu_ID then FEstouNaListaConvidados := True;

        FConvidados_List.Add( TJSONObject.Create(['guest', guest,
                                                  'to_id', u.Usuario_ID,
                                                  'to_name', u.Usuario_Nome
                                                 ])
                             ); // add

        // adiciona à uma lista para não selecionar novamente
        if ListaIDS <> '' then ListaIDS := ListaIDS + ',';
        ListaIDS := ListaIDS + u.Usuario_ID.ToString;
      end; // if
    end; // for
  except
  end;

  FGetToUsersBloqueio := False;

  if FIsMinhaSala and (scrChat.ControlCount > 0) and (OldListaIDS <> '') and (OldListaIDS <> ListaIDS) then
    // houve alteração dos convidados, notifica o integrantes
    NotificaAlteracaoConvidados;
end;

procedure TfrmChat.EnviarMensagem(AMessage, AFileName, AFileSize, AFileSizeExt: string);
// enviar a mensagem ao servidor do chat
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );

  if (lTo.Count < 1) then begin
    lTo.Free;
    Exit;
  end;

  if AFileSize = '' then AFileSize := '0';

  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'chat');
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('from_name', ChatClient.Meu_Nome);
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('file_name', AFileName);
    lMsg.Add('file_size', AFileSize);
    lMsg.Add('file_size_ext', AFileSizeExt);
    lMsg.Add('msg', AMessage);
    lMsg.Add('deleted', False);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.ExibeMensagem(const AStrJson: string);
// exibe a mensagem na lista
var
  AJson: TJSONObject;
  idchat, from_id: Integer;
  from_name, msg, file_name, msg_date: string;
  file_size: Int64;
  ldate: TDateTime;
  is_mine, is_deleted: Boolean;
begin
  if (AStrJson = '') or FCarregandoMensagens then Exit;

  FCarregandoMensagens := True;
  AJson := TJSONObject( GetJSON( AStrJson ) );

  try
    // lArray := TJSONArray( AJson.Arrays['to'] );
    // room_name     := AJson.Get('room_name', '');
    // file_size_ext := AJson.Get('file_size_ext', '');

    idchat    := AJson.Get('idchat', 0);
    from_id   := AJson.Get('from_id', 0);
    from_name := AJson.Get('from_name', '');
    msg       := AJson.Get('msg', '');
    file_name := Trim(AJson.Get('file_name', ''));
    file_size := StrToInt64Def('0'+ AJson.Get('file_size', '0'), 0 );
    msg_date  := AJson.Get('msg_date', FormatDateTime('yyyy-mm-dd hh:nn:ss', now));
    ldate     := ISO8601ToDate( msg_date, True );
    is_mine   := (from_id = ChatClient.Meu_ID);
    is_deleted := AJson.Get('deleted', False);

    if not is_mine then ResetWriting;

    if (file_name = '') then // conversa
      AdicionarCardMessage(idchat, from_id, from_name, msg, ldate, is_mine, is_deleted,
                           TChatCardMessageStatus.msRead)
    else // informações de arquivo
      AdicionarCardFile(idchat, file_name, file_size, ldate, is_mine, from_name, is_deleted,
                        TChatCardFileStatus.msRead);
  finally
    AJson.Free;
  end;

  // Auto-scroll
  scrChat.VertScrollBar.Position := scrChat.VertScrollBar.Range;
  FCarregandoMensagens := False;
end;

procedure TfrmChat.NotificaDigitacao;
// notifica aos membros da sala que estou digitando
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  if not ChatClient.IsConectado() then Exit;

  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );

  if (lTo.Count < 1) then begin
    lTo.Free;
    Exit;
  end;

  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'writing');
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('from_name', ChatClient.Meu_Nome);
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.ChamarAtencao;
// chama a atenção dos membros da sala
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  if not ChatClient.IsConectado() then Exit;

  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );

  if (lTo.Count < 1) then begin
    lTo.Free;
    Exit;
  end;

  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'attention');
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('from_name', ChatClient.Meu_Nome);
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.EntrandoNaSala;
// notifica sua entrada na sala aos membros
var
  lMsg: TJSONObject;
begin
  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'room_enter');
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('from_name', ChatClient.Meu_Nome);
    lMsg.Add('room_name', ChatRoom);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.SaindoDaSala;
// notifica sua saída da sala aos membros
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );

  if (lTo.Count < 1) then begin
    lTo.Free;
    Exit;
  end;

  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'room_leave');
    lMsg.Add('from_id', ChatClient.Meu_ID);
    lMsg.Add('from_name', ChatClient.Meu_Nome);
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;
end;

procedure TfrmChat.Convidados_AtualizaStatus(AStrJson: string; AValidarConvidados: Boolean);
// lista de usuários da sala, com total de mensagens não lidas e status online/offline
var
  i: Integer;
  U: TChatUserInfo;
begin
  if Trim(AStrJson) = '' then Exit;

  while FAtualizaStatus do
    Application.ProcessMessages;

  FAtualizaStatus := True;

  if AValidarConvidados then begin
    // verifica se precisa recriar a lista de convidados
    if RecriarListaConvidados( AStrJson ) then
      AtualizarListaConvidados( AStrJson );

    FAtualizaStatus := False;
    Exit;
  end;

  if scrConvidados.ComponentCount > 0 then begin
    for i := 0 to scrConvidados.ComponentCount - 1 do begin
      try
        U := TChatUserInfo( scrConvidados.Components[i] );
        U.AJustaInformacoes( AStrJson );
      except
      end; // try
    end; // for
  end; // if

  FAtualizaStatus := False;
end;

procedure TfrmChat.Convidados_AtualizaStatusByID(AIdUser: Integer; AStatus: TChatUserStatus);
// atualiza o status online/offline do convidado
var
  i: Integer;
  U: TChatUserInfo;
begin
  while FAtualizaStatus do
    Application.ProcessMessages;

  FAtualizaStatus := True;

  if scrConvidados.ComponentCount > 0 then begin
    for i := 0 to scrConvidados.ComponentCount - 1 do begin
      try
        U := TChatUserInfo( scrConvidados.Components[i] );
        if (U.Usuario_ID = AIdUser) or (AIdUser = 0) then begin
          U.Status := AStatus;
          if (AIdUser > 0) then Break;
        end;
      except
      end; // try
    end; // for
  end; // if

  FAtualizaStatus := False;
end;

procedure TfrmChat.Convidados_BuscarStatus;
// Pega a lista de convidados no servidor com com total de mensagens não lidas e status online/offline
var
  lMsg: TJSONObject;
  lTo: TJSONArray;
begin
  if FBuscandoStatusConvidados then Exit;
  if FConvidados_List.Count < 1 then Exit;

  FBuscandoStatusConvidados := True;
  lTo := TJSONArray( GetJSON( FConvidados_List.AsJSON ) );
  lMsg := TJSONObject.Create;

  try
    lMsg.Add('event', 'room_guests');
    lMsg.Add('room_name', ChatRoom);
    lMsg.Add('to', lTo);

    ChatClient.SendMessage( lMsg.AsJSON );
  finally
    lMsg.Free;
  end;

  FBuscandoStatusConvidados := False;
end;

function TfrmChat.RecriarListaConvidados(AStrJson: string): Boolean;
// verifica se a lista de convidados precisa ser recriada
var
  AJson: TJSONObject;
  lArrayTo: TJSONArray;
  i, j: Integer;
  bRecriar: Boolean;
begin
  if (Trim(AStrJson) = '') then Exit(False);
  if (scrConvidados.ControlCount < 1) then Exit(True);

  bRecriar := False;

  try
    AJson := TJSONObject( GetJSON( AStrJson ) );
    lArrayTo := TJSONArray( AJson.Arrays['to'] );

    if (lArrayTo.Count > 0) then begin
      bRecriar := True;
      if (lArrayTo.Count = scrConvidados.ControlCount) then begin
        // verificamos se são os mesmos convidados ou se houve alterações
        for i := 0 to lArrayTo.Count -1 do begin
          bRecriar := True;
          for j := 0 to FConvidados_List.Count -1 do begin
            try
              if TJSONObject( FConvidados_List[j] ).Get('to_id', 0) = TJSONObject( lArrayTo[i] ).Get('to_id', -1) then begin
                bRecriar := False;
                Break;
              end;
            except
            end;
          end; // for  j
        end; // for i
      end; // if
    end; // lArrayTo
  finally
    AJson.Free;
  end;

  Result := bRecriar;
end;

procedure TfrmChat.CarregarArquivoBaixado(AFilePath: string);
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

end.


unit Util.CEP;

// Acesso ao serviço CEP

{
  WINDOWS requer as seguintes DLLs
    libeay32.dll
    ssleay32.dll
    libssl-3.dll
}

{
Exemplo de uso

uses
  Util.CEP;

procedure Form1.btnCepClick(Sender: TObject);
var
  cep: TUtilCep;
  txt: string;
  cor: TColor;
begin
  LimparCampos;
  btnCep.Enabled := False;
  txt := lblCep.Caption;
  cor := lblCep.Font.Color;
  lblCep.Font.Color := clRed;
  lblCep.Caption := txt + ' (Pesquisando) ';

  cep := TUtilCep.Create( StrToIntDef(edtCep.Text, 0) );

  while cep.IsSearching do
    Application.ProcessMessages;

  lblCep.Font.Color := cor;
  lblCep.Caption := txt;

  if cep.Success then begin
    edtEndereco.Text    := cep.Logradouro;
    edtComplemento.Text := cep.Complemento;
    edtCidade.Text      := cep.Cidade;
    edtUF.Text          := cep.UF_Sigla;
    edtBairro.Text      := cep.Bairro;
    edtDDD.Text         := cep.DDD;
    edtIbge.Text        := cep.IBGE;
    edtSiafi.Text       := cep.SIAFI;
    edtGia.Text         := cep.GIA;
    edtRegiao.Text      := cep.Regiao;
  end
  else
    ShowMessage( cep.GetMessage );

  cep.Free;
  btnCep.Enabled := True;
end;
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser,
  fphttpclient, ssockets, openssl, opensslsockets;

type
  { ThreadCep }

  ThreadCep = class(TThread)
    ExecuteProcedure: procedure of object;
    ReturnProcedure: procedure of object;
    protected
      procedure Execute; override;
    private
      procedure ChamaCallBack;
    public
      constructor Create(CreateSuspended: boolean);
  end;

  { TUtilCep }

  TUtilCep = class
  private
    FMessage: string;
    FJsonResult: string;
    FIsSearching: Boolean;
    FCEP: Integer;

    //retorno
    FBairro: string;
    FCidade: string;
    FComplemento: string;
    FSuccess: Boolean;
    FUnidade: string;
    FDDD: string;
    FIBGE: string;
    FLogradouro: string;
    FRegiao: string;
    FSIAFI: string;
    FUF_Nome: string;
    FUF_Sigla: string;
    FGIA: string;

    procedure ApiCEP;
    procedure RetornoCEP;
  public
    constructor Create(ACEP: Integer);
    destructor Destroy; override;
    property IsSearching: Boolean read FIsSearching;
    property Success: Boolean read FSuccess;
    property GetMessage: string read FMessage;
    property Logradouro: string read FLogradouro;
    property Complemento: string read FComplemento;
    property Unidade: string read FUnidade;
    property Bairro: string read FBairro;
    property Cidade: string read FCidade;
    property UF_Sigla: string read FUF_Sigla;
    property UF_Nome: string read FUF_Nome;
    property DDD: string read FDDD;
    property IBGE: string read FIBGE;
    property SIAFI: string read FSIAFI;
    property GIA: string read FGIA;
    property Regiao: string read FRegiao;

  end;

implementation

{ ThreadCep }

constructor ThreadCep.Create(CreateSuspended: boolean);
// use o .Start para iniciar a thead e não precisa usar o .Free
begin
  FreeOnTerminate := True;
  inherited Create(CreateSuspended);
end;

procedure ThreadCep.Execute;
// executa o código em segundo plano
begin
  // chama a procedure onde o código em background será executado
  ExecuteProcedure;

  // chama o callback que irá consumir os dados processados
  Synchronize(@ChamaCallBack);
end;

procedure ThreadCep.ChamaCallBack;
// exibe os dados no form
begin
  // retorna o controle para a procedure onde o resultado será consumido
  ReturnProcedure;
end;

{ TUtilCep }


constructor TUtilCep.Create(ACEP: Integer);
var
  et: ThreadCep;
begin
  FCEP := ACEP;
  FIsSearching := True;
  FSuccess := False;
  FMessage := '';
  et := ThreadCep.Create(True);
  et.ExecuteProcedure := @ApiCEP;
  et.ReturnProcedure  := @RetornoCEP;
  et.Start;
end;

destructor TUtilCep.Destroy;
begin
  inherited Destroy;
end;

procedure TUtilCep.ApiCEP;
// Obtém o resultado a partir da API da viacep
// ACEP: Número do cep, ex 14781260
var
  httpClient: TFPHTTPClient;
begin
  FJsonResult := '';

  if (FCEP < 1) or (FCEP > 99999999) then begin
    FSuccess := False;
    FMessage := 'CEP inválido!';
    Exit;
  end;

  httpClient := TFPHTTPClient.Create(nil);

  try
    try
      // Adicionar cabeçalho user-agent para evitar bloqueio de requisições
      httpClient.AddHeader('User-Agent', 'Mozilla/5.0');
      FJsonResult := httpClient.Get('https://viacep.com.br/ws/'+ RightStr('00000000' + IntToStr(FCEP), 8) + '/json');
      FSuccess := (Length(FJsonResult) > 0);
    except
      on e: ESocketError do begin
        FSuccess := False;
        FJsonResult := '';
        FMessage := e.Message;
      end;
      on e: Exception do begin
        FSuccess := False;
        FJsonResult := '';
        FMessage := e.Message;
      end;
    end;

  finally
    httpClient.Free;
  end;
end;

procedure TUtilCep.RetornoCEP;
var
  lobj: TJSONData;
  lJson: TJSONObject;
begin
  if Length(FJsonResult) > 0 then begin
     FMessage  := '';

     try
       try
         lobj  := GetJSON( FJsonResult ); //será liberado da memória em lJson.Free
         lJson := TJSONObject( lobj );

         FLogradouro  := lJson.Get('logradouro', '');
         FComplemento := lJson.Get('complemento', '');
         FUnidade     := lJson.Get('unidade', '');
         FBairro      := lJson.Get('bairro', '');
         FCidade      := lJson.Get('localidade', '');
         FUF_Sigla    := lJson.Get('uf', '');
         FUF_Nome     := lJson.Get('estado', '');
         FRegiao      := lJson.Get('regiao', '');
         FIBGE        := lJson.Get('ibge', '');
         FGIA         := lJson.Get('gia', '');
         FDDD         := lJson.Get('ddd', '');
         FSIAFI       := lJson.Get('siafi', '');

         FSuccess     := (FLogradouro <> '');

         if not FSuccess then
           FMessage := 'CEP não encontrado!';
       except
         on E: Exception do
           FMessage := E.Message;
       end;
     finally
       FJsonResult := '';
       lJson.Free;
     end;
  end;

  FIsSearching := False;
end;

end.


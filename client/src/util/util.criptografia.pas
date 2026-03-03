unit Util.Criptografia;

// Aldo Marcio Soares - ams2kg@gmail.com - 05/2025

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, base64, BlowFish;

// Pode ser necessário instalar a biblioteca DCPcrypt (tem no online package)

type

  { TCriptografa }

  TCriptografa = class
    private
      FKey: string;
    public
      constructor Create(ASecretKey: string = 'key@secret9');
      function Encrypt(AValueToEncrypt: string): string;
      function Decrypt(AValueToDecrypt: String): string;
      function Encrypt64(AValueToEncrypt: string): string;
      function Decrypt64(AValueToDecrypt: String): string;
      class function EncryptString(const s:string): string;
      class function DecryptString(const s:string): string; 
  end;

implementation

{ TCriptografa }

constructor TCriptografa.Create(ASecretKey: string);
begin
  if Trim(ASecretKey) <> '' then
    FKey := ASecretKey;
end;

function TCriptografa.Encrypt(AValueToEncrypt: string): string;
//criptografa a string em AValue
var
  en: TBlowFishEncryptStream;
  s1: TStringStream;
begin
  s1 := TStringStream.Create('');
  en := TBlowFishEncryptStream.Create(FKey, s1);
  en.WriteAnsiString( AValueToEncrypt );
  en.Free;
  Result := s1.DataString;
  s1.Free;
end;

function TCriptografa.Decrypt(AValueToDecrypt: String): string;
//descriptografa a string em AValue
var
  de: TBlowFishDeCryptStream;
  s1: TStringStream;
begin
  s1 := TStringStream.Create( AValueToDecrypt );
  de := TBlowFishDeCryptStream.Create(FKey, s1);

  try
    Result := de.ReadAnsiString;
  except
    Result := AValueToDecrypt;
  end;

  de.Free;
  s1.Free;
end;

function TCriptografa.Encrypt64(AValueToEncrypt: string): string;
//criptografa uma string em base64
begin
  Result := EncodeStringBase64( AValueToEncrypt );
end;

function TCriptografa.Decrypt64(AValueToDecrypt: String): string;
//descriptografa uma string criptografada em base64
begin
  Result := DecodeStringBase64( AValueToDecrypt );
end;

// simple xor encrypt
class function TCriptografa.EncryptString(const s:string): string;
var
  i: Integer;
begin
  result := '';
  for i:=1 to Length(s) do
    result := result + chr(ord(s[i]) xor 21);
end;

class function TCriptografa.DecryptString(const s:string): string;
begin
  result := EncryptString(s);
end;

end.


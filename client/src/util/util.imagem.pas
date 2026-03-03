unit Util.Imagem;    
    
{ 
 Created by Topazzio at 2025-12-24 10:53:27
 Developed by Aldo Márcio Soares  |  ams2kg@gmail.com  |  CopyLeft 2025
} 

// Manipulação de imagens (foto) para banco de dados
// Requer o Package BGRABitmapPack
    
{$mode ObjFPC}{$H+}    
    
interface    
    
uses    
  Classes, SysUtils, Controls, Graphics, ExtCtrls, ZDataset, SQLDB, DB, Math,  
  LCLType, // HBitmap type   
  IntfGraphics, // TLazIntfImage type   
  fpImage, // TFPColor type    
  FPReadJpeg, FPWriteJpeg, // jpg support   
  FPImgCanv, FPWritePNG,
  BGRABitmap, BGRABitmapTypes, BGRAGraphics; { Requer o pacote BGRABitmapPack }

  //https://wiki.freepascal.org/BGRABitmap_tutorial

type    
    
  { TUtilImagem }    
    
  TUtilImagem = class
  public
    { TZQuery: Converte a imagem (BLOB) do banco de dados para bitmap para o TImage }
    class procedure GetImage(var AImage: TImage; AQuery: TZQuery; const AFieldName: string);
    { TZQuery: Converte o bitmap do TImage para Stream para salvar no banco de dados }
    class procedure GetStream(AImage: TImage; var AQuery: TZQuery; const AFieldName: string);
    { TSQLQuery: Converte a imagem (BLOB) do banco de dados para bitmap para o TImage }
    class procedure GetImageSQLQuery(var AImage: TImage; AQuery: TSQLQuery; const AFieldName: string);
    { TSQLQuery: Converte o bitmap do TImage para Stream para salvar no banco de dados }
    class procedure GetStreamSQLQuery(AImage: TImage; var AQuery: TSQLQuery; const AFieldName: string);
    { Altera o tamanho do TImage }
    class procedure ResizeImagem(var AImage: TImage; w, h: Integer);
    { Retorna um bitmap com as dimenões indicadas, a partir do TImage }
    class function ResizeBitmap(var AImage: TImage; w, h: Integer): TBitmap;
    { Altera o tamanho do TImage }
    class procedure ResizeToImageBox(var AImage: TImage);
    { Cria uma avatar a partir do Timage }
    class procedure CreateAvatarFromImage(var AImage: TImage; ADestSize: Integer );
    { Cria um avatar a partir de uma arquivo para o TImage }
    class procedure CreateAvatarFromFile(var AImage: TImage; ASourcePath: string; ADestSize: integer);
    { Adiciona borda circular à imagem }
    class procedure AvatarBorder(var AImage: TImage; ABorderColor: TColor; ABorderWidth: Integer = 4);
  end;
    
implementation    
    
{ TUtilImagem }    

class procedure TUtilImagem.GetImage(var AImage: TImage; AQuery: TZQuery; const AFieldName: string);
//pega a imagem do zquery e joga no TImage
var
  Stream: TMemoryStream;
  Png: TPortableNetworkGraphic;
begin
  AImage := TImage.Create(nil);
  AImage.Picture := nil;

  if not AQuery.FieldByName(AFieldName).IsNull then begin
    //carrega a foto
    Stream := TMemoryStream.Create;
    Png := TPortableNetworkGraphic.Create;

    try
      TBlobField(AQuery.FieldByName(AFieldName)).SaveToStream(Stream);
      Stream.Position := 0;

      if Stream.Size > 0 then begin
        try
          Png.LoadFromStream(Stream);
          AImage.Picture.Assign(Png);
        except //FPImageException - Wrong image format (não é png)
          begin
            TBlobField(AQuery.FieldByName(AFieldName)).SaveToStream(Stream);
            Stream.Position := 0;
            if Stream.Size > 0 then
              AImage.Picture.Bitmap.LoadFromStream(Stream);
          end;
        end;

        AImage.Transparent := True;
      end;
    finally
      Png.Free;
      Stream.Free;
    end;
  end;
end;

class procedure TUtilImagem.GetStream(AImage: TImage; var AQuery: TZQuery; const AFieldName: string);
// converte a imagem do TImage para Stream e carrega no zquery para salvar no banco de dados
var
  Stream: TMemoryStream;
  Source, Resized, Mask: TBGRABitmap;
  MinSide, DestSize: integer;
  CropRect: TRect;
begin
  //joga a foto no stream
  Stream := TMemoryStream.Create;
  Source := TBGRABitmap.Create;

  try
    Source.Assign(AImage.Picture.Graphic);
    DestSize := AImage.Picture.Bitmap.Width;

    //Crop Quadrado
    MinSide := Source.Width;
    if Source.Height < MinSide then MinSide := Source.Height;
    CropRect := Rect((Source.Width - MinSide) div 2, (Source.Height - MinSide) div 2,
                     ((Source.Width - MinSide) div 2) + MinSide, ((Source.Height - MinSide) div 2) + MinSide);

    //Redimensionar
    Resized := Source.GetPart(CropRect) as TBGRABitmap;
    BGRAReplace(Resized, Resized.Resample(DestSize, DestSize));

    //Máscara Circular
    Mask := TBGRABitmap.Create(DestSize, DestSize, BGRAPixelTransparent);
    Mask.FillEllipseAntialias(DestSize/2, DestSize/2, DestSize/2, DestSize/2, BGRAWhite);
    Resized.ApplyMask(Mask);

    //SALVAR DIRETO NO STREAM EM PNG
    Resized.SaveToStreamAsPNG(Stream);
    Stream.Position := 0;
    AQuery.ParamByName(AFieldName).LoadBinaryFromStream(Stream);

    Mask.Free;
    Resized.Free;
  finally
    Source.Free;
  end;
end;
  
class procedure TUtilImagem.GetImageSQLQuery(var AImage: TImage; AQuery: TSQLQuery; const AFieldName: string);  
//pega a imagem do sqlquery e jogo no TImage  
var  
  Stream: TMemoryStream;
  Png: TPortableNetworkGraphic;
begin  
  AImage := TImage.Create(nil);  
  AImage.Picture := nil; 
 
  if not AQuery.FieldByName(AFieldName).IsNull then begin  
    //carrega a foto  
    Stream := TMemoryStream.Create;
    Png := TPortableNetworkGraphic.Create;

    try  
      TBlobField(AQuery.FieldByName(AFieldName)).SaveToStream(Stream);
      Stream.Position := 0;

      if Stream.Size > 0 then begin
        try
          Png.LoadFromStream(Stream);
          AImage.Picture.Assign(Png);
        except //FPImageException - Wrong image format (não é png)
          begin
            TBlobField(AQuery.FieldByName(AFieldName)).SaveToStream(Stream);
            Stream.Position := 0;
            if Stream.Size > 0 then
              AImage.Picture.Bitmap.LoadFromStream(Stream);
          end;
        end;

        AImage.Transparent := True;
      end;
    finally
      Png.Free;
      Stream.Free;  
    end;  
  end;  
end;  
  
class procedure TUtilImagem.GetStreamSQLQuery(AImage: TImage; var AQuery: TSQLQuery; const AFieldName: string);  
// converte a imagem do TImage para Stream e carrega no sqlquery  
var  
  Stream: TMemoryStream;
  Source, Resized, Mask: TBGRABitmap;
  MinSide, DestSize: integer;
  CropRect: TRect;
begin  
  //joga a foto no stream  
  Stream := TMemoryStream.Create;
  Source := TBGRABitmap.Create;

  try
    Source.Assign(AImage.Picture.Graphic);
    DestSize := AImage.Picture.Bitmap.Width;

    //Crop Quadrado
    MinSide := Source.Width;
    if Source.Height < MinSide then MinSide := Source.Height;
    CropRect := Rect((Source.Width - MinSide) div 2, (Source.Height - MinSide) div 2,
                     ((Source.Width - MinSide) div 2) + MinSide, ((Source.Height - MinSide) div 2) + MinSide);

    //Redimensionar
    Resized := Source.GetPart(CropRect) as TBGRABitmap;
    BGRAReplace(Resized, Resized.Resample(DestSize, DestSize));

    //Máscara Circular
    Mask := TBGRABitmap.Create(DestSize, DestSize, BGRAPixelTransparent);
    Mask.FillEllipseAntialias(DestSize/2, DestSize/2, DestSize/2, DestSize/2, BGRAWhite);
    Resized.ApplyMask(Mask);

    //SALVAR DIRETO NO STREAM EM PNG
    Resized.SaveToStreamAsPNG(Stream);
    Stream.Position := 0;
    AQuery.ParamByName(AFieldName).LoadFromStream(Stream, ftBlob);

    Mask.Free;
    Resized.Free;
  finally
    Source.Free;
  end;
end;

class procedure TUtilImagem.ResizeImagem(var AImage: TImage; w, h: Integer);    
//redimensiona a imagem    
var    
  newBitmap: TBitmap;    
begin    
  if AImage.Picture.Bitmap.Width > 0 then begin    
    newBitmap := TBitmap.Create; 
    try 
      newBitmap.Canvas.Brush.Color := clWhite; 
      newBitmap.PixelFormat := pf24bit; 
      newBitmap.SetSize(w, h); 
 
      // Desenha a imagem original redimensionada dentro do novo bitmap 
      newBitmap.Canvas.StretchDraw( Rect(0, 0, w, h), AImage.Picture.Graphic ); 
      AImage.Picture := nil; 
      AImage.Picture.Bitmap.Assign(newBitmap); 
    finally 
      newBitmap.Free; 
    end; 
  end;    
end;    
    
class procedure TUtilImagem.ResizeToImageBox(var AImage: TImage);    
//ajusta a imagem para o tamanho do TImage    
var    
  newBitmap: TBitmap;    
begin    
  if AImage.Picture.Bitmap.Width > 0 then 
  begin 
    newBitmap := TBitmap.Create; 
    try 
      newBitmap.Canvas.Brush.Color := clWhite; 
      newBitmap.PixelFormat := pf24bit; 
      newBitmap.SetSize(AImage.ClientWidth, AImage.ClientHeight); 
      newBitmap.Canvas.StretchDraw( AImage.ClientRect, AImage.Picture.Graphic ); 
      AImage.Picture := nil; 
      AImage.Picture.Bitmap.Assign(newBitmap); 
    finally 
      newBitmap.Free; 
    end; 
  end;    
end;   
   
class function TUtilImagem.ResizeBitmap(var AImage: TImage; w, h: Integer): TBitmap;   
//cria uma imagem com as dimensões indicadas   
begin   
  Result := TBitmap.Create;   
  if AImage.Picture.Bitmap.Width > 0 then begin   
    Result.Canvas.Brush.Color := clWhite;   
    Result.PixelFormat := pf24bit;   
    Result.SetSize(w, h);   
    Result.Canvas.StretchDraw( AImage.ClientRect, AImage.Picture.Graphic );   
  end;   
end;   

class procedure TUtilImagem.CreateAvatarFromImage(var AImage: TImage; ADestSize: Integer);
//cria um avatar da imagem, no tamanho informado
//Requer o pacote BGRABitmapPack
var
  Source, Resized, Mask: TBGRABitmap;
  MinSide: integer;
  CropRect: TRect;
  lArqruivo: string;
begin
  if (AImage.Picture.Graphic = nil) or (AImage.Picture.Graphic.Empty) then Exit;

  Source := TBGRABitmap.Create;
  lArqruivo := ExtractFileDir(ParamStr(0)) + PathDelim + 'avatar0.png';

  try
    // Captura a imagem atual do TImage
    Source.Assign(AImage.Picture.Graphic);

    //Calcular o corte quadrado centralizado (para não achatar a imagem)
    MinSide := Source.Width;
    if Source.Height < MinSide then MinSide := Source.Height;

    CropRect := Rect((Source.Width - MinSide) div 2,
                     (Source.Height - MinSide) div 2,
                     ((Source.Width - MinSide) div 2) + MinSide,
                     ((Source.Height - MinSide) div 2) + MinSide);

    //Extrai o quadrado e redimensiona para o tamanho final desejado
    Resized := Source.GetPart(CropRect) as TBGRABitmap;
    Resized.ResampleFilter := rfBestQuality; // Garante alta velocidade/qualidade
    BGRAReplace(Resized, Resized.Resample(ADestSize, ADestSize));

    //Cria a máscara circular com Antialiasing
    Mask := TBGRABitmap.Create(ADestSize, ADestSize, BGRAPixelTransparent);

    // Desenha um elipse preenchido (círculo) na cor opaca
    Mask.FillEllipseAntialias(ADestSize/2, ADestSize/2, ADestSize/2, ADestSize/2, BGRAWhite);

    //Aplica a máscara (Multiplica o canal Alpha)
    Resized.ApplyMask(Mask);

    Resized.SaveToFile(lArqruivo);
    AImage.Picture := nil;
    AImage.Picture.LoadFromFile(lArqruivo);
    AImage.Transparent := True;
    //Resized.Draw(AImage.Picture.Bitmap.Canvas, 0, 0, True); //desenha direto no TImage
    //AImage.Picture.Bitmap.Assign( TBitmap(Resized.Bitmap) );

    Mask.Free;
    Resized.Free;

    try
      if FileExists(lArqruivo) then
        DeleteFile(lArqruivo);
    except
    end;
  finally
    Source.Free;
  end;
end;

class procedure TUtilImagem.CreateAvatarFromFile(var AImage: TImage; ASourcePath: string; ADestSize: integer);
//cria uma avatar da imagem de uma arquivo
var
  Source, Resized, Mask: TBGRABitmap;
  bmp: TBitmap;
  Png: TPortableNetworkGraphic;
  MinSide: integer;
  CropRect: TRect;
  lArqruivo: string;
begin
  // Carrega a imagem original
  Source := TBGRABitmap.Create(ASourcePath);
  lArqruivo := ExtractFileDir(ParamStr(0)) + PathDelim + 'avatar0.png';

  try
    //Calcular o corte quadrado centralizado (para não achatar a imagem)
    MinSide := Source.Width;
    if Source.Height < MinSide then MinSide := Source.Height;

    CropRect := Rect((Source.Width - MinSide) div 2,
                     (Source.Height - MinSide) div 2,
                     ((Source.Width - MinSide) div 2) + MinSide,
                     ((Source.Height - MinSide) div 2) + MinSide);

    //Extrai o quadrado e redimensiona para o tamanho final desejado
    Resized := Source.GetPart(CropRect) as TBGRABitmap;
    Resized.ResampleFilter := rfBestQuality; // Garante alta velocidade/qualidade
    BGRAReplace(Resized, Resized.Resample(ADestSize, ADestSize));

    //Cria a máscara circular com Antialiasing
    Mask := TBGRABitmap.Create(ADestSize, ADestSize, BGRAPixelTransparent);

    // Desenha uma elipse preenchida (círculo) na cor opaca
    Mask.FillEllipseAntialias(ADestSize/2, ADestSize/2, ADestSize/2, ADestSize/2, BGRAWhite);

    //Aplica a máscara (Multiplica o canal Alpha)
    Resized.ApplyMask(Mask);

    //Modo 1 - Transferência para o AImage
    //Resized.SaveToFile(lArqruivo);
    //AImage.Picture.LoadFromFile(lArqruivo);

    //Modo 2 - Transferência para o AImage
    //Resized.Draw(AImage.Picture.Bitmap.Canvas, 0, 0, True); //desenha direto no TImage

    //Modo 3 - Transferência para o AImage
    //bmp := Resized.MakeBitmapCopy(clWhite, True);
    //AImage.Picture.Bitmap.Assign(bmp);
    //bmp.Free;

    //Modo 4 - Transferência para o AImage
    // Converte de volta para o TImage via PNG
    Png := TPortableNetworkGraphic.Create;
    try
      Png.Assign(Resized);
      AImage.Picture.Assign(Png);
      AImage.Transparent := True;
    finally
      Png.Free;
    end;

    Mask.Free;
    Resized.Free;

    try
      if FileExists(lArqruivo) then
        DeleteFile(lArqruivo);
    except
    end;
  finally
    Source.Free;
  end;
end;

class procedure TUtilImagem.AvatarBorder(var AImage: TImage; ABorderColor: TColor; ABorderWidth: Integer);
//aplica borda na imagem
var
  lw, lh: Integer;
begin
  lw := AImage.Picture.Bitmap.Width;
  lh := AImage.Picture.Bitmap.Height;

  with AImage.Canvas do begin
    AntialiasingMode := amOn;
    Pen.Style := psSolid;
    Pen.Width := ABorderWidth;
    Pen.Color := ABorderColor;
    Brush.Style := bsClear;
    Ellipse(0, 0, lw, lh);
  end;
end;

end.    
   


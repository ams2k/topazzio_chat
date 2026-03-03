unit ChatLayoutManager;

(*
  Controle de objetos nas ScrollBox
  Aldo Márcio Soares | ams2kg@gmail.com | 2025-12-31
*)

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Forms, SysUtils, Controls, ExtCtrls,
  ChatCardMessage, ChatCardFile, ChatUserInfo, ChatUserSelect, ChatCardInfo;

type

  { TChatLayoutManager }

  TChatLayoutManager = class
  private
    FScrollBox: TScrollBox;
    FNextTop: Integer;
    FMargin: Integer;
    FSpacing: Integer;
    FPercent: Double;
    FLimpando: Boolean;
  public
    constructor Create(AScrollBox: TScrollBox);
    destructor Destroy; override;

    procedure Clear;
    procedure AddCardMessage(ACard: TChatCardMessage);
    procedure AddCardFile(ACardFile: TChatCardFile);
    procedure AddConvidado(AUserInfo: TChatUserInfo);
    procedure AddUserSelect(AUserSelect: TChatUserSelect);
    procedure AddCardRoom(AChatCardInfo: TChatCardInfo);
    procedure RecalculateLayout(AScrollDown: Boolean = True);
    procedure RecalculateLayout_UserInfo(AViewMode: TChatUserInfoViewMode);
  end;

implementation

{ TChatLayoutManager }

constructor TChatLayoutManager.Create(AScrollBox: TScrollBox);
begin
  FScrollBox := AScrollBox;
  FMargin  := 4;
  FSpacing := 6;
  FPercent := 0.75; //limita tamanho do balão de mensagem
  FNextTop := FMargin;
  FLimpando:= False;
end;

destructor TChatLayoutManager.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TChatLayoutManager.Clear;
var
  i: Integer;
begin
  if not Assigned(FScrollBox) then Exit;
  if FScrollBox.ControlCount <= 0 then Exit;
  FLimpando := True;

  try
    for i := FScrollBox.ControlCount - 1 downto 0 do
      FScrollBox.Controls[i].Free;
  except
  end;

  FNextTop := FMargin;
  FLimpando:= False;
end;

procedure TChatLayoutManager.AddCardMessage(ACard: TChatCardMessage);
//balão da mensagem
begin
  if not Assigned(FScrollBox) then Exit;

  ACard.Parent := FScrollBox;
  ACard.Top := FNextTop;

  if ACard.IsInitialDate then
    ACard.Left := (FScrollBox.ClientWidth - ACard.Width) div 2
  else begin
    if ACard.IsMine then
      ACard.Left := FScrollBox.ClientWidth - ACard.Width - FMargin
    else
      ACard.Left := FMargin;
  end;

  Inc(FNextTop, ACard.Height + FSpacing);
end;

procedure TChatLayoutManager.AddCardFile(ACardFile: TChatCardFile);
//balão do arquivo anexo
begin
  if not Assigned(FScrollBox) then Exit;

  ACardFile.Parent := FScrollBox;
  ACardFile.Top := FNextTop;

  if ACardFile.IsMine then
    ACardFile.Left := FScrollBox.ClientWidth - ACardFile.Width - FMargin
  else
    ACardFile.Left := FMargin;

  Inc(FNextTop, ACardFile.Height + FSpacing);
end;

procedure TChatLayoutManager.AddConvidado(AUserInfo: TChatUserInfo);
//balão do convidado
begin
  if not Assigned(FScrollBox) then Exit;

  AUserInfo.Parent := FScrollBox;
  AUserInfo.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
  AUserInfo.Top  := FNextTop;
  AUserInfo.Left := FMargin;

  Inc(FNextTop, AUserInfo.Height + FSpacing);
end;

procedure TChatLayoutManager.AddUserSelect(AUserSelect: TChatUserSelect);
//objeto da seleção de convidado na lista
begin
  if not Assigned(FScrollBox) then Exit;

  AUserSelect.Parent := FScrollBox;
  AUserSelect.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
  AUserSelect.Top  := FNextTop;
  AUserSelect.Left := FMargin;

  Inc(FNextTop, AUserSelect.Height + FSpacing);
end;

procedure TChatLayoutManager.AddCardRoom(AChatCardInfo: TChatCardInfo);
// card de mensagens não lidas/rooms
begin
  if not Assigned(FScrollBox) then Exit;

  AChatCardInfo.Parent := FScrollBox;
  AChatCardInfo.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
  AChatCardInfo.Top  := FNextTop;
  AChatCardInfo.Left := FMargin;

  Inc(FNextTop, AChatCardInfo.Height + FSpacing);
end;

procedure TChatLayoutManager.RecalculateLayout(AScrollDown: Boolean);
//ajusta os elementos dentro do scrollview quando há
//resize do scrollview/barra de rolagem aparece
var
  i: Integer;
  CardMsg: TChatCardMessage;
  CardFile: TChatCardFile;
  UserInfo: TChatUserInfo;
  UserSelect: TChatUserSelect;
  CardRooms: TChatCardInfo;
begin
  if not Assigned(FScrollBox) then Exit;
  if FScrollBox.ControlCount < 1 then Exit;
  if FLimpando then Exit;

  FNextTop := FMargin;

  try
    for i := 0 to FScrollBox.ControlCount - 1 do begin

      { TChatCardMessage }

      if FScrollBox.Controls[i] is TChatCardMessage then begin
        CardMsg := TChatCardMessage( FScrollBox.Controls[i] );
        CardMsg.CalculateSize;
        CardMsg.Top := FNextTop;

        if CardMsg.IsInitialDate then
          CardMsg.Left := (FScrollBox.ClientWidth - CardMsg.Width) div 2
        else begin
          if CardMsg.IsMine then
            CardMsg.Left := FScrollBox.ClientWidth - CardMsg.Width - FMargin
          else
            CardMsg.Left := FMargin;
        end;

        Inc(FNextTop, CardMsg.Height + FSpacing);
      end

      { TChatCardFile }

      else if FScrollBox.Controls[i] is TChatCardFile then begin
        CardFile := TChatCardFile( FScrollBox.Controls[i] );
        CardFile.CalculateSize;
        CardFile.Top := FNextTop;

        if CardFile.IsMine then
          CardFile.Left := FScrollBox.ClientWidth - CardFile.Width - FMargin
        else
          CardFile.Left := FMargin;

        Inc(FNextTop, CardFile.Height + FSpacing);
      end

      { TChatUserInfo }

      else if FScrollBox.Controls[i] is TChatUserInfo then begin
        UserInfo := TChatUserInfo( FScrollBox.Controls[i] );
        UserInfo.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
        UserInfo.Top  := FNextTop;
        UserInfo.Left := FMargin;

        Inc(FNextTop, UserInfo.Height + FSpacing);
      end

      { TChatCardInfo }

      else if FScrollBox.Controls[i] is TChatCardInfo then begin
        CardRooms := TChatCardInfo( FScrollBox.Controls[i] );
        CardRooms.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
        CardRooms.Top  := FNextTop;
        CardRooms.Left := FMargin;

        Inc(FNextTop, CardRooms.Height + FSpacing);
      end

      { TChatUserSelect }

      else if FScrollBox.Controls[i] is TChatUserSelect then begin
        UserSelect := TChatUserSelect( FScrollBox.Controls[i] );
        UserSelect.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
        UserSelect.Top  := FNextTop;
        UserSelect.Left := FMargin;

        Inc(FNextTop, UserSelect.Height + FSpacing);
      end;
    end; //for

    // Auto-scroll
    if AScrollDown then
      FScrollBox.VertScrollBar.Position := FScrollBox.VertScrollBar.Range;
  except
  end;
end;

procedure TChatLayoutManager.RecalculateLayout_UserInfo(AViewMode: TChatUserInfoViewMode);
//ajusta os elementos dentro do scrollview quando há
//resize do scrollview/barra de rolagem aparece
var
  i: Integer;
  UserInfo: TChatUserInfo;
begin
  if not Assigned(FScrollBox) then Exit;
  if FScrollBox.ControlCount < 1 then Exit;

  FNextTop := FMargin;

  try
    for i := 0 to FScrollBox.ControlCount - 1 do begin

      if FScrollBox.Controls[i] is TChatUserInfo then begin
        UserInfo := TChatUserInfo(FScrollBox.Controls[i]);
        UserInfo.ViewMode := AViewMode;
        UserInfo.Constraints.MaxWidth := FScrollBox.ClientWidth - (FMargin * 2 + 2);
        UserInfo.Top  := FNextTop;
        UserInfo.Left := FMargin;

        Inc(FNextTop, UserInfo.Height + FSpacing);
      end;

    end; //for

    // Auto-scroll
    FScrollBox.VertScrollBar.Position := FScrollBox.VertScrollBar.Range;
  except
  end;
end;

end.


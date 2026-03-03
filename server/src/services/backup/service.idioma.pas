unit Service.Idioma;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TUtilIdioma }

  TUtilIdioma = class
    public
      class function EncerrandoServidor_Msg1(ALang: string): string;
      class function EncerrandoServidor_Msg2(ALang: string): string;
      class function EncerrandoServidor_Msg3(ALang: string): string;

      class function DoRun_Thanks(ALang: string): string;
      class function DoRun_Msg1(ALang: string): string;
      class function DoRun_Msg2(ALang: string): string;
      class function DoRun_Msg3(ALang: string): string;
      class function DoRun_Msg4(ALang: string): string;
      class function DoRun_Msg5(ALang: string): string;
      class function DoRun_Msg6(ALang: string): string;

      class function OnAccept_Msg1(ALang: string): string;

      class function OnDisconnect_Msg1(ALang: string): string;
      class function OnDisconnect_Msg2(ALang: string): string;

      class function OnReceive_Msg1(ALang: string): string;
      class function OnReceive_Msg2(ALang: string): string;

      class function Evento_Login_Msg1(ALang: string): string;
      class function Evento_Login_Msg2(ALang: string): string;
      class function Evento_Login_Msg3(ALang: string): string;
      class function Evento_Login_Msg4(ALang: string): string;

      class function Evento_Logout_Msg1(ALang: string): string;
      class function Evento_Logout_Msg2(ALang: string): string;

      class function Evento_Chat_Msg1(ALang: string): string;

      class function Help_Msg1(ALang: string): string;
      class function Help_Msg2(ALang: string): string;
      class function Help_Msg3(ALang: string): string;

      class function ServiceMensagem_Msg1(ALang: string): string;
      class function ServiceMensagem_Msg2(ALang: string): string;
      class function ServiceMensagem_Msg3(ALang: string): string;
      class function ServiceMensagem_Msg4(ALang: string): string;

  end;

implementation

{ TUtilIdioma }

class function TUtilIdioma.EncerrandoServidor_Msg1(ALang: string): string;
begin
  Result := 'Encerrando servidor do chat...';
  if ALang = 'en' then Result := 'Closing chat server...';
  if ALang = 'es' then Result := 'Cerrando servidor de chat...';
end;

class function TUtilIdioma.EncerrandoServidor_Msg2(ALang: string): string;
begin
  Result := 'O servidor está sendo desligado agora.';
  if ALang = 'en' then Result := 'The server is shutting down now.';
  if ALang = 'es' then Result := 'El servidor se está cerrando ahora.';
end;

class function TUtilIdioma.EncerrandoServidor_Msg3(ALang: string): string;
begin
  Result := 'Servidor do chat terminou! < q >';
  if ALang = 'en' then Result := 'Chat server has ended! <q>';
  if ALang = 'es' then Result := '¡El servidor de chat ha finalizado! <q>';
end;

class function TUtilIdioma.DoRun_Thanks(ALang: string): string;
begin
  Result := '==[ Lazarus / Free Pascal ]==';
end;

class function TUtilIdioma.DoRun_Msg1(ALang: string): string;
begin
  Result := 'Erro ao iniciar servidor: %s na porta %d';
  if ALang = 'en' then Result := 'Error starting server: %s on port %d';
  if ALang = 'es' then Result := 'Error al iniciar el servidor: %s en el puerto %d';
end;

class function TUtilIdioma.DoRun_Msg2(ALang: string): string;
begin
  Result := 'Servidor Topazzio Chat pronto!';
  if ALang = 'en' then Result := 'Topazzio Chat server ready!';
  if ALang = 'es' then Result := '¡El servidor de chat Topazzio está listo!';
end;

class function TUtilIdioma.DoRun_Msg3(ALang: string): string;
begin
  Result := 'Database Conectado';
  if ALang = 'en' then Result := 'Connected Database';
  if ALang = 'es' then Result := 'Base de datos conectada';
end;

class function TUtilIdioma.DoRun_Msg4(ALang: string): string;
begin
  Result := 'Database Erro: ';
  if ALang = 'en' then Result := 'Database Error:';
  if ALang = 'es' then Result := 'Error de base de datos:';
end;

class function TUtilIdioma.DoRun_Msg5(ALang: string): string;
begin
  Result := 'LOG ativado para motivos de DEBUG';
  if ALang = 'en' then Result := 'LOG enabled for DEBUG reasons.';
  if ALang = 'es' then Result := 'LOG habilitado por razones de depuración.';
end;

class function TUtilIdioma.DoRun_Msg6(ALang: string): string;
begin
  Result := 'Pressione ''q'' para parar o servidor';
  if ALang = 'en' then Result := 'Press ''q'' to stop server';
  if ALang = 'es' then Result := 'Presione ''q'' para detener el servidor';
end;

class function TUtilIdioma.OnAccept_Msg1(ALang: string): string;
begin
  Result := 'Cliente conectado: %s';
  if ALang = 'en' then Result := 'Connected client: %s';
  if ALang = 'es' then Result := 'Cliente conectado: %s';
end;

class function TUtilIdioma.OnDisconnect_Msg1(ALang: string): string;
begin
  Result := 'Usuário < %s - %s > desconectou.';
  if ALang = 'en' then Result := 'User < %s - %s > disconnected.';
  if ALang = 'es' then Result := 'Usuario < %s - %s > desconectado.';
end;

class function TUtilIdioma.OnDisconnect_Msg2(ALang: string): string;
begin
  Result := 'Cliente desconectado: %s';
  if ALang = 'en' then Result := 'Client disconnected: %s';
  if ALang = 'es' then Result := 'Cliente desconectado: %s';
end;

class function TUtilIdioma.OnReceive_Msg1(ALang: string): string;
begin
  Result := '{"event":"error","message":"Servidor sendo finalizado"}';
  if ALang = 'en' then Result := 'Server being terminated.';
  if ALang = 'es' then Result := 'Servidor siendo terminado.';
end;

class function TUtilIdioma.OnReceive_Msg2(ALang: string): string;
begin
  Result := 'JSON inválido';
  if ALang = 'en' then Result := 'Invalid JSON';
  if ALang = 'es' then Result := 'JSON no válido';
end;

class function TUtilIdioma.Evento_Login_Msg1(ALang: string): string;
begin
  Result := 'Usuário < %s > efetuou login';
  if ALang = 'en' then Result := 'User <%s> logged in';
  if ALang = 'es' then Result := 'El usuario <%s> ha iniciado sesión';
end;

class function TUtilIdioma.Evento_Login_Msg2(ALang: string): string;
begin
  Result := 'está online';
  if ALang = 'en' then Result := 'is online';
  if ALang = 'es' then Result := 'está en línea';
end;

class function TUtilIdioma.Evento_Login_Msg3(ALang: string): string;
begin
  Result := 'Login efetuado com sucesso';
  if ALang = 'en' then Result := 'Login successful.';
  if ALang = 'es' then Result := 'Inicio de sesión exitoso.';
end;

class function TUtilIdioma.Evento_Login_Msg4(ALang: string): string;
begin
  Result := 'Login já existe em outra instância';
  if ALang = 'en' then Result := 'Login already exists in another instance';
  if ALang = 'es' then Result := 'El inicio de sesión ya existe en otra instancia.';
end;

class function TUtilIdioma.Evento_Logout_Msg1(ALang: string): string;
begin
  Result := 'está offline';
  if ALang = 'en' then Result := 'It''s offline.';
  if ALang = 'es' then Result := 'Está fuera de línea.';
end;

class function TUtilIdioma.Evento_Logout_Msg2(ALang: string): string;
begin
  Result := 'Logoff efetuado com sucesso';
  if ALang = 'en' then Result := 'Logoff successful.';
  if ALang = 'es' then Result := 'Cierre de sesión exitoso.';
end;

class function TUtilIdioma.Evento_Chat_Msg1(ALang: string): string;
begin
  Result := 'Não foi possível distribuir sua mensagem';
  if ALang = 'en' then Result := 'It was not possible to distribute your message';
  if ALang = 'es' then Result := 'No fue posible distribuir su mensaje';
end;

class function TUtilIdioma.Help_Msg1(ALang: string): string;
begin
  Result := 'Exibe o LOG para debug';
  if ALang = 'en' then Result := 'Displays the LOG for debugging.';
  if ALang = 'es' then Result := 'Muestra el REGISTRO para la depuración.';
end;

class function TUtilIdioma.Help_Msg2(ALang: string): string;
begin
  Result := 'Idioma de retorno das mensagens. Opções: [br, en, es]';
  if ALang = 'en' then Result := 'Message return language. Options: [br, en, es]';
  if ALang = 'es' then Result := 'Idioma de respuesta del mensaje. Opciones: [br, en, es]';
end;

class function TUtilIdioma.Help_Msg3(ALang: string): string;
begin
  Result := 'Idioma: ';
  if ALang = 'en' then Result := 'Language: ';
  if ALang = 'es' then Result := 'Idioma: ';

  Result := Result + ALang + '. --lang=[br, en, es]';
end;

class function TUtilIdioma.ServiceMensagem_Msg1(ALang: string): string;
begin
  Result := 'Não está conectado ao servidor!';
  if ALang = 'en' then Result := 'Not connected to the server!';
  if ALang = 'es' then Result := '¡No conectado al servidor!';
end;

class function TUtilIdioma.ServiceMensagem_Msg2(ALang: string): string;
begin
  Result :=  'Nova mensagem cadastrada do sucesso';
  if ALang = 'en' then Result := 'New message registered as successful';
  if ALang = 'es' then Result := 'Nuevo mensaje registrado como exitoso';
end;

class function TUtilIdioma.ServiceMensagem_Msg3(ALang: string): string;
begin
  Result :=  'Mensagem atualizada com sucesso';
  if ALang = 'en' then Result := 'Message updated successfully.';
  if ALang = 'es' then Result := 'Mensaje actualizado exitosamente.';
end;

class function TUtilIdioma.ServiceMensagem_Msg4(ALang: string): string;
begin
  Result :=  'Mensagem excluída com sucesso';
  if ALang = 'en' then Result := 'Message successfully deleted';
  if ALang = 'es' then Result := 'Mensaje eliminado exitosamente';
end;

end.


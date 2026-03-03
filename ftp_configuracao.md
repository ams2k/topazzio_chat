# Configurar servidor FTP no Linux

###1) sudo pacman -S vsftpd

###2) sudo useradd -m -d /srv/ftp/ftpchat -s /usr/bin/nologin ftpchat

-m → cria a pasta <br>
-d /srv/ftp/ftpuser → diretório onde os arquivos ficarão<br>
nologin → impede acesso SSH (mais seguro)

###3) sudo passwd ftpchat

pwd: chat123456

###4) Permissões

sudo chown ftpchat:ftpchat /srv/ftp/ftpchat<br>
sudo chmod 755 /srv/ftp/ftpchat <br>

###5) Configurar o ftp server

sudo nano /etc/vsftpd.conf

listen=YES <br>
listen_ipv6=NO <br>

anonymous_enable=NO <br>
local_enable=YES<br>
write_enable=YES<br>

local_umask=022

chroot_local_user=YES<br>
allow_writeable_chroot=YES<br>

user_sub_token=$USER<br>
local_root=/srv/ftp/$USER<br>

pam_service_name=vsftpd

xferlog_enable=YES

###6) Monitorar o ftp

sudo journalctl -u vsftpd -e

###7) 530 Login incorrect.

Verifique se 'nologin' está listado em /etc/shells

cat /etc/shells

echo /usr/bin/nologin | sudo tee -a /etc/shells

grep nologin /etc/shells


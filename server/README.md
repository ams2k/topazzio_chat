# TOPAZZIO CHAT

## Firewall

A PORTA do Servidor do Chat precisa estar liberada no firewall<br>
para que os clientes consigam conectar-se.

Exemplo: Porta padrão do servidor: 9022 (TCP)

- No Windows:

  Painel de Controle -> Firewall do Windows
 

- No Linux:

  Para liberar a porta no firewall:

  sudo ufw allow 9022/tcp
  
  ou
  
  sudo firewall-cmd --add-port=9022/tcp --permanent
  
  sudo firewall-cmd --reload
  
 Verificação:
 
  ss -ltnp | grep 9022

  ou

  netstat -tuln | grep 9022

  Se aparecer algo assim, é porque deu certo:

  LISTEN 0.0.0.0:9022
    
  
## Fonte de Emoji compatível com Linux e Windows

-- NotoColorEmoji.ttf

https://github.com/googlefonts/noto-emoji


### Linux

- Ubuntu / Debian / Mint

sudo apt install fonts-noto-color-emoji

- Arch / Manjaro

sudo pacman -S noto-fonts-emoji

- Fedora

sudo dnf install google-noto-emoji-color-fonts

### Windows

Tanto Windows quanto Linux.

https://github.com/googlefonts/noto-emoji


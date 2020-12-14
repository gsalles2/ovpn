# OVPN INSTALL

Versão: 3.9
Autor: Gabriel Salles

## OVPN Server - ( OpenVPN Server )

O OVPN-INSTALL é um script para instalação e configuração do OpenVPN Server em servidores Linux. 

Este script não descarta o conhecimento prévio da aplicação, uma vez que será realizado uma série de questionamentos durante a instalação sobre a configuração do servidor. 

O script serve apenas para automatizar a criação dos certificados, instalação de binários e configuração dos arquivos de configuração do servidor bem como dos usuários. 

#### Funcionalidades:

* Server Client-to-Site
* Utilitário de configuração dos usuários
* Monitoramento dos acessos.
* Criação dos Certificados e Arquivos


### Instalação

Entre como root ou execute como sudo os próximos passos:

1. Dê permissão de execução para o script:

			#chmod a+x ovpn-install.sh

**OBS: Caso deseje alterar o padrão de configuração do OpenVPN, bem como sua rede local, rede usada na VPN, servidor DNS, porta padrão, etc, por favor EDITAR AS CONFIGURAÇÕES NO SCRIPT!**

2. Execute o script: 
			.\ovpn-install.sh

3. Selecione a opção desejada.

4. Insira o IP da interface a qual o cliente irá se comunicar com o servidor.

5. Será gerado os certificados e gerado o arquivo .conf na pasta definida dentro do arquivo ovpn.d/ovpn.cfg.

5. Será necessário realizar a abertura da porta de comunicação com o servidor no firewall da máquina. Por padrão a porta é 1194/udp.
Ela poderá ser alterada modificando o arquivo ovpn.d/ovpn.cfg.

### Utilitário OVPN-USER

O utilitário ovpn-user, foi criado para facilitar a criação de usuário.
Execução:
			#ovpn-user -a usuario

Menu:
	-a - Adiciona um usuário
	-p - Altera a senha de um usário
	-r - Remove um usuário
	-v - Versão
	-h - Menu de ajuda
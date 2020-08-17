# OVPN INSTALL

Versão: 1.5
Autor: Gabriel Salles

## OVPN Server - ( OpenVPN Server )

O OVPN-INSTALL é um script para instalação e configuração do OpenVPN Server.
Este script não descarta o conhecimento prévio da aplicação, uma vez que será realizado uma série de questionamentos durante a instalação sobre a configuração do servidor.
O script serve apenas para automatizar a criação dos certificados, instalação de binários e configuração dos arquivos de configuração do servidor bem como dos usuários.

#### Funcionalidades:

Versão 1.5:

* Server Client-to-Site
* Utilitário ovpn-user -> Cria credência e certificados OpenVPN para os usuários e monitora a utilização

#### TODO

Versão 1.6:

* Adicionar ao arquivo .ovpn os certificados.
* Adicionar o ovpn-user dentro do ovpn-install e criar links automaticamente durante a instalação.

Versão 2.0:

* Criação do ovpn-server -> Monitorar o uso, consumo e logs do servidor
* Instalador Site-to-Site -> Oferecer funcionabilidade na instalação a configuração Site-to-Site

Agora sim vamos ao que interessa, a instalação:

### OVPN SERVER 

Faça download ou clone o diretorio git.

Entre como root ou execute como sudo os próximos passos:

1. Dê permissão de execução para o script:

	'#chmod a+x ovpn-install.sh'

'''
#### **OBS: Caso deseje alterar o padrão de configuração do OpenVPN, bem como sua rede local, rede usada na VPN, servidor DNS, porta padrão, etc
			por favor EDITAR AS CONFIGURAÇÕES NO SCRIPT!**
'''

2. Execute o script:
	'.\ovpn-install.sh'

3. Insira o IP Público ou DNS ao qual o cliente irá se comunicar com o servidor.
4. Será gerado os certificados e instalado os serviços necessários.

	Caso não sejam encontrados, será instalado os binários:
	yum install openvpn
	yum install lzo

5. Ao final irá informar o último procedimento necessário que é a adição da regra de liberação no firewall.

### OVPN USER

O utilitário ovpn-user, é utilizado para a criação de usuário para acesso a VPN, bem como seus certificados.
O arquivo deve ser colocado, para melhor proveito, na pasta /etc/openvpn/ e criado um link para /sbin/.

Criando o link:
	'#ln /etc/openvpn/ovpn-user.sh /sbin'

Após isto, ele irá executar como um comando do Linux.

Segue as funções do script:

Menu:
	-a - Adiciona um usuÃ¡rio
	-p - Altera a senha de um usuÃ¡rio
	-r - Remove um usuÃ¡rio
	-v - Versão
	-h - Menu de ajuda


Mais funções estão sendo adicionadas e bugs sendo resolvidos.

Versionamento:

2.1
Adição da opção -v como versão
Procurar atualização do script ovpn-user no servidor.

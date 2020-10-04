#!/bin/bash


# ARQUIVOS DE CONFIGURAÇÃO

source /etc/openvpn/ovpn.d/ovpn.cfg

# VARIABLES

versao="2.9"


#
##
### FUNÇÕES
##
#

ConIpServer(){

	echo "
	Edite o arquivo $0
	Altere o conteúdo da varialvel \"\$SERVIDOR\"
	para o endereço IP ou DNS do servidor que deseja.
	"
}
ConPortServer(){
	echo "
	Edite o arquivo $0
	Altere o conteudo da variavel \"\$PORTA\"
	para a porta do servidor que deseja
	"
}

EMPRESA(){
	echo "
	Edite o arquivo $0
	Altere o conteudo da variavel \"\$EMPRESA\"
	para o cliente que deseja.
	"
}

#
##
### Testes Iniciais
##
#

[[ -z $SERVIDOR ]]&& ConIpServer && exit 1
[[ -z $PORTA ]]&& ConPortServer && exit 1
[[ -z $EMPRESA ]]&& EMPRESA && exit 1


if [ $(id -u) == 0 ]; then		# Validação se é um usuário privilegiado


	[[ -e /sbin/ovpn-user ]]|| ln $PWD/$0 /sbin/ovpn-user

case $1 in

	-a)

	[[ -r $PKEYS ]]|| echo "Sem acesso a pasta $PKEYS"
	[[ -r $PKEYS/ca.crt ]]|| echo "Certificado ca.crt não encontrado ou sem permissão de leitura - pasta $PKEYS/ca.crt"
	ovpnca=$(cat $PKEYS/ca.crt)

	[[ -r $PKEYS/ta.key ]]|| echo "Chave ta.key não encontrada ou sem permissão de leitura - pasta $PKEYS/ta.key"
	ovpnta=$(cat $PKEYS/ta.key)
	
	[[ -r $PKEYS/server.crt ]]|| echo "Certificado server.crt não encontrado ou sem permissão de leitura - pasta $PKEYS/server.crt"

	#
##
### INICIO DO SCRIPT
##
#

	usuario="$2"
	echo "

	Empresa: $EMPRESA
	Usuário: $usuario 
	
	"

	$(mkdir $USERTEMP)
	echo -n "
	
	Insira a senha do usuário: "
	read senha
	
	echo "

	## Iniciando processos"
	
	$($SSL genrsa -out $USERTEMP/$usuario.key 2048)
	ovpnkey=$(cat $USERTEMP/$usuario.key)			# Chave do arquivo .ovpn
	echo ".:Gerando chave privada:."
	
	$($SSL req -new -key $USERTEMP/$usuario.key -out $USERTEMP/$usuario.csr -subj "/C=BR/ST=Rio_de_Janeiro/L=Rio_de_Janeiro/O='$ORGANIZACAO'/OU='$EMPRESA'/CN=$usuario/emailAddress='$EMAIL'")
	echo ".:Gerado arquivo CSR:."


	$($SSL x509 -req -days 7300 -in $USERTEMP/$usuario.csr -CA $PKEYS/ca.crt -CAkey $PKEYS/ca.key -out $USERTEMP/$usuario.crt)
	ovpncrt=$(cat $USERTEMP/$usuario.crt)			# Certificado do usuário para o arquivo .ovpn
	echo "	.:Gerado Certificado do usuÃ¡rio:."
	
	$(useradd -s /usr/sbin/nologin -M $usuario)		# Criação do usuário no arquivo passwd sem /home
	echo "	.:Usuário criado:."
	

	$(chown $usuario:users $USERTEMP/$usuario.*)
	echo "	.:Permissões adicionadas:."
	
	echo "	.:Gerando arquivo OVPN:."

$(echo "client
remote $SERVIDOR
dev tun
proto $PROTOCOLO
nobind
pull
port $PORTA
comp-lzo
verb 3
auth-user-pass
key-direction 1

<ca>
$ovpnca
</ca>

<cert>
$ovpncrt
</cert>

<key>
$ovpnkey
</key>

<tls-auth>
$ovpnta
</tls-auth>


" > $UKEYS/$usuario.ovpn)

	echo -n "
	Gerar arquivo ZIP? 
	(s)Sim | (n)Não   :"
	read opcao
	
	if [ $opcao == "s" ];then
		cd $UKEYS
		$(zip $usuario.zip $usuario.ovpn)
		$(chown $usuario $UKEYS/$usuario.zip)
	else
		continue
	fi
	
	$(rm -f $USERTEMP/$usuario.*)
	clear
	
	usuario=$2
	echo "
			=======
			ATENÇÃO
			=======
	
	EMPRESA: $EMPRESA
	USUÁRIO: $usuario
	SENHA: $senha
	ARQUIVOS OVPN: $UKEYS/$usuario.zip
	"

;;
	-p)
	
	echo -n "
	Insira a nova senha:"
	read senha
	echo -n "
	Insira novamente a senha:"
	read csenha
	[[ "senha" == "csenha" ]]&& $(echo "$senha:$usuario" | chpasswd)
;;
	-r)
	usuario=$2
	
	#
	##
	### Teste para tentativa de remoção do Certificado Raiz
	##
	#

	if [ "$usuario" == "ca"];then
	echo "
	USUÁRIO NÃO PERMITIDO
"
	$(logger -p 13.1 "Tentativa de exclusão de Certificados Raiz - OpenVPN")
	exit 1
	fi
	echo -n "

	DESEJA REMOVER O USUARIO [ $usuario ]"
	read confirmacao
	if [ "$confirmacao" == "s" ]; then
	
	echo " .:Removendo configuracoes do OPENVPN:."
	$(rm -i -f $USERTEMP/$usuario.*)
	echo " .:Removendo conta do Sistema:."
	$(userdel -r $usuario)
	echo "
	USUARIO $usuario REMOVIDO COM SUCESSO
"
else
	echo"
	Usuario $usuario, nao excluido!
"	
fi
;;
	-c)while :;do

clear

sleep 3
done

;;
	-v)echo "Versão: $versao"

;;
	-h)echo "
	
	Menu:
	-a - Adiciona um usuário
	-p - Altera a senha de um usuário
	-r - Remove um usuário
	-v - Versão
	-h - Menu de ajuda
	
	ex: #ovpn-user -a usuario.teste
	ex: #ovpn-user -v
	ex: #ovpn-user -r usuario.teste
"
	;;
	*) echo "

	Menu:
	-a - Adiciona um usuário
	-p - Altera a senha de um usuário
	-r - Remove um usuário
	-v - Valida os usuário ativos
	-h - Menu de ajuda

"

	;;
esac

#
##
### SE NAO FOR ROOT OU SUDO
##
#

else
	clear
	echo "

	USUARIO [ $(whoami) ] NÃO POSSUI PRIVILÉGIOS
	POR FAVOR ENTRE COM UM USUÁRIO ADMINISTRADOR

	"
fi

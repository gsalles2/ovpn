#!/bin/bash


# ARQUIVOS DE CONFIGURAÇÃO

source ovpn.cfg

# VARIABLES

versao="2.8"


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

	[[ -r $UKEYS ]]|| echo "Sem acesso a pasta $UKEYS"
	[[ -r $UKEYS/ca.crt ]]|| echo "Certificado ca.crt não encontrado ou sem permissÃ£o de leitura - pasta $UKEYS/ca.crt"
	ovpnca=$(cat $UKEYS/ca.crt)

	[[ -r $UKEYS/ta.key ]]|| echo "Chave ta.key não encontrada ou sem permissÃ£o de leitura - pasta $UKEYS/ta.key"
	ovpnta=$(cat $UKEYS/ta.key)
	
	[[ -r $UKEYS/server.crt ]]|| echo "Certificado server.crt não encontrado ou sem permissão de leitura - pasta $UKEYS/server.crt"

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


	$($SSL x509 -req -days 7300 -in $USERTEMP/$usuario.csr -CA $UKEYS/ca.crt -CAkey $UKEYS/ca.key -out $USERTEMP/$usuario.crt)
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
PROTOCOLO $PROTOCOLO
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

echo "           OVPN - Monitoramento de conexões"


# Função para listar a quantidade de usuários e criar o filtro
listar_usuario(){

$(grep "\." $LOG/$STATUS > $USERTEMP/monitor_temp )
filtro1=$(cat $USERTEMP/monitor_temp | wc -l )

logados=$(($filtro1 / 2))               # Divide o valor do filtro1 por 2 que é o resultado de usuarios logados

echo "

Usuários logados $logados

"

filtro2=$(($logados + 1))
}

# Função para tratar os dados da lista de usuário

usuarios_ativos(){

nome=$( cat $USERTEMP/monitor_temp | head -$filtro2 | tail -1 | cut -d"," -f2 )
iplocal=$( cat $USERTEMP/monitor_temp | head -$filtro2 | tail -1 | cut -d"," -f1 )
ipexterno=$( cat $USERTEMP/monitor_temp | head -$filtro2 | tail -1 | cut -d"," -f3 | cut -d":" -f1 )
data=$( cat $USERTEMP/monitor_temp | head -$filtro2 | tail -1 | cut -d"," -f4 )
}


listar_usuario

# Aqui começa o loop que lista os usuários e seus dados de conexão


echo "USUÁRIO   | IP VPN        | IP EXTERNO            | DATA"
while [ $filtro2 -le $filtro1 ]; do

        usuarios_ativos

echo "$nome     | $iplocal      | $ipexterno    | $data"

filtro2=$(($filtro2 + 1 ))

done

echo "
"
rm -f $USERTEMP/monitor_temp

# FIM DA PARTE DO MONITORAMENTO

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

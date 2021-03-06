#!/usr/bin/env bash

# VARIABLES


version="3.3"

pkeys="/etc/openvpn/chaves"			 # Chaves do Servidor
ukeys="/etc/openvpn/usuarios"			 # ovpn dos usuários
ssl="/usr/bin/openssl"
ovpn="/usr/sbin/openvpn"
ovpnconf="/etc/openvpn/vpnusers.conf"

# CONDIÇÕES QUE DEVEM SER AJUSTADAS DE ACORDO COM O AMBIENTE

dias="2920"					 # Validade do certificado - Default 8 anos
iplocal=""					 # IP de conexão externa
portlocal="1194"				 # Porta de conexão
protlocal="udp"					 # Protocolo de conexão
redeovpn="10.100.10.0"				 # Rede Interna da VPN
maskovpn="255.255.255.0"			 # Mascara da rede da VPN

localovpn="192.168.1.0"				 # Rede interna da empresa
masklocalovpn="255.255.255.0"			 # Mascara da rede da empresa
gwremoto="192.168.1.1"				 # Gateway da empresa
dnsremotoA="192.168.1.1"			 # DNS remoto
dnsremotoB="192.168.1.1"			 # DNS remoto

log="/var/log/openvpn"				 # Pasta de log
statusovpn="/var/log/openvpn/openvpn-status.log" # Status da VPN
logovpn="/var/log/openvpn/openvpn.log"		 # Log da VPN
maxcli="10"					 # Máximo de clientes


# VALIDANDO SE ESTÁ COM USUÁRIO ROOT
if [ $(id -u) == 0 ]; then

# START SCRIPT
echo "Seja Bem vindo ao Instalador do OPENVPN

Por favor insira o dados de conexão do OVPN:
"

echo -n "IP do Servidor: "
read iplocal

#########################################################

if [ -e $ovpn ];then
	echo ".:Pacote do OPENVPN já instalado:."

	sleep 3

else

	$(yum install openvpn lzo -y)

fi

echo ".:CRIANDO PASTA PARA AS CHAVES:."
$(mkdir $ukeys)
$(mkdir $pkeys)
cd $pkeys

echo ".:CRIANDO PASTA DE LOGS:."
$(mkdir $log)

# TODO ------------------------------  VALIDAR CRIACAO DA PASTA

echo ".:GERANDO CERTIFICADO:."

$($ssl genrsa -out ca.key 4096)
$($ssl req -x509 -new -nodes -key ca.key -sha256 -days $dias -out ca.crt -subj "/C=BR/ST=Rio_de_Janeiro/L=Rio de_janeiro/O='$EMPRESA'/OU='$EMPRESA/CN=RootAuthority/emailAddress='$EMAIL'")


# TODO ------------------------------  VALIDAR CRIACAO DO CERTIFICADO

echo ".:GERAR CERTIFICADO CSR:."

$($ssl genrsa -out server.key 2048)
$($ssl req -new -sha256 -key server.key -subj "/C=BR/ST=Rio_de_Janeiro/L=Rio de_janeiro/O=EMPRESA/OU='$EMPRESA'/CN=vpnserver/emailAddress='$EMAIL'" -out server.csr)

$($ssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days $dias -sha256)


# TODO ------------------------------  VALIDAR CRIACAO DO CERTIFICADO CSR

echo ".:GERAR DEFFIE HELLMAN:."
	
$($ssl dhparam -out dh1024.pem -5 1024)

echo ".:GERANDO CHAVE TA:."

$($ovpn --genkey --secret ta.key)


# TODO ------------------------------  VALIDAR CRIACAO DO DEFFIE HELLMAN

# ARQUIVO SERVER.CONF


echo "
local $iplocal
port $portlocal
proto $protlocal

dev tun

tls-server
ca $pkeys/ca.crt
cert $pkeys/server.crt
key $pkeys/server.key
dh $pkeys/dh1024.pem
tls-auth $pkeys/ta.key 0

mode server
tls-server
client-to-client

server $redeovpn $maskovpn
push \"ping-restart 3600\"
push \"route $localovpn $masklocalovpn\"
push \"dhcp-option DNS $dnsremotoA\"
push \"dhcp-option DNS $dnsremotoB\"
push \"dhcp-opton gateway $gwremoto\"

float
comp-lzo

status $statusovpn
log-append $logovpn
verb 4

#max-clients $maxcli

persist-key
persist-tun
" > $ovpnconf

# Configurando serviço do OpenVPN para iniciar junto com o Windows iniciando o serviço

$(systemctl enable openvpn\@vpnusers)
[[ $? == 1 ]]&& echo "Serviço não iniciado com o SO"

$(systemctl start openvpn\@vpnusers)
[[ $? == 1 ]]&& echo "Serviço não iniciado com sucesso"

status="0"



# VALIDAÇÃO DO USUÁRIO ROOT
else
		echo "
		USUÁRIO SEM PERMISSÃO.
		"
	

fi # Finalizando Script de instalação

# FIM DO SCRIPT

if [ $status == "0" ];then
	clear
	echo "
	SERVIÇO INSTALADO COM SUCESSO

	POR FAVOR VERIFIQUE SE O SERVIÇO ESTÁ INICIALIZADO CORRETAMENTE

	PROCEDIMENTOS NECESSÁRIO:

	- LIBERAÇÃO NO IPTABLES:

	#iptables -I INPUT -p $protlocal --dport $portlocal -j ACCEPT
	#iptables -I FORWARD -i tun+ -s $redeovpn -d $localovpn -j ACCEPT

	*Lembrando que essas regras são apenas em uma utilização geral, devem ser analisados os casos.
	Estas regras liberam todos ips da duas redes a se comunicarem

	- INSERIR A REGRA NO PUPPET
"

fi

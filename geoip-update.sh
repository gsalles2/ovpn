#!/usr/bin/env bash

#	SIRIUS - GEOIP - UPDATE
#
# Script de update para a listas de IPs por país.
# As listas de IPs são utilizadas no sistema de bloqueio por país do NGINX, como método de prevenção de ataques.
# 
#
#



# VARIAVEIS

codigos="country-list/codigos"
codigos_pais="country-list/cod_pais"
phpsessid=""		# Necessário inserir manualmente e atualizado | Não esquecer o ; no final
first_visit=""				# Necessário inserir manualmente e atualizado
nginx_option="nginx-deny"					# Default
log_update="logs/log-update"					# Log Padrão
log_error="logs/log-error"					# Logs de erro

phpssessid=$("curl -i -s https://www.ip2location.com/free/visitor-blocker | grep PHPSESSID | cut -d" " -f2")

##### Recaptcha tá barrando #####
#				#

#phpsessid=$(curl -i -s https://www.ip2location.com/free/visitor-blocker | grep PHPSESSID | cut -d" " -f2)

#first_visit=$(curl -i -s https://www.ip2location.com/free/visitor-blocker | grep first_visit | cut -d" " -f2 | cut -d";" -f1)

#				#
#################################


# -=-=-=-=-= Funções -=-=-=-=-=-=- #

## FUNÇÃO PARA ATUALIZAR APENAS UMA LISTA
coleta_individual(){

echo "

Exemplo de códigos do País: CH - China | BR - Brazil

"

echo -n "DIGITE O CÓDIGO DO PAIS: "
read cod_pais

$(curl -s -k -X $'POST' -H $'Content-Length: 49' -H $'Origin: https://www.ip2location.com' -H $'Cookie: '$phpsessid' '$first_visit'' --data-binary $'countryCodes%5B%5D='$cod_pais'&version=4&format=nginx-'$nginx_option'' $'https://www.ip2location.com/free/visitor-blocker' > ips/$nginx_option/$cod_pais)

clean_files
echo "Lista $cod_pais - ATUALIZADA"
echo "Lista $cod_pais - ATUALIZADA" >> $log_update
$(curl -s -k -X $'POST' -H $'Content-Length: 49' -H $'Origin: https://www.ip2location.com' -H $'Cookie: '$phpssessid' first_visit=159228041' --data-binary $'countryCodes%5B%5D='$cod_pais'&version=4&format=nginx-deny' $'https://www.ip2location.com/free/visitor-blocker' > ips/$cod_pais)

echo "Lista $cod_pais - ATUALIZADA"

exit 0
}


## FUNÇÃO PARA ATUALIZAR TODAS AS LISTAS

coleta_updatedb(){

	cod_pais=$(head -$linha $codigos | tail -1)

	sleep 2
	$(curl -L -s -k -X $'POST' -H $'Content-Length: 49' -H $'Origin: https://www.ip2location.com' -H $'Cookie: '$phpsessid' '$first_visit'' --data-binary $'countryCodes%5B%5D='$cod_pais'&version=4&format='$nginx_option'' $'https://www.ip2location.com/free/visitor-blocker' > ips/$nginx_option/$cod_pais)
	$(curl -s -k -X $'POST' -H $'Content-Length: 49' -H $'Origin: https://www.ip2location.com' -H $'Cookie: '$phpssessid' first_visit=159228041' --data-binary $'countryCodes%5B%5D='$cod_pais'&version=4&format=nginx-deny' $'https://www.ip2location.com/free/visitor-blocker' > ips/$cod_pais)
	
	status_update="FALHA"
	test_update=$(cat ips/$nginx_option/$cod_pais | grep script)
	[[ -z $test_update ]]&&status_update="ATUALIZADO"&&clean_files
if [[ -z $test_update ]];then
	
	clean_files
	echo "Pais $cod_pais - [ $(head -$linha $codigos_pais | tail -1 | cut -d" " -f3 ) - ATUALIZADO ]"
	echo "Pais $cod_pais - [ $(head -$linha $codigos_pais | tail -1 | cut -d" " -f3 ) - ATUALIZADO ][$(date "+%d-%m-%Y %H:%M")]" >> $log_update

else
	echo "Pais $cod_pais - [ $(head -$linha $codigos_pais | tail -1 | cut -d" " -f3 ) - FALHA ]"
	echo "Pais $cod_pais - [ $(head -$linha $codigos_pais | tail -1 | cut -d" " -f3 ) - FALHA ][$(date "+%d-%m-%Y %H:%M")]" >> $log_error

fi

	update_allow

	linha=$(($linha + 1))
}

update_allow(){

	$(cp ips/$nginx_option/$cod_pais ips/nginx-allow/)
	$(sed -i 's/deny/allow/g' ips/nginx-allow/$cod_pais)

}

clean_files(){
	$(sed -i -e '/#/g' ips/$nginx_option/$cod_pais)
	$(sed -i -e '/location/g' ips/$nginx_option/$cod_pais)
	$(sed -i -e '/}/g' ips/$nginx_option/$cod_pais)
	$(sed -i -e '/^$/d' ips/$nginx_option/$cod_pais)
}

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-= #

clear

case $1 in
	"-i")coleta_individual
		;;

	"--allow")nginx_options="nginx-allow"
		;;

	"--help")echo "

Como utilizar:
	ex: '$'$0
		
	Opções

	-i -> Individual - Coleta individual por pais, irá solicitar o código do pais a qual deseja atualizar.
	-s -> Silenciosa - Inicia a atualização total das listas sem interação com o usuário.
	--allow -> Lista NGINX ALLOW - Muda manualmente pra atualização da lista NGINX ALLOW
		"
		;;

esac

if [[ $1 != "-s" ]];then

echo "

	SERÁ INICIADO A ATUALIZAÇÃO DA BASE DE DADOS INTEIRA.


APERTE [Y] PARA CONTINUAR
"
read saida
[[ $saida == "y" || "Y" ]]||exit 0

else
	echo "

	INICIANDO ATUALIZAÇÃO DA BASE DE DADOS

	"
	sleep 2

fi


clear

# Iniciando a chamada da função de coleta Total


[[ $1 == "-i" ]]&&coleta_individual

numeropaises=$(cat $codigos | wc -l)
linha="1"

while [[ $linha -le $numeropaises ]];do

	coleta_updatedb
done


echo "

LISTAS ATUALIZADAS COM SUCESSO

"

echo "

Validando dados atualizados

"
problemas=$(cd ips/$nginx_option ; grep script ips/* | cut -d":" -f1 | uniq)			# Verifica quais arquivos estão com problemas

cd ..

if [ -z $problemas ];then

	echo "Nenhum Problema nos arquivos"

else
	$(cd ips ; grep script ips/* | cut -d":" -f1 | uniq | xargs -n1 rm)
	echo "Arquivos $problemas inconssistentes e foram removidos
	"

fi

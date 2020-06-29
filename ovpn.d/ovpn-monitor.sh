#!/usr/bin/env bash

source ovpn.cfg

# OVPN - MONITOR
#
# Software responsável pelo monitoramento das conexões do OpenVPN
#
#


while :;do

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

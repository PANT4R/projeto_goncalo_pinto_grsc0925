#!bin/bash

echo " Instalar o dhcp..."
sudo yum update
sudo yum upgrade
sudo dnf install -y dhcp-server
~


#Interface em internal network
sudo nmcli connection modify enp0s3 ipv4.method manual ipv4.addresses 192.168.5.1/24
sudo nmcli connection modify enp0s3 +ipv4.addresses 192.168.5.1/24
sudo nmcli connection down enp0s3
sudo nmcli connection up enp0s3

#recolha de ips para utilizar 
echo "Introduz uma gama de ips que  pertençam a mesma subnet do servidor dhcp 192.168.5.1/24:"
echo "Atenção!!!! Não utilizar uma gama de IPS onde o ip do servidor ( 192.168.5.1/24) nem o ips do gateway (192.168.5.254) estejam presentes!!"
read -p " Ip de inicío :" ip_inicio
read -p " ip final:" ip_fim

#verificar o intervalo da gama de ips

subnet="^192\.168\.5\."
mask="255.255.255.0"
subrede="192.168.5.0"
ip_servidor="192.168.5.1"

if [[ $ip_inicio =~ $subnet ]] && [[ $ip_fim =~ $subnet ]] && [[ $ip_inicio != $ip_servidor ]] &&  [[ $ip_fim != $ip_servidor ]]; then
echo " Todos os IPS validados com sucesso!"
else
echo " ERRO : Os ips introduzidos estão errados ( fora da subnet) ou em conflito com o ip do servidor, fecha o programa e tenta denovo !"
exit 1
fi

# Ip default gateway
echo " Introduz o IP do default-gateway"
read -p "gateway:" ip_gateway

#verificar gateway
if [[ $ip_gateway =~ $subnet ]];then
echo " O default-gateway é válido!"
else
echo "ERRO :  O default-gateway está fora da subrede . Fecha o programa..."
exit 1
fi

#receber o dns
echo " Introduza o ip do DNS"
read -p " DNS:" dns

#backup
echo " Backup do arquivo de configuração DHCP-SERVER"
sudo cp /etc/dhcp/dhcp.conf /etc/dhcp/dhcp.conf.bak

#
dhcp_config="/etc/dhcp/dhcpd.conf"
echo "A acabar as configurações..."
sudo bash -c "cat >> $dhcp_config" << END
subnet $subrede netmask $mask {
	default-lease-time 600;
	max-lease-time 7200;
	option broadcast-address 192.168.5.254;
	option subnet-mask 192.168.5.0;
	range $ip_inicio $ip_fim;
	option routers $ip_gateway;
	option domain-name-servers $dns;
}
END

#Inicio DHCP
echo " A iniciar todas as configurações..."
sudo systemctl enable --now dhcpd.service
sudo systemctl start --now dhcpd.service
#ativar serviços firewall
echo " Configurar a firewall..."
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload

#veriicar os status
echo " A verificar o status do DHCP..."
sudo systemctl status dhcpd.service

echo "PARABÉNS!!! Instalação realizada com sucesso."

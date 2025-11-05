#!/bin/bash
 
echo "Instalar o KEA DHCP Server..."
sudo yum update 
sudo yum install kea
 
# Interface em Lan Segment
sudo nmcli connection modify ens224 ipv4.method manual ipv4.addresses 192.168.5.254/24
sudo nmcli connection down ens224
sudo nmcli connection up ens224
 
# Recolha de IPs
echo "Introduz a gama de IPs dentro da subnet 192.168.5.0/24"
read -p "IP de início: " ip_inicio
read -p "IP final: " ip_fim
 
subnet="^192\.168\.5\."
mask="255.255.255.0"
subrede="192.168.5.0"
ip_servidor="192.168.5.1"
 
if [[ $ip_inicio =~ $subnet ]] && [[ $ip_fim =~ $subnet ]] && [[ $ip_inicio != $ip_servidor ]] && [[ $ip_fim != $ip_servidor ]]; then
  echo "IPs validados com sucesso!"
else
  echo "ERRO: IPs inválidos. Saindo..."
  exit 1
fi
 
read -p "IP do gateway: " ip_gateway
read -p "IP do DNS: " dns
 
if [[ ! $ip_gateway =~ $subnet ]]; then
  echo "ERRO: Gateway fora da subrede."
  exit 1
fi
 
# Backup do ficheiro original
kea_config="/etc/kea/kea-dhcp4.conf"
sudo cp $kea_config ${kea_config}.bak
 
echo "A configurar o ficheiro KEA DHCP..."
 
sudo cat > $kea_config <<EOF
{
"Dhcp4":{
    "interfaces-config":{
        "interfaces": ["ens192"]
},
    "expired-leases-processing": {
        "reclaim-timer-wait-time": 10,
        "flush-reclaimed-timer-wait-time": 25,
        "hold-reclaimed-time": 3600,
        "max-reclaim-leases": 100,
        "max-reclaim-time": 250,
        "unwarned-reclaim-cycles": 5
    },
    "renew-timer": 900,
    "rebind-timer": 1800,
    "valid-lifetime": 3600,
    "option-data": [
        {
            "name": "domain-name-servers",
            "data": "8.8.8.8"
        },
        {
            "name": "domain-name",
            "data": "empresa.local"
        },
        {
            "name": "domain-search",
            "data": "empresa.local"
        }
    ],
    "subnet4": [
        {
            "id": 1,
            "subnet": "$subrede/24",
            "pools": [ { "pool": "$ip_inicio - $ip_fim" } ],
            "option-data": [
                {
                    "name": "routers",
                    "data": "$ip_gateway"
                }
            ]
        }
    ],
    "loggers": [
    {
        "name": "kea-dhcp4",
        "output-options": [
            {
                "output": "/var/log/kea/kea-dhcp4.log"
            }
        ],
        "severity": "INFO",
        "debuglevel": 0
    }
  ]
}
}
 
EOF
 
# Iniciar e ativar serviço
echo "A iniciar o KEA DHCP Server..."
sudo systemctl enable --now kea-dhcp4.service
sudo systemctl restart kea-dhcp4.service
 
# Firewall
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload
 
# Verificar
sudo systemctl status kea-dhcp4.service --no-pager
 
echo "KEA DHCP configurado com sucesso!"

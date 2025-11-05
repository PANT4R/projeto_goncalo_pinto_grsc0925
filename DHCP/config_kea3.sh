#!/bin/bash
 
echo "Instalar o KEA DHCP Server..."
sudo yum update
sudo yum install kea-dhcp4 
 
# Interface em Lan Segment
# Utiliza a variável para coerência, embora o valor estivesse certo
sudo nmcli connection modify ens160 ipv4.method manual ipv4.addresses 192.168.5.1/24
sudo nmcli connection down ens160
sudo nmcli connection up ens160
 
# Recolha de IPs
echo "Introduz a gama de IPs dentro da subnet 192.168.5.0/24"
read -p "IP de início: " ip_inicio
read -p "IP final: " ip_fim
 
subnet="^192\.168\.5\."
mask="255.255.255.0" # Não utilizado, mas pode ficar
subrede="192.168.5.0"
ip_servidor="192.168.5.1" # Não utilizado na lógica, mas pode ficar
 
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
# Cria a pasta antes de tentar copiar (apenas por segurança)
sudo mkdir -p /etc/kea/
# Verifica se o ficheiro existe antes de tentar copiar
if [ -f "$kea_config" ]; then
    sudo cp "$kea_config" "${kea_config}.bak"
fi
 
echo "A configurar o ficheiro KEA DHCP..."

# O bloco de configuração JSON corrigido:
sudo cat > $kea_config <<EOF
{
"Dhcp4": {
    "interfaces-config": [
        {
            "interfaces": [ "ens160" ]
        }
    ],
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
            "data": "${dns}"
        },
        {
            "name": "domain-name",
            "data": "srv.world"
        },
        {
            "name": "domain-search",
            "data": "srv.world"
        }
    ], # <-- CORREÇÃO 2: A vírgula é essencial AQUI para separar option-data de subnet4
    "subnet4": [
        {
            "id": 1,
            "subnet": "${subrede}/24",
            "pools": [ { "pool": "${ip_inicio} - ${ip_fim}" } ],
            "option-data": [
                {
                    "name": "routers",
                    "data": "${ip_gateway}"
                }
            ]
        }
    ]
}, # <-- Esta vírgula separa Dhcp4 de loggers, está CORRETA.
"loggers": [
    {
        "name": "kea-dhcp4",
        "output-options": [
            {
                "output": "/var/log/kea/kea-dhcp4.log"
            }
        ],
        "severity": "INFO",
        "debugLevel": 0
    }
]
}
EOF
 
# Iniciar e ativar serviço
echo "A iniciar o KEA..."
sudo systemctl enable --now kea-dhcp4.service
sudo systemctl restart kea-dhcp4.service
 
# Firewall
sudo firewall-cmd --add-service=dhcp --permanent
sudo firewall-cmd --reload
 
# Verificar
sudo systemctl status kea-dhcp4.service --no-pager
 
echo "KEA configurado com sucesso!"

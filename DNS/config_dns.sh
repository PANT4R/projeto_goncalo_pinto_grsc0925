#!/bin/bash
set -e
 
#Instalar dns Bind
 
sudo dnf -y install bind bind-utils
 
 
read -p "Introduz o Ip do server: (tem de ser dentro da network 192.168.5.0)" ip_server
read -p "Introduz o Ip do server em www: (tem de ser dentro da network 192.168.5.0, nao pode ser igual ao server e nao pode estar dentro da lease do dhcp)" ip_server_www
 
 
#Configurar a placa de rede
sudo nmcli connection modify ens192 ipv4.addresses $ip_server/24
sudo nmcli connection modify ens192 ipv4.method manual ipv4.gateway $ip_server
sudo nmcli connection up ens192
nmcli
 
# Adicionar estas linhas para retirar o último octeto para o DNS
# O AWK separa a ip em octetos atraves dos pontos e faz print do 4 campo para dentro do last_octet
ip_last_octet=$(echo $ip_server | awk -F'.' '{print $4}')
ip_www_last_octet=$(echo $ip_server_www | awk -F'.' '{print $4}')
 
 
#Aplicar as configurações caso o dns esteja sido instalado
 
sudo cat > /etc/named.conf << END
 
# configurar ACL para local network
 
acl internal-network {
        192.168.5.0/24;
};
 
options {
        listen-on port 53 { any; };
        listen-on-v6 { none; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { localhost; internal-network; };
        allow-transfer  { localhost; };
 
        forwarders {
            8.8.8.8;
            1.1.1.1;
        };
        forward only;
 
        recursion yes;
 
        dnssec-validation yes;
 
        managed-keys-directory "/var/named/dynamic";
        geoip-directory "/usr/share/GeoIP";
 
        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};
 
logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};
 
zone "." IN {
        type hint;
        file "named.ca";
};
 
include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
 
# Adiciona Zonas para a Network
 
zone "empresa.local" IN {
        type primary;
        file "empresa.local.lan";
        allow-update { none; };
};
zone "5.168.192.in-addr.arpa" IN {
        type primary;
        file "5.168.192.db";
        allow-update { none; };
};
 
END
 
sudo cat > /var/named/empresa.local.lan << END
 
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1762172329  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
@        IN  NS      servidor1.empresa.local.
 
servidor1  IN  A       $ip_server
 
@        IN  MX 10   servidor1.empresa.local.
 
dlp     IN  A       $ip_server
 
 
END
 
sudo cat > /var/named/5.168.192.db << END
 
\$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1762172329 ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
@        IN  NS      servidor1.empresa.local.
 
$ip_last_octet          IN  PTR     servidor1.empresa.local.
$ip_www_last_octet      IN  PTR     www.empresa.local.
 
END
 
# INICIAR BIND
 
systemctl enable --now named
 
# CONFIGURAR a Firewall
 
sudo firewall-cmd --add-service=dns --permanent
sudo firewall-cmd --runtime-to-permanent
 
# Verificação do Nome e da Address
 
dig empresa.local
 
# Outro dig
 
dig -x $ip_server
 
# NSLOOKUP
 
nslookup servidor1.empresa.local $ip_server
 
#Ping Google
 
ping www.google.com
 

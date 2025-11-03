sudo dnf -y install bind bind-utils


sudo cat > /etc/named.conf<< END
// add : set ACL entry for local network
acl internal-network {
        192.168.5.0/24;
};

options {
        // change ( listen all )
        listen-on port 53 { any; };
        // change if need ( if not listen IPv6, set [none] )
        listen-on-v6 { any; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        // add local network set on [acl] section above
        // network range you allow to receive queries from hosts
        allow-query     { localhost; internal-network; };
        // network range you allow to transfer zone files to clients
        // add secondary DNS servers if it exist
        allow-transfer  { localhost; };

        .....
        .....

        recursion yes;

        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";
        geoip-directory "/usr/share/GeoIP";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include "/etc/crypto-policies/back-ends/bind.config";
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

// add zones for your network and domain name
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

$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1762170738  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
        ;; define Name Server
        IN  NS      servidor1.empresa.local.
        ;; define Name Server's IP address
        IN  A       192.168.5.1
        ;; define Mail Exchanger Server
        IN  MX 10   servidor1.empresa.local.

;; define each IP address of a hostname
servidor1     IN  A       192.168.5.1
www           IN  A       192.168.5.90

# if you don't use IPv6 and also suppress logs for IPv6 related, possible to change
# set BIND to use only IPv4
END
sudo cat > /var/named/5.168.192.db << END
$TTL 86400
@   IN  SOA     servidor1.empresa.local. root.empresa.local. (
        1762170738  ;Serial
        3600        ;Refresh
        1800        ;Retry
        604800      ;Expire
        86400       ;Minimum TTL
)
        ;; define Name Server
        IN  NS      servidor1.empresa.local.

;; define each hostname of an IP address
1        IN  PTR     servidor1.empresa.local.
90       IN  PTR     www.empresa.local.

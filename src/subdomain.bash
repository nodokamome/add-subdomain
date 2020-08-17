#!/bin/bash
#スクリプト開始時刻
echo ======================;
echo "subdomaint script"
date;
echo ======================;

set -x

#サブドメイン入力
read -p "subdomain: " subdomain
tty -s && echo
echo "${subdomain}"


mkdir /var/www/html/${subdomain};
cat << EOF > /etc/httpd/conf.d/vhost-${subdomain}.conf
<VirtualHost *:80>
    ServerName ${subdomain}
    DocumentRoot /var/www/html/${subdomain}
    CustomLog logs/${subdomain}_access.log combined
    ErrorLog logs/${subdomain}_error.log
</VirtualHost>
EOF

systemctl restart httpd;


certbot certonly --webroot -w /var/www/html/${subdomain} -d ${subdomain} -m ${subdomain} --agree-tos -n
cat << EOF >> /etc/httpd/conf.d/vhost-${subdomain}.conf

<VirtualHost *:443>
    ServerName ${subdomain}
    DocumentRoot /var/www/html/${subdomain}
    TransferLog logs/${subdomain}_ssl_access_log
    ErrorLog logs/${subdomain}_ssl_error_log

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/${subdomain}/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/${subdomain}/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/${subdomain}/fullchain.pem
</VirtualHost>
EOF

systemctl restart httpd;

#htmlに書き込み設定
cd /var/www;
chown -R apache:nodokamome html;
chmod -R 775 html;

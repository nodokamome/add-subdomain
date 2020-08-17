#!/bin/bash
#サブドメイン追加スクリプト
echo ======================;
echo "subdomaint script"
date;
echo ======================;

set -x

#サブドメイン入力
read -p "subdomain: " subdomain
tty -s && echo
echo "${subdomain}"

#ユーザー設定
read -p "user: " user
tty -s && echo
echo "${user}"


#ディレクトリ作成
mkdir /var/www/html/${subdomain};

#http(Port:80)でvhost作成
cat << EOF > /etc/httpd/conf.d/vhost-${subdomain}.conf
<VirtualHost *:80>
    ServerName ${subdomain}
    DocumentRoot /var/www/html/${subdomain}
    CustomLog logs/${subdomain}_access.log combined
    ErrorLog logs/${subdomain}_error.log
</VirtualHost>
EOF

#設定反映
systemctl restart httpd;

#Let's encryptで設定
certbot certonly --webroot -w /var/www/html/${subdomain} -d ${subdomain} -m ${subdomain} --agree-tos -n

#https(Port:443)でvhost追記
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

#設定反映
systemctl restart httpd;

#htmlに書き込み設定
cd /var/www;
chown -R apache:${user} html;
chmod -R 775 html;

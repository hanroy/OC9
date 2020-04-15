# LOG
#exec &> /var/log/backup-$(date +"%d-%m-%Y").log

# change hostname
hostnamectl set-hostname webserver

sleep 5

echo "configure hosts"
echo "127.0.0.1   webserver localhost localhost.localdomain localhost4 localhost4.localdomain4" > /etc/hosts

echo "update machine"
dnf update -y

echo "disable ipv6"
cat <<EOT >> /etc/sysctl.d/disableipv6.conf
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOT

systemctl restart systemd-sysctl

sleep 10

echo "install wordpress"

echo "installation des pre-requis"
dnf install php expect php-mysqlnd php-fpm mariadb-server httpd tar curl php-json lftp -y

echo "autorisation firewall"
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload

sleep 5

echo "démarrage apache et mariadb"
systemctl enable mariadb
systemctl enable httpd
systemctl start mariadb
systemctl start httpd

sleep 5

echo "configuration mariadb"
echo "secure mysql"
expect -f - <<-EOF
  set timeout 10
  spawn mysql_secure_installation
  expect "Enter current password for root (enter for none):"
  send -- "\r"
  expect "Set root password?"
  send -- "y\r"
  expect "New password:"
  send -- "ubuntu\r"
  expect "Re-enter new password:"
  send -- "ubuntu\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF

sleep 10

echo "creer la base wordpress "

mysql -u root -pubuntu -e "CREATE DATABASE wordpress;"
mysql -u root -pubuntu -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'ubuntu';"
mysql -u root -pubuntu -e "GRANT ALL ON wordpress.* TO 'admin'@'localhost';"
mysql -u root -pubuntu -e "FLUSH PRIVILEGES;"

sleep 5

echo "Telecharger et extraire wordpress"

lftp -u  wordpress,ubuntu 192.168.141.142 -e "set ssl:verify-certificate no; mirror --verbose --use-pget-n=8 -c --verbose  /home/wordpress/"wordpress-$(date +"%d-%m-%Y")" /root/ ; bye"

echo "configuration wordpress"
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp
chmod 755 /usr/local/bin/wp

mkdir -p /var/www/html/wordpress
chown -R apache:apache /var/www/html/wordpress
cd /var/www/html/wordpress
wp core download
wp core config --dbname=wordpress --dbuser=admin --dbpass=ubuntu
wp db import /root/wordpress-$(date +"%d-%m-%Y")/BddBackup.$(date +"%Y-%m-%d").sql

i=$(ip  -f inet a show ens33| grep inet| awk '{ print $2}' | cut -d/ -f1)
echo $i

wp search-replace "http://192.168.141.139/wordpress" "http://${i}/wordpress"


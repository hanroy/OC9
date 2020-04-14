lftp -u  wordpress,ubuntu 192.168.141.142 -e "set ssl:verify-certificate no; mirror --verbose --use-pget-n=8 -c --verbose  /home/wordpress/"wordpress-$(date +"%d-%m-%Y")" /root/ ; bye"
cd "wordpress-$(date +"%d-%m-%Y")"
gzip -d BddBackup.$(date +"%Y-%m-%d").sql.gz
mysqldump -u root -pubuntu wordpress <  BddBackup.$(date +"%Y-%m-%d").sql
tar -xzvf  WordpressBackup.$(date +"%Y-%m-%d").tar.gz
cp -R wordpress /var/www/html/

set +x

# supprimer les vieilles sauvegarde de plus de 5 jours
find /root/backup/* -type d -mtime +1 -exec rm -rdf {} \;

# Sauvegarde

if [ -d "/root/backup/"wordpress-$(date +"%d-%m-%Y")"" ]; then
  echo "bye"
else

  # creer le dossier du backup
  mkdir -v /root/backup/"wordpress-$(date +"%d-%m-%Y")"
  # sauvegarde des donnees de la base de donnee
  cd /var/www/html/wordpress 
  wp db export /root/backup/"wordpress-$(date +"%d-%m-%Y")"/BddBackup.$(date +"%Y-%m-%d").sql
  # sauvegarde des donnees wordpress
  cd /var/www/html/
  tar -v -cpPzf "/root/backup/"wordpress-$(date +"%d-%m-%Y")"/WordpressBackup.$(date +"%Y-%m-%d").tar.gz" wordpress/

  # lftp

ftpsite="192.168.141.142"
ftpuser="wordpress"
ftppass="ubuntu"
#remote folder in which you want to delete files
putdir="/home/wordpress/"
nullfolder="/tmp/null"

ndays=5

mkdir -p nullfolder

lftp -u $ftpuser,$ftppass $ftpsite <<-EOF
mirror $putdir $nullfolder --older-than=now-${ndays}days --Remove-source-files;
mirror -R /root/backup/"wordpress-$(date +"%d-%m-%Y")"/
EOF

rm $nullfolder/* -Rf

fi

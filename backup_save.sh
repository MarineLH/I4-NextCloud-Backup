#!/bin/bash

#IP du serveur NextCloud
NC_HOST=root@192.168.33.200
# Nom de la BDD Nextcloud
NC_BDD_NAME=nextcloud
# User de la BDD Nextcloud
NC_BDD_USER=root
# Mot de passe du User de la BDD Nextcloud
NC_BDD_PWD=root
# Hote de la BDD Nextcloud
NC_BDD_HOST=localhost
# Date formatee
DATE_FORMAT=`date +"%Y%m%d"`

if [ ! -d /data/backup/nextcloud ];
then
    mkdir /data/backup/nextcloud
	mkdir /data/backup/nextcloud/donnees
	mkdir /data/backup/nextcloud/bdd
fi

echo "########## Debut du processus de sauvegarde de Nextcloud ##########"

# Mise en maintenance de Nextcloud
echo "########## Mise en maintenance de Nextcloud ##########"
ssh $NC_HOST 'sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ maintenance:mode --on'

# Dump de la BDD de Nextcloud
echo "########## Dump de la base de donnees de Nextcloud ##########"
ssh $NC_HOST "mysqldump --single-transaction -h $NC_BDD_HOST -u $NC_BDD_USER --password=$NC_BDD_PWD $NC_BDD_NAME" > /data/backup/nextcloud/bdd/nc_bdd_$DATE_FORMAT.bak

# Transfert des fichiers Nextcloud vers Backup
echo "########## Realisation du transfert des fichiers Nextcloud ##########"
rsync -Aavx -e "ssh" $NC_HOST:/var/www/html/nextcloud/ /data/backup/nextcloud/donnees/

# Snapshot de la sauvegarde Nextcloud
echo "########## Realisation du Snapshot de la sauvegarde Nextcloud ##########"
zfs snapshot data/backup@nextcloud_$DATE_FORMAT

# Gestion de la retention des donnees (30 jours)
retention_duration="data/backup@nextcloud_`date --date='-30 day' +"%Y%m%d"`"
for snapshot in `zfs list -H -t snapshot -o name` ; do
	if [[ $snapshot < $retention_duration ]]; then
		zfs destroy $snapshot
	fi
done

# Sortie du mode maintenance de Nextcloud
echo "########## Remise en marche des services Nextcloud ##########"
ssh $NC_HOST 'sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ maintenance:mode --off'

echo "########## Fin du processus de sauvegarde ##########"
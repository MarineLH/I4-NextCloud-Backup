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

if [ ! -d /data/restore/nextcloud/snapshots ];
then
    mkdir /data/restore/nextcloud/snapshots
fi

echo "########## Debut du processus de restauration de Nextcloud ##########"

echo "Veuillez entrer la date de la restauration voulue [format : AAAAMMJJ]"
read date_saisie

# Mise en maintenance de Nextcloud
echo "########## Mise en maintenance de Nextcloud ##########"
ssh $NC_HOST 'sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ maintenance:mode --on'

# Verrouillage du snapshot
echo "########## Verrouillage du snapshot de NextCloud ##########"
zfs hold keep data/backup@nextcloud_$date_saisie

# Clone du snapshot
echo "########## Copie du snapshot NextCloud ##########"
zfs clone data/backup@nextcloud_$date_saisie data/restore/nextcloud/snapshots

# Restauration des fichiers du serveur NextCloud
echo "########## Restauration des fichiers de NextCloud ##########"
rsync -Aavx /data/backup/nextcloud/donnees/* -e "ssh" $NC_HOST:/var/www/html/nextcloud/

# Suppression de la BDD avant restauration
echo "########## Suppression de la base de donnees NextCloud avant restauration ##########"
ssh $NC_HOST "mysql -h $NC_BDD_HOST -u $NC_BDD_USER --password=$NC_BDD_PWD -e \"DROP DATABASE $NC_BDD_NAME\""

# Creation de la BDD pour restauration
echo "########## Creation de la base de donnees NextCloud pour restauration ##########"
ssh $NC_HOST "mysql -h $NC_BDD_HOST -u $NC_BDD_USER --password=$NC_BDD_PWD -e \"CREATE DATABASE $NC_BDD_NAME\""

# Restauration de la BDD du serveur NextCloud
echo "########## Restauration de la base de donnees NextCloud ##########"
ssh $NC_HOST "mysql -h $NC_BDD_HOST -u $NC_BDD_USER --password=$NC_BDD_PWD $NC_BDD_NAME" < /data/backup/nextcloud/bdd/nc_bdd_$DATE_FORMAT.bak

# Déverrouillage du snapshot
echo "########## Deverrouillage du snapshot de NextCloud ##########"
zfs release keep data/backup@nextcloud_$date_saisie

# Sortie du mode maintenance de Nextcloud
echo "########## Remise en marche des services Nextcloud ##########"
ssh $NC_HOST 'sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ maintenance:mode --off'

echo "########## Fin du processus de sauvegarde ##########"

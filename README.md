# TP Systèmes de sauvegarde - Backup de Nextcloud

## Sujet
Vous devez mettre en place la sauvegarde de cette application de la manière la plus efficace possible en
considérant que le volume de données peut devenir très important.

De plus, vous devrez permettre une historisation de ces sauvegardes avec une durée de rétention de 30 jours.
Vous sauvegarderez bien évidemment les fichiers aussi bien que la base de données de manière à ce qu’une
restauration soit parfaitement possible.

Vous planifierez cette sauvegarde de manière à ce qu’elle s’effectue de manière totalement automatique, le
plus fréquemment possible et en mettent en application les bonnes pratiques étudiées en cours.


### Autorisation de connexion en tant que root via SSH - Serveur Nextcloud

Afin de pouvoir se connecter via SSH au serveur Nextcloud à partir du serveur Backup, il est nécessaire de modifier
le fichier : sshd_config.
Pour ce faire, dans /etc/ssh/sshd_config décommenter la ligne `PermitRootLogin` et remplacer `prohibit-password` par `yes`


### Installation des scripts - Serveur Backup

1) Ajouter les droits aux scripts "backup_save.sh" et "backup_restore.sh" : 

- `chmod +x backup_save.sh backup_restore.sh`

2) Génération d'une paire de clés SSH pour que le serveur Backup puisse se connecter au server Nextcloud :

Sur le serveur Backup executer les commandes suivantes :
- `ssh-keygen -t rsa`
- `ssh-copy-id -i ~/.ssh/rsa.pub root@192.168.33.200`

 
### Utilisation des scripts - Serveur Backup

**Sauvegarde de nextcloud**

Lancer la commande suivante afin d'executer le script de sauvegarde : `./backup_save.sh`


**Restauration de nextcloud**

Lancer la commande suivante afin d'executer le script de restauration : `./backup_restore.sh`


### Automatisation - Serveur Backup

Afin d'automatiser l'execution du script de sauvegarde de nextcloud, il est nécessaire d'utiliser une tache cron.

Pour cela, il faut éditer le fichier cron à l'aide de la commande `crontab -e`.

Ajouter à la fin du fichier la ligne suivante, ici la tâche est programmée pour s'executer à 03H00 :
- `0 3 * * * /chemin_vers_le_script/backup_save.sh`

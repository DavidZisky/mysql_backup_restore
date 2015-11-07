#!/bin/bash -e

#Interactive MySQL backup/restore script. It uses mydumper/myloader commands.
#Autor: Dawid Ziolkowski

#Set some basic variables for folder creation and title
date=`date '+%Y-%m-%d'`
time=`date '+%H-%M'`
title="Mysql Backup/Restore"
#FILL THIS:
mysql_user=
mysql_pass=


#Take actual list of databases from server asking first if user want to be able to deal with production databases also.
#It assumes that databases have name convention as fallows:
#Production databases: [DBNAME]_prod
#Test/dev DBs: [DBNAME]_test / [DBNAME]_dev
if (whiptail --title "$title" --yesno "Do You want to work also with production databases? " 8 78) then
    if (whiptail --title "$title" --yesno "Are You sure?!." 8 78) then
	whiptail --title "$title" --msgbox "So please be careful, ok?" 8 78
	DB_LIST=`echo "SHOW DATABASES;" | mysql -u$mysql_user -p$mysql_pass | grep -v -e "Database" -e "information_schema" -e "mysql" -e "performance_schema" -e "phpmyadmin"`
    else
	DB_LIST=`echo "SHOW DATABASES;" | mysql -u$mysql_user -p$mysql_pass | grep -v -e "Database" -e "information_schema" -e "mysql" -e "performance_schema" -e "phpmyadmin" -e 'prod$'`
    fi
else
    DB_LIST=`echo "SHOW DATABASES;" | mysql -u$mysql_user -p$mysql_pass | grep -v -e "Database" -e "information_schema" -e "mysql" -e "performance_schema" -e "phpmyadmin" -e 'prod$'`
fi


#Ask what to do
whattodo=$(whiptail --title "$title" --menu "What to do" 20 78 10 \
"[BACKUP]" "Backup database" \
"[RESTORE]" "Restore database" 3>&1 1>&2 2>&3)


#Ask user which DB he wants to deal with
DB=$(whiptail --title "$title" --menu "Choose database" 20 78 10 `for db in $DB_LIST; do echo $db "-"; done` 3>&1 1>&2 2>&3)

if [ "$whattodo" = "[BACKUP]" ]
then
    if (whiptail --title "$title" --yesno "Are You sure You want to backup $DB database ?." 8 78) then
	mkdir -p /data/backupmysql/mydumper/$DB/$date/$time
	#Make a backup
	/usr/share/mydumper/mydumper -B $DB -u $mysql_user -p $mysql_pass -o /data/backupmysql/mydumper/$DB/$date/$time --compress --build-empty-files --threads=8 --less-locking
	whiptail --title "$title" --msgbox "Backup of $DB database DONE!\n Path: /data/backupmysql/mydumper/$DB/$date/$time" 8 78
    else
	echo "I will not make backup $?."
    fi
else
	#Ask user to choose restore data
    CHOSEN_DATE=$(whiptail --title "$title" --menu "Chose Backup Date" 20 78 10 `for x in /data/backupmysql/mydumper/$DB/*; do echo "$x" "-" | sed 's!.*/!!'; done` 3>&1 1>&2 2>&3)
    CHOSEN_TIME=$(whiptail --title "$title" --menu "Chose Backup Time" 20 78 10 `for x in /data/backupmysql/mydumper/$DB/$CHOSEN_DATE/*; do echo "$x" "@" | sed 's!.*/!!'; done` 3>&1 1>&2 2>&3)
    if (whiptail --title "$title" --yesno "Are You sure You want to restore $DB database from /data/backupmysql/mydumper/$DB/$CHOSEN_DATE/$CHOSEN_TIME directory?\n \nBackup just before restore will be made" 12 78) then
	PASSWORD=$(whiptail --passwordbox "Please enter MySQL root password" 8 78 --title "$title" 3>&1 1>&2 2>&3)
	#Make backup just before restore
	mkdir -p /data/backupmysql/mydumper/before_upgrade/$DB/$date/$time
	/usr/share/mydumper/mydumper -B $DB -u $mysql_user -p $mysql_pass -o /data/backupmysql/mydumper/before_upgrade/$DB/$date/$time --compress --build-empty-files --threads=8 --less-locking
	#Recreate database for clean restore
	mysql -uroot -p$PASSWORD -e "drop database $DB;"
	mysql -uroot -p$PASSWORD -e "create database $DB;"
	#Restore
	/usr/share/mydumper/myloader -t 8 -B $DB -u root -p $PASSWORD -d /data/backupmysql/mydumper/$DB/$CHOSEN_DATE/$CHOSEN_TIME
	whiptail --title "$title" --msgbox "Restore of $DB database DONE!\n \nTo revert this operation restore backup from: \n /data/backupmysql/mydumper/before_upgrade/$DB/$date/$time" 10 85
    else
	echo "I will not restore"
    fi
fi

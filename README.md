# mysql_backup_restore
Interactive "windowed" script to backup and restore mysql databases

Bash script for easy backup and restore mysql dataases;

"Windows" made with whiptail:

https://en.wikibooks.org/wiki/Bash_Shell_Scripting/Whiptail

Backup/restore itselfs made with mydumper/myloader:

https://launchpad.net/mydumper

I will add soon option to use mysqldump (but take a look at mydumper - it's better ;p)

The only thing to do if You want to use my script is to edit .sh file and fill mysql_user and mysql_pass variables. I propose to use dedicated "backup user" to not hardcode root password. And even better use mysql --login-path function (but then You have to change script [replace "-u $mysql_user -p $mysql_pass" with "--login-path=backup"]. More info about login-path:

https://dev.mysql.com/doc/mysql-utilities/1.5/en/mysql-utils-intro-connspec-mylogin.cnf.html

Best regards,
Navid

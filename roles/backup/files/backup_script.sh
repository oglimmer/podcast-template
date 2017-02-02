#!/bin/bash

DATUM=`date +"%d"`
DATETIME=$(date +"%d-%H")

if [ -f /etc/backup-config ]; then
	. /etc/backup-config
fi

# BACKUP_TYPE defines if daily / hourly / etc
BACKUP_TYPE=$1
if [ -z "$BACKUP_TYPE" ]; then
	echo "Illegal BACKUP_TYPE=$BACKUP_TYPE"
	exit 1
fi

# 2nd parameter is used to skip uploads (with any value)
NO_UPLOAD=$2

MYSQL_CNF=/root/.my.cnf

#FTP_USER=
#FTP_PASS=
#FTP_HOST=

#SFTP_FETCH_HOST=...

fetchSftp()
{
	TARGET_DIR=$1
	REMOTE_DIR=$2
	shift 2
	for FILE in $*
	do
		scp -q $SFTP_FETCH_HOST:$REMOTE_DIR/$FILE $TARGET_DIR/$FILE
	done
}

backupMysql()
{
	# we want to backup all schemas except of the internal mysql and information_schema
	mysql --defaults-file=$MYSQL_CNF -e "show databases" >allSchemas.txt
	cat allSchemas.txt | grep -v "^Database$" | grep -v "^information_schema$" | grep -v "^mysql$" | grep -v "^performance_schema$" | grep -v "^sys$" >backupSchemas.txt
	awk 'NR==1{x=$0;next}NF{x=x" "$0}END{print x}' backupSchemas.txt >backupSchemasRow.txt
	DATABASES_TO_BACKUP=`cat backupSchemasRow.txt`
	rm allSchemas.txt backupSchemas.txt backupSchemasRow.txt

	mysqldump --defaults-file=$MYSQL_CNF --databases $DATABASES_TO_BACKUP | bzip2 | ccrypt -e -k /etc/keyfile -f >$1
}

# param: list of directories to tar,compress and encrypt
# DONT USE A / AT THE START OF THE DIRECTORIES!
backupDir()
{
	TARGET_FILE=$1
	shift
	TAR_ERROR_LOG=$(mktemp)
	tar cp -C / $* 2>$TAR_ERROR_LOG | bzip2 | ccrypt -e -k /etc/keyfile -f >$TARGET_FILE
	if [ -s $TAR_ERROR_LOG ] && ! grep -q "file changed as we read it" $TAR_ERROR_LOG; then
		cat $TAR_ERROR_LOG
	fi
	rm $TAR_ERROR_LOG
}

replicateFtp()
{
	BUFF=
	for f in $*
	do
		BUFF="${BUFF}put $f\n"
	done
	BUFF=`echo -e $BUFF`
	echo $BUFF

	cd /home/backup

	ftp -n -i -v $FTP_HOST <<END_OF_SESSION
	user $FTP_USER $FTP_PASS
	bin
	$BUFF
	bye
END_OF_SESSION

}

replicateGoogleDrive()
{
	[ -z "$GOOGLE_DRIVE_FOLDER" ] && echo "Var GOOGLE_DRIVE_FOLDER not set." && exit 1

	GOOGLE_DRIVE_REFRESH_KEY=$(/usr/local/bin/google_auth.sh refresh)
	cd /home/backup
	for file in $*
	do
		/usr/local/bin/google_up.sh $GOOGLE_DRIVE_REFRESH_KEY "$file" "$file" $GOOGLE_DRIVE_FOLDER
		#echo $file
	done

	/usr/local/bin/google_del.py $GOOGLE_DRIVE_REFRESH_KEY
}

NEW_FILES=()

if [ "$MYSQL" != "" ] && [ "$BACKUP_TYPE" == "DAILY" ]; then
	TARGET_FILE=/home/backup/mysql-$DATUM.sql.bz2.cpt
	backupMysql $TARGET_FILE
	NEW_FILES+=($(basename $TARGET_FILE))
fi

if [ "$CONFIG" != "" ] && [ "$BACKUP_TYPE" == "DAILY" ]; then
	TARGET_FILE=/home/backup/config-$DATUM.tar.bz2.cpt
	backupDir $TARGET_FILE etc/letsencrypt var/lib/mumble-server/mumble-server.sqlite
	NEW_FILES+=($(basename $TARGET_FILE))
fi

if [ "$WORDPRESS" != "" ] && [ "$BACKUP_TYPE" == "DAILY" ]; then
	TARGET_FILE=/home/backup/wordpress-$DATUM.tar.bz2.cpt
	backupDir $TARGET_FILE var/www/wordpress/wp-content
	NEW_FILES+=($(basename $TARGET_FILE))
fi

if [ "$MEDIA" != "" ] && [ "$BACKUP_TYPE" == "DAILY" ]; then
	TARGET_FILE=/home/backup/media-$DATUM.tar.bz2.cpt
	backupDir $TARGET_FILE var/www/media
	NEW_FILES+=($(basename $TARGET_FILE))
fi

if [ -z "$NO_UPLOAD" ]; then
	if (( ${#NEW_FILES[@]} > 0 )); then
		replicateGoogleDrive ${NEW_FILES[@]}
	fi
else
	echo "Skipping replication to google drive..."
fi

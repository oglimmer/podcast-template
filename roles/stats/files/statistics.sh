#!/bin/bash

ACCESS_FILES=(access access_webdav)
for FILE in ${ACCESS_FILES[@]}; do
	
	mkdir -p /var/www/webstats/$FILE
	(find /var/log/apache2/ -name "$FILE.*" -not -name "*.gz" -type f -mtime -$(date +%d) | while read -r filename
		do cat "$filename"
	done
	find /var/log/apache2/ -name "$FILE.*.gz" -type f -mtime -$(date +%d) | while read -r filename
		do zcat "$filename"
	done) | /bin/grep --text $(date +/%b/%Y:) | goaccess -a 1>/var/www/webstats/$FILE/index-$(date +%b-%Y).html 2>/dev/null

done

#
# mail log processing
#
TMP_FILE=$(mktemp)
for DAY in `seq 0 7`;
do
	DATE_PATTERN=$(date +'%b %e' --date "-$DAY day")
	grep -h --text "^$DATE_PATTERN" /var/log/mail.log* --exclude='*.gz' >>$TMP_FILE
done 
/usr/sbin/pflogsumm $TMP_FILE >/var/www/webstats/mail.txt 2>/dev/null
rm $TMP_FILE
# mail end

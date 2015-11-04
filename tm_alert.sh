#!/bin/bash
delay=30
warn_days=5
sleep $(($delay))
IFS=$'\n' pids=($(syslog -T sec -F '$PID' -k Message 'Backup completed successfully.'))
IFS=$'\n' timestamps=($(syslog -T sec -F '$Time' -k Message 'Backup completed successfully.'))
IFS=$'\n' timestampshum=($(syslog -F '$Time' -k Message 'Backup completed successfully.'))
IFS=',' read -a backup_names <<< "`tmutil destinationinfo | grep Name | sed "s/^Name          : //" | tr '\r\n' ','`"
last_backup=0 

len=${#timestamps[*]}
for nameb in ${backup_names[@]}
do
	last_backuph=`(( -1 ))`
	last_backup=`(( -1 ))`
	found=0
	i=$(( len-1 ))
	while [ $i -ne 0 ] && [ $found -eq 0 ]
	do
		str=`syslog -F '$Message' -k PID ${pids[$i]} | grep $nameb/`
		if [ -n "$str" ]; then
	    	last_backup=${timestamps[$i]}
	    	last_backuph=${timestampshum[$i]}
	    	found=1
		fi
		((i--))
	done

echo $nameb
echo $last_backuph
if [[ $last_backup < "`date -v-\$warn_days\d +%s`" ]]; then
	echo "backup" $nameb "is old"
	message="Last backup on "$nameb" is outdated, connect disk and click Continue "
	osascript <<EOT
        tell app "System Events"
            set question to display dialog "$message" buttons ["Cancel", "Continue"] default button 2 with icon caution with title "Time Machine Backup" 
            set answer to button returned of question
            if answer is equal to "Continue" then
				do shell script "tmutil startbackup"
			end if
        end tell
EOT
fi

done

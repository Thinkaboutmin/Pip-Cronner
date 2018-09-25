#! /bin/bash

function verbose_log {
	local MEN=$1
	local LEVEL_MEN=$2

	if (($LEVEL_MEN == 1))
	then
		echo "ERROR:$MEN" >> $WORK_LOG
	else
		echo "INFO:$MEN" >> $WORK_LOG
	fi
}

readonly INFO=0
readonly ERROR=1
readonly CONFIG_FILE="/etc/Pip_Updater/pip_updater.conf"
readonly WORK_LOG="/tmp/pip_updater.log"

echo "--------------------------$(date +%y-%m-%d)---------------------------" >> $WORK_LOG

if [ ! -s $CONFIG_FILE ]
then
	verbose_log "CONFIG_FILE is not settled!" $ERROR
	verbose_log "Leaving the program" $INFO
	exit
elif (($(id -u) != 0 ))
then
	verbose_log "Script ins't running as superuser!" $ERROR
	verbose_log "Leaving the program" $INFO
	exit
fi 

declare -a UPDATE_LIST
counter=0

for PROGRAM_PIP in $(cat $CONFIG_FILE | grep -v "#.*")
do
	if pip -q show $PROGRAM_PIP
	then
		UPDATE_LIST[$counter]=$PROGRAM_PIP
		counter=$(($counter + 1))
		verbose_log "$PROGRAM_PIP is marked to be updated" $INFO
	else
		verbose_log "The $PROGRAM_PIP does not exist! Ignoring" $ERROR
	fi
done

verbose_log "Starting update process" $INFO

for UPDATE_PROGRAM in ${UPDATE_LIST[*]}
do
	verbose_log "The $UPDATE_PROGRAM will be updated now" $INFO
	if pip -q install $UPDATE_PROGRAM --upgrade
	then
		verbose_log "The $UPDATE_PROGRAM was succefully updated" $INFO
	else
		verbose_log "The $UPDATE_PROGRAM was not updated, error arrived" $ERROR
	fi

done

verbose_log "End of the workload" $INFO

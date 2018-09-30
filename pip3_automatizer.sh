#! /bin/bash

# pip3_automatizer.sh - Automate boring programs downloaded from pip, the python package manager.

function how_to {
	verbose "Not implemented yet..." $INFO
	return 0
}

function verbose {
	local MEN=$1
	local LEVEL_MEN=$2
	if  [ "$LEVEL_MEN" = 1 ]
	then
		echo -e "\e[31mERROR:$MEN\e[0m"
	elif [ "$LEVEL_MEN" = 0 ]
	then
		echo -e "\e[34mINFO:$MEN\e[0m"
	else
		echo "$MEN"
	fi

	return 0
}

function check_requirements {
	if (($(id -u) != 0))
	then
		verbose "You need to run this script as root!" $ERROR
		return 1
	elif ! hash python 2>/dev/null
	then
		verbose "Python wasn't found on the system!" $ERROR
		return 1
	elif ! hash pip 2>/dev/null
	then
		verbose "Pip wasn't found on the system!" $ERROR
		return 1
	elif ! hash crontab 2>/dev/null
	then
		verbose "Crontab wasn't found on the system!" $ERROR
		return 1
	else
		verbose "Your passed in the system requirements!" $INFO
		return 0
	fi
}

function is_it_installed {
	local CONF_FOLDER="/etc/Pip_Updater"
	local SCRIPT_SOURCE="pip_script.sh"
	local VERIFY_FILES=("$CONF_FOLDER/" "$CONF_FOLDER/pip_script.sh" "$CONF_FOLDER/pip_updater.conf")

	local steps=4
 	local steps_done=0

	for FILES_VER in ${VERIFY_FILES[*]}
	do
		if [ -s $FILES_VER ]
		then
			steps_done=$(($steps_done + 1))
		fi
	done
	
	if crontab -l | grep -q "$CONF_FOLDER/$SCRIPT_SOURCE"
	then
		steps_done=$(($steps_done + 1))
	fi

	if (($steps_done == $steps))
	then
		verbose "It seems that this program is already installed" $INFO
		verbose "Not installing it again" $INFO
		return 0
	else
		verbose "It seems that this program is not installed yet" $INFO
		verbose "Numbers of steps that worked, meaning that it found traces of the program: $steps_done" $INFO
		return 1
	fi
	
}

function install_process {

	local SCRIPT_SOURCE="pip_script.sh"
	
	local CONF_FOLDER="/etc/Pip_Updater"

	verbose "Creating the folder and configuration file" $INFO

	verbose "Configuration folder will be create at $CONF_FOLDER" $INFO

	if [ -s $CONF_FOLDER ]
	then
		verbose "The folder is already created!" $ERROR
		return 1
	else
		mkdir $CONF_FOLDER

		if [ -s $CONF_FOLDER ]
		then
			verbose "The folder was created!" $INFO
		else
			verbose "The folder wasn't created!" $ERROR
			return 1
		fi
	fi
	
	local CONF_FILE="$CONF_FOLDER/pip_updater.conf"

	verbose "Creating the configuration file" $INFO


	echo "# One program per line" >> $CONF_FILE

	if [ -s $CONF_FILE ]
	then
		verbose "The configuration file was created!" $INFO
	else
		verbose "The configuraion file wasn't created!" $ERROR
		return 1
	fi

	verbose "Copying script to the $CONF_FOLDER" $INFO
	
	cp "$SCRIPT_SOURCE" "$CONF_FOLDER/$SCRIPT_SOURCE"

	if [ -s "$CONF_FOLDER/$SCRIPT_SOURCE" ]
	then
		verbose "The file was copied correctly!" $INFO
	else
		verbose "The file wasn't copied correctly!" $ERROR
		return 1
	fi
 
	verbose "Configuring crontab" $INFO

	# This fixes the empty space that is created when cron doesn't have anything to put before
	if [ ! -z "$(crontab -l)" ]
	then
		(crontab -l && echo "30 12,00 * * * $CONF_FOLDER/$SCRIPT_SOURCE") | crontab
	else
		echo "30 12,00 * * * $CONF_FOLDER/$SCRIPT_SOURCE" | crontab
	fi
	
	chmod +x "$CONF_FOLDER/$SCRIPT_SOURCE"

	verbose "Done configuring crontab!" $INFO

	verbose "Everything was configured, done!" $INFO

	return 0
}

function desinstall_process {
	local CONF_FOLDER="/etc/Pip_Updater"
	
	local SCRIPT_SOURCE="pip_script.sh"

	local TMP_LOG="/tmp/pip_updater.log"

	verbose "Deleting pip script now" $INFO
	
	# Rm -f is done to supress the error message
	# Thus, the program seems to run as it's expected
	if  [ -s $CONF_FOLDER ] && rm -r "$CONF_FOLDER"
	then
		verbose "Deleted the program folder" $INFO
	else
		verbose "Folder couldn't be deleted, moving on" $ERROR
	fi

	verbose "Deleting crontab configuration" $INFO

	if crontab -l | grep -q "$CONF_FOLDER/$SCRIPT_SOURCE"
	then
		(crontab -l | grep -v "$CONF_FOLDER/$SCRIPT_SOURCE") | crontab
		verbose "Deleted crontab configuration" $INFO
	else
		verbose "No crontab configuration was found, moving on!" $ERROR
	fi

	verbose "Deleting temporary log" $INFO
	
	if  [ -s $TMP_LOG ] && rm $TMP_LOG
	then
		verbose "Temporary log deleted" $INFO
	else
		verbose "Temporary log couldn't be deleted!" $ERROR
	fi

	return 0
}

# Default variables for message info and error

readonly ERROR=1
readonly INFO=0
readonly UNLABELLED=-1
readonly EXIT_MESSAGE="Leaving the program now"

verbose "Do you want to install or desinstall or leave the script? " $UNLABELLED
read -p "install-desinstall-leave : " OPTION

if [ $OPTION = "install" ]
then
	if check_requirements 
	then
		if is_it_installed
		then
			verbose $EXIT_MESSAGE $UNLABELLED
			exit
		else
			if install_process
			then
				verbose "Exiting $0"
				exit
			else
				verbose $EXIT_MESSAGE $UNLABELLED
				exit
			fi

		fi

	else
		verbose $EXIT_MESSAGE $UNLABELLED
		exit
	fi
elif [ $OPTION = "desinstall" ]
then
	if check_requirements
	then
		if desinstall_process
		then 
			verbose "Desinstalled!" $INFO
			exit
		else
			verbose "Couldn't desinstall it!" $ERROR
			exit
		fi
	else
		verbose $EXIT_MESSAGE $UNLABELLED
	fi
else
	verbose $EXIT_MESSAGE $UNLABELLED
	exit
fi


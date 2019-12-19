#!/bin/bash
# Works for Debian 9.9 (minimal)
# wget --no-check-certificate -P /YOUR_DIRECTORY/DBTerminal/ https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/install.sh && chmod +x /YOUR_DIRECTORY/DBTerminal/install.sh
# ./install.sh
# Actually you have to confirm with Yes/No
gitUrl=https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/DBTerminal/

installPackages=ca-certificates,locales-all,curl,screen,tmux,htop,git,default-jdk,jq

doInstallPackages() {
	IFS=, read -a listPackages <<< "$installPackages"
	for varPackage in "${listPackages[@]}";do 
		isInstalled=$(dpkg-query -W -f='${Status}' $varPackage 2>/dev/null | grep -c "ok installed")
		if [[ $isInstalled == 0 ]];then
			echo "[INFO]: -> Starte Installation von  [$varPackage]..."
			apt-get install $varPackage
		fi
	done
}

setLocalesDE() {
	apt-get clean && apt-get -y update && apt-get install -y locales && locale-gen de_DE.UTF-8
	echo -e "[DONE]: -> Lokale Sprache auf Deutsch gesetzt!"
}

fixBashrc() {
	fixPath="export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	bashrc="/root/.bashrc"
	tmpfile=instTempfile
	if [[ -f $bashrc ]];then
		while read -r line || [ -n "$line" ]; do 
			if [[ $line == $fixPath ]];then
				echo exportPathFound > instTempfile
			fi
		done < $bashrc
	fi

	if [[ -f $tmpfile ]];then
		if ! [[ -z $(grep -o 'exportPathFound' $tmpfile) ]];then
			rm $tmpfile
		fi
	else
		( echo "" ; echo "$fixPath" ; echo "" ) >> $bashrc
		echo -e "[Done/fixBashrc]: -> Linie [$fixPath] wurde der Datei <$bashrc> hinzugefuegt!"
	fi
}

installTMUXconf() {
	wget https://raw.githubusercontent.com/DerbanTW/bash/master/tmux.conf -O tmuxtmpfile
	cp tmuxtmpfile ~/.tmux.conf && rm tmuxtmpfile
}

createDBTDirectory() {
	actDir=${PWD##*/}
	if [[ $actDir == DBTerminal ]];then
		DBTDir="${PWD}/"
	elif [[ -z $(ls -d */ 2>/dev/null) ]] || ! [[ $(ls -d */ | grep -c DBTerminal/) == 1 ]];then
		DBTDir="${PWD}/DBTerminal/"
		mkdir DBTerminal
		echo -e "[DONE]: -> Neuer Ordner <$DBTDir> erstellt..."
	else
		DBTDir="${PWD}/DBTerminal/"
	fi
}

downloadDBTScripts() {
	if [[ -z $DBTDir ]];then
		echo -e "[Error]: -> [ERR_instsh_001] please report on: \n>> https://github.com/DerbanTW/DBTerminal/issues"
		exit 1
	fi
	cd $DBTDir
	DBTScripts=stdvariables.sh,functions.sh,mcfunctions.sh,cmdfunctions.sh,TerminalCMD.sh,reboundloop.sh,backup.sh
	gitUrl=https://raw.githubusercontent.com/DerbanTW/DBTerminal/master/DBTerminal/
	IFS=, read -a DBTScriptsArray <<< "$DBTScripts"
	for varScript in "${DBTScriptsArray[@]}";do
		if [[ -f $varScript ]];then
			echo -e "[INFO]: -> Datei <$varScript> bereits vorhanden..."
		else
			echo -e "${yellow}>> Starte download von [$varScript]...${norm}"
			varUrl=$gitUrl$varScript
			wget $varUrl -qO $varScript
			chmod +x $varScript
		fi
	done
}

createMCDirectory() {
	stdvarFile=""$DBTDir"stdvariables.sh"
	if ! [[ -f $stdvarFile ]];then
		echo -e "[Error]: -> [ERR_instsh_002] please report on: \n>> https://github.com/DerbanTW/DBTerminal/issues"
		exit 1
	fi
	fullmcDir=$(grep -o 'mcDir=[^"]*' $stdvarFile)
	stdmcDir=${fullmcDir#*=}
	if ! [[ -d $stdmcDir ]];then
		mkdir -p ""$stdmcDir"YourServer/"
		echo -e "[DONE]: -> Neuer Ordner <$stdmcDir> erstellt."
	fi
}

installCronJob() {
	CRON_FILE=/var/spool/cron/crontabs/root
	reboundShell="$(dirname "$(readlink -fn "$0")")/rebound.sh"
	cronJob="@reboot screen -dmS "ReboundLoop" bash -c ""$DBTDir"reboundloop.sh""
	cronExist=$(grep -o "$reboundShell" $CRON_FILE 2>/dev/null)
	if [[ -z $cronExist  ]];then
		crontab -l 2>/dev/null | { cat; echo "$cronJob"; } | crontab -
		echo -e "[DONE]: -> Crontab bearbeitet. DBTerminal startet nun bei jedem Reboot!"
	fi
}


echo Install Script started...

cd $(dirname "$(readlink -fn "$0")")
apt-get update
doInstallPackages
apt-get update
setLocalesDE
fixBashrc
installTMUXconf
createDBTDirectory
downloadDBTScripts
createMCDirectory
installCronJob

echo "Install packages finished!"


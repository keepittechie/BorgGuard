#!/bin/bash
####################################
#
# Backup script utilizing BorgBackup.
# Written by: KeepItTechie
# Required Dependencies:
#  - borg
#  - pwgen
#
####################################

# Init Procedure
init_repo () {
  # Set config file
  local config="./config"

  # Set varibles from config file.
  local passwd=$(sed '1q;d' $config)
  export BORG_PASSPHRASE=$passwd
  borg init --encryption=repokey $ndest
}

# Backup Procedure
backup_procedure() {
  # Set config file
  local config="./config"

  # Set varibles from config file.
  local passwd=$(sed '1q;d' $config)
  local dest=$(sed '2q;d' $config)
  #bkupdir="/home/josh/test" #Static Test Directory
  local bkupdir
  read -p "Enter the directory you want to backup. " bkupdir

  # Formating Borg Backup name.
  local day=$(date +%A)
  local hostname=$(hostname -s)
  local borg_bckupname="$hostname-$(date +%Y%m%d)-$(date +%H:%M:%S)"

  # Start backup precedure using variables
  echo "Backing up $bkupdir to $dest/$borg_bckupname"
  date
  export BORG_PASSPHRASE=$passwd
  echo
  echo "borg create -v --stats $dest::$borg_bckupname $bkupdir"
  borg create -v --stats $dest::$borg_bckupname $bkupdir

  # Print end status message.
  echo
  echo "Backup Complete"
  echo $day
}

while true
do
  # (1) Prompt user, is this is a new repository.
  read -p "Is this a new backup repository? y/n " newrepo

  # (2) Handle the script based on users response.
  case $newrepo in
   [yY]* ) read -p "Enter path to new repository. " ndest
           npasswd=$(pwgen -ysBv 15 1)
           touch ./config
           echo "$npasswd" > ./config
           echo "$ndest" >> ./config
           echo "Initializing a new backup repository."
           init_repo #init new repo procedure
           echo "Creating first backup."
           backup_procedure #backup procedure
           exit;;
   [nN]* ) cf="./config"
           if [ ! -f ./config ]; then
           echo "File not found!"
           fi
           if test -e "$cf"; then
             echo "Existing config file found."
             echo "Creating new backup."
             backup_procedure #backup procedure
           fi
           exit;;

   * )     echo "Please enter Y or N."
           exit;;
  esac
done

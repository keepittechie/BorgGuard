#!/usr/bin/env bash
####################################
#
# Backup script utilizing BorgBackup.
# Written by: KeepItTechie
# Required Dependencies:
#  - borg
#  - pwgen
#
####################################

function store_password {

    local passwd="$1"
    local user_home="$HOME"
    local store_name="/passwd_bytes.borg"

    local passwd_location="$user_home$store_name"

    python3 << ENDOFpy

import os, hashlib, re

passwd = "$passwd"
salt = os.urandom(32)
password_hash = hashlib.pbkdf2_hmac("sha256", passwd.encode("utf-8"), salt, 100000)

storage = salt + password_hash

strfile = r'$passwd_location'
with open(strfile,'bw') as f:
        f.write(storage)

ENDOFpy
}

function passd_with_asterisk {

    stty -echo

    local CHARCOUNT=0
    local CHAR
    local PASSWORD
    local PROMPT

    while IFS= read -p "$PROMPT" -r -s -n 1 CHAR
    do
        # Enter - accept password
        if [[ $CHAR == $'\0' ]] ; then
            break
        fi
        # Backspace
        if [[ $CHAR == $'\177' ]] ; then
            if [ $CHARCOUNT -gt 0 ] ; then
                CHARCOUNT=$((CHARCOUNT-1))
                PROMPT=$'\b \b'
                PASSWORD="${PASSWORD%?}"
            else
                PROMPT=''
            fi
        else
            CHARCOUNT=$((CHARCOUNT+1))
            PROMPT='*'
            PASSWORD+="$CHAR"
        fi
    done

    stty echo
    eval "$1='$PASSWORD'"

}

function check_passwd_len_char {

    local password
    password="$1"

    local LEN
    local let the_dector=0
    local let the_dector_1=0

    LEN=${#password}

    if [ "$LEN" -lt 6 ]; then

        ((the_dector ++))

    fi


    if [ -z "$(printf %s "$password" | tr -d "[:alnum:]")" ]; then
        ((the_dector_1 ++))
    else
        eval "$2='0'"
    fi



    if [[  $the_dector -eq "1" ]] && [[  $the_dector_1 -eq "1"  ]] ;then

        echo -e "\033[5;31;40m\nPassord is not strong enough\033[0m \n"
        printf "Your password needs to have at least one special character and be 6 characters long\nTry Again\n"


    elif [[ $the_dector -eq "1"  ]] && [[ $the_dector_1 -eq "0" ]] ; then

        echo -e "\033[5;31;40m\nPassord is not strong enough\033[0m \n"
        printf "Your password should be at least 6 characters long\nTry Again\n"

    elif [[ $the_dector -eq "0"  ]] && [[ $the_dector_1 -eq "1" ]] ; then

        echo -e "\033[5;31;40m\nPassord is not strong enough\033[0m \n"
        printf "Your password needs to have at least one special character\nTry Again\n"

    fi


}

function auto_setting_passwd {
    local npasswd

    npasswd=$(pwgen -ysBv 15 1)
    touch ./config.borg
    echo "$npasswd" > ./config.borg
    export BORG_PASSPHRASE=$npasswd

}

function man_setting_passwd {

    local passwd=$""
    local password
    local passwd_len_checker=1
    local i=0

    while true
    do

        while [ "$passwd_len_checker" -eq "1" ]; do


            if [[ $i -eq "4"  ]] ; then

                echo -e "\033[5;31;40m\nThe maximum amount of tries is reached\033[0m \nThe program will now quit"
                exit

            fi


            echo -n "Enter a password: "
            passd_with_asterisk  password
            passwd="$password"



            if [ -n "$passwd" ] ;then
                check_passwd_len_char "$passwd" passwd_len_checker

            fi

        done

        echo -en "\nVerify your password: "
        passd_with_asterisk  password

        if [[ "$passwd" == "$password" ]]; then

            export BORG_PASSPHRASE=$passwd
            break

        else

            passwd_len_checker=1
            password=$""
            passwd=$""

            ((i++))

            if [[ $i -ne "4" ]];then

                echo -e "\033[5;31;40m\nPassords didn't match\033[0m \nTry Again"

            fi


        fi

    done

    store_password "$passwd"

}

function check_passwd {

    local passwd="$1"
    local user_home="$HOME"
    local store_name="/passwd_bytes.borg"
    local passwd_location="$user_home$store_name"
    local detect_passwd_accuracy

    detect_passwd_accuracy=$(python3 << ENDOFpy

import os, hashlib, re

strfile = r'$passwd_location'

with open(strfile,'br') as f:
        storage_input = f.read()

salt_stored = storage_input[:32]
passwd_stored = storage_input[32:]

check_password = "$passwd"

encoded_check_password = hashlib.pbkdf2_hmac("sha256", check_password.encode(), salt_stored, 100000)


print (encoded_check_password == passwd_stored)


ENDOFpy
                          )

    echo "$detect_passwd_accuracy"

}

function getting_passwd_info {

    local passwd_option


    echo -e "\nTo create a backup a password will be created to secure the backup\nEnter 'a or A' to automatically create a password or 'm or M' to manually create a password \n\n"
    read -p "Default is manual to accept press enter: " passwd_option

    if [[ -z "$passwd_option" ]];then

        passwd_option=m

    fi



    case $passwd_option in

	[mM]* )

            man_setting_passwd
            echo "Manually set password" > ./config.borg

            ;;

	[aA]* )

            auto_setting_passwd

            ;;

	* )

            echo -e "\033[5;31;40m\nOption $passwd_option is unknown\033[0m \n"

            ;;

    esac
}

function detect_passwd_option {

    local config
    local des
    local passwd_option=$""
    local password
    local passwd_accurate

    while true; do
        echo -e "\nWhat method did you setup your password\n Enter 'a or A' for automatically\n Enter 'm or M' for manually\n\n"
        read -p "Please ENTER an option: " passwd_option


        case $passwd_option in

            [mM]* )

		while [[ "$passwd_accurate" != "True" ]]; do
                    echo -en "\nVerify your password: "
                    passd_with_asterisk  password

                    passwd_accurate=$(check_passwd "$password" )

                    if [[ "$passwd_accurate" != "True" ]];then

			echo -e "\033[5;31;40m\nPassord is not accurate \033[0m \nTry Again"

                    fi

		done


                config="./config.borg"
                dest=$(sed '2q;d' $config)

                break
                ;;


            [aA]* )


		# Set config file
		config="./config.borg"

		# Set varibles from config file.
		password=$(sed '1q;d' $config)
		dest=$(sed '2q;d' $config)
		break
		;;


            * )

		echo -e "\033[5;31;40m\nOption $passwd_option is unknown\033[0m \n"

		;;
        esac

    done

    eval "$2='$dest'"
    eval "$1='$password'"

}

# Init Procedure
function init_repo {

    borg init --encryption=repokey $ndest
}

# Backup Procedure
function backup_procedure {
    local bkupdir
    local backup_day
    local host_name
    local borg_bckupname
    local passwd
    local dest_get

    detect_passwd_option  passwd  dest_get

    echo
    #bkupdir="/home/josh/test" #Static Test Directory
    read -p "Enter the directory you want to backup. " bkupdir

    # Formating Borg Backup name.
    backup_day=$(date +%A\ the\ %d.%b.%Y)
    host_name=$(hostname -s)
    borg_bckupname="$host_name-$(date +%Y%m%d)-$(date +%H:%M:%S)"

    # Start backup precedure using variables
    echo -e "\nInitializing Backup $borg_bckupname\nBacking up $bkupdir to $dest_get on $backup_day"

    export BORG_PASSPHRASE=$passwd
    echo -e "\nborg create -v --stats $dest_get::$borg_bckupname $bkupdir"
    borg create -v --stats $dest_get::$borg_bckupname $bkupdir

    # Print end status message.
    echo -e "\nBackup Completed on $backup_day"
}

let i=0

while true
do
    # (1) Prompt user, is this is a new repository.
    read -p "Is this a new backup repository? y/n " newrepo

    # (2) Handle the script based on users response.
    case $newrepo in

        [yY]* ) i=0
                read -p "Enter path to new repository. " ndest
                echo "$ndest" > ./config.borg
                echo -e "\nInitializing a new backup repository."
                getting_passwd_info
                init_repo #init new repo procedure
                echo "Creating first backup."
                backup_procedure #backup procedure
                break
                ;;


        [nN]* ) i=0
                cf="./config"
                if [ ! -f ./config.borg ]; then
                    echo "File not found!"
                fi
                if test -e "$cf"; then
                    echo "Existing config file found."
                    echo "Creating new backup."
                    backup_procedure #backup procedure
                fi
                break
                ;;


        * )     ((i++))

                if [[ $i -ne "4" ]];then

                    echo -e "\033[5;31;40m\nOption $newrepo is unknown\033[0m \n"
                    echo "Please enter Y or N."

                else

                    echo -e "\033[5;31;40m\nOption $newrepo is unknown\033[0m \n"
                    echo "Program will now exit"
                    exit

                fi
                ;;
    esac
done

#!/usr/bin/env bash

# BorgGuard Backup Script
# Created by: KeepItTechie
# YouTube Channel: https://youtube.com/@KeepItTechie
# Blog: https://docs.keepittechie.com/

# Purpose:
# This script automates the process of creating and managing encrypted backups using BorgBackup.
# BorgGuard simplifies the setup and execution of secure backups by handling tasks such as:
# - Creating and storing secure passwords for encryption.
# - Initializing new Borg repositories.
# - Automating the backup process with detailed progress and status messages.
# - Providing both manual and automatic password generation options.
# - Ensuring strong password policies are enforced for security.
# - Verifying passwords to ensure they match the stored hash before performing operations.
# - Storing and retrieving password hashes securely.

# This script was created to make it easier for Linux users to secure their data with encrypted backups.
# By reducing the manual configuration required, BorgGuard provides a quick and efficient way to safeguard
# important data. 

# Please review the script before running it on your system to ensure it meets your requirements and to
# understand the changes it will make. Customize the backup directory and other settings as needed to 
# suit your environment.

# Full details and instructions can be found on my GitHub repository:
# https://github.com/keepittechie/borgguard

 _____                 _____            _             
| __  | ___  ___  ___ | __  | ___  ___ | |_  _ _  ___ 
| __ -|| . ||  _|| . || __ -|| .'||  _|| '_|| | || . |
|_____||___||_|  |_  ||_____||__,||___||_,_||___||  _|
                 |___|                           |_|  

# Dependencies check
check_dependencies() {
    for dep in borg pwgen python3; do
        if ! command -v $dep &> /dev/null; then
            echo "Error: $dep is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Logging function
log() {
    local msg="$1"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $msg"
}

# Store password securely
store_password() {
    local passwd="$1"
    local passwd_location="$HOME/passwd_bytes.borg"

    python3 << ENDOFpy
import os, hashlib

passwd = "$passwd"
salt = os.urandom(32)
password_hash = hashlib.pbkdf2_hmac("sha256", passwd.encode("utf-8"), salt, 100000)
storage = salt + password_hash

with open('$passwd_location', 'bw') as f:
    f.write(storage)
ENDOFpy
}

# Read password with asterisks
passd_with_asterisk() {
    stty -echo
    local CHAR PASSWORD
    while IFS= read -p "" -r -s -n 1 CHAR; do
        if [[ $CHAR == $'\0' ]]; then
            break
        elif [[ $CHAR == $'\177' ]]; then
            if [ ${#PASSWORD} -gt 0 ]; then
                PASSWORD="${PASSWORD%?}"
                printf '\b \b'
            fi
        else
            PASSWORD+="$CHAR"
            printf '*'
        fi
    done
    stty echo
    printf '\n'
    eval "$1='$PASSWORD'"
}

# Check password length and special character
check_passwd_len_char() {
    local password="$1"
    local special_char_check=$(printf %s "$password" | tr -d "[:alnum:]")
    local length_check=${#password}

    if [ "$length_check" -lt 6 ] || [ -z "$special_char_check" ]; then
        echo -e "\033[5;31;40m\nPassword is not strong enough\033[0m"
        echo "Your password needs to be at least 6 characters long and contain at least one special character."
        return 1
    else
        return 0
    fi
}

# Automatically set password
auto_setting_passwd() {
    local npasswd=$(pwgen -ysBv 15 1)
    echo "$npasswd" > ./config.borg
    export BORG_PASSPHRASE="$npasswd"
}

# Manually set password
man_setting_passwd() {
    local passwd password

    for i in {1..4}; do
        echo -n "Enter a password: "
        passd_with_asterisk password
        passwd="$password"

        if check_passwd_len_char "$passwd"; then
            echo -n "Verify your password: "
            passd_with_asterisk password

            if [ "$passwd" == "$password" ]; then
                export BORG_PASSPHRASE="$passwd"
                store_password "$passwd"
                return 0
            else
                echo -e "\033[5;31;40m\nPasswords didn't match\033[0m\nTry Again"
            fi
        fi
    done

    echo -e "\033[5;31;40m\nMaximum attempts reached. Exiting.\033[0m"
    exit 1
}

# Check password against stored hash
check_passwd() {
    local passwd="$1"
    local passwd_location="$HOME/passwd_bytes.borg"

    python3 << ENDOFpy
import os, hashlib

with open('$passwd_location', 'br') as f:
    storage_input = f.read()

salt_stored = storage_input[:32]
passwd_stored = storage_input[32:]
check_password = "$passwd"
encoded_check_password = hashlib.pbkdf2_hmac("sha256", check_password.encode(), salt_stored, 100000)

print(encoded_check_password == passwd_stored)
ENDOFpy
}

# Get password information
getting_passwd_info() {
    read -p "To create a backup a password will be created to secure the backup\nEnter 'a' to automatically create a password or 'm' to manually create a password (default: manual): " passwd_option
    passwd_option=${passwd_option:-m}

    case $passwd_option in
        [mM]*) man_setting_passwd ;;
        [aA]*) auto_setting_passwd ;;
        *) echo -e "\033[5;31;40m\nInvalid option\033[0m" ;;
    esac
}

# Detect password option
detect_passwd_option() {
    while true; do
        read -p "Enter 'a' for automatic password or 'm' for manual password: " passwd_option
        case $passwd_option in
            [mM]*) while true; do
                        echo -n "Verify your password: "
                        passd_with_asterisk password
                        if [ "$(check_passwd "$password")" == "True" ]; then
                            local dest=$(sed '2q;d' ./config.borg)
                            eval "$2='$dest'"
                            eval "$1='$password'"
                            return 0
                        else
                            echo -e "\033[5;31;40m\nPassword is not accurate\033[0m\nTry Again"
                        fi
                    done ;;
            [aA]*) local password=$(sed '1q;d' ./config.borg)
                   local dest=$(sed '2q;d' ./config.borg)
                   eval "$2='$dest'"
                   eval "$1='$password'"
                   return 0 ;;
            *) echo -e "\033[5;31;40m\nInvalid option\033[0m" ;;
        esac
    done
}

# Initialize repository
init_repo() {
    borg init --encryption=repokey "$1"
}

# Backup procedure
backup_procedure() {
    detect_passwd_option passwd dest
    read -p "Enter the directory you want to backup: " bkupdir

    local backup_day=$(date '+%A the %d.%b.%Y')
    local host_name=$(hostname -s)
    local borg_bckupname="$host_name-$(date +%Y%m%d)-$(date +%H:%M:%S)"

    log "Initializing Backup $borg_bckupname. Backing up $bkupdir to $dest on $backup_day."
    export BORG_PASSPHRASE="$passwd"
    borg create -v --stats "$dest::$borg_bckupname" "$bkupdir"

    log "Backup Completed on $backup_day."
}

# Main function
main() {
    check_dependencies
    while true; do
        read -p "Is this a new backup repository? (y/n): " newrepo
        case $newrepo in
            [yY]*) read -p "Enter path to new repository: " ndest
                   echo "$ndest" > ./config.borg
                   getting_passwd_info
                   init_repo "$ndest"
                   backup_procedure
                   break ;;
            [nN]*) if [ ! -f ./config.borg ]; then
                       echo "Config file not found!"
                       exit 1
                   else
                       backup_procedure
                       break
                   fi ;;
            *) echo -e "\033[5;31;40m\nInvalid option\033[0m" ;;
        esac
    done
}

main

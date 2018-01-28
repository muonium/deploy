#!/usr/bin/env bash

usage(){
    echo -e "--deploy-new-release [branch name] or -n\n\
--change-branch [branch name] or -b [branch name]\n\
-ls or --list-branches\n\
-x or --fix-permissions
--backup
-r or --rollback
-u
-c or --fix-conf or -c help or --fix-conf help

In order to edit the script, use the 'edit' argument, such as 'deploy edit'"
    exit
}

err(){
	echo -e "\033[1;31m$1\033[0m";exit
}

ok_green(){
	echo -e "[ \033[1;32mOK\033[0m ]"
}

green_it(){
	echo -e "\033[1;32m$1\033[0m"
}

new_release(){
    b=$1
    if [[ -z $b ]]; then
	while [[ -z $b ]];do
		read -p "Enter the branch name: " b
	done
    fi
    echo "Saving current release..."
    cp -r /var/www/html/core /var/www/html/core.bckp && ok_green
    echo "Deleting current release..."
    rm -rf /var/www/html/core && ok_green
    echo "Downloading new release..."
    cd /var/www/html/
    git clone https://github.com/muonium/core &>/dev/null && ok_green
    cd core
    echo "Switching branch..."
    git checkout $b &>/dev/null && ok_green || err "Was the branch name correct?"
    echo "Applying configuration files..."
    deploy -c
    cd - &>/dev/null
    chown -R www-data:www-data /var/www/html/core
    local choice="";while test -z $choice;do read -p "Do you want to apply the template configuration files? (y|n)" choice;done
    if [[ $choice == "y" ]];then deploy -c && green_it "Successfully applied!" || err "Failed to apply template configuration files...";fi
    echo "Setting up permissions..."
    umask 770 /var/www/html/core && ok_green || err "Failed to set up permission"
	git clone https://github.com/muonium/infra-scripts /var/www/html/core/cron&&
	git clone https://github.com/muonium/admin-panel /var/www/html/core/cron/panel
    green_it "Everything's good!"
}

roll_back(){
	if [[ ! -d "/var/www/html/core.bckp" ]];then
		err "Error, backup might have been deleted. Exiting...";exit
	fi
	rm -rf /var/www/html/core
	mv /var/www/html/core.bckp /var/www/html/core
	green_it "Done."
}

backup_it(){
	if test -d /var/www/html/core.bckp;then
	local choice="";
		while test -z $choice;do
			read -p "do you really want to delete the older backup? (y|n)" choice
		done
	fi

	if [[ $choice == "y" ]];then
		rm -rf /var/www/html/core.bckp
		cp -r /var/www/html/core /var/www/html/core.bckp
	else
		echo exiting
		exit
	fi
	cp -r /var/www/html/core /var/www/html/core.bckp
	green_it "Done"
}


branch_deploy(){
    b=$1
    if [[ -z $b ]]; then
	while test -z $b;
	do
		read -p "Enter branch name: " b
	done
    fi
    cd /var/www/html/core
    git checkout $b --force &>/dev/null && green_it "Successfully switched to $b!" ||
    echo "Error, branch might not exist."
    local choice=""
    while test -z $choice;do read -p "Do you want to apply the template configuration files \
to this branch? (y|n)" choice;done
    if [[ $choice == "y" ]];then deploy -c && green_it "Configuration files successfully applied!" || echo "Failed to \
apply configuration files from template!";fi
    cd - &>/dev/null
    echo "Done."
}

list_branches(){
	k=$1
	cd /var/www/html/core;
	case $k in
		"remote") git branch -a
			;;
		*) git branch
			;;
	esac
	cd - &>/dev/null
}

fix_conf(){

	k=$1
	case $k in
		"mail") nano /var/www/html/template/config/confMail.php
			;;
		"database"|"db") nano /var/www/html/template/config/confDB.php
			;;
		"payment") nano /var/www/html/template/config/confPayments.php
			;;
		"help") echo -e "mettre à jour les fichiers de conf:\n\
deploy -c applique la template à l'application
deploy -c mail permet d'éditer le fichier de conf confMail.php\n\
deploy -c db ou deploy -c database permet d'éditer confDB.php\n\n\
si vous faites deploy -c mail, pas besoin de faire quoi que ce soit une fois l'éditeur de texte quitté, le script update automatiquement"
		;;
	esac

	if test -d /var/www/html/core/config;then
		cp -r /var/www/html/template/config /var/www/html/core/.
	fi
	echo "Done."
}

fix_perms(){
	chmod -R 770 /var/www/html/core
	chmod -R 770 /var/www/html/nova
	chown -R www-data:www-data /var/www/html/core
	chown -R www-data:www-data /var/www/html/nova
	echo "Done."
}

update_server(){
	echo "Fetching changes..."
	apt update &>/dev/null && echo -e "Success.\nNext." ||
	err "Error while updating. Exiting."
	apt upgrade -y &>/dev/null && echo "Successfully put up-to-date!" ||
	echo "Error while upgrading.";exit
}

k=$1
args=$2
case $k in
    "--deploy-new-release"|"-n") new_release $args
        ;;
    "--rollback"|"-r") roll_back;
	;;
    "--backup") backup_it;
	;;
    "--change-branch"|"-b") branch_deploy $args
        ;;
    "--help"|"-h") usage;
        ;;
    "--list-branches"|"-ls") list_branches $args
	;;
    "--fix-conf"|"-c") fix_conf $args
	;;
    "--fix-permissions"|"-x") fix_perms
	;;
    "--update-server"|"-u") update_server
	;;
    "edit") nano /opt/bin/deploy
	;;
    *)  usage
        ;;
esac
exit

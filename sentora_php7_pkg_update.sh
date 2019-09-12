#!/bin/bash

SENTORA_UPDATER_VERSION="0.3.0"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"

#--- Display the 'welcome' splash/user warning info..
echo ""
echo "#############################################################################################"
echo "#  Welcome to the Unofficial Sentora PHP 7 PKG updater. Installer v.$SENTORA_UPDATER_VERSION  #"
echo "#############################################################################################"

echo -e "\nChecking that minimal requirements are ok"

# Check if the user is 'root' before updating
if [ $UID -ne 0 ]; then
    echo "Install failed: you must be logged in as 'root' to install."
    echo "Use command 'sudo -i', then enter root password and then try again."
    exit 1
fi
# Ensure the OS is compatible with the launcher
if [ -f /etc/centos-release ]; then
    OS="CentOs"
    VERFULL=$(sed 's/^.*release //;s/ (Fin.*$//' /etc/centos-release)
    VER=${VERFULL:0:1} # return 6 or 7
elif [ -f /etc/lsb-release ]; then
    OS=$(grep DISTRIB_ID /etc/lsb-release | sed 's/^.*=//')
    VER=$(grep DISTRIB_RELEASE /etc/lsb-release | sed 's/^.*=//')
elif [ -f /etc/os-release ]; then
    OS=$(grep -w ID /etc/os-release | sed 's/^.*=//')
    VER=$(grep VERSION_ID /etc/os-release | sed 's/^.*"\(.*\)"/\1/')
else
    OS=$(uname -s)
    VER=$(uname -r)
fi
ARCH=$(uname -m)

echo "Detected : $OS  $VER  $ARCH"

if [[ "$OS" = "CentOs" && ("$VER" = "6" || "$VER" = "7" ) || 
      "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]] ; then
    echo "Ok."
else
    echo "Sorry, this OS is not supported by Sentora." 
    exit 1
fi

### Ensure that sentora is installed
if [ -d /etc/sentora ]; then
    echo "Found Sentora, processing..."
else
    echo "Sentora is not installed, aborting..."
    exit 1
fi

######################################################################################


	################################################################################
	
	# Start Sentora php 7.3 config update
	
	################################################################################

	if [[ "$VER" = "16.04" ]]; then
	
	# Fix missing php.ini settings sentora needs
	echo ""
	echo "Fix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
	echo "setting upload_tmp_dir = /var/sentora/temp/"
	echo ""
	sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
	echo "Setting session.save_path = /var/sentora/sessions"
	sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
	
	# Fix postfix not working after upgrade to 16.04
	echo ""
	echo "Fixing postfix not working after upgrade to 16.04..."
	# *Workaround* Postfix disable daemon_directory for now to allow startup after update
	sed -i 's|daemon_directory = /usr/lib/postfix|#daemon_directory = /usr/lib/postfix|g' /etc/sentora/configs/postfix/main.cf
	systemctl restart postfix
	
	# Install missing php7.3-xml for system and roundcube
	echo ""
	echo "Install missing php7.3-xml for system and roundcube..."
	apt-get -y install php7.3-xml php7.3-gd
				
	fi

	################################################################################
	
	# Start Sentora php 7.3 module package update Below
	
	################################################################################
	
	echo ""
	echo "Starting PHP 7.3 with Snuffaluffagus packages updates"
		
	#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	echo ""
	echo "Downloading Updated package files..." 
	rm -rf sentora_php7_upgrade
	mkdir -p sentora_php7_upgrade
	cd sentora_php7_upgrade
	wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	echo ""
	echo "Unzipping files..."
	unzip -o sentora_php7_upgrade.zip
	
	# Upgrade apache_admin with apache_admin 1.0.x
	echo ""
	echo "Updating Apache_admin module..."
	rm -rf /etc/sentora/panel/modules/apache_admin
	cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/	
	
	# Upgrade domains_module to 1.0.x
	echo ""
	echo "Updating Domains module..."
	rm -rf /etc/sentora/panel/modules/domains/
	cp -r  ~/sentora_php7_upgrade/modules/domains $PANEL_PATH/panel/modules/
	
	# Upgrade ftp_management module 1.0.x
	echo ""
	echo "Updating FTP_management module..."
	rm -rf /etc/sentora/panel/modules/ftp_management/
	cp -r  ~/sentora_php7_upgrade/modules/ftp_management $PANEL_PATH/panel/modules/
		
	# Upgrade parked_Domains module 1.0.x
	echo ""
	echo "Updating Parked_Domains module..."
	rm -rf /etc/sentora/panel/modules/parked_domains/
	cp -r  ~/sentora_php7_upgrade/modules/parked_domains $PANEL_PATH/panel/modules/
	
	# Upgrade Sub_Domains module 1.0.x
	echo ""
	echo "Updating Sub_Domains module..."
	rm -rf /etc/sentora/panel/modules/sub_domains/
	cp -r  ~/sentora_php7_upgrade/modules/sub_domains $PANEL_PATH/panel/modules/
	
	# Copy New Apache config template files
	echo ""
	echo "Updating Sentora vhost templates..."
	rm -rf /etc/sentora/configs/apache/templates/
	cp -r ~/sentora_php7_upgrade/preconf/apache/templates /etc/sentora/configs/apache/
	echo ""
	
	
	################################################################################
	
	# Start Roundcube-1.3.10 upgrade Below
	
	################################################################################
	
	echo ""
	echo "Starting Roundcube upgrade to 1.3.10..."
	
	wget -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
	tar xf roundcubemail-*.tar.gz
	cd roundcubemail-1.3.10
	bin/installto.sh /etc/sentora/panel/etc/apps/webmail/
	
	chown -R root:root /etc/sentora/panel/etc/apps/webmail
	
	
	################################################################################
	
	# Start PHPsysinfo 3.3.1 upgrade Below
	
	################################################################################
	
	echo ""
	echo "Starting PHPsysinfo upgrade to 3.3.1..."
	rm -rf /etc/sentora/panel/etc/apps/phpsysinfo/
	cp -r  ~/sentora_php7_upgrade/etc/apps/phpsysinfo $PANEL_PATH/panel/etc/apps/
	
	
	################################################################################
	
	# Start PHPmyadmin 4.9 upgrade Below - TESTING WHICH VERSION IS BEST HERE.
	
	################################################################################
	
	#echo ""
	#echo "Starting PHPmyadmin upgrade to 4.9..."
	#mkdir -p /etc/sentora/panel/etc/apps/phpmyadmin-old
	#cp -r /etc/sentora/panel/etc/apps/phpmyadmin/* /etc/sentora/panel/etc/apps/phpmyadmin-old
	#rm -rf /etc/sentora/panel/etc/apps/phpmyadmin/*
	
	# copy original conf bak to phpmyadmin
	#cp -r /etc/sentora/panel/etc/apps/phpmyadmin-old/config.inc.php /etc/sentora/panel/etc/apps/phpmyadmin/
	# copy new PHPmyadmin 4.9 files to PHPmyadmin dir
	#cp -r  ~/sentora_php7_upgrade/etc/apps/phpmyadmin/* $PANEL_PATH/panel/etc/apps/phpmyadmin
	
	
	################################################################################
	
	echo "Done Processing PHP 7.3 with Snuffaluffagus packages updates. Enjoy."
	
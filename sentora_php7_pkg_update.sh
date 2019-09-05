#!/bin/bash

SENTORA_UPDATER_VERSION="1.0.3"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"

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
	
	# Start Sentora php 7.3 module package update Below
	
	################################################################################
	
	echo "Starting PHP 7.3 with Snuffaluffagus packages updates"
		
	#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	echo ""
	echo "Downloading Updated package files..." 
	#mkdir -p sentora_php7_upgrade
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
	
	echo "Done Processing PHP 7.3 with Snuffaluffagus packages updates. Enjoy."
	



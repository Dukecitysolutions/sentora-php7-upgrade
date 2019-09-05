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

## If OS is CENTOS 7 then perform update
if [[ "$OS" = "CentOs" ]]; then

	PACKAGE_INSTALLER="yum -y -q install"

	if [[ "$VER" = "6" ]]; then
    
	# START
	##############################################################################################
	    
	echo "Starting PHP 7.3 with Snuffaluffagus update on Centos 6.*"	

	yum clean all
	rm -rf /var/cache/yum/*

	# Add Repos
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
	wget http://rpms.remirepo.net/enterprise/remi-release-6.rpm
	rpm -Uvh remi-release-6.rpm epel-release-latest-6.noarch.rpm
	
	# Install PHP 7.3 and update modules
	yum -y install yum-utils
	yum-config-manager --enable remi-php73
	yum -y update
	yum -y install php-zip php-mysql php-mcrypt
	
	# Install git
	yum -y install git
	
		
	# END
	##############################################################################################


    elif [[ "$VER" = "7" ]]; then
        
		
	# START
	##############################################################################################	
		
	echo "Starting PHP 7.3 with Snuffaluffagus update on Centos 7.*"	
	
	yum clean all
	rm -rf /var/cache/yum/*

	# Add Repos
	wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm

	# Install PHP 7.3 and update modules
	yum -y install yum-utils
	yum-config-manager --enable remi-php73
	yum -y update
	yum -y install php-zip php-mysql php-mcrypt
	
	#yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-fpm php-intl php-imagick php-pspell wget

	# Install git
	yum -y install git
	

	# END
	##############################################################################################
	
	else
        
	#add something here for non-Centos OS
	echo "Wrong CentOS Version. Exiting update."
	exit 1


    fi
fi	

#################################################################################
if [[ "$OS" = "Ubuntu" || "$OS" = "debian" ]]; then
	
	PACKAGE_INSTALLER="apt-get -yqq install"
	
    if [[ "$VER" = "16.04" ]]; then
	
	# START
	##############################################################################################
	
		echo "Starting PHP 7.3 with Snuffaluffagus update on Ubuntu 16.04"
		
        # start here
		
		sudo add-apt-repository ppa:ondrej/php
		sudo apt-get -yqq update
		sudo apt-get -yqq upgrade
		
		# Add repos
		#deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		#deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		
		# Install PHP 7 and modules
		apt-get -yqq install php7.3 php7.3-common 
		apt-get -yqq install php7.3-mysql php7.3-mbstring
		apt-get -yqq install php7.3-zip 
		apt-get -yqq install php7.0-dev libapache2-mod-php7.3
		apt-get -yqq install php7.3-dev
		
		#apt install php-pear php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml php7.3-fpm libapache2-mod-php7.3 php7.3-imagick php7.3-recode php7.3-tidy php7.3-xmlrpc php7.3-intl

		# Disable Apache mod_php7.0
		sudo a2dismod php7.0
		# Enable Apache mod_php7.3
		sudo a2enmod php7.3
		
		# Install git
		apt-get -y install git
		
		# Fix missing php.ini settings sentora needs
		echo ""
		echo "Fix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
		echo "setting upload_tmp_dir = /var/sentora/temp/"
		echo ""
		sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
		echo "Setting session.save_path = /var/sentora/sessions"
		sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
		
    fi
		# ....
fi

	# END
	################################################################################################
	
	################################################################################
	
	# Start Snuffleupagus install Below
	
	################################################################################
	
	
	# Install Snuffleupagus
	#yum -y install git
	git clone https://github.com/nbs-system/snuffleupagus
	
	#setup PHP_PERDIR in Snuffleupagus.c in src
	cd snuffleupagus/src
	
	sed -i 's/PHP_INI_SYSTEM/PHP_INI_PERDIR/g' snuffleupagus.c
		
	phpize
	./configure --enable-snuffleupagus
	make clean
	make
	make install
	
	cd ~
	
	# Setup Snuffleupagus Rules
	mkdir /etc/sentora/configs/php
	mkdir /etc/sentora/configs/php/sp
	touch /etc/sentora/configs/php/sp/snuffleupagus.rules
	
	
	
	if [[ "$OS" = "Ubuntu" ]]; then
	
		# Enable snuffleupagus in PHP.ini
		echo '' >> /etc/php/7.3/apache2/php.ini
		echo 'extension=snuffleupagus.so' >> /etc/php/7.3/apache2/php.ini
		echo '' >> /etc/php/7.3/apache2/php.ini
		echo 'sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules' >> /etc/php/7.3/apache2/php.ini
		
    elif [[ "$OS" = "CentOs" ]]; then
	
		# Enable snuffleupagus in PHP.ini
		echo '' >> /etc/php.ini
		echo 'extension=snuffleupagus.so' >> /etc/php.ini
		echo '' >> /etc/php.ini
		echo 'sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules' >> /etc/php.ini
		
		#### FIX - Suhosin loading in php.ini
		zip -r /etc/php.d/suhosin.zip /etc/php.d/suhosin.ini
		rm -rf /etc/php.d/suhosin.ini
		
    fi
	
	
	# Restart Apache service
	if [[ "$OS" = "Ubuntu" ]]; then
		systemctl restart apache2
    elif [[ "$OS" = "CentOs" ]]; then
		systemctl restart httpd
    fi
	

	################################################################################
	
	# Start Sentora upgrade Below
	
	################################################################################
		
	#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	mkdir -p sentora_php7_upgrade
	cd sentora_php7_upgrade
	wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	unzip sentora_php7_upgrade.zip
	
	# ####### start here   Upgrade __autoloader() to x__autoloader()
	#rm -rf $PANEL_PATH/panel/dryden/loader.inc.php
	#cd 
	#cp -r /sentora_update/loader.inc.php $PANEL_PATH/panel/dryden/
	sed -i 's/__autoload/x__autoload/g' /etc/sentora/panel/dryden/loader.inc.php
	
	
	# Upgrade domains_module to 1.0.1
	rm -rf /etc/sentora/panel/modules/domains/
	cp -r  ~/sentora_php7_upgrade/modules/domains $PANEL_PATH/panel/modules/
		
	# Upgrade parked_Domains module 1.0.1
	rm -rf /etc/sentora/panel/modules/parked_domains/
	cp -r  ~/sentora_php7_upgrade/modules/parked_domains $PANEL_PATH/panel/modules/
	
	# Upgrade Sub_Domains module 1.0.1
	rm -rf /etc/sentora/panel/modules/sub_domains/
	cp -r  ~/sentora_php7_upgrade/modules/sub_domains $PANEL_PATH/panel/modules/
	
	# install Smarty files
	cp -r ~/sentora_php7_upgrade/etc/lib/smarty /etc/sentora/panel/etc/lib/

	# Copy New Apache config template files
	cp -r ~/sentora_php7_upgrade/preconf/apache/templates /etc/sentora/configs/apache/
	
	# Upgrade apache_admin with apache_admin 1.0.1
	rm -rf /etc/sentora/panel/modules/apache_admin
	cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/
	# Download new Apache_admin 1.0.1	
	#zppy repo add zppy-repo.dukecitysolutions.com
	#zppy update
	#zppy install apache_admin
	
	
	# Update Sentora Core Mysql tables
	# get mysql root password, check it works or ask it
	mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
	while ! mysql -u root -p$mysqlpassword -e ";" ; do
	read -p "Can't connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
	done
	echo -e "Connection mysql ok"
	#wget -nv -O  update.sql https://raw.githubusercontent.com/sentora/sentora-installers/master/preconf/sentora-update/1-0-3/sql/update.sql #need url
	mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sentora_1_0_3_1.sql
	
	
	#sudo /usr/bin/php -q /etc/sentora/panel/bin/daemon.php
	
	# Install php-fpm
	#yum -y install php-fpm
	
	# Create CGI Scripts
	#....
	
	# Fix permissions to prep and secure sentora for PHP-FPM
	# Needs research and testing. All help is needed
	# Panel permissions
	#chmod 0770 /etc/sentora
	#chmod 0770 /etc/sentora/panel
	
	# Logs permissions
	#chmod 0770 /var/sentora/logs/domains/*
	
	# Hostdata permissions
	#chmod 0740 /var/sentora/hostdata
	#chmod 0740 /var/sentora/hostdata/*/public_html
	#chmod 0740 /var/sentora/hostdata/*/public_html/tmp

echo "We are done upgrading Sentora 1.0.3 - PHP 5.* w/Suhosin to PHP 7.3 w/Snuffleupagus"

#!/bin/bash

SENTORA_UPDATER_VERSION="1.0.3.1-Build 0.3.6-BETA"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"
PANEL_CONF="/etc/sentora/configs"

# Bash Color
red='\e[0;31m'
green='\e[0;32m'
yellow='\e[0;33m'
bold='\e[1m'
underlined='\e[4m'
NC='\e[0m' # No Color
COLUMNS=$(tput cols)

# -------------------------------------------------------------------------------
# Installer Logging
#--- Set custom logging methods so we create a log file in the current working directory.

	logfile=$(date +%Y-%m-%d_%H.%M.%S_sentora_php7_install.log)
	touch "$logfile"
	exec > >(tee "$logfile")
	exec 2>&1
# -------------------------------------------------------------------------------	
	
#--- Display the 'welcome' splash/user warning info..
echo ""
echo "############################################################################################"
echo "#  Welcome to the Unofficial Sentora PHP 7.3 upgrader. Installer v.$SENTORA_UPDATER_VERSION  #"
echo "############################################################################################"
echo ""
echo -e "\n- Checking that minimal requirements are ok"

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

echo "- Detected : $OS  $VER  $ARCH"

if [[ "$OS" = "CentOs" && ("$VER" = "6" || "$VER" = "7" ) || 
      "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]] ; then
    echo "- Ok."
else
    echo "Sorry, this OS is not supported by Sentora." 
    exit 1
fi

### Ensure that sentora is installed
if [ -d /etc/sentora ]; then
    echo "- Found Sentora, processing..."
else
    echo "Sentora is not installed, aborting..."
    exit 1
fi

# -------------------------------------------------------------------------------

while true; do
	echo ""
	echo "# -----------------------------------------------------------------------------"
	echo "# THIS CODE IS NOT FOR PRODUCTION SYSTEMS YET. -TESTING ONLY-. USE AT YOUR OWN RISK."
	echo "# HAPPY SENTORA PHP 7 TESTING. ALL HELP IS NEEDED TO GET THIS OFF THE GROUND AND RELEASED."
	echo "# -----------------------------------------------------------------------------"
	echo -e ""
	echo "###############################################################################"
	echo -e "\nPlease make sure the Date/Time is correct. This script will need correct Date/Time to install correctly"
	echo -e "If you continue with wrong date/time this script/services (phpmyadmin) may not install correctly. DO NOT CONTINUE IF DATE/TIME IS WRONG BELOW"
	echo ""
	echo -e "\nSet Date/time with this command here - date -s \"19 APR 2012 11:14:00\" "
	# show date/time to make sure its correct
	echo ""
		date
	echo ""
	echo "###############################################################################"
	echo "# -----------------------------------------------------------------------------"
    read -p "Do you wish to continue installing this program? y/yes or n/no..| " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# -------------------------------------------------------------------------------

## If OS is CENTOS then perform update
if [[ "$OS" = "CentOs" ]]; then

	PACKAGE_INSTALLER="yum -y -q install"

	if [[ "$VER" = "6" ]]; then
    
	# START
	# -------------------------------------------------------------------------------
	echo -e "\nStarting PHP 7.3 with Packages update on Centos 6.*"	
	# -------------------------------------------------------------------------------
	
	# Stop Apache services to prevent users experiencing issues during Upgrade
	service httpd stop
	
	yum clean all
	rm -rf /var/cache/yum/*
	
	yum -y install epel-release
	
	rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
	
	#Check for updates
	yum -y update
	yum -y upgrade
	
	# Remove PHP 5.3 first
	#yum -y remove php
	
	# Install PHP 7.3
	yum -y --enablerepo=remi-php73 install php
	
	# yum --enablerepo=remi-php73 install php-xml php-soap php-xmlrpc php-mbstring php-json php-gd php-mcrypt
	
	# Fix autoconf issues
	wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
	tar xvfvz autoconf-2.69.tar.gz
	cd autoconf-2.69
	./configure
	make
	sudo make install
	
	
	## Setup PHP 7.3 new PHP.INI file shipped with PHP and rename old PHP.INI
	file="/etc/php.ini.OLD"
	if [ ! -f "$file" ]; then
		mv /etc/php.ini /etc/php.ini.OLD
		cp -r /etc/php.ini.rpmnew /etc/php.ini
	fi
	
	# Pass php.ini.OLD Date.timezone over to new PHP.ini
	TIMEZONE=$(cat /etc/php.ini.OLD | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
	sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' /etc/php.ini
	
	# Fix missing php.ini settings sentora needs
	echo -e "\nFix missing php.ini settings sentora needs in CentOS 6.x php 7.3 ..."
	echo "setting upload_tmp_dir = /var/sentora/temp/"
	echo ""
	sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php.ini
	echo "Setting session.save_path = /var/sentora/sessions"
	sed -i 's|;session.save_path = "/tmp"|session.save_path = "/var/sentora/sessions"|g' /etc/php.ini
	
	# Curl CERT Setup in PHP.ini files
	echo -e "\nSetting up PHP.ini curl CERT..."
	wget https://curl.haxx.se/ca/cacert.pem
	mkdir -p /etc/php.d/curl_cert
	mv cacert.pem /etc/php.d/curl_cert/cacert.pem
	sed -i 's|;curl.cainfo =|curl.cainfo = "/etc/php.d/curl_cert/cacert.pem"|g' /etc/php.ini
	sed -i 's|;openssl.cafile=|openssl.cafile = "/etc/php.d/curl_cert/cacert.pem"|g' /etc/php.ini
	
	# Reset home
	cd ~
	
	# upgrade PRCE
	yum -y install pcre-devel
		
	# Install git
	yum -y install git
	
	# Restart Apache
	service httpd restart
			
	# END
	# -------------------------------------------------------------------------------

    elif [[ "$VER" = "7" ]]; then
	# -------------------------------------------------------------------------------
	
	# Stop Apache services to prevent users experiencing issues during Upgrade
	systemctl stop httpd
	
	yum clean all
	rm -rf /var/cache/yum/*
	
	# Add Repos
	if wget --spider https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm 2>/dev/null; then
		echo -e "\nRepo *epel-release-latest-7.noarch.rpm* is available procced ..."
		wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	else
		echo -e "\nRepo *epel-release-latest-7.noarch.rpm* is not available. Exiting installer. Please contact script admin"
		exit 1
	fi
        
	# -------------------------------------------------------------------------------
	echo -e "\nStarting PHP 7.3 with Packages update on Centos 7.*"	
	# -------------------------------------------------------------------------------
	
	if wget --spider http://rpms.remirepo.net/enterprise/remi-release-7.rpm 2>/dev/null; then
		echo -e "\nRepo *remi-release-7.rpm* is available procced ..."
		wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	else
		echo -e "\nRepo *remi-release-7.rpm* is not available. Exiting installer. Please contact script admin"
		exit 1
	fi
	
	#wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
	#wget http://rpms.remirepo.net/enterprise/remi-release-7.rpm
	rpm -Uvh remi-release-7.rpm epel-release-latest-7.noarch.rpm

	# Install PHP 7.3 and update modules
	
	#yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-fpm php-intl php-imagick php-pspell wget
	
	yum -y install yum-utils
	yum-config-manager --enable remi-php73
	yum -y update
	yum -y install php-zip php-mysql php-mcrypt
	
	
	## Setup PHP 7.3 new PHP.INI file shipped with PHP and rename old PHP.INI
	file="/etc/php.ini.OLD"
	if [ ! -f "$file" ]; then
		mv /etc/php.ini /etc/php.ini.OLD
		cp -r /etc/php.ini.rpmnew /etc/php.ini
	fi
	
	# Pass php.ini.OLD Date.timezone over to new PHP.ini
	TIMEZONE=$(cat /etc/php.ini.OLD | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
	sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' /etc/php.ini
	
	# Fix missing php.ini settings sentora needs
	echo -e "\nFix missing php.ini settings sentora needs in CentOS 7.x php 7.3 ..."
	echo "setting upload_tmp_dir = /var/sentora/temp/"
	echo ""
	sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php.ini
	echo "Setting session.save_path = /var/sentora/sessions"
	sed -i 's|;session.save_path = "/tmp"|session.save_path = "/var/sentora/sessions"|g' /etc/php.ini
	
	# Curl CERT Setup in PHP.ini files
	echo -e "\nSetting up PHP.ini curl CERT..."
	wget https://curl.haxx.se/ca/cacert.pem
	mkdir -p /etc/php.d/curl_cert
	mv cacert.pem /etc/php.d/curl_cert/cacert.pem
	sed -i 's|;curl.cainfo =|curl.cainfo = "/etc/php.d/curl_cert/cacert.pem"|g' /etc/php.ini
	sed -i 's|;openssl.cafile=|openssl.cafile = "/etc/php.d/curl_cert/cacert.pem"|g' /etc/php.ini	
	
	# Install php-fpm
	#yum -y install php-fpm
	
	# Create CGI Scripts
	#....
	
	# Install git
	yum -y install git
	
	# Restart Apache
	systemctl restart httpd
	
    fi
fi	

# -------------------------------------------------------------------------------
if [[ "$OS" = "Ubuntu" ]]; then
	
	PACKAGE_INSTALLER="apt-get -yqq install"
	
    if [[ "$VER" = "16.04" ]]; then
	
	# START
	# -------------------------------------------------------------------------------
		echo -e "\nStarting PHP 7.3 with Packages update on Ubuntu 16.04"
	# -------------------------------------------------------------------------------	

        # START HERE
				
		# Stop Apache services to prevent users experiencing issues during Upgrade
		systemctl stop apache2
			
		# Disable PHP 7.1, 7.2, 7.4 package tell we can test.
		sudo apt-mark hold php7.1
		sudo apt-mark hold php7.2
		sudo apt-mark hold php7.4
		
		# Add Ondrej Repos
		#sudo add-apt-repository -y ppa:ondrej/apache2
		sudo add-apt-repository -y ppa:ondrej/php
		sudo apt-get -yqq update
		sudo apt-get -yqq upgrade
		
		# Check if PHP 7.1, 7.2, 7.4 is installed and remove
		sudo apt-get -yqq remove php7.1*
		sudo apt-get -yqq purge php7.1*
		sudo apt-get -yqq remove php7.2*
		sudo apt-get -yqq purge php7.2*
		sudo apt-get -yqq remove php7.4*
		sudo apt-get -yqq purge php7.4*

		# Add repos
		#deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		#deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		
		# Install PHP 7 and modules
		#apt install php-pear php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml php7.3-fpm libapache2-mod-php7.3 php7.3-imagick php7.3-recode php7.3-tidy php7.3-xmlrpc php7.3-intl
		
		apt-get -yqq install php7.3 php7.3-common 
		apt-get -yqq install php7.3-mysql php7.3-mbstring
		apt-get -yqq install php7.3-zip php7.3-xml php7.3-gd
		apt-get -yqq install php7.0-dev libapache2-mod-php7.3
		apt-get -yqq install php7.3-dev
		apt-get -yqq install php7.3-curl
		
		# PHP Mcrypt 1.0.2 install
		if [ ! -f /etc/php/7.3/apache2/conf.d/20-mcrypt.ini ]
				then
			echo -e "\nInstalling php mcrypt 1.0.2"
			sudo apt-get -yqq install gcc make autoconf libc-dev pkg-config
			sudo apt-get -yqq install libmcrypt-dev
			echo '' | sudo pecl install mcrypt-1.0.2
			sudo bash -c "echo extension=mcrypt.so > /etc/php/7.3/mods-available/mcrypt.ini"
			ln -s /etc/php/7.3/mods-available/mcrypt.ini /etc/php/7.3/apache2/conf.d/20-mcrypt.ini
		
		fi	
		
		# Disable Apache mod_php7.0-7.2 & 7.4
		sudo a2dismod php7.0
		sudo a2dismod php7.1
		sudo a2dismod php7.2
		sudo a2dismod php7.4
		
		# Enable Apache mod_php7.3
		sudo a2enmod php7.3
		
		# Install git
		apt-get -y install git
		
		# Pass php.ini.OLD Date.timezone over to new PHP.ini
		TIMEZONE=$(cat /etc/php5/apache2/php.ini | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
		sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' /etc/php/7.3/apache2/php.ini
		
		# Fix missing php.ini settings sentora needs
		echo -e "\nFix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
		echo "setting upload_tmp_dir = /var/sentora/temp/"
		echo ""
		sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
		echo "Setting session.save_path = /var/sentora/sessions"
		sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
		
		# Curl CERT Setup in PHP.ini files for PHP CURL_OPT
		echo -e "\nSetting up PHP.ini curl CERT..."
		wget https://curl.haxx.se/ca/cacert.pem
		mv cacert.pem /etc/php/7.3/cacert.pem
		sed -i 's|;curl.cainfo =|curl.cainfo = "/etc/php/7.3/cacert.pem"|g' /etc/php/7.3/apache2/php.ini
		sed -i 's|;openssl.cafile=|openssl.cafile = "/etc/php/7.3/cacert.pem"|g' /etc/php/7.3/apache2/php.ini
	
		# Restart Apache
		systemctl restart apache2
		
		# Run update & upgrade
		sudo apt-get -yqq update
		sudo apt-get -yqq upgrade
		
    fi
fi


	# END
	# -------------------------------------------------------------------------------
	
	##### Check php 7 was installed or quit installer.
	PHPVERFULL=$(php -r 'echo phpversion();')
	PHPVER=${PHPVERFULL:0:3} # return 5.x or 7.x

	echo -e "\nDetected PHP: $PHPVER "

	if  [[ "$PHPVER" = "7.3" ]]; then
    	echo -e "\nPHP 7.3 installed. Procced installing ..."
	else
		echo -e "\nPHP 7.3 not installed. Exiting installer. Please contact script admin"
		exit 1
	fi
	
	# -------------------------------------------------------------------------------
	# Start Snuffleupagus install Below
	# -------------------------------------------------------------------------------
	
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
	
	if [[ "$OS" = "CentOs" && ( "$VER" = "6" || "$VER" = "7" ) ]]; then
	
		# Enable snuffleupagus in PHP.ini
		echo -e "\nUpdating CentOS PHP.ini Enable snuffleupagus..."
		echo "extension=snuffleupagus.so" >> /etc/php.d/20-snuffleupagus.ini
		echo "sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules" >> /etc/php.d/20-snuffleupagus.ini
				
		#### FIX - Suhosin loading in php.ini
		mv /etc/php.d/suhosin.ini /etc/php.d/suhosin.ini_bak
		# zip -r /etc/php.d/suhosin.zip /etc/php.d/suhosin.ini
		# rm -rf /etc/php.d/suhosin.ini
		
    elif [[ "$OS" = "Ubuntu" && ( "$VER" = "16.04" ) ]]; then
	
		# Enable snuffleupagus in PHP.ini
		echo -e "\nUpdating Ubuntu PHP.ini Enable snuffleupagus..."
		echo "extension=snuffleupagus.so" >> /etc/php/7.3/mods-available/snuffleupagus.ini
		echo "sp.configuration_file=/etc/sentora/configs/php/sp/snuffleupagus.rules" >> /etc/php/7.3/mods-available/snuffleupagus.ini
		ln -s /etc/php/7.3/mods-available/snuffleupagus.ini /etc/php/7.3/apache2/conf.d/20-snuffleupagus.ini
		
	fi
	
	# Restart Apache service
	if [[ "$OS" = "CentOs" && ("$VER" = "6") ]]; then
		service httpd restart
	
	elif [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
		systemctl restart httpd
	
    elif [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		systemctl restart apache2
    fi
	
# -------------------------------------------------------------------------------
# PANEL SERVICE FIXES/UPGRADES BELOW
# -------------------------------------------------------------------------------
	
	# -------------------------------------------------------------------------------
	# Download Sentora Upgrader files Now
	# -------------------------------------------------------------------------------	
	
		#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	echo -e "\nDownloading Updated package files..." 
	
	# Clone Github instead
	upgradedir="~/sentora_php7_upgrade"
	if [ -d "$upgradedir" ]; then
		rm -r ~/sentora_php7_upgrade
	fi
	git clone https://github.com/Dukecitysolutions/sentora-php7-upgrade sentora_php7_upgrade
	
	# mkdir -p sentora_php7_upgrade
	# cd sentora_php7_upgrade
	# wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	
	#echo -e "\n--- Unzipping files..."
	#unzip -oq sentora_php7_upgrade.zip
	
	# -------------------------------------------------------------------------------
	# BIND/NAMED DNS Below
	# -------------------------------------------------------------------------------
	
	# reset home dir for commands
	cd ~
	
	# Fix Ubuntu 16.04 DNS 
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
	
		# Ubuntu DNS fix now starting fix
		# Update Snuff Default rules to fix panel timeout
		echo -e "\nUpdating Ubuntu DNS fix..."
		rm -rf /etc/apparmor.d/usr.sbin.named
		cp -r  ~/sentora_php7_upgrade/preconf/apparmor.d/usr.sbin.named /etc/apparmor.d/
		#chown -R root:root /etc/apparmor.d/usr.sbin.named 
		#chmod 0644 /etc/apparmor.d/usr.sbin.named 
		
		if ! grep -q "managed-keys-directory" /etc/bind/named.conf; then
			echo -e "\nUpdating named.conf with managed-keys-directory for Ubuntu 16 & 18\n"
			sed -i '\~dnssec-lookaside auto;~a   managed-keys-directory "/var/named/dynamic";' /etc/bind/named.conf
			
			# Delete Default empty managed-keys.bind.jnl file
			rm -rf /var/named/dynamic/managed-keys.bind
						
		fi

		# DELETING maybe or using later ################
		# DNS now starting fix
		#file="/etc/apparmor.d/usr.sbin.named"
		#TARGET_STRING="/etc/sentora/configs/bind/etc/** rw,"
		#grep -q $TARGET_STRING $file
		#if [ ! $? -eq 0 ]
		#	then
    	#		echo "Apparmor does not include DNS fix. Updating..."
    	#	sed -i '\~/var/cache/bind/ rw,~a   /etc/sentora/configs/bind/etc/** rw,' /etc/apparmor.d/usr.sbin.named
		#	sed -i '\~/var/cache/bind/ rw,~a   /var/sentora/logs/bind/** rw,' /etc/apparmor.d/usr.sbin.named
		#fi
		###############################

	fi	
	
	# -------------------------------------------------------------------------------
	# CRON Below
	# -------------------------------------------------------------------------------
	
		# prepare daemon crontab
		# sed -i "s|!USER!|$CRON_USER|" "$PANEL_CONF/cron/zdaemon" #it screw update search!#
		rm -rf /etc/cron.d/zdaemon
		cp -r ~/sentora_php7_upgrade/preconf/cron/zdaemon /etc/cron.d/zdaemon
		sed -i "s|!USER!|root|" "/etc/cron.d/zdaemon"
		chmod 644 /etc/cron.d/zdaemon
		
		# Fix Sentora user CRON_MANAGER Module
		if [[ "$OS" = "CentOs" ]]; then
		
			chown apache:apache /var/spool/cron
			chmod 0770 /var/spool/cron
			
			chown apache:apache /var/spool/cron/apache
			chmod 0770 /var/spool/cron/apache
			
		elif [[ "$OS" = "Ubuntu" ]]; then
		
			chown root:root /var/spool/cron
			chmod 0777 /var/spool/cron
			
			chown www-data:www-data /var/spool/cron/crontabs
			chmod 0770 /var/spool/cron/crontabs
		
		fi
	
	# -------------------------------------------------------------------------------
	# MYSQL Below
	# -------------------------------------------------------------------------------
	
	if [[ "$OS" = "CentOs" && ("$VER" = "6") ]]; then
	
		echo -e "Starting CentOS 6.x MYSQL 5.x upgrade to MYSQL 5.5 " 
		
		# start here
		rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm
		rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
		
		#change repo
		sed -i 's|mirrorlist=http://cdn.remirepo.net/enterprise/6/remi/mirror|mirrorlist=http://rpms.remirepo.net/enterprise/6/remi/mirror|g' /etc/yum.repos.d/remi.repo
		sed -i 's|enabled=0|enabled=1|g' /etc/yum.repos.d/remi.repo
		
		# Upgrade Mysql to 5.7.*
		yum -y update mysql*
		
		# Run Mysql_upgrade to check/fix any issues.
		mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
		while ! mysql -u root -p$mysqlpassword -e ";" ; do
		read -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
		done
		echo -e "Connection mysql ok"
		mysql_upgrade --force -uroot -p"$mysqlpassword"

		# Bug fix under some MySQL 5.7+ about the sql_mode for "NO_ZERO_IN_DATE,NO_ZERO_DATE"
		# Need to be considere on the next .sql build query version.
		if ! grep -q "sql_mode" /etc/my.cnf; then
		
			sed -i "s|\[mysqld\]|&\nsql_mode = 'NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'|" /etc/my.cnf
			
		fi
	fi
	
	# Bug fix under some MySQL 5.7+ about the sql_mode for "NO_ZERO_IN_DATE,NO_ZERO_DATE"
	# Need to be considere on the next .sql build query version.
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
			# sed '/\[mysqld]/a\sql_mode = "NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' /etc/mysql/mysql.conf.d/mysqld.cnf
			# sed 's/^\[mysqld\]/\[mysqld\]\sql_mode = "NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"/' /etc/mysql/mysql.conf.d/mysqld.cnf
		if ! grep -q "sql_mode" /etc/mysql/mysql.conf.d/mysqld.cnf; then
		
			echo "!includedir /etc/mysql/mysql.conf.d/" >> /etc/mysql/my.cnf;
        	echo "sql_mode = 'NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
			
				systemctl restart mysql
    	fi
	fi

	# -------------------------------------------------------------------------------
	# POSTFIX Below
	# -------------------------------------------------------------------------------
	
	# Fix postfix not working after upgrade to 16.04
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		echo -e "\nFixing postfix not working after upgrade to 16.04..."
		
		# disable postfix daemon_directory for now to allow startup after update
		sed -i 's|daemon_directory = /usr/lib/postfix|#daemon_directory = /usr/lib/postfix|g' /etc/sentora/configs/postfix/main.cf
				
		systemctl restart postfix
		
	fi
	
	# -------------------------------------------------------------------------------
	# ProFTPd Below
	# -------------------------------------------------------------------------------

	if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
		echo -e "\n-- Installing ProFTPD if not installed"
		
		PACKAGE_INSTALLER="yum -y -q install"
		
    	$PACKAGE_INSTALLER proftpd proftpd-mysql 
    	FTP_CONF_PATH='/etc/proftpd.conf'
    	sed -i "s|nogroup|nobody|" $PANEL_CONF/proftpd/proftpd-mysql.conf
		
		# Setup proftpd base file to call sentora config
		rm -f "$FTP_CONF_PATH"
		#touch "$FTP_CONF_PATH"
		#echo "include $PANEL_CONF/proftpd/proftpd-mysql.conf" >> "$FTP_CONF_PATH";
		ln -s "$PANEL_CONF/proftpd/proftpd-mysql.conf" "$FTP_CONF_PATH"
		
		systemctl enable proftpd
		
	elif [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		
		echo -e "\n-- Reinstall ProFTPD to fix Ubuntu issues"
		
		# Remove Proftpd for reinstall
		apt-get -y remove proftpd-basic

		# Reinstall Proftpd and proftpd-mysql
		apt-get -y install proftpd proftpd-mod-mysql

		FTP_CONF_PATH='/etc/proftpd/proftpd.conf'

		# Setup proftpd base file to call sentora config
		rm -f "$FTP_CONF_PATH"
		#touch "$FTP_CONF_PATH"
		#echo "include $PANEL_CONF/proftpd/proftpd-mysql.conf" >> "$FTP_CONF_PATH";
		ln -s "$PANEL_CONF/proftpd/proftpd-mysql.conf" "$FTP_CONF_PATH"

		# Restart Proftpd
		service proftpd restart
		
	fi
	
# -------------------------------------------------------------------------------
# Start Sentora upgrade Below
# -------------------------------------------------------------------------------
		
	# -------------------------------------------------------------------------------
	# Start
	# -------------------------------------------------------------------------------

	# ####### start here   Upgrade __autoloader() to x__autoloader()
	# rm -rf $PANEL_PATH/panel/dryden/loader.inc.php
	# cd 
	# cp -r /sentora_update/loader.inc.php $PANEL_PATH/panel/dryden/
	sed -i 's/__autoload/x__autoload/g' /etc/sentora/panel/dryden/loader.inc.php
	
	# Update Snuffleupagus Default rules to fix panel timeout
	echo -e "\n--- Updating Snuffleupagus default rules..."
	rm -rf /etc/sentora/configs/php/sp/snuffleupagus.rules
	rm -rf /etc/sentora/configs/php/sp/sentora.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/snuffleupagus.rules /etc/sentora/configs/php/sp/snuffleupagus.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/sentora.rules /etc/sentora/configs/php/sp/sentora.rules
	
	# Upgrade apache_admin with apache_admin 1.0.x
	echo -e "\n--- Updating Apache_admin module..."
	rm -rf /etc/sentora/panel/modules/apache_admin/
	cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/
		
		# Set new sentora panel logs dir
		mkdir -p /var/sentora/logs/panel
		
	# Upgrade cron module 1.0.x
	echo -e "\n--- Updating Cron module..."
	rm -rf /etc/sentora/panel/modules/cron/
	cp -r  ~/sentora_php7_upgrade/modules/cron $PANEL_PATH/panel/modules/
		
	# Upgrade dns_admin module 1.0.x
	echo -e "\n--- Updating Dns_Admin module..."
	rm -rf /etc/sentora/panel/modules/dns_admin/
	cp -r  ~/sentora_php7_upgrade/modules/dns_admin $PANEL_PATH/panel/modules/
		
	# Upgrade dns_manager module 1.0.x
	echo -e "\n--- Updating Dns_Manager module..."
	rm -rf /etc/sentora/panel/modules/dns_manager/
	cp -r  ~/sentora_php7_upgrade/modules/dns_manager $PANEL_PATH/panel/modules/
	
	# Upgrade domains_module to 1.0.x
	echo -e "\n--- Updating Domains module..."
	rm -rf /etc/sentora/panel/modules/domains/
	cp -r  ~/sentora_php7_upgrade/modules/domains $PANEL_PATH/panel/modules/
	
	# Upgrade ftp_management module 1.0.x
	echo -e "\n--- Updating FTP_management module..."
	rm -rf /etc/sentora/panel/modules/ftp_management/
	cp -r  ~/sentora_php7_upgrade/modules/ftp_management $PANEL_PATH/panel/modules/
	
	# Upgrade mailboxes module 1.0.x
	echo -e "\n--- Updating Mailboxes module..."
	rm -rf /etc/sentora/panel/modules/mailboxes/
	cp -r  ~/sentora_php7_upgrade/modules/mailboxes $PANEL_PATH/panel/modules/
	
	# Upgrade mysql_databases module 1.0.x
	echo -e "\n--- Updating Mysql_databases module..."
	rm -rf /etc/sentora/panel/modules/mysql_databases/
	cp -r  ~/sentora_php7_upgrade/modules/mysql_databases $PANEL_PATH/panel/modules/
	
	# Upgrade mysql_users module 1.0.x
	echo -e "\n--- Updating Mysql_users module..."
	rm -rf /etc/sentora/panel/modules/mysql_users/
	cp -r  ~/sentora_php7_upgrade/modules/mysql_users $PANEL_PATH/panel/modules/
	
	# Upgrade parked_Domains module 1.0.x
	echo -e "\n--- Updating Parked_Domains module..."
	rm -rf /etc/sentora/panel/modules/parked_domains/
	cp -r  ~/sentora_php7_upgrade/modules/parked_domains $PANEL_PATH/panel/modules/
	
	# Upgrade Sub_Domains module 1.0.x
	echo -e "\n--- Updating Sub_Domains module..."
	rm -rf /etc/sentora/panel/modules/sub_domains/
	cp -r  ~/sentora_php7_upgrade/modules/sub_domains $PANEL_PATH/panel/modules/
	
	# Copy New Apache config template files
	echo -e "\n--- Updating Sentora vhost templates..."
	rm -rf /etc/sentora/configs/apache/templates/
	cp -r ~/sentora_php7_upgrade/preconf/apache/templates /etc/sentora/configs/apache/
	echo ""
	
	# install Smarty files
	cp -r ~/sentora_php7_upgrade/etc/lib/smarty /etc/sentora/panel/etc/lib/
	
	# Replace .htaccess with new file
	rm -r $PANEL_PATH/panel/.htaccess
	cp -r ~/sentora_php7_upgrade/.htaccess $PANEL_PATH/panel/
	
	# Replace /inc/init.inc.php with new file
	rm -r $PANEL_PATH/panel/inc/init.inc.php
	cp -r ~/sentora_php7_upgrade/inc/init.inc.php $PANEL_PATH/panel/inc/
	
	# Update Sentora Core Mysql tables
	# get mysql root password, check it works or ask it
	mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
	while ! mysql -u root -p$mysqlpassword -e ";" ; do
	read -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
	done
	echo -e "Connection mysql ok"
	mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sentora_1_0_3_1.sql
	
	# Restart apache to set Snuffleupagus
	if [[ "$OS" = "CentOs" ]]; then
		service httpd restart
	elif [[ "$OS" = "Ubuntu" ]]; then
		systemctl restart apache2
	fi
		
	# -------------------------------------------------------------------------------
	# Start Roundcube-1.3.10 upgrade Below
	# -------------------------------------------------------------------------------
	
	echo -e "\nStarting Roundcube upgrade to 1.3.10..."
	cd ~/sentora_php7_upgrade
	wget --no-check-certificate -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
	tar xf roundcubemail-*.tar.gz
	cd roundcubemail-1.3.10
	bin/installto.sh /etc/sentora/panel/etc/apps/webmail/
	chown -R root:root /etc/sentora/panel/etc/apps/webmail
	
	# -------------------------------------------------------------------------------
	# Start PHPsysinfo 3.3.1 upgrade Below
	# -------------------------------------------------------------------------------
	
	echo -e "\nStarting PHPsysinfo upgrade to 3.3.1..."
	rm -rf /etc/sentora/panel/etc/apps/phpsysinfo/
	cp -r  ~/sentora_php7_upgrade/etc/apps/phpsysinfo $PANEL_PATH/panel/etc/apps/
	
	# -------------------------------------------------------------------------------
	# Start PHPmyadmin 4.9 upgrade Below - TESTING WHICH VERSION IS BEST HERE.
	# -------------------------------------------------------------------------------
		
	#--- Some functions used many times below
	# Random password generator function
	passwordgen() {
    	l=$1
    	[ "$l" == "" ] && l=16
    	tr -dc A-Za-z0-9 < /dev/urandom | head -c ${l} | xargs
	}
	
	echo -e "\n-- Configuring phpMyAdmin 4.9..."
	phpmyadminsecret=$(passwordgen 32);
	
	#echo "password"
	#echo -e "$phpmyadminsecret"
	
	#Version checker function dor Mysql & PHP
	versioncheck() { 
		echo "$@" | gawk -F. '{ printf("%03d%03d%03d\n", $1,$2,$3); }'; 
	}

	# Check the php version installed on the OS.
	# phpver=php -v |grep -Eow '^PHP [^ ]+' |gawk '{ print $2 }'
	phpver=`php -r 'echo PHP_VERSION;'`

	PHPMYADMIN_OLD="/etc/sentora/panel/etc/apps/phpmyadmin_old"

	if [ ! -d "$PHPMYADMIN_OLD" ]; then		
	# Start
		if [[ "$(versioncheck "$phpver")" < "$(versioncheck "5.5.0")" ]]; then
			echo -e "\n-- Your current php Version installed is $phpver, you can't upgrade phpMyAdmin to the last stable version. You need php 5.5+ for upgrade."
		else
			while true; do
			read -e -p "PHPmyadmin 4.0.x will not work properly with PHP 7.3. Installer is about to upgrade PHPmyadmin to 4.9.1. Installer will backup current PHPmyadmin 4.x to /phpmyadmin_old incase something goes wrong. Do you want to keep the (O)riginal phpMyAdmin from Sentora or (U)pdate to the last stable version ? UPGRADE IS STRONGLY RECOMMENDED. (O/U)" pma
			echo ""
				
				case $pma in
        	        [Uu]* )
							## START Install here
							
            	            #PHPMYADMIN_VERSION="STABLE"
							PHPMYADMIN_VERSION="4.9.2-all-languages"
                	        cd  $PANEL_PATH/panel/etc/apps/
							# backup 	
                    	    mv phpmyadmin  phpmyadmin_old
														
							# empty folder
							rm -rf /etc/sentora/panel/etc/apps/phpmyadmin

							# Download/Get PHPmyadmin 4.9.2
							#wget -nv -O phpmyadmin.zip https://github.com/phpmyadmin/phpmyadmin/archive/$PHPMYADMIN_VERSION.zip
							cp -r  ~/sentora_php7_upgrade/etc/apps/phpmyadmin.zip phpmyadmin.zip
							
                    	    unzip -q  phpmyadmin.zip
                        	mv phpMyAdmin-$PHPMYADMIN_VERSION phpmyadmin
											
                        	#sed -i "s/memory_limit = .*/memory_limit = 512M/" $PHP_INI_PATH
							#if [[ "$OS" = "CentOs" || "$OS" = "Fedora" ]]; then
								#echo 'suhosin.executor.include.whitelist = phar' >> $PHP_EXT_PATH/suhosin.ini
								#systemctl restart $HTTP_SERVICE
							#fi
							
                        	cd phpmyadmin
							
							##
							#echo "start composer"
                        	                        	
							#EXPECTED_SIGNATURE="$(wget -q -O - https://composer.github.io/installer.sig)"
							#php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
							#ACTUAL_SIGNATURE="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

							#if [ "$EXPECTED_SIGNATURE" != "$ACTUAL_SIGNATURE" ]
								#then
    							#>&2 echo 'ERROR: Invalid installer signature'
   								# rm composer-setup.php
    							#exit 1
							#fi

							#php composer-setup.php --quiet
							#RESULT=$?
							#rm composer-setup.php
							#exit $RESULT
							
							## Setup composer
							#sudo php composer-setup.php --install-dir=/usr/local/bin --filename=composer
                        	#php composer-setup.php
                        	#php -r "unlink('composer-setup.php');"
							
                        	#composer update --no-dev
							
							# setup PHPmyadmin 4.9.1
							#composer create-project
							
                        	cd $PANEL_PATH/panel/etc/apps/
                        	chmod -R 777 phpmyadmin
                        	chown -R $HTTP_USER:$HTTP_USER phpmyadmin
							
							#mv $PANEL_PATH/panel/etc/apps/phpmyadmin_old/robots.txt phpmyadmin/robots.txt
                        	
							mkdir -p /etc/sentora/panel/etc/apps/phpmyadmin/tmp
							chmod -R 777 /etc/sentora/panel/etc/apps/phpmyadmin/tmp
							ln -s $PANEL_CONF/phpmyadmin/config.inc.php $PANEL_PATH/panel/etc/apps/phpmyadmin/config.inc.php
							chmod 644 $PANEL_CONF/phpmyadmin/config.inc.php
							sed -i "s|\$cfg\['blowfish_secret'\] \= '.*';|\$cfg\['blowfish_secret'\] \= '$phpmyadminsecret';|" $PANEL_CONF/phpmyadmin/config.inc.php
	
							# Remove phpMyAdmin's setup folders in case they were left behind.
							rm -rf phpmyadmin/setup
							rm -rf phpmyadmin/sql
							rm -rf phpmyadmin/test
                        	rm -rf phpmyadmin.zip
							#rm -rf phpmyadmin_old
                	break;;
                	[oO]* )
                	break;;
				esac
			done
		fi	
		
	fi
	
	# -------------------------------------------------------------------------------
	# Start Sentora system premission upgrade Below
	# -------------------------------------------------------------------------------
	
	# Fix permissions to prep and secure sentora for PHP-FPM
	# Needs research and testing. All help is needed
	# Panel permissions
	#chmod 0770 /etc/sentora
	#chmod 0770 /etc/sentora/configs
	#chmod 0770 /etc/sentora/panel
	
	# Logs permissions
	#chmod 0770 /var/sentora/logs/domains/*
	
	# Hostdata permissions
	#chmod 0770 /var/sentora/hostdata
	#chmod 0770 /var/sentora/hostdata/*/public_html
	#chmod 0770 /var/sentora/hostdata/*/public_html/tmp
	
# -------------------------------------------------------------------------------
	
# Update Sentora APACHE_CHANGED, DBVERSION and run DAEMON

	# Set apache daemon to build vhosts file.
	$PANEL_PATH/panel/bin/setso --set apache_changed "true"
	
	# Set dbversion
	$PANEL_PATH/panel/bin/setso --set dbversion "$SENTORA_UPDATER_VERSION"
	
	# Run Daemon
	php -d "sp.configuration_file=/etc/sentora/configs/php/sp/sentora.rules" -q $PANEL_PATH/panel/bin/daemon.php		
	
# -------------------------------------------------------------------------------

# Clean up files downloaded for install/update
rm -r ~/sentora_php7_upgrade

# Disable PHP 7.1, 7.2, 7.4 package tell we can test. AGAIN to make ubuntu 16.04 didnt override during install(ISSUE)
sudo apt-mark hold php7.1
sudo apt-mark hold php7.2
sudo apt-mark hold php7.4

# -------------------------------------------------------------------------------

echo -e "\nDone updating all Sentora_core and PHP 7.3 files"
echo -e "\nEnjoy and have fun testing!"
echo -e "\nWe are done upgrading Sentora 1.0.3 - PHP 5.* w/Suhosin to PHP 7.3 w/Snuffleupagus"

# Wait until the user have read before restarts the server...
if [[ "$INSTALL" != "auto" ]] ; then
    while true; do
		
        read -e -p "Restart your server now to complete the install (y/n)? " rsn
        case $rsn in
            [Yy]* ) break;;
            [Nn]* ) exit;
        esac
    done
    shutdown -r now
fi

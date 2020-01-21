#!/bin/bash

SENTORA_UPDATER_VERSION="1.0.3.1-Build 0.3.5-BETA"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"
PANEL_CONF="/etc/sentora/configs"

# Bash Colour
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

	logfile=$(date +%Y-%m-%d_%H.%M.%S_sentora_php7_update.log)
	touch "$logfile"
	exec > >(tee "$logfile")
	exec 2>&1
# -------------------------------------------------------------------------------	
	
#--- Display the 'welcome' splash/user warning info..
echo ""
echo "###############################################################################################"
echo "#  Welcome to the Unofficial Sentora PHP 7.3 PKG updater. Installer v.$SENTORA_UPDATER_VERSION  #"
echo "###############################################################################################"
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
      "$OS" = "Ubuntu" && ( "$VER" = "16.04" || "$VER" = "18.04" ) ]] ; then
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

### Ensure that sentora_1.0.3.1 PHP7_upgrade is installed to run this update
#if [ -d /etc/sentora ]; then
#    echo "- Found Sentora v1.0.3.1 with PHP 7.3, processing..."
#else
#    echo "Sentora v1.0.3.1 with PHP 7.3 is not installed, aborting..."
#    exit 1
#fi

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

while true; do
	echo ""
	echo "# -----------------------------------------------------------------------------"
	echo "# THIS CODE IS NOT FOR PRODUCTION SYSTEMS YET. -TESTING ONLY-. USE AT YOUR OWN RISK."
	echo "# HAPPY SENTORA PHP 7 TESTING. ALL HELP IS NEEDED TO GET THIS OFF THE GROUND AND RELEASED."
	echo "# -----------------------------------------------------------------------------"
	echo ""
	echo "###############################################################################"
	echo -e "\nPlease make sure the Date/Time is correct. This script will need correct Date/Time to install correctly"
	echo -e "If you continue with wrong date/time this script/services (phpmyadmin) may not install correctly. DO NOT CONTINUE IF DATE?TIME IS WRONG BELOW"
	echo ""
	# show date/time to make sure its correct
		date
	echo ""
	echo "###############################################################################"
	echo "# -----------------------------------------------------------------------------"
    read -p "Do you wish to continue updating this program? y/yes or n/no..| " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

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
	
	#mkdir -p sentora_php7_upgrade
	#cd sentora_php7_upgrade
	#wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	
	#echo -e "\n--- Unzipping files..."
	#unzip -oq sentora_php7_upgrade.zip
	
	# -------------------------------------------------------------------------------	
	# BIND/NAMED DNS Below
	# -------------------------------------------------------------------------------
	
	# reset home dir for commands
	cd ~
	
	# Fix Ubuntu 16.04 DNS 
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04" || "$VER" = "18.04" ) ]]; then
	
		# Ubuntu DNS fix now starting fix
		# Update Snuff Default rules to fix panel timeout
		
		echo -e "\n--- Updating Ubuntu DNS fix..."
		rm -rf /etc/apparmor.d/usr.sbin.named
		cp -r  ~/sentora_php7_upgrade/preconf/apparmor.d/usr.sbin.named /etc/apparmor.d/
		#chown -R root:root /etc/apparmor.d/usr.sbin.named 
		#chmod 0644 /etc/apparmor.d/usr.sbin.named 
		
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
		
		echo -e "\n--- Updating Sentora Zdeamon..."
		rm -rf /etc/cron.d/zdaemon
		cp -r ~/sentora_php7_upgrade/preconf/cron/zdaemon /etc/cron.d/zdaemon
		sed -i "s|!USER!|root|" "/etc/cron.d/zdaemon"
		chmod 644 /etc/cron.d/zdaemon
	
	# -------------------------------------------------------------------------------
	# MYSQL Below
	# -------------------------------------------------------------------------------
	
	# Bug fix under some MySQL 5.7+ about the sql_mode for "NO_ZERO_IN_DATE,NO_ZERO_DATE"
	# Need to be considere on the next .sql build query version.
	if [[ "$OS" = "CentOs" && ("$VER" = "6") ]]; then
	
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
	
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04" || "$VER" = "18.04") ]]; then
	
	echo -e "\n--- Appling MySQL fix..."
	
			# sed '/\[mysqld]/a\sql_mode = "NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"' /etc/mysql/mysql.conf.d/mysqld.cnf
			# sed 's/^\[mysqld\]/\[mysqld\]\sql_mode = "NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION"/' /etc/mysql/mysql.conf.d/mysqld.cnf
		if ! grep -q "sql_mode" /etc/mysql/mysql.conf.d/mysqld.cnf; then
		
			echo "!includedir /etc/mysql/mysql.conf.d/" >> /etc/mysql/my.cnf;
        	echo "sql_mode = 'NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION'" >> /etc/mysql/mysql.conf.d/mysqld.cnf;
			
				systemctl restart $DB_SERVICE
    	fi
	fi
	
	# -------------------------------------------------------------------------------
	# POSTFIX Below
	# -------------------------------------------------------------------------------
	
	# Fix postfix not working after upgrade to 16.04
	if [[ "$OS" = "Ubuntu" && ( "$VER" = "16.04" || "$VER" = "18.04" ) ]]; then
		echo -e "\n--- Fixing postfix not working after upgrade to 16.04..."
		
		# disable postfix daemon_directory for now to allow startup after update
		sed -i 's|daemon_directory = /usr/lib/postfix|#daemon_directory = /usr/lib/postfix|g' /etc/sentora/configs/postfix/main.cf
				
		systemctl restart postfix
		
	fi
	
	# -------------------------------------------------------------------------------
	# ProFTPd Below
	# -------------------------------------------------------------------------------

	if [[ "$OS" = "CentOs" && ("$VER" = "7") ]]; then
		echo -e "\n-- Installing ProFTPD if not installed CentOS 6 & 7"
	
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
		
	elif [[ "$OS" = "Ubuntu" && ("$VER" = "16.04" || "$VER" = "18.04") ]]; then
		
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
# Start Sentora php 7.3 module package(s) update Below
# -------------------------------------------------------------------------------

	# -------------------------------------------------------------------------------	
	# Start
	# -------------------------------------------------------------------------------
	
	echo -e "\nStarting PHP 7.3 with Snuffaluffagus packages updates"
		
	# Update Snuff Default rules to fix panel timeout
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
	
	# Upgrade dns_admin module 1.0.x
	echo -e "\n--- Updating Dns_Admin module..."
	rm -rf /etc/sentora/panel/modules/dns_admin/
	cp -r  ~/sentora_php7_upgrade/modules/dns_admin $PANEL_PATH/panel/modules/	
	
	# Upgrade dns_manager module 1.0.x
	echo -e "\n--- Updating Dns_Manager module..."
	rm -rf /etc/sentora/panel/modules/dns_manager/
	cp -r  ~/sentora_php7_upgrade/modules/dns_manager $PANEL_PATH/panel/modules/
	
	# Upgrade domains module 1.0.x
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
	
	# Replace .htaccess with new file
	rm -r $PANEL_PATH/panel/.htaccess
	cp -r ~/sentora_php7_upgrade/.htaccess $PANEL_PATH/panel/
	
	# Replace /inc/init.inc.php with new file
	rm -r $PANEL_PATH/panel/inc/init.inc.php
	cp -r ~/sentora_php7_upgrade/inc/init.inc.php $PANEL_PATH/panel/inc/
	
	# Restart apache to set Snuffleupagus
	if [[ "$OS" = "CentOs" ]]; then
		service httpd restart
	elif [[ "$OS" = "Ubuntu" ]]; then
		systemctl restart apache2
	fi
	
	# -------------------------------------------------------------------------------
	# Start all OS Sentora php 7.3 config update
	# -------------------------------------------------------------------------------
	
	if [[ "$OS" = "CentOs" && ( "$VER" = "6" || "$VER" = "7" ) ]]; then
	
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
						
	fi
	
	# ----------------------------------------------------------------------------------
	
	if [[ "$OS" = "Ubuntu" && ( "$VER" = "16.04" || "$VER" = "18.04" ) ]]; then
	
			# Check PHP 7.4 is not installed and remove
			sudo apt-get remove php7.4-common
			sudo apt-get purge php7.4-common
	
			# Disable PHP 7.2 & 7.4 package tell we can test.
			#apt-mark hold php7.2
			apt-mark hold php7.4
		
			#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
			# reset home dir for commands
			cd ~
	
			# Pass php.ini.OLD Date.timezone over to new PHP.ini
			TIMEZONE=$(cat /etc/php5/apache2/php.ini | grep "date.timezone =" | sed -s "s|.*date.timezone \= '\(.*\)';.*|\1|")
			sed -i 's|;date.timezone =|'"$TIMEZONE"'|g' /etc/php/7.3/apache2/php.ini
	
			# Fix missing php.ini settings sentora needs
			echo -e "\nFix missing php.ini settings sentora needs in Ubuntu 16.04 & 18.04 php 7.3 ..."
			echo "setting upload_tmp_dir = /var/sentora/temp/"
			echo ""
			sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
			echo "Setting session.save_path = /var/sentora/sessions"
			sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
	
			# Install missing php7.3-xml for system and roundcube
			echo -e "\nInstall missing php7.3-xml for system and roundcube..."
			apt-get -y install php7.3-xml php7.3-gd
			
			# Curl CERT Setup in PHP.ini files for PHP CURL_OPT
			echo -e "\nSetting up PHP.ini curl CERT..."
			wget https://curl.haxx.se/ca/cacert.pem
			mv cacert.pem /etc/php/7.3/cacert.pem
			sed -i 's|;curl.cainfo =|curl.cainfo = "/etc/php/7.3/cacert.pem"|g' /etc/php/7.3/apache2/php.ini
			sed -i 's|;openssl.cafile=|openssl.cafile = "/etc/php/7.3/cacert.pem"|g' /etc/php/7.3/apache2/php.ini
	
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
							
	fi
	
	# -------------------------------------------------------------------------------
	# Start Roundcube-1.3.10 upgrade Below
	# -------------------------------------------------------------------------------
	
	echo -e "\n--- Starting Roundcube upgrade to 1.3.10..."
	cd ~/sentora_php7_upgrade
	wget --no-check-certificate -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
	tar xf roundcubemail-*.tar.gz
	cd roundcubemail-1.3.10
	bin/installto.sh /etc/sentora/panel/etc/apps/webmail/
	chown -R root:root /etc/sentora/panel/etc/apps/webmail
	
	# -------------------------------------------------------------------------------
	# Start PHPsysinfo 3.3.1 upgrade Below
	# -------------------------------------------------------------------------------
	
	echo -e "\n--- Starting PHPsysinfo upgrade to 3.3.1..."
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

	PHPMYADMIN_OLD="/etc/sentora/panel/apps/phpmyadmin_old"

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

# -------------------------------------------------------------------------------
	
echo -e "\n--- Done Processing PHP 7.3 with Snuffaluffagus packages updates. Enjoy."
echo ""
	
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
	
#!/bin/bash

SENTORA_UPDATER_VERSION="0.3.0-BETA"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"
PANEL_CONF="/etc/sentora/configs"

#--- Display the 'welcome' splash/user warning info..
echo ""
echo "###############################################################################################"
echo "#  Welcome to the Unofficial Sentora PHP 7 PKG updater. Installer v.$SENTORA_UPDATER_VERSION  #"
echo "###############################################################################################"

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
	echo "# -------------------------------------------------------------------------------"
	echo "# THIS CODE IS NOT FOR PRODUCTION SYSTEMS YET. -TESTING ONLY-. USE AT YOUR OWN RISK."
	echo "# HAPPY SENTORA PHP 7 TESTING. ALL HELP IS NEEDED TO GET THIS OFF THE GROUND AND RELEASED."
	echo "# -------------------------------------------------------------------------------"
    read -p "Do you wish to install this program?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done


	# -------------------------------------------------------------------------------
	# Download Sentora Upgrader files Now
	# -------------------------------------------------------------------------------
	
	#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	echo -e "\nDownloading Updated package files..." 
	rm -rf sentora_php7_upgrade
	mkdir -p sentora_php7_upgrade
	cd sentora_php7_upgrade
	wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	
	echo -e "\n--- Unzipping files..."
	unzip -oq sentora_php7_upgrade.zip
	

	# -------------------------------------------------------------------------------	
	# Start Sentora php 7.3 module package update Below
	# -------------------------------------------------------------------------------
	
	echo -e "\nStarting PHP 7.3 with Snuffaluffagus packages updates"
		
		
	# Update Snuff Default rules to fix panel timeout
	echo -e "\n--- Updating Snuffleupagus default rules..."
	rm -rf /etc/sentora/configs/php/sp/snuffleupagus.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/snuffleupagus.rules /etc/sentora/configs/php/sp/snuffleupagus.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/sentora.rules /etc/sentora/configs/php/sp/sentora.rules
	
	# Upgrade apache_admin with apache_admin 1.0.x
	echo -e "\n--- Updating Apache_admin module..."
	rm -rf /etc/sentora/panel/modules/apache_admin
	cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/	
	
	# Upgrade dns_manager module 1.0.x
	echo -e "\n--- Updating dns_manager module..."
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
	
	# -------------------------------------------------------------------------------
	# Start all OS Sentora php 7.3 config update
	# -------------------------------------------------------------------------------
	
	if [[ "$OS" = "CentOs" && ("$VER" = "6") ]]; then
	
			# Fix missing php.ini settings sentora needs
			echo -e "\nFix missing php.ini settings sentora needs in CentOS 6.x php 7.3 ..."
			#echo "setting upload_tmp_dir = /var/sentora/temp/"
			#echo ""
			#sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php.ini
			echo "Setting session.save_path = /var/sentora/sessions"
			sed -i 's|session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php.ini
						
	fi
	
	----------------------------------------------------------------------------------
	
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		
			#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
			# reset home dir for commands
			cd ~
	
			# Fix missing php.ini settings sentora needs
			echo -e "\nFix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
			echo "setting upload_tmp_dir = /var/sentora/temp/"
			echo ""
			sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
			echo "Setting session.save_path = /var/sentora/sessions"
			sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
	
			# Install missing php7.3-xml for system and roundcube
			echo -e "\nInstall missing php7.3-xml for system and roundcube..."
			apt-get -y install php7.3-xml php7.3-gd
	
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
	cd sentora_php7_upgrade
	wget -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
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
	
	#echo -e "\n--- Starting PHPmyadmin upgrade to 4.9..."
	#mkdir -p /etc/sentora/panel/etc/apps/phpmyadmin-old
	#cp -rf /etc/sentora/panel/etc/apps/phpmyadmin/* /etc/sentora/panel/etc/apps/phpmyadmin-old
	#rm -rf /etc/sentora/panel/etc/apps/phpmyadmin/*
	
	# copy original conf bak to phpmyadmin
	#cp -r /etc/sentora/panel/etc/apps/phpmyadmin-old/config.inc.php /etc/sentora/panel/etc/apps/phpmyadmin/
	# copy new PHPmyadmin 4.9 files to PHPmyadmin dir
	#cp -r  ~/sentora_php7_upgrade/etc/apps/phpmyadmin/* $PANEL_PATH/panel/etc/apps/phpmyadmin
	
	
# -------------------------------------------------------------------------------
# PANEL SERVICE FIXES/UPGRADES BELOW
# -------------------------------------------------------------------------------
	
	# BIND/NAMED DNS Below
	# -------------------------------------------------------------------------------
	
	# reset home dir for commands
	cd ~
	
	# Fix Ubuntu 16.04 DNS 
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
	
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
	# MYSQL Below
	# -------------------------------------------------------------------------------
	
	# Bug fix under some MySQL 5.7+ about the sql_mode for "NO_ZERO_IN_DATE,NO_ZERO_DATE"
	# Need to be considere on the next .sql build query version.
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
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
	if [[ "$OS" = "Ubuntu" && ("$VER" = "16.04") ]]; then
		echo -e "\n--- Fixing postfix not working after upgrade to 16.04..."
		
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
		
	fi
	

# -------------------------------------------------------------------------------
	
# Update Sentora APACHE CHANGED

echo -e "\n--- Setting APACHE_CHANGED to true to set vhost setings..."
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p$mysqlpassword -e ";" ; do
	read -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "\nConnection mysql ok"
mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sen_apache_changed.sql	
	
	
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
	
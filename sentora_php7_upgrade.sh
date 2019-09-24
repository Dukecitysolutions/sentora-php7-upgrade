#!/bin/bash

SENTORA_UPDATER_VERSION="0.3.0"
PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"
PANEL_CONF="/etc/sentora/configs"

#--- Display the 'welcome' splash/user warning info..
echo ""
echo "############################################################################################"
echo "#  Welcome to the Unofficial Sentora PHP 7 upgrader. Installer v.$SENTORA_UPDATER_VERSION  #"
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
## If OS is CENTOS 7 then perform update
if [[ "$OS" = "CentOs" ]]; then

	PACKAGE_INSTALLER="yum -y -q install"

	if [[ "$VER" = "6" ]]; then
    
	# START
	# -------------------------------------------------------------------------------
	echo "Starting PHP 7.3 with Packages update on Centos 6.*"	
	# -------------------------------------------------------------------------------

	yum clean all
	rm -rf /var/cache/yum/*
	
	yum -y install epel-release
	
	rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-6.rpm
	
	yum -y --enablerepo=remi-php73 install php
	# yum --enablerepo=remi-php73 install php-xml php-soap php-xmlrpc php-mbstring php-json php-gd php-mcrypt
	
	# Fix autoconf issues
	wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz
	tar xvfvz autoconf-2.69.tar.gz
	cd autoconf-2.69
	./configure
	make
	sudo make install
	 
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
        
	# START
	# -------------------------------------------------------------------------------
	echo "Starting PHP 7.3 with Packages update on Centos 7.*"	
	
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
	yum -y install yum-utils
	yum-config-manager --enable remi-php73
	yum -y update
	yum -y install php-zip php-mysql php-mcrypt
	
	#yum -y install httpd mod_ssl php php-zip php-fpm php-devel php-gd php-imap php-ldap php-mysql php-odbc php-pear php-xml php-xmlrpc php-pecl-apc php-mbstring php-mcrypt php-soap php-tidy curl curl-devel perl-libwww-perl ImageMagick libxml2 libxml2-devel mod_fcgid php-cli httpd-devel php-fpm php-intl php-imagick php-pspell wget
	
	# Install php-fpm
	#yum -y install php-fpm
	
	# Create CGI Scripts
	#....
	
	# Install git
	yum -y install git
	
	
    fi
fi	

# -------------------------------------------------------------------------------
if [[ "$OS" = "Ubuntu" ]]; then
	
	PACKAGE_INSTALLER="apt-get -yqq install"
	
    if [[ "$VER" = "16.04" ]]; then
	
	# START
	# -------------------------------------------------------------------------------
		echo "Starting PHP 7.3 with Packages update on Ubuntu 16.04"
	# -------------------------------------------------------------------------------	


        # START HERE
		
		sudo add-apt-repository ppa:ondrej/php
		sudo apt-get -yqq update
		sudo apt-get -yqq upgrade
		
		# Add repos
		#deb http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		#deb-src http://ppa.launchpad.net/ondrej/php/ubuntu xenial main
		
		# Install PHP 7 and modules
		apt-get -yqq install php7.3 php7.3-common 
		apt-get -yqq install php7.3-mysql php7.3-mbstring
		apt-get -yqq install php7.3-zip php7.3-xml php7.3-gd
		apt-get -yqq install php7.0-dev libapache2-mod-php7.3
		apt-get -yqq install php7.3-dev
		
		
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
		
		#apt install php-pear php7.3-curl php7.3-dev php7.3-gd php7.3-mbstring php7.3-zip php7.3-mysql php7.3-xml php7.3-fpm libapache2-mod-php7.3 php7.3-imagick php7.3-recode php7.3-tidy php7.3-xmlrpc php7.3-intl

		# Disable Apache mod_php7.0
		sudo a2dismod php7.0
		# Enable Apache mod_php7.3
		sudo a2enmod php7.3
		
		# Install git
		apt-get -y install git
		
		# Fix missing php.ini settings sentora needs
		echo -e "\nFix missing php.ini settings sentora needs in Ubuntu 16.04 php 7.3 ..."
		echo "setting upload_tmp_dir = /var/sentora/temp/"
		echo ""
		sed -i 's|;upload_tmp_dir =|upload_tmp_dir = /var/sentora/temp/|g' /etc/php/7.3/apache2/php.ini
		echo "Setting session.save_path = /var/sentora/sessions"
		sed -i 's|;session.save_path = "/var/lib/php/sessions"|session.save_path = "/var/sentora/sessions"|g' /etc/php/7.3/apache2/php.ini
		
		
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
	# Download Sentora Upgrader files Now
	# -------------------------------------------------------------------------------	
	
		#### FIX - Upgrade Sentora to Sentora Live for PHP 7.x fixes
	# reset home dir for commands
	cd ~
		
	# Download Sentora upgrade packages
	echo -e "\nDownloading Updated package files..." 
	mkdir -p sentora_php7_upgrade
	cd sentora_php7_upgrade
	wget -nv -O sentora_php7_upgrade.zip http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.zip
	
	echo -e "\n--- Unzipping files..."
	unzip -oq sentora_php7_upgrade.zip
	

	# -------------------------------------------------------------------------------
	# Start Sentora upgrade Below
	# -------------------------------------------------------------------------------
		
	# ####### start here   Upgrade __autoloader() to x__autoloader()
	# rm -rf $PANEL_PATH/panel/dryden/loader.inc.php
	# cd 
	# cp -r /sentora_update/loader.inc.php $PANEL_PATH/panel/dryden/
	sed -i 's/__autoload/x__autoload/g' /etc/sentora/panel/dryden/loader.inc.php
	
	# Update Snuff Default rules to fix panel timeout
	echo -e "\nUpdating Snuffleupagus default rules..."
	rm -rf /etc/sentora/configs/php/sp/snuffleupagus.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/snuffleupagus.rules /etc/sentora/configs/php/sp/snuffleupagus.rules
	cp -r  ~/sentora_php7_upgrade/preconf/php/sentora.rules /etc/sentora/configs/php/sp/sentora.rules
	
	# Upgrade apache_admin with apache_admin 1.0.x
	echo -e "\nUpdating Apache_admin module..."
	rm -rf /etc/sentora/panel/modules/apache_admin
	cp -r  ~/sentora_php7_upgrade/modules/apache_admin $PANEL_PATH/panel/modules/	
	
	# Upgrade domains_module to 1.0.x
	echo -e "\nUpdating Domains module..."
	rm -rf /etc/sentora/panel/modules/domains/
	cp -r  ~/sentora_php7_upgrade/modules/domains $PANEL_PATH/panel/modules/
	
	# Upgrade ftp_management module 1.0.x
	echo -e "\nUpdating FTP_management module..."
	rm -rf /etc/sentora/panel/modules/ftp_management/
	cp -r  ~/sentora_php7_upgrade/modules/ftp_management $PANEL_PATH/panel/modules/
		
	# Upgrade parked_Domains module 1.0.x
	echo -e "\nUpdating Parked_Domains module..."
	rm -rf /etc/sentora/panel/modules/parked_domains/
	cp -r  ~/sentora_php7_upgrade/modules/parked_domains $PANEL_PATH/panel/modules/
	
	# Upgrade Sub_Domains module 1.0.x
	echo -e "\nUpdating Sub_Domains module..."
	rm -rf /etc/sentora/panel/modules/sub_domains/
	cp -r  ~/sentora_php7_upgrade/modules/sub_domains $PANEL_PATH/panel/modules/
	
	# Copy New Apache config template files
	echo -e "\nUpdating Sentora vhost templates..."
	rm -rf /etc/sentora/configs/apache/templates/
	cp -r ~/sentora_php7_upgrade/preconf/apache/templates /etc/sentora/configs/apache/
	echo ""
	
	# install Smarty files
	cp -r ~/sentora_php7_upgrade/etc/lib/smarty /etc/sentora/panel/etc/lib/
	
	
	# Update Sentora Core Mysql tables
	# get mysql root password, check it works or ask it
	mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
	while ! mysql -u root -p$mysqlpassword -e ";" ; do
	read -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
	done
	echo -e "Connection mysql ok"
	mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sentora_1_0_3_1.sql
	
		
	# -------------------------------------------------------------------------------
	# Start Roundcube-1.3.10 upgrade Below
	# -------------------------------------------------------------------------------
	
	echo -e "\nStarting Roundcube upgrade to 1.3.10..."
	
	wget -nv -O roundcubemail-1.3.10.tar.gz https://github.com/roundcube/roundcubemail/releases/download/1.3.10/roundcubemail-1.3.10-complete.tar.gz
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
		echo -e "\nUpdating Ubuntu DNS fix..."
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
	
# Update Sentora APACHE CHANGED

#echo -e "\n--- Setting APACHE_CHANGED to true to set vhost setings..."
# get mysql root password, check it works or ask it
mysqlpassword=$(cat /etc/sentora/panel/cnf/db.php | grep "pass =" | sed -s "s|.*pass \= '\(.*\)';.*|\1|")
while ! mysql -u root -p$mysqlpassword -e ";" ; do
	read -p "Cant connect to mysql, please give root password or press ctrl-C to abort: " mysqlpassword
done
echo -e "Connection mysql ok"
mysql -u root -p"$mysqlpassword" < ~/sentora_php7_upgrade/preconf/sql/sen_apache_changed.sql		
	
	
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

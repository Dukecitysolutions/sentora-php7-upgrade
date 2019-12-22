#!/bin/bash

PANEL_PATH="/etc/sentora"
PANEL_DATA="/var/sentora"
PANEL_CONF="/etc/sentora/configs"
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
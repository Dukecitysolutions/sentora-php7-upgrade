# Sentora php7 upgrade - *Beta*
 Sentora PHP7 Upgrade

* Version: 1.0.0
* [Bug Tracker](https://github.com/Dukecitysolutions/sentora-php7-upgrade/issues) for any bugs or security related issues.

## THIS CODE IS NOT FOR PRODUCTION SYSTEMS YET. NEEDS TESTING. USE AT YOUR OWN RISK.

## About this upgrade script:
* Upgrades PHP 5.x to PHP 7.3
* Replaces Suhosin 9.x with Snuffleupagus for DISABLED_FUNCTIONS rules per vhost.
* Apache_admin - Upgraded to support SSL, Snuffleupagus disable_functions, vhosts file written with Smarty .tpl files.
* Domains Module - supports Snuffleupagus vhost rules deletion.
* Parked_Domains Module - supports Snuffleupagus vhost rules deletion.
* Sub_Domains Module - supports Snuffleupagus vhost rules deletion.
* Fixes __auto_loader issues with PHP 7.x
* Adds Smarty template lib to /etc/sentora/panel/etc/libs/smarty
* Adds apache vhost templates to /etc/sentora/configs/apache/templates
* NEEDS Security testing to make sure PHP 7 w/Snuffleupagus upgrade did not uninstall packages we need.(Except for Suhosin)
* More details to come soon.

Supported OS:

CentOS 6 & 7

Ubuntu 16.04 - Upgraded from 14.04 Proir to running upgrade script. - Details coming soon.


## How to use Sentora php7 upgrade script.

## CentOS Install:
wget -nv -O sentora_php7_upgrade.sh http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.sh

chmod +x sentora_php7_upgrade.sh

bash sentora_php7_upgrade.sh


## Ubuntu 14.04 to 16.04 Install:

### Download and Read upgrade instructions found below first. Use them Step-by-step.
(https://github.com/Dukecitysolutions/sentora-php7-upgrade/blob/master/sentora_ubun14to16.04_upgrade_guide.txt)

### After Ubuntu 14.04 to 16.04 is completed with instructions above. Run code below.

wget -nv -O sentora_php7_upgrade.sh http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/sentora_php7_upgrade.sh

chmod +x sentora_php7_upgrade.sh

bash sentora_php7_upgrade.sh

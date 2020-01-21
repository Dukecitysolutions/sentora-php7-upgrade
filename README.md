# Sentora PHP 7.3 upgrade - \*Testing ONLY\*

* PRODUCTION/LIVE RELEASE COMING SOON. STAY TUNED. Just needs testing.

* Version: 0.3.5 - BETA - 2020-01-20
* [BUG TRACKER](https://github.com/Dukecitysolutions/sentora-php7-upgrade/issues) for any bugs or security related issues.
* [CHANGELOG](https://github.com/Dukecitysolutions/sentora-php7-upgrade/blob/master/CHANGELOG.md) for viewing changes to this build.
* [TODO](https://github.com/Dukecitysolutions/sentora-php7-upgrade/blob/master/ToDo.md) List of changes to be made.
* [SUPPORT PAGE](http://sentora.dukecitysolutions.com) for forum support by our staff and community members.


## THIS CODE IS NOT FOR PRODUCTION/COMMERCIAL SYSTEMS YET. NEEDS FULL/SECURITY TESTING. USE AT YOUR OWN RISK.

## About this upgrade script:
* Created this upgrade script to help get PHP 7.x support to Sentora users Quickly, Safely and SECURELY.
* Upgrades PHP 5.x to PHP 7.3
* Replaces Suhosin 0.9.3x with Snuffleupagus for DISABLED_FUNCTIONS rules per vhost.
* Apache_admin - Upgraded to support SSL, Snuffleupagus disable_functions, vhosts file written with Smarty .tpl files.
* Adds Smarty template lib to /etc/sentora/panel/etc/libs/smarty
* NEEDS Security testing to make sure PHP 7 w/Snuffleupagus upgrade did not uninstall packages we need.(Except for Suhosin)
* Check out [CHANGELOG](https://github.com/Dukecitysolutions/sentora-php7-upgrade/blob/master/CHANGELOG.md) to view changes/details about this build.
* More details to come soon.

### Supported OS:

CentOS 6 & 7

Ubuntu 16.04 - Upgraded from 14.04 Prior to running upgrade script. - Details Below.


## How to use Sentora php7 upgrade script.

## CentOS Install:
```
bash <(curl -L -Ss http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/install.sh)
```

## Ubuntu 14.04 to 16.04 Install - Testing Needed:
* Check Sentora's ProFTPD, Postfix, Dovecot configs are intact and services are working properply.

### Download and Read upgrade instructions found below first. Use them Step-by-step.
(https://github.com/Dukecitysolutions/sentora-php7-upgrade/blob/master/sentora_ubun14to16.04_upgrade_guide.txt)

### After Ubuntu 14.04 to 16.04 is completed with instructions above. Run code below.
```
bash <(curl -L -Ss http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/install.sh)
```

## Nightly Updating for packages for this install - USE ONLY IF YOU HAVE INSTALLED upgrade.sh script:
### This script is safe to run at any time. Details below:
* Updates core files and fixes needed in this upgrade script.
* Use when updates have been made to files in this repo or use daily to keep current.
```
bash <(curl -L -Ss http://zppy-repo.dukecitysolutions.com/repo/sentora-live/php7_upgrade/update.sh)
```
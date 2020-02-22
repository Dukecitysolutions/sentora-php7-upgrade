# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [0.3.8-BETA] - 202-02-20
### Added
- Fail2ban to Sentora services(Apache, dovcote, Postfix, Proftpd, Roundcube)
- Installer version check. Sentora must be v1.0.3 or greater to use script.
- Update version check. Sentora must be equal to v1.0.3.1 to use update script.

### Changed
- Postfix database tables from MYISAM to INNODB
- Cleaned up installer/update script fixed typos, adjusted code.

### Fixed
- PHPsysinfo 3.3.1 phpsysinfo.ini missing. Sorry about that.
- Cleaned up installer/updater scripts a little.
- CentOS/Ubuntu Default/Sentora Snuffleupagus.rules command line/panel being to restrictive AGAIN. (Fixed int_get-suhosin snuff error and others.)
- CentOS 7 Bind issue not loading zones due to managed-keys not set correctly.

## [0.3.7-BETA] - 2020-02-04
### Changed
- Cron module to use its own cron.rules with disabled functions for security.

### Fixed
- PChart2 upgraded to PChart2.4 w/PHP7 support to fix Chart issues.
- CentOS php7-zip module missing in install/update script.
- CentOS/Ubuntu default Snuffleupagus.rules being to restrictive for panel/php commands.

## [0.3.6-BETA] - 2020-01-31
### Added
- Apache service to stop while upgrade/update is processing to avoid user side issues.
- Ubuntu PHP pkg Hold on PHP 7.1, 7.2 & 7.4 tell futher testing. Helps avoid updates installing other versions.
- Ubuntu added ppa:ondrej/apache2 repo to update apache modules.

### Fixed
- Ubuntu installing/updating to other PHP 7 versions during update. Might still need work.
- Ubuntu 16.04 Bind issue not loading zones due to managed-keys not set correctly.
- Cron module to use Snuffleupagus.rules for PHP function security.
- Ubuntu not adding user cron to crontabs file. CentOS for some reason still has issues.

### Security
- Fixed Sentora MYSQL_DATABASE module SECURITY ISSUE.

## [0.3.5-BETA] - 2020-01-20
### Added
- PHP 7.3 rebuild of php.ini file with shipped version (php.ini.rpmnew) for CentOS. PHP.ini backup to php.ini.OLD

### Fixed
- CentOS 6.x Apache 2.2 NameVirtualHost error resolved. (Redirect to panel issue)
- PHP set Curl/Openssl (curl.cainfo & openssl.cafile) CERT in php.ini for PHP curl_opt- 
  (man-in-the-middle attacks) protection with Snuffleupagus.

### Security
- Fixed Sentora MYSQL_USERS module SECURITY ISSUE. Sentora_core issue #338.
- Fixed Sentora MAILBOXES module SECURITY ISSUE. Sentora_core issue #NEED to submit.

## [0.3.4-BETA] - 2020-01-15
### Added
- Updated update script ONLY for Ubuntu 18.04 support - STILL NEEDS TESTING!

### Changed
- Changed install/update scripts to use GIT clone instead of wget for v1.0.3.1 core upgrade files.

### Fixed
- Issue with CentOS 6 Mysql upgrade corrupting mysql_users table.
- Adjusted install/update scripts for better compatibilty.

### Security
- Fixed Sentora DNS_ADMIN module SECURITY ISSUE. Sentora_core issue #344.

## [0.3.3-BETA] - 2020-01-09
### Added
- Sentora Live will now show BUILD verison in Update Module

### Changed
- Upgrade/update script to change Sentora DBVERSION differently. 

### Fixed
- PHP 7.4 removed package tell futher testing.
- Wordpress SSL issue with curl_opt (Snuffleupagus config was the cause). Need to check later for security issues.

## [0.3.2-BETA] - 2020-01-01
### Changed
- Snuffleupagus updated (default Rules) for better default PHP/VHOST security.
- Snuffleupagus updated (Sentora default Rules) for better control panel security.
- Apache_admin updated templates (vhost_cp/vhost_cp_ssl) preparing for Sentora CP PHP (openbase_dir) lockdown.
- Cron (Zdaemon) changed/updated for Snuffleupagus rules.
- Changed/Updated/Cleaned upgrader/update.sh scripts for issues/fixes/typos

### Fixed
- PHPMyAdmin 500 error DB issue. (Snuffleupagus config was the cause).
- Zdaemon not running/finishing with Snuffleupagus default rules.
- CentOS 6 upgrader script not installing PHP 7 issue.
- Ubuntu 16.04 Proftpd not working after install/upgrade.

## [0.3.1-BETA] - 2019-10-17
### Changed
- PHPMyAdmin 4.x to 4.9.2 current version.
- CentOS 6.x MYSQL 5.x to 5.5 upgrade.

### Fixed
- Snuffleupagus custom rules issues not setting correctly for control panel.

## [0.3.0-BETA] - 2019-09-11
### Added
- Snuffleupagus default rules
- Sentora panel Snuffleupagus default rules
- Version # added to installer/updater files
- Upgrader now logs upgrade output to /root/*_php7upgrade.log for DEBUGGING
- Added a ToDo.md file with check list
- Installers styling reformated to read better
- Lots of little fixes like styling. No need to list

### Fixed
- Ubuntu 16.04 PHP 7 install not installing Mcrypt
- CentOS fixed Proftpd not installing with Sentora orignal installer
- Sentora Panel error 500 after accessing other vhosts.
- CentOS 6 PHP 7 install issue with autoconfig wrong version
- Fixed Ubuntu 16.04 bind9 not starting after upgrade because of apparmor
- Minor cleanup of apache_admin OnDaemonRun.hook file 
- Fixed Roundcube 1.3.10 folder owner to root:root
- Fixed ftp_management module not creating proftpd user in proftpd database
- Cleaned up upgrader script and added Fail points with errors

## [0.2.0-ALPHA] - 2019-09-09
### Added
- Added Nightly package update script to update core build files.
- Added CHANGELOG.md to log all changes of builds.

### Changed
- Apache_admin module - Fixed Suhosin 0.9.3x and PHP7/Suhosin 7 support when released.
- FTP_management PHP 7.x fixes.
- PHPsysinfo 3.3.1 upgraded.
- Roundcube 1.3.10 upgraded.

## [0.1.0-PRE-ALPHA] - 2019-09-06
### Added
- Initial upload of starting core files.
- CentOS 6 & 7 and Ubuntu 16.04 supported
- PHP 5.x to 7.3 upgrade.
- Fixed Loader.inc.php (__autoload) for PHP 7.x
- Apache_admin module w/Snuffleupagus disable_functions per vhost.
- Domain module w/Snuffleupagus delete vhost rules support.
- Parked_domains module w/Snuffleupagus delete vhost rules support.
- Sub_domian module w/Snuffleupagus delete vhost rules support.


# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [0.3.1] - 2019-10-17
### Changed
- PHPMyAdmin 4.x to 4.9.1 current version.
- CentOS 6.x MYSQL 5.x to 5.5 upgrade.

### Fixed
- Snuffleupagus custom rules issues not setting correctly.

## [0.3.0] - 2019-09-11
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

## [0.2.0] - 2019-09-09
### Added
- Added Nightly package update script to update core build files.
- Added CHANGELOG.md to log all changes of builds.

### Changed
- Apache_admin module - Fixed Suhosin 0.9.3x and PHP7/Suhosin 7 support when released.
- FTP_management PHP 7.x fixes.
- PHPsysinfo 3.3.1 upgraded.
- Roundcube 1.3.10 upgraded.

## [0.1.0] - 2019-09-06
### Added
- Initial upload of starting core files.
- CentOS 6 & 7 and Ubuntu 16.04 supported
- PHP 5.x to 7.3 upgrade.
- Fixed Loader.inc.php (__autoload) for PHP 7.x
- Apache_admin module w/Snuffleupagus disable_functions per vhost.
- Domain module w/Snuffleupagus delete vhost rules support.
- Parked_domains module w/Snuffleupagus delete vhost rules support.
- Sub_domian module w/Snuffleupagus delete vhost rules support.


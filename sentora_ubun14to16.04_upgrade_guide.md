# Sentora Ubuntu 14.04 to 16.04 upgrade Guide

### Login to server directly or thur SSH as root
### and run the commands below and follow the instructions
```
apt-get -y update
apt-get -y install update-manager-core
sudo do-release-upgrade
```
------------------------------------------------------------------------
### Upgrade will start downloading files
It will say "Installing the upgrade can take serverals hours. Once the download has finished, the process cannot be canceled"
Press [y] - then press Enter.
------------------------------------------------------------------------

### Continues downloading files...

1 #------------------------------------------------------------------------

[Postfix Configuration] window will appear.
Select [No Configuration] - then press enter

2 #------------------------------------------------------------------------

[ProFTPD Configuration] window will apprear.
Select [standalone] - then press enter

3 #------------------------------------------------------------------------

[Configuring Libssl1.0.x:i386] window will apprear.
Select [Yes] - then press enter

4 #------------------------------------------------------------------------

[*Dovecot*- Modified configuration file] window will apprear.
Select [Keep the local version currently installed] - then press enter

5 #------------------------------------------------------------------------

[Configuration file '/etc/init.d/proftpd'] will ask again about config
Press [N] - then press enter

6 #------------------------------------------------------------------------

[ProFTPD Configuration] window will apprear.
Select [Keep the local version currently installed] - then press enter

7 #------------------------------------------------------------------------

[Unattended-upgrade] windows will appear
Select [Keep the local version currently installed] - then press enter

8 #------------------------------------------------------------------------

[Remove Obsolete packages?]
Press [Y] - then press enter

9 #------------------------------------------------------------------------

[Restart required]
Press [Y] - then press enter

10 #------------------------------------------------------------------------

## Done. Enjoy.



# Configuration for Sentora control panel SSL.
<VirtualHost *:443>
ServerAdmin {$cp.server_admin}
DocumentRoot "{$cp.server_root}"
ServerName {$cp.server_name}

<Directory "{$cp.server_root}">
    Options +FollowSymLinks -Indexes
    AllowOverride All
{if $cp.grant == '1'}
    Require all granted
{/if}
</Directory>

AddType application/x-httpd-php .php
#php_admin_value open_basedir "/var/sentora/:/etc/sentora/"
php_admin_value sp.configuration_file "/etc/sentora/configs/php/sp/sentora.rules"

ErrorLog "{$cp.log_dir}panel/sentora-error.log" 
CustomLog "{$cp.log_dir}panel/sentora-access.log" combined
CustomLog "{$cp.log_dir}panel/sentora-bandwidth.log" common

{if $loaderrorpages <> "0"}
{foreach $loaderrorpages as $errorpage}
{$errorpage}
{/foreach}
{/if}

{if $panel_ssl_txt != null }
{$panel_ssl_txt}
{/if}

# Custom settings are loaded below this line (if any exist)
{$global_zpcustom}
</VirtualHost>
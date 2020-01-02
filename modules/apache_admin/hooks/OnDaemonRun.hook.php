<?php

//start smarty
require '/etc/sentora/panel/etc/lib/smarty/libs/Smarty.class.php';
	
//** un-comment the following line to show the debug console
//$smarty->debugging = false;

echo fs_filehandler::NewLine() . "START Apache Config Hook." . fs_filehandler::NewLine();
if (ui_module::CheckModuleEnabled('Apache Config')) {
    echo "Apache Admin module ENABLED..." . fs_filehandler::NewLine();
    TriggerApacheQuotaUsage();
    if (ctrl_options::GetSystemOption('apache_changed') == strtolower("true")) {
        echo "Apache Config has changed..." . fs_filehandler::NewLine();
        if (ctrl_options::GetSystemOption('apache_backup') == strtolower("true")) {
            echo "Backing up Apache Config to: " . ctrl_options::GetSystemOption('apache_budir') . fs_filehandler::NewLine();
            BackupVhostConfigFile();
			
			//add ssl vhost backup
			//BackupSslVhostConfigFile();
        }
        echo "Begin writing Apache Config to: " . ctrl_options::GetSystemOption('apache_vhost') . fs_filehandler::NewLine();
        WriteVhostConfigFile();
		
		//begin to write ssl vhost files
		// "Begin writing Apache SSL Config to: " . ctrl_options::GetSystemOption('apache_ssl_vhost') . fs_filehandler::NewLine();
        //WriteSslVhostConfigFile();
		
    } else {
        echo "Apache Config has NOT changed...nothing to do." . fs_filehandler::NewLine();
    }
} else {
    echo "Apache Admin module DISABLED...nothing to do." . fs_filehandler::NewLine();
}
echo "END Apache Config Hook." . fs_filehandler::NewLine();

/**
 *
 * @param string $vhostName
 * @param numeric $customPort
 * @param string $userEmail[5~ * @return string
 *
 */
function BuildVhostPortForward($vhostName, $customPort, $userEmail)
{
	// ($sslenabled == !null) {
		//$customPort_in = 443;
	//} else {
		
		$customPort_in = $customPort;
	//};
	
    $line = "# DOMAIN: " . $vhostName . fs_filehandler::NewLine();
    $line .= "# PORT FORWARD FROM 80 TO: " . $customPort_in . fs_filehandler::NewLine();
    $line .= "<Virtualhost 0.0.0.0:80>" . fs_filehandler::NewLine();
    $line .= "ServerName " . $vhostName . fs_filehandler::NewLine();
    $line .= "ServerAlias www." . $vhostName . fs_filehandler::NewLine();
    $line .= "ServerAdmin " . $userEmail . fs_filehandler::NewLine();
    $line .= "RewriteEngine on" . fs_filehandler::NewLine();
    $line .= "ReWriteCond %{SERVER_PORT} !^" . $customPort_in . "$" . fs_filehandler::NewLine();
    $line .= ( $customPort_in === "443" ) ? "RewriteRule ^/(.*) https://%{HTTP_HOST}/$1 [NC,R,L] " . fs_filehandler::NewLine() : "RewriteRule ^/(.*) http://%{HTTP_HOST}:" . $customPort . "/$1 [NC,R,L] " . fs_filehandler::NewLine();
    $line .= "</virtualhost>" . fs_filehandler::NewLine();
    $line .= "# END DOMAIN: " . $vhostName . fs_filehandler::NewLine() . fs_filehandler::NewLine();
	$line .= "################################################################" . fs_filehandler::NewLine();
	$line .= fs_filehandler::NewLine();
		
    return $line;
}

function WriteVhostConfigFile()
{
    global $zdbh;
	
	//Start Smarty Session
	$smarty = new Smarty;
	$smarty->setTemplateDir('/etc/sentora/configs/apache/templates/');
	$smarty->setCompileDir('/etc/sentora/panel/etc/lib/smarty/templates_c/');
	//$smarty->setConfigDir('smarty/configs/');
	//$smarty->setCacheDir('smarty/cache/');
	
	if ((double) sys_versions::ShowApacheVersion() < 2.4) {
        $apgrant = "0";
    } else {
        $apgrant = "1";
    }
	
    //Get email for server admin of Sentora
    $getserveremail = $zdbh->query("SELECT ac_email_vc FROM x_accounts where ac_id_pk=1")->fetch();
    $serveremail = ( $getserveremail['ac_email_vc'] != "" ) ? $getserveremail['ac_email_vc'] : "postmaster@" . ctrl_options::GetSystemOption('sentora_domain');

    $VHostDefaultPort = ctrl_options::GetSystemOption('apache_port');
    $customPorts = array(ctrl_options::GetSystemOption('sentora_port'));
	
    $portQuery = $zdbh->prepare("SELECT vh_custom_port_in FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    $portQuery->execute();
	while ($rowport = $portQuery->fetch()) {
        $customPorts[] = (empty($rowport['vh_custom_port_in'])) ? $VHostDefaultPort : $rowport['vh_custom_port_in'];
		
		// Add vh_ssl_port_in ports to list array 
		$portQuery2 = $zdbh->prepare("SELECT vh_ssl_port_in FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    	$portQuery2->execute();
		while ($rowport2 = $portQuery2->fetch()) {
         	$customPorts[] = (empty($rowport2['vh_ssl_port_in'])) ? $VHostDefaultPort : $rowport2['vh_ssl_port_in'];
    	}	
    }
	
    $customPortList = array_unique($customPorts);
	
	//Set Control vhost path and check is there folder
	$server_panel = "/etc/sentora/configs/apache/vhosts/";	
	
	if ( !is_dir( $server_panel  ) ) {
              fs_director::CreateDirectory( $server_panel  );
       }
	
	//Error fucntion for Smarty template
	$errorpages = ctrl_options::GetSystemOption('sentora_root') . "/etc/static/errorpages";
	
	function is_errorpages() {
	$errorpages = ctrl_options::GetSystemOption('sentora_root') . "/etc/static/errorpages";
	if (is_dir($errorpages)) {
		if ($handle = opendir($errorpages)) {
			while (($file = readdir($handle)) !== false) {
				if ($file != "." && $file != "..") {
					$page = explode(".", $file);
					if (!fs_director::CheckForEmptyValue(CheckErrorDocument($page[0]))) {
						$loaderrorpages[] .= "ErrorDocument " . $page[0] . " /etc/static/errorpages/" . $page[0] . ".html";
					}
				}
			}
			closedir($handle);
			
			return $loaderrorpages;
		}
		
	}
	};
	
  	$is_errorpages = is_errorpages();
	
		 //***************************
	// Server values
	$server_port = ctrl_options::GetSystemOption('sentora_port');
	$server_root = ctrl_options::GetSystemOption('sentora_root');
	$server_name = ctrl_options::GetSystemOption('sentora_domain');
	$server_log_dir = ctrl_options::GetSystemOption('log_dir');	
	$panel_ssl_txt = ctrl_options::GetSystemOption('panel_ssl_tx');
	$global_zpcustom = ctrl_options::GetSystemOption('global_zpcustom');
	
  	//Smarty values
 	$cpsearch = array('server_ip' => '*',
					'server_port' => ctrl_options::GetSystemOption('sentora_port'),
					'server_root' => $server_root,
					'server_admin' => $serveremail,
					'server_name' => $server_name,
					'log_dir' => $server_log_dir,
					'grant' => $apgrant
					); 
					
	$smarty->assign('cp', $cpsearch);
	$smarty->assign('panel_ssl_txt', $panel_ssl_txt);
	$smarty->assign('global_zpcustom', $global_zpcustom);
	$smarty->assign('loaderrorpages', $is_errorpages);
	
	//****************************
					
    /*
     * ###########################################################################?###################################
     * #
     * # Default Virtual Host Container
     * #
     * ###########################################################################?###################################
     */

    $line = "################################################################" . fs_filehandler::NewLine();
    $line .= "# Apache VHOST configuration file" . fs_filehandler::NewLine();
    $line .= "# Automatically generated by Sentora " . sys_versions::ShowSentoraVersion() . fs_filehandler::NewLine();
    $line .= "# Generated on: " . date(ctrl_options::GetSystemOption('sentora_df'), time()) . fs_filehandler::NewLine();
    $line .= "#==== YOU MUST NOT EDIT THIS FILE : IT WILL BE OVERWRITTEN ====" . fs_filehandler::NewLine();
    $line .= "# Use Sentora Menu -> Admin -> Module Admin -> Apache config" . fs_filehandler::NewLine();
    $line .= "################################################################" . fs_filehandler::NewLine();
    $line .= fs_filehandler::NewLine();


    # Listen is mandatory for each port <> 80 (80 is defined in system config)
    foreach ($customPortList as $port) {
        $line .= "Listen " . $port . fs_filehandler::NewLine();
    }
    $line .= fs_filehandler::NewLine();
	  
	//Load template file into vhost cofig to save
	$line .= $smarty->fetch("vhost_cp.tpl") . fs_filehandler::NewLine();
		
	//Forwrd Sentora Panel if SSL is in use
	// If vhost SSL_TX not null create spearate <virtualhost>
	// Build Vhost SSL section
    if ($panel_ssl_txt != null) {
		$line .= "################################################################" . fs_filehandler::NewLine();
		$line .= fs_filehandler::NewLine();
		$line .= $smarty->fetch("vhost_cp_ssl.tpl") . fs_filehandler::NewLine();
		}
	
	//*********Write to file
	//writetofile($server_panel . "sentora-cp.conf", $line);
	//***********
	
	$line .= fs_filehandler::NewLine();
    $line .= "################################################################" . fs_filehandler::NewLine();
    $line .= "# Sentora generated VHOST configurations below....." . fs_filehandler::NewLine();
    $line .= "################################################################" . fs_filehandler::NewLine();
    $line .= fs_filehandler::NewLine();

    /*
     * ##############################################################################################################
     * #
     * # All Virtual Host Containers
     * #
     * ##############################################################################################################
     */

    // Sentora virtual host container configuration
    $sql = $zdbh->prepare("SELECT * FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    $sql->execute();
    while ($rowvhost = $sql->fetch()) {
		
		
        // Grab some variables we will use for later...
        $vhostuser = ctrl_users::GetUserDetail($rowvhost['vh_acc_fk']);
        $bandwidth = ctrl_users::GetQuotaUsages('bandwidth', $vhostuser['userid']);
        $diskspace = ctrl_users::GetQuotaUsages('diskspace', $vhostuser['userid']);
        // Set the vhosts to "LIVE"
        $vsql = $zdbh->prepare("UPDATE x_vhosts SET vh_active_in=1 WHERE vh_id_pk=:id");
        $vsql->bindParam(':id', $rowvhost['vh_id_pk']);
        $vsql->execute();

        // Add a default email if no email found for client.
        $useremail = ( fs_director::CheckForEmptyValue($vhostuser['email']) ) ? "postmaster@" . $rowvhost['vh_name_vc'] : $vhostuser['email'];

        // Check if domain or subdomain to see if we add an alias with 'www'
        $serveralias = ( $rowvhost['vh_type_in'] == 2 ) ? '' : " www." . $rowvhost['vh_name_vc'];

		//Check if site is ssl enabled to pevent duplicate Port 443
        //if ($rowvhost['vh_ssl_tx'] == !null) {
			//$vhostPort = $VHostDefaultPort;
		//} else {
			$vhostPort = ( fs_director::CheckForEmptyValue($rowvhost['vh_custom_port_in']) ) ? $VHostDefaultPort : $rowvhost['vh_custom_port_in'];
		//};
		
        $vhostIp = ( fs_director::CheckForEmptyValue($rowvhost['vh_custom_ip_vc']) ) ? "*" : $rowvhost['vh_custom_ip_vc'];
		
		// Get Package php and cgi enabled options
        $rows = $zdbh->prepare("SELECT * FROM x_packages WHERE pk_id_pk=:packageid AND pk_deleted_ts IS NULL");
        $rows->bindParam(':packageid', $vhostuser['packageid']);
        $rows->execute();
        $packageinfo = $rows->fetch();
		
	//*************************************************
			  
		$vhRootDir =  ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . '/public_html' . $rowvhost['vh_directory_vc'];  
	  
		//Sentora code values
		$vh_server_ip = $vhostIp;
		$vh_server_port = $vhostPort;
		$vh_server_name = $rowvhost['vh_name_vc'];
		$vh_serveralias = ( $rowvhost['vh_type_in'] == 2 ) ? '' : " www." . $rowvhost['vh_name_vc'];
		$vh_server_admin = $useremail;
		$vh_server_root = $vhRootDir;
		$vh_server_type = ($packageinfo['pk_enablephp_in'] <> 0) ? ctrl_options::GetSystemOption('php_handler') : '#' . ctrl_options::GetSystemOption('php_handler');
		$vh_error_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-error.log' . '"';
		$vh_access_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-access.log" ' . ctrl_options::GetSystemOption('access_log_format');
		$vh_bandwidth_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-bandwidth.log" ' . ctrl_options::GetSystemOption('bandwidth_log_format');
		$vh_php_open_basedir = ($rowvhost['vh_obasedir_in'] <> 0) ? '"' . $vh_server_root . ctrl_options::GetSystemOption('openbase_seperator') . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . ctrl_options::GetSystemOption('openbase_seperator') . ctrl_options::GetSystemOption('openbase_temp') . '"' : '"' . $vh_server_root . ':     ' . '"';
	
		$vh_php_upload_dir = '"' . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . "\"";
		$vh_php_session_path = '"' . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . "\"";
		$vh_parking_path = ctrl_options::GetSystemOption('parking_path');
		$vh_static_dir = ctrl_options::GetSystemOption('static_dir');
		$use_openbase = ctrl_options::GetSystemOption('use_openbase');
		$use_suhosin = ctrl_options::GetSystemOption('use_suhosin');
		$obasedir_in = $rowvhost['vh_obasedir_in']; 
		$suhosin_in = $rowvhost['vh_suhosin_in'];
		$vh_snuff_path = "/etc/sentora/configs/php/sp/";
		$vh_vhostuser = $vhostuser['username'];
		
		# PHP Disable_functions protection system ( suhison or Ssnuffleupagus )
		if (extension_loaded('suhosin') == true ) {	
			$func_blklist_sys = ($rowvhost['vh_suhosin_in'] <> 0) ? ctrl_options::GetSystemOption('suhosin_value') : '';
		} else {
			$func_blklist_sys = ($rowvhost['vh_suhosin_in'] <> 0) ? 'php_admin_value sp.configuration_file "' . $vh_snuff_path . $vh_vhostuser . "/" . $rowvhost['vh_name_vc'] . '.rules"' : '';
					
			// Check sp user path exists if not make folder for sp vhost configs
			if(!is_file($vh_snuff_path . $vh_vhostuser . "/" . $rowvhost['vh_name_vc'] . '.rules')) {
				
				if ( !is_dir( $vh_snuff_path . $vh_vhostuser ) ) {
					fs_director::CreateDirectory( $vh_snuff_path . $vh_vhostuser );
				}
  				//$linesp = $smarty->fetch("vhost_sp_rules.tpl") . fs_filehandler::NewLine();
				$linesp = $rowvhost['vh_custom_sp_tx'];
				$linesp .= fs_filehandler::NewLine();
				$linesp .= $smarty->fetch("vhost_sp_rules.tpl") . fs_filehandler::NewLine();

				//*********Write to file
				writetofile($vh_snuff_path . $vh_vhostuser . "/" . $rowvhost['vh_name_vc'] . '.rules'  , $linesp);
				//***********
				
			} elseif (is_file($vh_snuff_path . $vh_vhostuser . "/" . $rowvhost['vh_name_vc'] . '.rules')) {
				
				// TEST build if statment to add custom sp values
				//if($rowvhost['vh_custom_sp_tx'] != null) {
				$linesp = $rowvhost['vh_custom_sp_tx'];
				$linesp .= fs_filehandler::NewLine();
				$linesp .= $smarty->fetch("vhost_sp_rules.tpl") . fs_filehandler::NewLine();
				
				//*********Write to file
				writetofile($vh_snuff_path . $vh_vhostuser . "/" . $rowvhost['vh_name_vc'] . '.rules'  , $linesp);
				//***********
				//}
			}
		};
		/*
		//Set vhost path and checks if there is folder
		$vh_path = "/etc/sentora/configs/apache/vhosts/";
		if ( !is_dir( $vh_path  ) ) {
              fs_director::CreateDirectory( $vh_path  );
       	}
		*/	
		
 		//Smarty values
 		$vhsearch = array('server_ip' => $vh_server_ip,
						'server_port' => $vh_server_port,
						'server_name' => $vh_server_name,
						'server_alias' => $vh_serveralias,
						'server_admiin' => $vh_server_admin,
						'server_root' => $vh_server_root,
						'server_addtype' => $vh_server_type,
						'error_log' => $vh_error_log,
						'access_log' => $vh_access_log,
						'bandwidth_log' => $vh_bandwidth_log,
						'php_values' => $vh_php_open_basedir,
						'php_func_blacklist' => $func_blklist_sys,
						'php_upload_dir' => $vh_php_upload_dir,
						'php_session_path' => $vh_php_session_path,
						'parking_path' => $vh_parking_path,
						'static_dir' => $vh_static_dir,
						'use_openbase' => $use_openbase,
						'use_suhosin' => $use_suhosin,
						'obasedir_in' => $obasedir_in,
						'suhosin_in' => $suhosin_in,
						'global_vhcustom' => ctrl_options::GetSystemOption('global_vhcustom'),
						'vh_custom_tx' => $rowvhost['vh_custom_tx'],
						'ssl_tx' => $rowvhost['vh_ssl_tx'],
						'ssl_port_in' => $rowvhost['vh_ssl_port_in'],
						'hosted_dir' => ctrl_options::GetSystemOption('hosted_dir'),
						'vhost_user' => $vh_vhostuser,
						'grant' => $apgrant
						);
				
		$smarty->assign('vh', $vhsearch);
 		
		//****************************
	
        //Domain is enabled
        //Line1: Domain enabled & Client also is enabled.
        //Line2: Domain enabled & Client may be disabled, but 'Allow Disabled' = 'true' in apache settings.
        if ($rowvhost['vh_enabled_in'] == 1 && ctrl_users::CheckUserEnabled($rowvhost['vh_acc_fk']) ||
            $rowvhost['vh_enabled_in'] == 1 && ctrl_options::GetSystemOption('apache_allow_disabled') == strtolower("true")) {

            /*
             * ##################################################
             * #
             * # Disk Quotas Check
             * #
             * ##################################################
             */

            //Domain is beyond its diskusage
            if ($vhostuser['diskquota'] != 0 && $diskspace > $vhostuser['diskquota']) {
				
				
				//Load template file into vhost cofig to save
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN DISABLED FOR QUOTA OVERAGE" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_disk_quota.tpl") . fs_filehandler::NewLine();
				
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                // If vhost SSL_TX not null create spearate <virtualhost>
                if ($rowvhost['vh_ssl_tx'] != null) {
                    // Build Vhost SSL section
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "# THIS DOMAIN HAS BEEN DISABLED FOR QUOTA OVERAGE & HAS SSL Enabled" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_disk_quota_ssl.tpl") . fs_filehandler::NewLine();
				$line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "################################################################" . fs_filehandler::NewLine();
				}
				$line .= fs_filehandler::NewLine();
				
				//*********Write to file
				//writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********	
				
                /*
                 * ##################################################
                 * #
                 * # Bandwidth Quotas Check
                 * #
                 * ##################################################
                 */

                //Domain is beyond its quota
            } elseif ($vhostuser['bandwidthquota'] != 0 && $bandwidth > $vhostuser['bandwidthquota']) {
				
				//Load template file into vhost cofig to save
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN DISABLED FOR BANDWIDTH OVERAGE" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_bandwidth.tpl") . fs_filehandler::NewLine();
				
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                // If vhost SSL_TX not null create spearate <virtualhost>
                if ($rowvhost['vh_ssl_tx'] != null) {
                    // Build Vhost SSL section
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "# THIS DOMAIN HAS BEEN DISABLED FOR BANDWIDTH OVERAGE & HAS SSL Enabled" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_bandwidth_ssl.tpl") . fs_filehandler::NewLine();
				$line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "################################################################" . fs_filehandler::NewLine();
				}
				$line .= fs_filehandler::NewLine();
				
				//*********Write to file
				//writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********				
				
                /*
                 * ##################################################
                 * #
                 * # Parked Domain
                 * #
                 * ##################################################
                 */

                //Domain is a PARKED domain.
            } elseif ($rowvhost['vh_type_in'] == 3) {
				
				//Load template file into vhost config to save
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN PARKED" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_parked.tpl") . fs_filehandler::NewLine();	
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
				$line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
				// If vhost SSL_TX not null create spearate <virtualhost>
                if ($rowvhost['vh_ssl_tx'] != null) {
                    // Build Vhost SSL section
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "# THIS DOMAIN IS PARKED & HAS SSL Enabled" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_parked_ssl.tpl") . fs_filehandler::NewLine();
				$line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "################################################################" . fs_filehandler::NewLine();
				}
				$line .= fs_filehandler::NewLine();
								
				//*********Write to file
				//writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********
				
                /*
                 * ##################################################
                 * #
                 * # Regular or Sub domain With PHP7/PHP-FPM MOD - PHP 7+
                 * #
                 * ##################################################
                 */

				//checo
                //Domain is a regular domain or a subdomain with PHP MOD.
            } else {
               
				// Temp
                if ( !is_dir( ctrl_options::GetSystemOption('hosted_dir') . $vhostuser[ 'username' ] . "/tmp" ) ) {
                    fs_director::CreateDirectory( ctrl_options::GetSystemOption( 'hosted_dir' ) . $vhostuser[ 'username' ] . "/tmp" );
                }
				
				// Logs
                if (!is_dir(ctrl_options::GetSystemOption('log_dir') . "domains/" . $vhostuser['username'] . "/")) {
                    fs_director::CreateDirectory(ctrl_options::GetSystemOption('log_dir') . "domains/" . $vhostuser['username'] . "/");
                }
				
				//Load template file into vhost config to save
				$line .= $smarty->fetch("vhost_domain.tpl") . fs_filehandler::NewLine();
                // End Virtual Host Settings
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                				
				// If vhost SSL_TX not null create spearate <virtualhost>
                if ($rowvhost['vh_ssl_tx'] != null) {
                    // Build Vhost SSL section
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "# THIS DOMAIN HAS SSL Enabled" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_domain_ssl.tpl") . fs_filehandler::NewLine();
				$line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "################################################################" . fs_filehandler::NewLine();
                }
                $line .= fs_filehandler::NewLine();
				
				//*********Write to file
				//writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********
            }

            /*
             * ##################################################
             * #
             * # Disabled domain
             * #
             * ##################################################
             */
        } else {
            //Domain is NOT enabled
			
			//Load template file into vhost cofig to save
			$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
            $line .= "# THIS DOMAIN HAS BEEN DISABLED" . fs_filehandler::NewLine();
			$line .= $smarty->fetch("vhost_disabled.tpl") . fs_filehandler::NewLine();
					
            $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
            $line .= "################################################################" . fs_filehandler::NewLine();
			$line .= fs_filehandler::NewLine();
			
			// If vhost SSL_TX not null create spearate <virtualhost>
                if ($rowvhost['vh_ssl_tx'] != null) {
                    // Build Vhost SSL section
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "# THIS DOMAIN HAS BEEN DISABLED & HAS SSL Enabled" . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_disabled_ssl.tpl") . fs_filehandler::NewLine();
				$line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
    			$line .= "################################################################" . fs_filehandler::NewLine();
				}
				$line .= fs_filehandler::NewLine();
			
			//*********Write to file
			//writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
			//***********
        }
    }

    /*
     * ##############################################################################################################
     * #
     * # Write vhost file to disk
     * #
     * ##############################################################################################################
     */
/*
    // write the vhost config file
    $vhconfigfile = ctrl_options::GetSystemOption('apache_vhost');
    if (fs_filehandler::UpdateFile($vhconfigfile, 0777, $line)) {
        // Reset Apache settings to reflect that config file has been written, until the next change.
        $time = time();
        $vsql = $zdbh->prepare("UPDATE x_settings
                                    SET so_value_tx=:time
                                    WHERE so_name_vc='apache_changed'");
        $vsql->bindParam(':time', $time);
        $vsql->execute();
        echo "Finished writting Apache Config... Now reloading Apache..." . fs_filehandler::NewLine();

        $returnValue = 0;

        if (sys_versions::ShowOSPlatformVersion() == "Windows") {
            system("" . ctrl_options::GetSystemOption('httpd_exe') . " " . ctrl_options::GetSystemOption('apache_restart') . "", $returnValue);
        } else {
            $command = ctrl_options::GetSystemOption('zsudo');
            $args = array(
                "service",
                ctrl_options::GetSystemOption('apache_sn'),
                ctrl_options::GetSystemOption('apache_restart')
            );
            $returnValue = ctrl_system::systemCommand($command, $args);
        }

        echo "Apache reload " . ((0 === $returnValue ) ? "suceeded" : "failed") . "." . fs_filehandler::NewLine();
    } else {
        return false;
    }
	*/
	
	//Restart/Reload Webserver service
	//*********Write to file
	$vhconfigfile = ctrl_options::GetSystemOption('apache_vhost');
	writetofile($vhconfigfile, $line);
	//***********
	restarthttp();
	
}

function restarthttp() {
	   
	   global $zdbh;
	   
        // Reset Apache settings to reflect that config file has been written, until the next change.
        $time = time();
        $vsql = $zdbh->prepare("UPDATE x_settings
                                    SET so_value_tx=:time
                                    WHERE so_name_vc='apache_changed'");
        $vsql->bindParam(':time', $time);
        $vsql->execute();
        echo "Finished writting Apache Config... Now reloading Apache..." . fs_filehandler::NewLine();

        $returnValue = 0;

        if (sys_versions::ShowOSPlatformVersion() == "Windows") {
            system("" . ctrl_options::GetSystemOption('httpd_exe') . " " . ctrl_options::GetSystemOption('apache_restart') . "", $returnValue);
        } else {
            $command = ctrl_options::GetSystemOption('zsudo');
            $args = array(
                "service",
                ctrl_options::GetSystemOption('apache_sn'),
                ctrl_options::GetSystemOption('apache_restart')
            );
            $returnValue = ctrl_system::systemCommand($command, $args);
        }

        echo "Apache reload " . ((0 === $returnValue ) ? "suceeded" : "failed") . "." . fs_filehandler::NewLine();

}
/*
function DeleteVhostSpFileIfNotActive() {
	
	global $zdbh;
	
	$sql = $zdbh->prepare("SELECT * FROM x_vhosts WHERE vh_deleted_ts IS NOT NULL");
    $sql->execute();
    while ($rowvhost = $sql->fetch()) {
				
		$vhostuser = ctrl_users::GetUserDetail($rowvhost['vh_acc_fk']);
		$vhostusername = $vhostuser['username'];
		$vh_snuff_path = "/etc/sentora/configs/php/sp/";
		
		if (file_exists($vh_snuff_path . $vhostusername . "/" . $rowvhost['vh_name_vc'] . '.rules')) {
			unlink($vh_snuff_path . $vhostusername . "/" . $rowvhost['vh_name_vc'] . '.rules') or print fs_filehandler::NewLine() . "Couldn't delete " . $rowvhost['vh_name_vc'] . "vhost sp file" . fs_filehandler::NewLine();
		}
	}
}
*/
/*
  * ###########################################################################?###################################
  * #
  * # Write SSL vhost files and restart srever
  * #
  * ###########################################################################?###################################
*/
/*
function WriteSslVhostConfigFile()
{
    global $zdbh;
	
	//Start Smarty Session
	$smarty = new Smarty;
	$smarty->setTemplateDir('/etc/sentora/configs/apache/templates/');
	$smarty->setCompileDir('modules/apache_admin/smarty/templates_c/');
	//$smarty->setConfigDir('smarty/configs/');
	//$smarty->setCacheDir('smarty/cache/');
	
    //Get email for server admin of Sentora
    $getserveremail = $zdbh->query("SELECT ac_email_vc FROM x_accounts where ac_id_pk=1")->fetch();
    $serveremail = ( $getserveremail['ac_email_vc'] != "" ) ? $getserveremail['ac_email_vc'] : "postmaster@" . ctrl_options::GetSystemOption('sentora_domain');

    $VHostDefaultPort = ctrl_options::GetSystemOption('apache_port');
    $customPorts = array(ctrl_options::GetSystemOption('sentora_port'));
    $portQuery = $zdbh->prepare("SELECT vh_custom_port_in FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    $portQuery->execute();
    while ($rowport = $portQuery->fetch()) {
        $customPorts[] = (empty($rowport['vh_custom_port_in'])) ? $VHostDefaultPort : $rowport['vh_custom_port_in'];
    }
    $customPortList = array_unique($customPorts);
	
	 //***************************
	// Server values
	$server_ip = "*";
	$server_port = ctrl_options::GetSystemOption('sentora_port');
	$server_root = ctrl_options::GetSystemOption('sentora_root');
	$server_name = ctrl_options::GetSystemOption('sentora_domain');
	$server_log_dir = ctrl_options::GetSystemOption('log_dir');		
	$global_zpcustom = ctrl_options::GetSystemOption('global_zpcustom');
  
  	//Set Control SSL vhost path and check is there folder
	$server_panel = "/etc/sentora/configs/apache/vhost_cp/";	
	
	if ( !is_dir( $server_panel  ) ) {
              fs_director::CreateDirectory( $server_panel  );
       }
  
  	//Smarty values
 	$cpsearch = array('server_ip' => $server_ip,
					'server_port' => $server_port,
					'server_root' => $server_root,
					'server_admin' => $serveremail,
					'server_name' => $server_name,
					'log_dir' => $server_log_dir,
					'global_zpcustom' => $global_zpcustom
					); 
					
	$smarty->assign('cp', $cpsearch);
  	
	//****************************
				
    /*
     * ###########################################################################?###################################
     * #
     * # Default SSL Virtual Host Container
     * #
     * ###########################################################################?###################################
     */
/*
    $line = "################################################################" . fs_filehandler::NewLine();
    $line .= "# Apache VHOST configuration file" . fs_filehandler::NewLine();
    $line .= "# Automatically generated by Sentora " . sys_versions::ShowSentoraVersion() . fs_filehandler::NewLine();
    $line .= "# Generated on: " . date(ctrl_options::GetSystemOption('sentora_df'), time()) . fs_filehandler::NewLine();
    $line .= "#==== YOU MUST NOT EDIT THIS FILE : IT WILL BE OVERWRITTEN ====" . fs_filehandler::NewLine();
    $line .= "# Use Sentora Menu -> Admin -> Module Admin -> Apache config" . fs_filehandler::NewLine();
    $line .= "################################################################" . fs_filehandler::NewLine();
    $line .= fs_filehandler::NewLine();


    # Listen is mandatory for each port <> 80 (80 is defined in system config)
    foreach ($customPortList as $port) {
        $line .= "Listen " . $port . fs_filehandler::NewLine();
    }
    $line .= fs_filehandler::NewLine();
	
  
	//Load template file into vhost cofig to save
    //$line .= $str . fs_filehandler::NewLine();
	$line .= $smarty->fetch("vhost_cp.tpl") . fs_filehandler::NewLine();
		
    $line .= fs_filehandler::NewLine();
    	
	//SSL engine settings
	//$line .= "# SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
	//$line .= ctrl_options::GetSystemOption('apache_ssl_tx') . fs_filehandler::NewLine();
	//$line .= "# END SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
	// END SSL engine settings

    //$line .= "</VirtualHost>" . fs_filehandler::NewLine();

	//*********Write to file
	writetofile($server_panel . "vhost_cp_ssl.conf", $line);
	//***********
*/

    /*
     * ##############################################################################################################
     * #
     * # All SSL Virtual Host Containers
     * #
     * ##############################################################################################################
     */
/*
    // Sentora virtual host container configuration
    $sql = $zdbh->prepare("SELECT * FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    $sql->execute();
    while ($rowvhost = $sql->fetch()) {
		
        // Grab some variables we will use for later...
        $vhostuser = ctrl_users::GetUserDetail($rowvhost['vh_acc_fk']);
        $bandwidth = ctrl_users::GetQuotaUsages('bandwidth', $vhostuser['userid']);
        $diskspace = ctrl_users::GetQuotaUsages('diskspace', $vhostuser['userid']);
        // Set the vhosts to "LIVE"
        $vsql = $zdbh->prepare("UPDATE x_vhosts SET vh_active_in=1 WHERE vh_id_pk=:id");
        $vsql->bindParam(':id', $rowvhost['vh_id_pk']);
        $vsql->execute();

        // Add a default email if no email found for client.
        $useremail = ( fs_director::CheckForEmptyValue($vhostuser['email']) ) ? "postmaster@" . $rowvhost['vh_name_vc'] : $vhostuser['email'];

        // Check if domain or subdomain to see if we add an alias with 'www'
        $serveralias = ( $rowvhost['vh_type_in'] == 2 ) ? '' : " www." . $rowvhost['vh_name_vc'];


		//Check if site is ssl enabled to pevent duplicate Port 443
        if ($rowvhost['vh_ssl_tx'] == !null) {
			
			$vhostPort = $VHostDefaultPort;
		} else {
			
			$vhostPort = ( fs_director::CheckForEmptyValue($rowvhost['vh_custom_port_in']) ) ? $VHostDefaultPort : $rowvhost['vh_custom_port_in'];
		};


        $vhostIp = ( fs_director::CheckForEmptyValue($rowvhost['vh_custom_ip_vc']) ) ? "*" : $rowvhost['vh_custom_ip_vc'];
		
		
	//************************************************* 
	//Sentora code values
	$vh_server_ip = $vhostIp;
	$vh_server_port = "443";
	$vh_server_name = $rowvhost['vh_name_vc'];
	$vh_serveralias = ( $rowvhost['vh_type_in'] == 2 ) ? '#ServerAlias' : "ServerAlias www." . $rowvhost['vh_name_vc'];
	$vh_server_admin = $useremail;
	$vh_server_root = $RootDir;
	$vh_server_type = ($packageinfo['pk_enablephp_in'] <> 0) ? ctrl_options::GetSystemOption('php_handler') : '#' . ctrl_options::GetSystemOption('php_handler');
	$vh_error_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-error.log' . '"';
	$vh_access_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-access.log" ' . ctrl_options::GetSystemOption('access_log_format');
	$vh_bandwidth_log = '"' . "/var/sentora/logs/" . "domains/" . $vhostuser['username'] . "/" . $rowvhost['vh_name_vc'] . '-bandwidth.log" ' . ctrl_options::GetSystemOption('bandwidth_log_format');
	$vh_php_open_basedir = ($rowvhost['vh_obasedir_in'] <> 0) ? 'php_admin_value open_basedir "' . $vh_server_root . ctrl_options::GetSystemOption('openbase_seperator') . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . ctrl_options::GetSystemOption('openbase_seperator') . ctrl_options::GetSystemOption('openbase_temp') . '"' : '#php_admin_value open_basedir ' . $vh_server_root . ':     ' . '"';
	
	$vh_php_func_blacklist = ($rowvhost['vh_suhosin_in'] <> 0) ? ctrl_options::GetSystemOption('suhosin_value') : '#' . ctrl_options::GetSystemOption('suhosin_value');
	$vh_php_upload_dir = '"' . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . "\"";
	$vh_php_session_path = '"' . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . "/tmp" . "\"";
	$vh_parking_path = ctrl_options::GetSystemOption('parking_path');
	$vh_static_dir = ctrl_options::GetSystemOption('static_dir');
	$use_openbase = ctrl_options::GetSystemOption('use_openbase');
	$use_suhosin = ctrl_options::GetSystemOption('use_suhosin');
	$obasedir_in = $rowvhost['vh_obasedir_in'];
	$suhosin_in = $rowvhost['vh_suhosin_in'];
	
	//Set SSL vhost path and check is there folder
	$vh_path = "/etc/sentora/configs/apache/vhosts_ssl/";
	
	if ( !is_dir( $vh_path  ) ) {
              fs_director::CreateDirectory( $vh_path  );
       }
				
 
 	//Smarty values
 	$vhsearch = array('server_ip' => $vh_server_ip,
					'server_port' => $vh_server_port,
					'server_name' => $vh_server_name,
					'server_alias' => $vh_serveralias,
					'server_admiin' => $vh_server_admin,
					'server_root' => $vh_server_root,
					'server_addtype' => $vh_server_type,
					'error_log' => $vh_error_log,
					'access_log' => $vh_access_log,
					'bandwidth_log' => $vh_bandwidth_log,
					'php_values' => $vh_php_open_basedir,
					'php_func_blacklist' => $vh_php_func_blacklist,
					'php_upload_dir' => $vh_php_upload_dir,
					'php_session_path' => $vh_php_session_path,
					'parking_path' => $vh_parking_path,
					'static_dir' => $vh_static_dir,
					'use_openbase' => $use_openbase,
					'use_suhosin' => $use_suhosin,
					'obasedir_in' => $obasedir_in,
					'suhosin_in' => $suhosin_in,
					'global_vhcustom' => ctrl_options::GetSystemOption('global_vhcustom'),
					'vh_custom_tx' => $rowvhost['vh_custom_tx'],
					'ssl_tx' => $rowvhost['vh_ssl_tx']
					);
				
	$smarty->assign('vh', $vhsearch);
 	
	//****************************
	
        //Domain is enabled
        //Line1: Domain enabled & Client also is enabled.
        //Line2: Domain enabled & Client may be disabled, but 'Allow Disabled' = 'true' in apache settings.
        if ($rowvhost['vh_enabled_in'] == 1 && ctrl_users::CheckUserEnabled($rowvhost['vh_acc_fk']) ||
            $rowvhost['vh_enabled_in'] == 1 && ctrl_options::GetSystemOption('apache_allow_disabled') == strtolower("true")) {
*/
            /*
             * ##################################################
             * #
             * # SSL Disk Quotas Check
             * #
             * ##################################################
             */
/*
            //Domain is beyond its diskusage
            if ($vhostuser['diskquota'] != 0 && $diskspace > $vhostuser['diskquota']) {
				
				
				//Load template file into vhost cofig to save
				$line = "";
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN DISABLED FOR QUOTA OVERAGE" . fs_filehandler::NewLine();
    			//$line .= $str . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_disk_quota.tpl") . fs_filehandler::NewLine();
				
				//SSL engine settings
				//$line .= "# SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				//$line .= $rowvhost['vh_ssl_tx'] . fs_filehandler::NewLine();
				//$line .= "# END SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				// END SSL engine settings
				
				//$line .= "</virtualhost>" . fs_filehandler::NewLine();
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                $line .= fs_filehandler::NewLine();
				
				//*********Write to file
				writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********	
				*/
                /*
                 * ##################################################
                 * #
                 * # SSL Bandwidth Quotas Check
                 * #
                 * ##################################################
                 */
/*
                //Domain is beyond its quota
            } elseif ($vhostuser['bandwidthquota'] != 0 && $bandwidth > $vhostuser['bandwidthquota']) {

				
				//Load template file into vhost cofig to save
				$line = "";
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN DISABLED FOR BANDWIDTH OVERAGE" . fs_filehandler::NewLine();
    			//$line .= $str . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_bandwidth.tpl") . fs_filehandler::NewLine();
				
				//SSL engine settings
				//$line .= "# SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				//$line .= $rowvhost['vh_ssl_tx'] . fs_filehandler::NewLine();
				//$line .= "# END SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				// END SSL engine settings
				
                //$line .= "</virtualhost>" . fs_filehandler::NewLine();
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                $line .= fs_filehandler::NewLine();
				
				//*********Write to file
				writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********				
/*				
                /*
                 * ##################################################
                 * #
                 * # SSL Parked Domain
                 * #
                 * ##################################################
                 */
/*
                //Domain is a PARKED domain.
            } elseif ($rowvhost['vh_type_in'] == 3) {
				
				
				//Load template file into vhost cofig to save
				$line = "";
				$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "# THIS DOMAIN HAS BEEN PARKED" . fs_filehandler::NewLine();
    			//$line .= $str . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_parked.tpl") . fs_filehandler::NewLine();
				
				
				//SSL engine settings
				//$line .= "# SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				//$line .= $rowvhost['vh_ssl_tx'] . fs_filehandler::NewLine();
				//$line .= "# END SSL Engine settings (if any exist)" . fs_filehandler::NewLine();
				// END SSL engine settings
				
                //$line .= "</virtualhost>" . fs_filehandler::NewLine();
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
				$line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'], $vhostPort, $useremail);
                }
                $line .= fs_filehandler::NewLine();
				
				//*********Write to file
				writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********
/*				
                /*
                 * ##################################################
                 * #
                 * # SSL Regular or Sub domain
                 * #
                 * ##################################################
                 */
/*
				//checo
                //Domain is a regular domain or a subdomain.
            } else {
                $RootDir = '"' . ctrl_options::GetSystemOption('hosted_dir') . $vhostuser['username'] . '/public_html' . $rowvhost['vh_directory_vc'] . '"';
				
				
				// Temp
                if ( !is_dir( ctrl_options::GetSystemOption('hosted_dir') . $vhostuser[ 'username' ] . "/tmp" ) ) {
                    fs_director::CreateDirectory( ctrl_options::GetSystemOption( 'hosted_dir' ) . $vhostuser[ 'username' ] . "/tmp" );
                }
				
				// Logs
                if (!is_dir(ctrl_options::GetSystemOption('log_dir_domain') . "domains/" . $vhostuser['username'] . "/")) {
                    fs_director::CreateDirectory(ctrl_options::GetSystemOption('log_dir_domain') . "domains/" . $vhostuser['username'] . "/");
					//fs_director::SetFileSystemPermissions(ctrl_options::GetSystemOption('log_dir_domain') . "domains/" . $vhostuser['username'], 0750);
                }
				
				//Load template file into vhost cofig to save
				$line = "";
    			//$line .= $str . fs_filehandler::NewLine();
				$line .= $smarty->fetch("vhost_domain_ssl.tpl") . fs_filehandler::NewLine();
			

                // End Virtual Host Settings
                //$line .= "</virtualhost>" . fs_filehandler::NewLine();
                $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
                $line .= "################################################################" . fs_filehandler::NewLine();
				
                $line .= fs_filehandler::NewLine();
                if ($rowvhost['vh_portforward_in'] <> 0) {
                    $line .= BuildVhostPortForward($rowvhost['vh_name_vc'],$rowvhost['vh_ssl_tx'], $vhostPort, $useremail);
                }
                $line .= fs_filehandler::NewLine();
				
				//*********Write to file
				writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
				//***********
            }
*/
            /*
             * ##################################################
             * #
             * # SSL Disabled domain
             * #
             * ##################################################
             */
 /*       } else {
            //Domain is NOT enabled
			
			//Load template file into vhost cofig to save
			$line = "";
			$line .= "# DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
            $line .= "# THIS DOMAIN HAS BEEN DISABLED" . fs_filehandler::NewLine();
    		//$line .= $str . fs_filehandler::NewLine();
			$line .= $smarty->fetch("vhost_disabled.tpl") . fs_filehandler::NewLine();
				
            //$line .= "</virtualhost>" . fs_filehandler::NewLine();
            $line .= "# END DOMAIN: " . $rowvhost['vh_name_vc'] . fs_filehandler::NewLine();
            $line .= "################################################################" . fs_filehandler::NewLine();
			
			//*********Write to file
			writetofile($vh_path . $rowvhost['vh_name_vc']. ".conf"  , $line);
			//***********
			
        }
    }
*/
    /*
     * ##############################################################################################################
     * #
     * # Write SSL vhost file to disk
     * #
     * ##############################################################################################################
     */
/*
 // write the sslvhost config file
    $vhsslconfigfile = ctrl_options::GetSystemOption('apache_ssl_vhost');
	
	//Backup old vhost file in folder incase apache config fails we can roll back
	//$backupsslfile = "/mnt/nfs/www/configs/apache/httpd-vhosts-ssl.bak.conf";

	//if (!copy($vhsslconfigfile, $backupsslfile)) {
   	 	//echo "failed to backup Apache SSL Vhost file" . fs_filehandler::NewLine();
	//}
	
	//start write
    if (fs_filehandler::UpdateFile($vhsslconfigfile, 0777, $line)) {
        // Reset Apache settings to reflect that config file has been written, until the next change.
        $time = time();
        $vsql = $zdbh->prepare("UPDATE x_settings
                                    SET so_value_tx=:time
                                    WHERE so_name_vc='apache_changed'");
        $vsql->bindParam(':time', $time);
        $vsql->execute();
        echo "Finished writing Apache SSL Config... Now reloading Apache..." . fs_filehandler::NewLine();
        $returnValue = 0;
        if (sys_versions::ShowOSPlatformVersion() == "Windows") {
            system("" . ctrl_options::GetSystemOption('httpd_exe') . " " . ctrl_options::GetSystemOption('apache_restart') . "", $returnValue);
        } else {
            $command = ctrl_options::GetSystemOption('zsudo');
            $args = array(
                "service",
                ctrl_options::GetSystemOption('apache_sn'),
                ctrl_options::GetSystemOption('apache_restart')
            );
            $returnValue = ctrl_system::systemCommand($command, $args);
        }
        echo "Apache reload " . ((0 === $returnValue ) ? "succeeded" : "failed") . "." . fs_filehandler::NewLine();
    } else {
        return false;
    }

}
*/

function writetofile($panel, $line) {
//write the entire string
file_put_contents($panel , $line);
}


function CheckErrorDocument($error)
{
    $errordocs = array(100, 101, 102, 200, 201, 202, 203, 204, 205, 206, 207,
        300, 301, 302, 303, 304, 305, 306, 307, 400, 401, 402,
        403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413,
        414, 415, 416, 417, 418, 419, 420, 421, 422, 423, 424,
        425, 426, 500, 501, 502, 503, 504, 505, 506, 507, 508,
        509, 510);
    if (in_array($error, $errordocs)) {
        return true;
    } else {
        return false;
    }
}

function BackupVhostConfigFile()
{
    echo "Apache VHost backups are enabled... Backing up current vhost.conf to: " . ctrl_options::GetSystemOption('apache_budir') . fs_filehandler::NewLine();
    if (!is_dir(ctrl_options::GetSystemOption('apache_budir'))) {
        fs_director::CreateDirectory(ctrl_options::GetSystemOption('apache_budir'));
    }
    copy(ctrl_options::GetSystemOption('apache_vhost'), ctrl_options::GetSystemOption('apache_budir') . "VHOST_BACKUP_" . time());
	
    fs_director::SetFileSystemPermissions(ctrl_options::GetSystemOption('apache_budir') . ctrl_options::GetSystemOption('apache_vhost') . ".BU", 0777);
	
    if (ctrl_options::GetSystemOption('apache_purgebu') == strtolower("true")) {
        echo "Apache VHost purges are enabled... Purging backups older than: " . ctrl_options::GetSystemOption('apache_purge_date') . " days..." . fs_filehandler::NewLine();
        echo "[FILE][PURGE_DATE][FILE_DATE][ACTION]" . fs_filehandler::NewLine();
        $purge_date = ctrl_options::GetSystemOption('apache_purge_date');
        if ($handle = @opendir(ctrl_options::GetSystemOption('apache_budir'))) {
            while (false !== ($file = readdir($handle))) {
                if ($file != "." && $file != "..") {
                    $filetime = @filemtime(ctrl_options::GetSystemOption('apache_budir') . $file);

                    if ($filetime == NULL) {
                        $filetime = @filemtime(utf8_decode(ctrl_options::GetSystemOption('apache_budir') . $file));
                    }
                    $filetime = floor((time() - $filetime) / 86400);
                    echo $file . " - " . $purge_date . " - " . $filetime . "";
                    if ($purge_date < $filetime) {
                        //delete the file
                        echo " - Deleting file..." . fs_filehandler::NewLine();
                        unlink(ctrl_options::GetSystemOption('apache_budir') . $file);
                    } else {
                        echo " - Skipping file..." . fs_filehandler::NewLine();
                    }
                }
            }
        }
        echo "Purging old backups complete..." . fs_filehandler::NewLine();
    }
    echo "Apache backups complete..." . fs_filehandler::NewLine();
}


function TriggerApacheQuotaUsage()
{
    global $zdbh;
    global $controller;
    $sql = $zdbh->prepare("SELECT * FROM x_vhosts WHERE vh_deleted_ts IS NULL");
    $sql->execute();
    while ($rowvhost = $sql->fetch()) {
        if ($rowvhost['vh_enabled_in'] == 1 && ctrl_users::CheckUserEnabled($rowvhost['vh_acc_fk']) ||
            $rowvhost['vh_enabled_in'] == 1 && ctrl_options::GetSystemOption('apache_allow_disabled') == strtolower("true")) {

            //$checksize = $zdbh->query("SELECT * FROM x_bandwidth WHERE bd_month_in = " . date("Ym") . " AND bd_acc_fk = " . $rowvhost['vh_acc_fk'] . "")->fetch();

            $date = date("Ym");
            $findsize = $zdbh->prepare("SELECT * FROM x_bandwidth WHERE bd_month_in = :date AND bd_acc_fk = :acc");
            $findsize->bindParam(':date', $date);
            $findsize->bindParam(':acc', $rowvhost['vh_acc_fk']);
            $findsize->execute();
            $checksize = $findsize->fetch();

            $currentuser = ctrl_users::GetUserDetail($rowvhost['vh_acc_fk']);
            if ($checksize['bd_diskover_in'] != $checksize['bd_diskcheck_in'] && $checksize['bd_diskover_in'] == 1) {
                echo "Disk usage over quota, triggering Apache..." . fs_filehandler::NewLine();
                $updateapache = $zdbh->prepare("UPDATE x_settings SET so_value_tx = 'true' WHERE so_name_vc ='apache_changed'");
                $updateapache->execute();

                //$updateapache = $zdbh->query("UPDATE x_bandwidth SET bd_diskcheck_in = 1 WHERE bd_acc_fk =" . $rowvhost['vh_acc_fk'] . "");
                $updateapache2 = $zdbh->prepare("UPDATE x_bandwidth SET bd_diskcheck_in = 1 WHERE bd_acc_fk = :acc");
                $updateapache2->bindParam(':acc', $rowvhost['vh_acc_fk']);
                $updateapache2->execute();
            }
            if ($checksize['bd_diskover_in'] != $checksize['bd_diskcheck_in'] && $checksize['bd_diskover_in'] == 0) {
                echo "Disk usage under quota, triggering Apache..." . fs_filehandler::NewLine();
                $updateapache = $zdbh->prepare("UPDATE x_settings SET so_value_tx = 'true' WHERE so_name_vc ='apache_changed'");
                $updateapache->execute();

                //$updateapache = $zdbh->query("UPDATE x_bandwidth SET bd_diskcheck_in = 0 WHERE bd_acc_fk =" . $rowvhost['vh_acc_fk'] . "");
                $updateapache2 = $zdbh->prepare("UPDATE x_bandwidth SET bd_diskcheck_in = 0 WHERE bd_acc_fk = :acc");
                $updateapache2->bindParam(':acc', $rowvhost['vh_acc_fk']);
                $updateapache2->execute();
            }
            if ($checksize['bd_transover_in'] != $checksize['bd_transcheck_in'] && $checksize['bd_transover_in'] == 1) {
                echo "Bandwidth usage over quota, triggering Apache..." . fs_filehandler::NewLine();
                $updateapache = $zdbh->prepare("UPDATE x_settings SET so_value_tx = 'true' WHERE so_name_vc ='apache_changed'");
                $updateapache->execute();

                //$updateapache = $zdbh->query("UPDATE x_bandwidth SET bd_transcheck_in = 1 WHERE bd_acc_fk =" . $rowvhost['vh_acc_fk'] . "");
                $updateapache2 = $zdbh->prepare("UPDATE x_bandwidth SET bd_transcheck_in = 1 WHERE bd_acc_fk = :acc");
                $updateapache2->bindParam(':acc', $rowvhost['vh_acc_fk']);
                $updateapache2->execute();
            }
            if ($checksize['bd_transover_in'] != $checksize['bd_transcheck_in'] && $checksize['bd_transover_in'] == 0) {
                echo "Bandwidth usage under quota, triggering Apache..." . fs_filehandler::NewLine();
                $updateapache = $zdbh->prepare("UPDATE x_settings SET so_value_tx = 'true' WHERE so_name_vc ='apache_changed'");
                $updateapache->execute();

                //$updateapache = $zdbh->query("UPDATE x_bandwidth SET bd_transcheck_in = 0 WHERE bd_acc_fk =" . $rowvhost['vh_acc_fk'] . "");
                $updateapache2 = $zdbh->prepare("UPDATE x_bandwidth SET bd_transcheck_in = 0 WHERE bd_acc_fk = :acc");
                $updateapache2->bindParam(':acc', $rowvhost['vh_acc_fk']);
                $updateapache2->execute();
            }
        }
    }
}


?>

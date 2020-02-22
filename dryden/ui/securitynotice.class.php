<?php

/**
 * @copyright 2014-2015 Sentora Project (http://www.sentora.org/) 
 * Sentora is a GPL fork of the ZPanel Project whose original header follows:
 *
 * Generic template place holder class.
 * @package zpanelx
 * @subpackage dryden -> ui -> tpl
 * @version 1.1.0
 * @author Bobby Allen (ballen@bobbyallen.me)
 * @copyright ZPanel Project (http://www.zpanelcp.com/)
 * @link http://www.zpanelcp.com/
 * @license GPL (http://www.gnu.org/licenses/gpl.html)
 */
class ui_tpl_securitynotice {

    public static function Template() {

	// Work in progress for new security module

		if (!extension_loaded('suhosin')) {
		    return ui_sysmessage::shout(
            runtime_xss::xssClean("Suhosin is not enabled/installed. This allows for dangerous PHP functions to be used with NO PROTECTION."),
            'error',
            'Security Notice:',
            true
			);
    	
		}
		if (!extension_loaded('snuffleupagus')) {
			return ui_sysmessage::shout(
            runtime_xss::xssClean("Snuffleupagus is not enabled/installed. This allows for dangerous PHP functions to be used with NO PROTECTION."),
            'notice',
            'Security Notice:',
            true
			);
		}
	
	}

}

?>

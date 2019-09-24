USE `sentora_core`;

/* Update the sentora database version number */
UPDATE `x_settings` SET `so_value_tx` = 'true' WHERE `so_name_vc` = 'apache_changed';
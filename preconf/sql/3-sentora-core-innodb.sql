
USE `sentora_core`;

/* Convert Panel MYISAM tables to INNODB - TESTING if this works and doesnt break Sentora panel. MYISAM support ends in mysql 8.0 */

ALTER TABLE x_bandwidth ENGINE=InnoDB;

ALTER TABLE x_cronjobs ENGINE=InnoDB;

ALTER TABLE x_ftpaccounts ENGINE=InnoDB;

ALTER TABLE x_groups ENGINE=InnoDB;

ALTER TABLE x_htaccess ENGINE=InnoDB;

ALTER TABLE x_mysql_databases ENGINE=InnoDB;

ALTER TABLE x_mysql_dbmap ENGINE=InnoDB;

ALTER TABLE x_mysql_users ENGINE=InnoDB;

ALTER TABLE x_packages ENGINE=InnoDB;

ALTER TABLE x_permissions ENGINE=InnoDB;

ALTER TABLE x_quotas ENGINE=InnoDB;

ALTER TABLE x_vhosts ENGINE=InnoDB;
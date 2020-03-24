<?php
/*
 * Generated configuration file
 * Generated by: phpMyAdmin 4.8.5 setup script
 * Date: Sat, 02 Mar 2019 05:23:52 +0000
 */

/* Servers configuration */
$i = 0;

/* Server: localhost [1] */
$i++;
$cfg['Servers'][$i]['verbose'] = 'localhost';
$cfg['Servers'][$i]['socket'] = '/run/sockets/mariadb.sock';
$cfg['Servers'][$i]['auth_type'] = 'config';
$cfg['Servers'][$i]['user'] = 'root';
// $cfg['Servers'][$i]['password'] <-- auto
$cfg['Servers'][$i]['DisableIS'] = true;
$cfg['Servers'][$i]['pmadb'] = 'phpmyadmin';
$cfg['Servers'][$i]['controluser'] = 'phpmyadmin';
$cfg['Servers'][$i]['controlpass'] = 'phpmyadmin';
$cfg['Servers'][$i]['bookmarktable'] = 'pma__bookmark';
$cfg['Servers'][$i]['relation'] = 'pma__relation';
$cfg['Servers'][$i]['userconfig'] = 'pma__userconfig';
$cfg['Servers'][$i]['users'] = 'pma__users';
$cfg['Servers'][$i]['usergroups'] = 'pma__usergroups';
$cfg['Servers'][$i]['navigationhiding'] = 'pma__navigationhiding';
$cfg['Servers'][$i]['table_info'] = 'pma__table_info';
$cfg['Servers'][$i]['column_info'] = 'pma__column_info';
$cfg['Servers'][$i]['history'] = 'pma__history';
$cfg['Servers'][$i]['recent'] = 'pma__recent';
$cfg['Servers'][$i]['favorite'] = 'pma__favorite';
$cfg['Servers'][$i]['table_uiprefs'] = 'pma__table_uiprefs';
$cfg['Servers'][$i]['tracking'] = 'pma__tracking';
$cfg['Servers'][$i]['table_coords'] = 'pma__table_coords';
$cfg['Servers'][$i]['pdf_pages'] = 'pma__pdf_pages';
$cfg['Servers'][$i]['savedsearches'] = 'pma__savedsearches';
$cfg['Servers'][$i]['central_columns'] = 'pma__central_columns';
$cfg['Servers'][$i]['designer_settings'] = 'pma__designer_settings';
$cfg['Servers'][$i]['export_templates'] = 'pma__export_templates';
$cfg['Servers'][$i]['tracking_version_auto_create'] = true;

/* End of servers configuration */

$cfg['blowfish_secret'] = 'Op_e;W^aP1=9h?;#X0_g^,Cv?0=xBnqp';
$cfg['Export']['method'] = 'custom';
$cfg['Export']['quick_export_onserver'] = true;
$cfg['Export']['quick_export_onserver_overwrite'] = true;
$cfg['Export']['compression'] = 'gzip';
$cfg['Export']['charset'] = 'utf-8';
$cfg['Export']['onserver'] = true;
$cfg['Export']['onserver_overwrite'] = true;
$cfg['Export']['sql_dates'] = true;
$cfg['Export']['sql_relation'] = true;
$cfg['Export']['sql_mime'] = true;
$cfg['Export']['sql_create_database'] = true;
$cfg['Export']['sql_if_not_exists'] = true;
$cfg['Export']['sql_type'] = 'UPDATE';
$cfg['Export']['ods_columns'] = true;
$cfg['SendErrorReports'] = 'always';
$cfg['PmaNoRelation_DisableWarning'] = true;
$cfg['SuhosinDisableWarning'] = true;
$cfg['ReservedWordDisableWarning'] = true;
$cfg['Console']['DarkTheme'] = true;
$cfg['Console']['OrderBy'] = 'time';
$cfg['Console']['Order'] = 'desc';
$cfg['UploadDir'] = '/backup';
$cfg['SaveDir'] = '/backup';
$cfg['CheckConfigurationPermissions'] = false;
$cfg['AllowUserDropDatabase'] = true;
$cfg['AllowArbitraryServer'] = true;
$cfg['LoginCookieRecall'] = false;
$cfg['UserprefsDeveloperTab'] = true;
$cfg['DBG']['sql'] = true;
$cfg['OBGzip'] = 0;
$cfg['PersistentConnections'] = true;
// $cfg['ProxyUrl'] 
$cfg['Import']['charset'] = 'utf-8';
$cfg['ShowPhpInfo'] = true;
$cfg['ShowDbStructureCharset'] = true;
$cfg['ShowDbStructureComment'] = true;
$cfg['MaxRows'] = 250;
$cfg['RepeatCells'] = 50;
$cfg['TablePrimaryKeyOrder'] = 'DESC';
$cfg['DefaultTabTable'] = 'structure';
$cfg['NavigationTreeDisplayDbFilterMinimum'] = 5;
$cfg['NavigationTreeDefaultTabTable2'] = 'browse';
$cfg['NavigationTreeTableSeparator'] = '_';
$cfg['QueryHistoryMax'] = 100;
$cfg['RetainQueryBox'] = true;
$cfg['QueryHistoryDB'] = true;
$cfg['DefaultLang'] = 'zh_cn';
$cfg['ServerDefault'] = 1;
$cfg['DefaultConnectionCollation'] = 'utf8mb4_bin';

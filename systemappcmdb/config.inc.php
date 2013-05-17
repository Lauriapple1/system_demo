<?php
$cfg['ShowChgPassword'] = false;
$cfg['VersionCheck'] = false;
$cfg['OBGzip'] = 'auto';
$cfg['ShowServerInfo'] = false;
$cfg['ShowStats'] = false;
$cfg['ShowCreateDb'] = false;
$cfg['Error_Handler']['display'] = false;

/* vim: set expandtab sw=4 ts=4 sts=4: */
/**
 * phpMyAdmin sample configuration, you can use it as base for
 * manual configuration. For easier setup you can use setup/
 *
 * All directives are explained in Documentation.html and on phpMyAdmin
 * wiki <http://wiki.phpmyadmin.net>.
 *
 * @package PhpMyAdmin
 */

/*
 * Servers configuration
 */
$i = 0;

$services_json = json_decode(getenv("VCAP_SERVICES"),true);

$cfg['Servers'][1]['auth_type'] = 'appfog';
$cfg['bound_services'] = false;

foreach($services_json["mysql-5.1"] as $E) {
    $i++;

    $mysql_config = $E["credentials"];

    $cfg['Servers'][$i]['auth_type'] = 'appfog';
    /* Server parameters */
    $cfg['Servers'][$i]['host'] = $mysql_config["hostname"];
    $cfg['Servers'][$i]['verbose'] = $E["name"];
    $cfg['Servers'][$i]['connect_type'] = 'tcp';
    $cfg['Servers'][$i]['compress'] = false;
    /* Select mysql if your server does not have mysqli */
    $cfg['Servers'][$i]['extension'] = 'mysqli';
    $cfg['Servers'][$i]['AllowNoPassword'] = false;
    $cfg['Servers'][$i]['user'] = $mysql_config["username"];
    $cfg['Servers'][$i]['password'] = $mysql_config["password"];
    $cfg['Servers'][$i]['only_db'] = $mysql_config["name"];
    $cfg['Servers'][$i]['hide_db'] = 'information_schema';
    $cfg['Servers'][$i]['ShowDatabasesCommand'] = 'SELECT DISTINCT TABLE_SCHEMA FROM information_schema.SCHEMA_PRIVILEGES';

    $cfg['bound_services'] = true;


    $cfg['Servers'][$i]['controluser'] = $mysql_config["username"];
    $cfg['Servers'][$i]['controlpass'] = $mysql_config["password"];

    /* $cfg['Servers'][$i]['pmadb'] = 'd028d0fa291424631b7443b1adc250fa2'; */
    $cfg['Servers'][$i]['bookmarktable'] = 'pma_bookmark';
    $cfg['Servers'][$i]['relation'] = 'pma_relation';
    $cfg['Servers'][$i]['table_info'] = 'pma_table_info';
    $cfg['Servers'][$i]['table_coords'] = 'pma_table_coords';
    $cfg['Servers'][$i]['pdf_pages'] = 'pma_pdf_pages';
    $cfg['Servers'][$i]['column_info'] = 'pma_column_info';
    $cfg['Servers'][$i]['history'] = 'pma_history';
    $cfg['Servers'][$i]['table_uiprefs'] = 'pma_table_uiprefs';
    $cfg['Servers'][$i]['tracking'] = 'pma_tracking';
    $cfg['Servers'][$i]['designer_coords'] = 'pma_designer_coords';
    $cfg['Servers'][$i]['userconfig'] = 'pma_userconfig';
    $cfg['Servers'][$i]['recent'] = 'pma_recent';
}
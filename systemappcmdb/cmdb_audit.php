<?php
$services_json = json_decode(getenv("VCAP_SERVICES"), true);
$mysql_config = $services_json["mysql-5.1"][0]["credentials"];

$username = $mysql_config["username"];
$password = $mysql_config["password"];
$hostname = $mysql_config["hostname"];
$port = $mysql_config["port"];
$db = $mysql_config["name"];

$link = mysql_connect("$hostname:$port", $username, $password);
$db_selected = mysql_select_db($db, $link);

$rs = mysql_query("SELECT H.*, M.datacenter_id, M.title AS machine_title, M.cpu_load AS machine_cpu_load, M.ram_total AS machine_ram_total, M.disk_total AS machine_disk_total, M.disk_load AS machine_disk_load FROM cmdb_machine M, cmdb_host H WHERE M.id = H.machine_id");

function mysql2json($mysql_result) {
     $json="[\n";
     $field_names = array();
     $fields = mysql_num_fields($mysql_result);
     
     for ($x = 0; $x < $fields; $x++) {
          $field_name = mysql_fetch_field($mysql_result, $x);
          if ($field_name) {
               $field_names[$x] = $field_name->name;
          }
     }
     
     $rows = mysql_num_rows($mysql_result);
     
     for ($x = 0; $x < $rows; $x++) {
          $row = mysql_fetch_array($mysql_result);
          $json .= "{\n";
          for($y = 0; $y < count($field_names); $y++) {
               $json .= "\"$field_names[$y]\" :	\"$row[$y]\"";
               if ($y == count($field_names) - 1) {
                    $json .= "\n";
               }
               else{
                    $json .= ",\n";
               }
          }
          if ($x==$rows-1) {
               $json .= "\n}\n";
          }
          else{
               $json .= "\n},\n";
          }
     }
     
     $json .= "]";
     
     return($json);
}

mysql_close($link);

echo mysql2json($rs);
?>
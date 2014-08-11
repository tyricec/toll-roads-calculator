<?php
// set the level of error reporting
error_reporting(E_ALL & ~E_NOTICE);
session_start();
  
require('configure.php');
require(_DIR_CLASSES.'class.database.php');
require(_DIR_CLASSES.'class.manage.php');
require(_DIR_CLASSES.'class.paginate.php');
require(_DIR_CLASSES.'class.forms.php');
require(_DIR_CLASSES.'class.links.php');

// redirect user if not logged in
  //function curPageName() {
  //return substr($_SERVER["SCRIPT_NAME"],strrpos($_SERVER["SCRIPT_NAME"],"/")+1);
  //}
  //$pageName = curPageName();
  //$rootLevel = $_SERVER['SERVER_NAME'].'/';
  //$currentDir = getcwd().'/';
  //if($currentDir.$pageName != $_SERVER['DOCUMENT_ROOT'].'/index.php')
  //{
  //ob_start();

  //if(!isset($_SESSION['flag']))
  //header('location: http://systemresolutions.com/admin');
  //}
function myTruncate($string, $limit, $break=".", $pad="...") { 
if(strlen($string) <= $limit) return $string; 
if(false !== ($breakpoint = strpos($string, $break, $limit))) { 
if($breakpoint < strlen($string) - 1) { 
$string = substr($string, 0, $breakpoint) . $pad; } 
} 
return $string; }
//initiate objects
$db = new db_class();
$db->connect();
$manage = new manage($db);
$links = new links($db,$manage);

//define round robin settings
$query = $manage->select('settings',false,false,1);
$settings = $db->get_row($query,'MYSQL_ASSOC');
define('_LINK_RATIO',$settings['settings_batch']);
define('_TOP_LINK_RATIO',$settings['settings_top']);
define('_NON_CLICK_ACTION',$settings['settings_nonclick']);
?>

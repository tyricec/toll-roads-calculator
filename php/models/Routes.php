<?php

/*
 *		Company			:			Civic Resource Group (CRG)
 *		Project			:			Toll Roads (Toll Road Rate Calculator)
 * 		Date 			:			08/11/2014
 * 		File	 		: 			Routes.php
 * 		Purpose			:			Model class relates to the database table routes in the calculator database
 * 		Input			:			NA
 * 		Output			:			NA 
 */

require_once './helpers/db.class.php';

class routes {
	
	public function getRoutes() {
		$_db = Db::init();
	  $sth = $_db->prepare('SELECT route_id, route_name, route_lat, route_long, route_type, route_point_type, route_fwy FROM routes');
		$sth->execute();
		$result = $sth->fetchAll();
		return json_encode($result);
	}
	
	public static function getRouteById($ID) {
		$_db = Db::init();
		$ID= intval($ID);
		$data = array('ID' => $ID);
	  $sth = $_db->prepare('SELECT `route_id`, `route_name`, `route_lat`, `route_long`, `route_type`, `route_fwy` FROM `routes` WHERE `route_id` = :ID');
		$sth->execute($data);
		$result = $sth->fetch();
		return $result;
	}
	
	public function getRouteByName($name) {
		$_db = Db::init();
		$data = array('Name' => $name);
		$sth = $_db->prepare('SELECT `route_id`, `route_name`, `route_lat`, `route_long`, `route_type`, `route_fwy` FROM `routes` WHERE `route_name` = :Name');
		$sth->execute($data);
		$result = $sth->fetch();
		return json_encode($result);
	}
	
}

?>
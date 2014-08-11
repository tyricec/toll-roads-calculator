<?php

/*
 *		Company			:			Civic Resource  Group (CRG)
 *		Project			:			BSMS (Bus System Management System)
 * 		Date 			:			03/24/2014
 * 		File	 		: 			CheckUserAvailability.php
 * 		Purpose			:			Checks the availability of the username
 * 		Input			:			userName
 * 		Output			:			True or False
 */

require_once './models/Routes.php';

$method = $_REQUEST['method'];

$routes = new routes();

switch($method) {
	
	case 'getRoutes':
		$result = $routes->getRoutes();
	break;
	
	case 'getRouteById':
		$id = intval($_REQUEST['route_id']);
		$result = $routes->getRouteById($id);
	break;
	
	case 'getRouteByName':
		$name = $_REQUEST['route_name'];
		$result = $routes->getRouteByName($name);
	break;
	
}

print_r($result);

?>
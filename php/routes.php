<?php

/*
 *		Company			:			Civic Resource Group (CRG)
 *		Project			:			Toll Roads (Toll Road Rate Calculator)
 * 		Date 			:			08/11/2014
 * 		File	 		: 			routes.php
 * 		Purpose			:			controller that relates to routes model methods
 * 		Input			:			NA
 * 		Output			:			NA 
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
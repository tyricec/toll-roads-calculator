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

require_once './application.php';

$params = $_REQUEST;

$routes = new routes();

switch($params['method']) {
	
	case 'getRoutes':
		$result = $routes->getRoutes();
	break;
	
	case 'getRouteById':
		$id = intval($params['route_id']);
		$result = $routes->getRouteById($id);
	break;
	
	case 'getRouteByName':
		$name = $params['route_name'];
		$result = $routes->getRouteByName($name);
	break;
	
}

print_r($result);

?>
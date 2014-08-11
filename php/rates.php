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

//$userName = $_REQUEST['userName'];

$routes = new routes();
//$route_array = $routes->getRoutes();
//$route_id = $routes->getRouteById(3);
$route_name = $routes->getRouteByName('JAMBOREE ROAD (Irvine)');
print_r($route_name);

?>
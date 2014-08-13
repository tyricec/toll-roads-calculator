<?php

/*
 *		Company			:			Civic Resource Group (CRG)
 *		Project			:			Toll Roads (Toll Road Rate Calculator)
 * 		Date 			:			08/11/2014
 * 		File	 		: 			rates.php
 * 		Purpose			:			controller that relates to rates model methods
 * 		Input			:			NA
 * 		Output			:			NA 
 */

require_once './application.php';

$params = $_REQUEST;

$rates = new rates();

switch($params['method']) {
	
	case 'getRate':
	
		$entry_id = intval($params['entry']);
		$exit_id = intval($params['exit']);
		
		$result['start'] = routes::getRouteById($entry_id);
		$result['start'] = 'CA-'.$result['start']['route_fwy'].' - '.$result['start']['route_name'];
		$result['end'] = routes::getRouteById($exit_id);
		$result['end'] = 'CA-'.$result['end']['route_fwy'].' - '.$result['end']['route_name'];
		
		switch($params['type']) {
			
			case 'fasttrak':
			$result['payment'] = 'FastTrak';
			break;
			
			case 'express':
			$result['payment'] = 'ExpressAccount';
			break;
			
			case 'onetime':
			$result['payment'] = 'One-Time-Toll';
			break;
			
		}
		
		switch($params['axles']) {
			
			case '2':
			$result['axles'] = '2 Axle Vehicles and Motorcycles';
			break;
			
			case '3':
			$result['axles'] = '3-4 Axle Vehicles';
			break;
			
			case '5':
			$result['axles'] = '5+ Axle Vehicles';
			break;
			
		}
	
		$result['rates'] = $rates->getRate($entry_id,$exit_id,intval($params['axles']),$params['type']);

	break;
}

print_r($result);

?>
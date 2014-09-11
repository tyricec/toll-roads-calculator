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
	
	case 'getRates':
	
		//set start values
		$result['startid'] = intval($params['start']);
		$result['start'] = routes::getRouteById($result['startid']);
		$result['start'] = 'CA'.$result['start']['route_fwy'].' - '.$result['start']['route_name'];
		
		//set end values
		$result['endid'] = intval($params['end']);
		$result['end'] = routes::getRouteById($result['endid']);
		$result['end'] = 'CA'.$result['end']['route_fwy'].' - '.$result['end']['route_name'];
		
		//clean axles value
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
		
		//clean type value
		switch($params['type']) {
			
			case 'fastrak':
			$result['payment'] = 'FastTrak';
			$compare_type = 'onetime';
			break;
			
			case 'express':
			$result['payment'] = 'ExpressAccount';
			$compare_type = 'fastrak';
			break;
			
			case 'onetime':
			$result['payment'] = 'One-Time-Toll';
			$compare_type = 'fastrak';
			break;
			
		}
		
		//request rates for selected type
		$result['rates'] = $rates->getRates($result['startid'],$result['endid'],intval($params['axles']),$params['type']);
		
		//request price adjustments if relevant
		if($params['type'] != 'onetime'):
			if(strlen($result['rates']['rate_extra'])):
				$result['rates'] = $rates->getAdjustments($result['rates']);
			endif;
		endif;
		
		//clean rates output
		$result['rates'] = $rates->getOutput($result['rates']);
		
		//request fastrak savings
		$result['savings'] = $rates->getRates($result['startid'],$result['endid'],intval($params['axles']),$compare_type);

		//calculate savings
		$result['savings'] = $rates->getSavings(
			array(
			$result['rates']['off_peak'],
			$result['savings']['off_peak']
			)
		);
		
	break;

}

echo json_encode($result);

?>
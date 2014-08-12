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

require_once './models/Rates.php';

$method = $_REQUEST['method'];

$rates = new rates();

switch($method) {
	
	case 'getRate':
	$entry = intval($_REQUEST['entry']);
	$exit = intval($_REQUEST['exit']);
	$axles = intval($_REQUEST['axles']);
	$type = $_REQUEST['type'];
	$result = $rates->getRate($entry,$exit,$axles,$type);
	break;
}

print_r($result);

?>
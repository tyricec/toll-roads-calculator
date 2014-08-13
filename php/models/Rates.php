<?php

/*
 *		Company			:			Civic Resource Group (CRG)
 *		Project			:			Toll Roads (Toll Road Rate Calculator)
 * 		Date 			:			08/11/2014
 * 		File	 		: 			Routes.php
 * 		Purpose			:			Model class relates to the database table rates in the calculator database
 * 		Input			:			NA
 * 		Output			:			NA 
 */

require_once './helpers/db.class.php';

class rates {
	
	public function getRate($entryID,$exitID,$axles,$type) {
		$_db = Db::init();
		$data = array('entry' => intval($entryID), 'exit' => intval($exitID), 'axles' => intval($axles));
	    $sth = $_db->prepare('SELECT `rate_'.$type.'` AS `off_peak`, `rate_extra` FROM `rates` WHERE `rate_entry` = :entry AND `rate_exit` = :exit AND `rate_axles` = :axles LIMIT 1');
        $sth->execute($data);
        $result = $sth->fetch();
		if(strlen($result['rate_extra'])):
			$result = $this->adjustRate($result);
		endif;
		return $this->buildDisplay($result);
	}
	
	public function adjustRate($result) {
		$_db = Db::init();
		$new_result = $result;
		$adjustments = explode(',',$new_result['rate_extra']);
		foreach($adjustments as $adjustment) {
			$data = array('adjust_id' => intval($adjustment));
			$sth = $_db->prepare('SELECT `adjust_description`, `adjust_variable` FROM `adjustments` WHERE `adjust_id` = :adjust_id LIMIT 1');
			$sth->execute($data);
        	$result = $sth->fetch();
			$new_result['peak'][] = $result;
		}
		return $new_result;
	}
	
	public function buildDisplay($result) {
		$new_result['off_peak'] = '$'.$result['off_peak'];
		$i = 0;
		foreach($result['peak'] as $peak) {
			$new_result['peak'][$i]['rate'] = '$'.($result['off_peak'] + $peak['adjust_variable']);
			$new_result['peak'][$i]['description'] = $peak['adjust_description'];
			$i++;
		}
		return $new_result;
	}
}

?>
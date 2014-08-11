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
	    $sth = $_db->prepare('SELECT `'.$type.'`, `extra` FROM `rates` WHERE `rate_entry` = :entry AND `rate_exit` = :exit AND `axles` = :axles LIMIT 1');
        $sth->execute($data);
        $result = $sth->fetch();
		return $result;
	}
}

?>
<?php
 /*
 *		Company			:			Civic Resource  Group (CRG)
 *		Project			:			Toll Roads (Toll Roads Rate Calculator)
 * 		Date 			:			08/11/2014
 * 		File	 		: 			DBHelper.php
 * 		Purpose			:			Managing database transaction of the application
 * 		Input			:			NA	
 * 		Output			:			NA
 */

require_once './config.php';

class Db
{
    private static $db;
     
    public static function init()
    {
        if (!self::$db)
        {
            try {
                $dsn = 'mysql:host='.DB_HOST.';dbname='.DB_NAME.';charset=UTF8';
                self::$db = new PDO($dsn, DB_USER, DB_PASS);
                self::$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                self::$db->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
            } catch (PDOException $e) {
                die('Connection error: ' . $e->getMessage());
            }
        }
        return self::$db;
    }
}
?>
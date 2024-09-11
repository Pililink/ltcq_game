<?php

/**
 * 系统设置
 */
$sysConfig = array(
    'listenPort'=>'2350',
    'count' => 1,
);

$mysqlConfig = array(
    'host' => '127.0.0.1',
    'port' => 3306,
    'username' => 'root',
    'password' => '123456',
	'center' => 'center',
    'charset' => 'utf8',
	'game' => 'actor_s1'
);

$whitelist = array('172.20.128.1',);

$maintain = array(
    //array('begin' => 277, 'end'=> 289),
  // array('begin' => 10205, 'end'=> 10218),

);

$serverlist = array(
	array(
		'srvname' =>urlencode('唯我独尊'),
		'ip' => '172.20.128.1',
		'port' => '9001',
		'index' => 1,
		'status' => 0,
		'url' => 'http://172.20.128.1:81/web/s10001/Login.php/',
		'ID' => 1,
		'pf' => 'test',
		'opentime' => '2019-01-18 9:50:00',
	),	
);

?>

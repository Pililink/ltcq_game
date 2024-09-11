<?php

	require_once __DIR__ ."/config.php";

	$server = $_GET['server'];
	$account = $_GET['account'];
	$pid= $_GET['pid'];
	$sign = $_GET['sign'];
	if (!isset($server) or $server == 0) die("1");
	if (!isset($account) or $account == "") die("2");
	if (!isset($pid)) die("3");
	if (!isset($sign) or $sign == "") die("4");
	global $md5Key;
	$sign_check = md5("$account"."$pid"."$server"."$md5Key");
	if ($sign_check != $sign) {
		die("5");
	}

	global $mysqlConfig;
	$con_game = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
	if (!isset($con_game)) {
		die("6");
	}
	$con_game->query("set names utf8");
	$sql = "select * from actors where accountname = '$account' and serverindex='$server'";
	// echo $sql;die;

	$result = $con_game->query($sql);
	if (!$result) {
		$con_game->close();
		die("7");
	}
	$row = $result->fetch_assoc();

	if ($row) {
		//强制类型转换
		foreach ($row as $key => &$value) {
			$value = iconv("gbk", "utf-8//ignore", $value);
		}
		echo json_encode($row);
		$result->free_result();
	}
	
?>

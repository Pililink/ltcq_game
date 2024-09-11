<?php

	require_once __DIR__ ."/config.php";

	$server = $_GET['server'];
	$account = $_GET['account'];
	$amount = $_GET['amount'];
	$actorid = $_GET['actorid'];
	$sign = $_GET['sign'];
	if (!isset($server) or $server == 0) die("0");
	if (!isset($account) or $account == "") die("0");
	if (!isset($amount) or $amount == 0) die("0");
	if (!isset($sign) or $sign == "") die("0");
	global $md5Key;
	$sign_check = md5("$account"."$actorid"."$server"."$amount"."$md5Key");
	if ($sign_check != $sign) {
		die("0");
	}

	global $mysqlConfig;
	$con_game = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
	if (!isset($con_game)) {
		die("0");
	}
	$con_game->query("set names utf8");
	if ($actorid == 0) {
		$sql = "select actorid from actors where accountname = '$account'";
		$result = $con_game->query($sql);
		if (!$result) {
			$con_game->close();
			die("0");
		}
		$row = $result->fetch_row();
		if ($row) {
			$actorid = $row[0];
			$result->free_result();
		}
	}
	$sql = "insert into feecallback(serverid,openid,itemid,actor_id) values ('$server','$account','$amount','$actorid')";
	$result = $con_game->query($sql);
	if (!$result) {
		$con_game->close();
		die("0");
	}
	echo 1;
	
?>

<?php

	require_once __DIR__ ."/config.php";

	$account = $_GET['account'];
	$amount = $_GET['amount'];
	$sign = $_GET['sign'];
	if (!isset($account) or $account == "") die("0");
	if (!isset($amount) or $amount == 0) die("0");
	if (!isset($sign) or $sign == "") die("0");
	global $md5Key;
	$sign_check = md5("$account"."$amount"."$md5Key");
	if ($sign_check != $sign) {
		die("0");
	}

	global $mysqlConfig;
	$con_game = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
	if (!isset($con_game)) {
		die("0");
	}
	$con_game->query("set names utf8");
	$sql = "select actorid,serverindex from actors where accountname = '$account'";
	$result = $con_game->query($sql);
	if (!$result) {
		$con_game->close();
		die("0");
	}
	
	$n = 0;
	while ($row = $result->fetch_row()) {
		$actorid = $row[0];
		$server = $row[1];
		$sql = "insert into feecallback(serverid,openid,itemid,actor_id) values ('$server','$account','$amount','$actorid')";
		$con_game->query($sql);
		++$n;
	}
	$result->free_result();
	$con_game->close();
	echo $n;
	
?>

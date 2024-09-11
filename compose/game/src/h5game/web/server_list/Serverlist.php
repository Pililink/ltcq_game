<?php
header('Access-Control-Allow-Origin: *');
require_once __DIR__ ."/config.php";

class ServerList {
	public static function onGetList($data, $ip, &$res) {
		$account = $data['account'];
		if (!isset($account)) {
			return 100;
		}

        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['center']);
        if (!isset($con)) {
            return 100;
        }
        $con->query("set names utf8");
		
        $sqlFind = "select srvid from serverlist where account = '$account' order by updatetime desc limit 10";

        $result = $con->query($sqlFind);
        if (!$result) {
            $con->close();
            return 100;
        }

        while ($row = $result->fetch_row()) {
            $res['login'][] = $row[0];
        }
        $result->free_result();

        global $serverlist;
		$now = time();
		foreach($serverlist as $s) {
			$opentime = $s['opentime'];
			$opentime_t = strtotime($opentime);
			if ($opentime_t <= $now) {
				$status = $s['status'];
				if ($now - $opentime_t > 86400 && $status == 0) {
					$s['status'] = 1;
				}
				global $maintain;
				foreach($maintain as $mt) {
					if ($s['index'] >= $mt['begin'] && $s['index'] <= $mt['end']) {
						$s['status'] = 2;
					}
				}
				
				$res['serverlist'][] = $s;
			}
			else {
				global $whitelist;
				if (in_array($ip, $whitelist)) {
					$res['serverlist'][] = $s;
				}
			}
		} 
		$res['serverlist'] = $serverlist;
        $con->close();
        return 0;
	}

    public static function onSaveList($data) {
        $account = $data['account'];
        if (!isset($account)) {
            return 100;
        }
        $srvid = $data['srvid'];
        if (!isset($srvid)) {
            return 101;
        }

        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['center']);
        if (!isset($con)) {
            return 102;
        }
        $con->query("set names utf8");

		$sqlFind = "select idx from serverlist where account = '$account' and srvid = '$srvid'";
		$result = $con->query($sqlFind);
        if (!$result) {
            $con->close();
            return 103;
        }
		$row = $result->fetch_row();
		if ($row) {
			$d = date("Y-m-d H:i:s", time());
			$sqlUpdate = "update serverlist set updatetime = '$d' where idx = $row[0]";
			$result1 = $con->query($sqlUpdate);
			if (!$result1) {
				$con->query($sqlUpdate);
				$con->close();
				return 104;
			}
			$result->free_result();
		}
		else {
			$sqlInsert = "insert into serverlist(account, srvid, updatetime) values ('$account', '$srvid', now())";
			$result2 = $con->query($sqlInsert);
			if (!$result2) {
				$con->query($sqlInsert);
				$con->close();
				return 105;
			}
		}
        $con->close();
        return 0;
    }
}

$req = $_POST ? $_POST : $_GET;

if (!is_array($req)) {
	echo 201;
}
$save = 0;
if (array_key_exists('srvid', $req)) {
	$save = 1;
}
if ($save == 1) {
	$code = ServerList::onSaveList($req);
	echo $code;
}
else {
	$res = array();
	$ip = $_SERVER['REMOTE_ADDR'];
	$code = Serverlist::onGetList($req, $ip, $res);
	if ($code == 0) {
		$res = urldecode(json_encode($res));
		echo $res;
	}
	else {
		echo $code;
	}
}


?>

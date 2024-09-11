<?php
header('Access-Control-Allow-Origin: *');
require_once __DIR__ ."/config.php";

global $mysqlConfig;
class Login {
	public static function onLogin($data) {
		if (!array_key_exists('account', $data)) {
			return 0;
		}
		$account = $data['account'];
		if (!isset($account)) {
			return 100;
		}
		$getPwd = 0;
		if (array_key_exists('pwd', $data)) {
			$getPwd = 1;
		}
		
        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
        if (!isset($con)) {
            return 100;
        }
        $con->query("set names utf8");
		
        $sqlFind = "select account, passwd from globaluser where account = '$account'";

        $result = $con->query($sqlFind);
        if (!$result) {
            $con->close();
            return 100;
        }
        $row = $result->fetch_row();
        if ($getPwd == 0) {
            if (!$row) {
                $passwd = $data['passwd'];
                if (!isset($passwd)) {
                    return 100;
                }
                $sqlCreate = "insert into globaluser(account, passwd, identity, gmlevel) values ('$account', 'e10adc3949ba59abbe56e057f20f883e', '430481198112113256', 0)";
                $result2 = $con->query($sqlCreate);
                if (!$result2) {
                    $con->close();
                    return 100;
                }
            }
            $result->free_result();
            $con->close();
            return 0;
        }
        else{
            if (!$row) {
                return 100;
            }
            $result->free_result();
            $con->close();
            return "$row[1]";
        }
	}
}

$req = $_POST ? $_POST : $_GET;
$res = Login::onLogin($req);
echo $res;
?>
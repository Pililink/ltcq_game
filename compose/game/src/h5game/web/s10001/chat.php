<?php
header('Access-Control-Allow-Origin: *');
require_once __DIR__ ."/config.php";

global $mysqlConfig;
class Chat {
	public static function getChatList($data, &$res) {
		
		// 获取聊天类型（0全部，1世界，2公会，3私聊）
		if (!array_key_exists('type', $data)) {
			return -1;
		}
		$type = $data['type'];
		
		// 连接数据库
        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
        if (!isset($con)) {
            return 101;
        }
        $con->query("set names utf8");
		
		// 查询
        $sqlFind = "select * from chatmonitoring where type = '$type' order by id desc limit 2000";
		if($type == 0){
			$sqlFind = "select * from chatmonitoring order by id desc limit 2000";
		}
        $result = $con->query($sqlFind);
        if (!$result) {
            $con->close();
            return 102;
        }

		// 放入res
        while ($row = $result->fetch_assoc()) {
			$res[] = $row;
		}
		$con->close();
	}
	
	public static function Clean($data) {
		
		// 获取清理类型（0全清，1世界，2公会，3私聊）
		if (!array_key_exists('clean', $data)) {
			return -1;
		}
		$clean = $data['clean'];
		
		// 连接数据库
		global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
        if (!isset($con)) {
            return -3;
        }
        $con->query("set names utf8");
		
		// 清理数据
		$sqldel= "delete from chatmonitoring where type = '$clean'";
		if($clean == 0){
			$sqldel= "truncate table chatmonitoring;";
		}
		$result = $con->query($sqldel);
		if (!$result) {
            $con->close();
            return -5;
        }
		$con->close();
		
		return 0;
	}
	
	public static function Del($data) {
		
		// 获取索引
		if (!array_key_exists('id', $data)) {
			return -1;
		}
		$id = $data['id'];
		if (!isset($id)) {
			return -2;
		}
		$server = $data['server'];
		
		// 连接数据库
        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
        if (!isset($con)) {
            return -3;
        }
        $con->query("set names utf8");
		
		// 删除监控中的数据
		if ($type == 2) {
			$sqlDel = "delete from chatmonitoring where guildid = $guildid";
			$con->query($sqlDel);
			
			$sqlDel = "delete from guildchat where guildid = $guildid";
			$con->query($sqlDel);
		}
		else {
			$sqlDel = "delete from chatmonitoring where id = $id";
			$con->query($sqlDel);
		}
		
		// 保留2000条
		$sqlFind1= "SELECT id FROM chatmonitoring ORDER BY id desc LIMIT 2000,1";
		$result = $con->query($sqlFind1);
        if (!$result) {
            $con->close();
            return 0;
        }
		$row = $result->fetch_row();
		$newId = $row[0];
		$sqldel = "delete from chatmonitoring where id < $newId";
		$result = $con->query($sqldel);
		$con->close();
		return 0;
	}
	
/*	public static function Del($data) {
		
		// 获取索引
		if (!array_key_exists('id', $data)) {
			return -1;
		}
		$id = $data['id'];
		if (!isset($id)) {
			return -2;
		}
		$server = $data['server'];
		
		// 连接数据库
        global $mysqlConfig;
        $con = new \mysqli($mysqlConfig['host'], $mysqlConfig['username'], $mysqlConfig['password'], $mysqlConfig['game']);
        if (!isset($con)) {
            return -3;
        }
        $con->query("set names utf8");
		
		// 通知服务器代码中删除世界留言或工会留言
        $sqlFind = "select id, actorid, type, msgid, guildid, actorname, account, msg from chatmonitoring where id = $id";
        $result = $con->query($sqlFind);
        if (!$result) {
            $con->close();
            return -4;
        }
		$row = $result->fetch_row();
		$type = $row[2];
		$msgid = $row[3];
		$guildid = $row[4];
		
		if ($type == 1) {
			$sqlCmd = "insert into gmcmd(serverid, cmd, param1, param2) values($server, 'chatMonitoring', '$type', '$msgid')";
		}
		if ($type == 2) {
			$sqlCmd = "insert into gmcmd(serverid, cmd, param1, param2) values($server, 'chatMonitoring', '$type', '$guildid')";
		}
		$result = $con->query($sqlCmd);
		if (!$result) {
            $con->close();
            return -5;
        }
		
		// 删除监控中的数据
		if ($type == 1) {
			$sqlDel = "delete from chatmonitoring where id = $id";
			$con->query($sqlDel);
		}
		else if ($type == 2) {
			$sqlDel = "delete from chatmonitoring where guildid = $guildid";
			$con->query($sqlDel);
			
			$sqlDel = "delete from guildchat where guildid = $guildid";
			$con->query($sqlDel);
		}
		
		// 保留2000条
		$sqlFind1= "SELECT id FROM chatmonitoring ORDER BY id desc LIMIT 2000,1";
		$result = $con->query($sqlFind1);
        if (!$result) {
            $con->close();
            return 0;
        }
		$row = $result->fetch_row();
		$newId = $row[0];
		$sqldel = "delete from chatmonitoring where id < $newId";
		$result = $con->query($sqldel);
		$con->close();
		return 0;
	}
	*/
}

$req = $_GET ? $_GET : $_POST;

// delete
if (array_key_exists('id', $req)) {
	echo Chat::Del($req);
}
// clean
elseif (array_key_exists('clean', $req)) {
	echo Chat::Clean($req);
}
// get list
else if (array_key_exists('type', $req)) {
	$res = array();
	Chat::getChatList($req, $res);
	$res = urldecode(json_encode($res));
	echo $res;
}
// error
else{
	echo 199;
}

?>

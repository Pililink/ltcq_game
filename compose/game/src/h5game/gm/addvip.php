<meta charset="utf-8">
<?php 
error_reporting(0);
header("Content-type:text/html;charset=utf-8"); 
include 'config.php';
	$username = $_POST['username'];
	$password = $_POST['password'];
	$gamename = $_POST['gamename'];
	if($_POST['endtime'] == ''){
		$date=date('Y-m-d H:i:s',strtotime('+9years'));
	}
	elseif($_POST['endtime'] == 20){
		$date=date('Y-m-d H:i:s',strtotime('+1 hour'));
	}
	elseif($_POST['endtime'] == 21){
		$date=date('Y-m-d H:i:s',strtotime('+1 day'));
	}
	elseif($_POST['endtime'] == 22){
		$date=date('Y-m-d H:i:s',strtotime('+3 day'));
	}
	elseif($_POST['endtime'] == 23){
		$date=date('Y-m-d H:i:s',strtotime('+7 day'));
	}
	elseif($_POST['endtime'] == 24){
		$date=date('Y-m-d H:i:s',strtotime('+15 day'));
	}
	elseif($_POST['endtime'] == 1){
		$date=date('Y-m-d H:i:s',strtotime('+1month'));
	}
	elseif($_POST['endtime'] == 2){
		$date=date('Y-m-d H:i:s',strtotime('+2month'));
	}
	elseif($_POST['endtime'] == 3){
		$date=date('Y-m-d H:i:s',strtotime('+3month'));
	}
	elseif($_POST['endtime'] == 6){
		$date=date('Y-m-d H:i:s',strtotime('+6month'));
	}
	elseif($_POST['endtime'] == 12){
		$date=date('Y-m-d H:i:s',strtotime('+1years'));
	}
	elseif($_POST['endtime'] ==99){
		$date=date('Y-m-d H:i:s',strtotime('+9years'));
	}
		$vip = $_POST['vip'];
		$con = new mysqli($db_host,$db_username,$db_password,$dbgame,$dbport);
		$con->set_charset('utf8');	
		$sql = $con->prepare("SELECT * FROM `actors` WHERE `accountname` LIKE ? or `actorname` LIKE ? limit 1");
		$sql->bind_param('ss', $gamename, $gamename);
		$sql->execute();
		$result = $sql->get_result();
		$row = mysqli_fetch_array($result);	
		$roleid=$row['actorid'];
	if(!empty($gamename) && empty($roleid)){
		echo "<script>alert('数据库无此角色');history.go(-1)</script>";
		exit;
	}



	$mysqli = new mysqli($db_host,$db_username,$db_password,$gmdb,$dbport);
	if(!$mysqli){
	echo "<script>alert('系统提示：数据库连接失败');history.go(-1)</script>";
	exit;	
	}
	session_start();
	$mysqli->set_charset('utf8');	
	$query = $mysqli->prepare("select * from `user` where `user`=? and `password`=? limit 1");
	$query->bind_param('ss', $_SESSION["user"], $_SESSION["password"]);
	$query->execute();
	$result = $query->get_result();
	$row = mysqli_fetch_array($result);
	$check = md5($row['user'] . $row['password']);
	$status= $row['status'];
	if (($_SESSION['check'] <> $check || empty($_SESSION['status']) || $_SESSION['status'] != $status) and ($_SESSION['status'] != 'admin' || $_SESSION['status'] != 'proxy')){		
	unset($_SESSION);
	echo "<script>alert('您无此权限！');window.location.href='index.php';</script>";
	exit;
	}	
	if(isset($_SESSION['expiretime'])) {   
    if($_SESSION['expiretime'] < time()) {  
    unset($_SESSION['expiretime']);  
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'退出登陆',?)");
	$query->bind_param('sss', $_SESSION["user"], $_SESSION["name"], $user_IP);
	$query->execute();
	$mysqli->close();
	header('Location: exit.php?TIMEOUT'); // 登出  
	exit(0);  
	} else {  
	$_SESSION['expiretime'] = time() + 3600; // 刷新时间戳  
	}  
  
} 	
$t=date('Y-m-d H:i:s');
$log='log/log_addvip_'.date('Y-m-d').'.log';
if ($_POST){   
        switch ($_POST['sub']){
			case 'addvip':
				if(empty($username) || empty($password )){
				echo "<script>alert('账号或密码不可为空');history.go(-1)</script>";
				exit;
				}
				$mysqli->set_charset('utf8');	
				$query = $mysqli->prepare("select * from `user` where `user` = ? limit 1");
				$query->bind_param('s', $username);
				$query->execute();
				$result = $query->get_result();				
				if(mysql_num_rows($result)>0){
					$mysqli->close();
					echo "<script>alert('系统提示：该帐号已经被注册');history.go(-1)</script>";
					exit;
				}else {
				$query = $mysqli->prepare("INSERT INTO user (user, password,name,status,qu,roleid,addname,endtime) VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
				// $query->bind_param('ssssssss', $username, $password, $gamename, $vip, $qu, $roleid, $_SESSION["user"], $date);
				$query->bind_param('ssssssss', $gamename, $password, $gamename, $vip, $qu, $roleid, $_SESSION["user"], $date);
				$query->execute();					
				$remark = '添加 用户:'.$username.' '.' 密码:'.$password.' '.' 游戏账号:'.$gamename.' 权限:'.$vip."\t 角色ID：".$roleid."\t 添加人员：".$_SESSION["user"]."\t 有效期".$date.' 成功!!';
				$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES ( ? ,now(), ? , ?, ?)");
				$query->bind_param('sss', $_SESSION["user"], $_SESSION["name"], $remark, $user_IP);
				$query->execute();	
				echo '玩家ID：'.$roleid;
				file_put_contents($log,$t."\t".'管理员:'.$_SESSION["user"].' 添加用户:'.$username.' '.' 密码:'.$password.' '.' 游戏账号:'.$gamename.' 权限:'.$vip."\t 角色ID：".$roleid."\t 有效期".$date."成功!!"."\t IP:".$user_IP.PHP_EOL,FILE_APPEND);
				echo "<script>alert('添加用户成功');history.go(-1)</script>";
				}
				break;			
			case 'editvip':	
				if($_SESSION["status"] == $row['status']){
				$query = $mysqli->prepare("update user set `password` = ?, `name` = ?, `status` = ? ,`qu` = ?,`roleid`= ?, `addname`= ?,`endtime`= ? where `user` = ?");
				$query->bind_param('ssssssss',  $password, $gamename, $vip, $qu, $roleid, $_SESSION["user"], $date, $username);
				$query->execute();	
				$remark = '修改 用户:'.$username.' '.' 密码:'.$password.'  游戏账号:'.$gamename.' 权限: '.$vip."\t 角色ID：".$roleid."\t 添加人员：".$_SESSION["user"]."\t 有效期：".$date.' 分区: '.$qu.'区 成功!!';
				$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip ) VALUES ( ? ,now(), ? , ?, ?)");
				$query->bind_param('sss', $_SESSION["user"], $_SESSION["name"], $remark, $user_IP);
				$query->execute();	
				file_put_contents($log,$t."\t".'管理员'.$_SESSION["user"].' 修改用户:'.$username.' '.' 密码:'.$password.' '.' 游戏账号:'.$gamename.' 权限:'.$vip."\t 角色ID：".$roleid."\t 有效期".$date."成功!!"."\t IP:".$user_IP.PHP_EOL,FILE_APPEND);
				echo "<script>alert('修改权限成功!');history.go(-1)</script>";
				exit;
				}			
				echo "<script>alert('无权限修改!.');history.go(-1)</script>";		
				break;	
			case 'addtime':		
				$oldtime = $_POST['oldtime'];
				$addtime =trim($_POST['addtime']);
				if($addtime == 20){
					$time= date('Y-m-d H:i:s',strtotime('+1 hour',strtotime($oldtime))); 
				}
				elseif($addtime == 21){
					$time= date('Y-m-d H:i:s',strtotime('+1 day',strtotime($oldtime))); 
				}
				elseif($addtime == 22){
					$time= date('Y-m-d H:i:s',strtotime('+3 day',strtotime($oldtime))); 
				}
				elseif($addtime == 23){
					$time= date('Y-m-d H:i:s',strtotime('+7 day',strtotime($oldtime))); 
				}
				elseif($addtime == 24){
					$time= date('Y-m-d H:i:s',strtotime('+15 day',strtotime($oldtime))); 
				}
				elseif($addtime == 1){
					$time= date('Y-m-d H:i:s',strtotime('+1 month',strtotime($oldtime))); 
				}
				elseif($addtime == 2){
					$time= date('Y-m-d H:i:s',strtotime('+2 month',strtotime($oldtime))); 
				}
				elseif($addtime == 3){
					$time= date('Y-m-d H:i:s',strtotime('+3 month',strtotime($oldtime))); 
				}
				elseif($addtime == 6){
					$time= date('Y-m-d H:i:s',strtotime('+6 month',strtotime($oldtime))); 
				}
				elseif($addtime == 12){
					$time= date('Y-m-d H:i:s',strtotime('+1 years',strtotime($oldtime))); 
				}
				elseif($addtime == 99){
					$time= date('Y-m-d H:i:s',strtotime('+9 years',strtotime($oldtime))); 
				}				
				if(!empty($username)){									
				$query->bind_param("update user set endtime = ? where user = ?");
				$query->bind_param('ss', $time, $username);
				$remark = "管理：".$_SESSION["user"].'增加 用户:'.$username.' '.' 有效期:'.$time.' 分区: '.$qu.'区 成功!!';
				$query->bind_param("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?,now(),?, ?, ? )");
				$query->bind_param('sss', $_SESSION["user"], $_SESSION["name"], $remark, $user_IP);
				$query->execute();
				echo $endtime;
				file_put_contents($log,$t."\t".'管理员'.$_SESSION["user"].'增加用户:'.$username."\t 有效期".$time.' 分区: '.$qu."区 成功!!"."\t IP:".$user_IP.PHP_EOL,FILE_APPEND);
				echo "<script>alert('增加有效期成功!');history.go(-1)</script>";
				exit;
				}			
				echo "<script>alert('增加失败');history.go(-1)</script>";
				break;				
			case 'delvip':	
				$result = $query->bind_param("DELETE FROM user where user= ?");
				$query->bind_param('s', $username);
				$query->execute();
				if($result){
				$remark = "管理：".$_SESSION["user"].' 删除 用户:'.$username.' 成功!!';
				$query->bind_param("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?,now(),?,?,? )");
				$query->bind_param('sss', $_SESSION["user"], $_SESSION["name"], $remark, $user_IP);
				$query->execute();	
				file_put_contents($log,$t."\t".'管理员'.$_SESSION["user"].'删除 用户:'.$username." 成功!!"."\t IP:".$user_IP.PHP_EOL,FILE_APPEND);				
				echo "<script>alert('删除成功');history.go(-1)</script>";
				echo '<script language="javascript">top.location.href="gm.php"</script>';
				exit;			
				}else{
				echo "<script>alert('删除失败');history.go(-1)</script>";
				exit;			
				}
				break;		
			default:
				echo "<script>alert('未知操作');history.go(-1)</script>";
				exit;
				break;
        }


}

?>
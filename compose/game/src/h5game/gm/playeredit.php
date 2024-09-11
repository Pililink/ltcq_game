<meta charset="utf-8">
<?php 
error_reporting(0);
header("Content-type:text/html;charset=utf-8"); 
include 'config.php';
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
	if (($_SESSION['check'] <> $check || empty($_SESSION['status']) || $_SESSION['status'] != $status) and ($_SESSION['status'] != 'vip1' || $_SESSION['status'] != 'vip2' || $_SESSION['status'] != 'vip3')){		
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
if ($_POST){   
        switch ($_POST['sub']){		
			case 'playeredit':	
				if($_SESSION['user']=$row['user']){
				$password =	$_POST['password'];
				$query =  $mysqli->prepare("update user set password= ? where user = ? ");
				$query->bind_param('ss', $password, $row['user']);
				$query->execute();
				$remark = '修改 用户:'.$row['user'].' '.' 密码:'.$password.'  游戏账号:'.$row['name'].' 分区: '.$row['qu'].'区 修改密码成功!!';
				$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (? , now(),? , ? ,?)");
				$query->bind_param('sss', $row['user'], $row['name'], $remark, $user_IP);
				$query->execute();	
				echo "<script>alert('密码修改成功，请重新登陆！');window.location.href='index.php';</script>";
				exit;
				}			
				echo "<script>alert('无权限修改.');history.go(-1)</script>";		
				break;	
			default:
				echo "<script>alert('未知操作');history.go(-1)</script>";
				exit;
				break;
        }


}

?>
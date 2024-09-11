<meta charset="utf-8">
<?php 
header("Content-type:text/html;charset=utf-8"); 
include_once "config.php"; 
	$eff = urldecode("success");
	$con = @mysql_connect($db_host,$db_username,$db_password,$dbport);
	if (!mysql_select_db($gmdb, $con))
    {
	mysql_query("CREATE DATABASE {$gmdb}",$con);	
	mysql_select_db($gmdb, $con);
	mysql_query("CREATE TABLE if not exists user( ".
        "id INT NOT NULL AUTO_INCREMENT, ".
        "user VARCHAR(100) NOT NULL COMMENT '用户', ".
        "password VARCHAR(40) NOT NULL COMMENT '密码', ".	
		"name VARCHAR(100)  NULL COMMENT '游戏账号', ".		
        "status VARCHAR(100) NOT NULL COMMENT '权限', ".
		"qu INT NOT NULL COMMENT '分区', ".
		"roleid VARCHAR(100) NULL COMMENT '角色id', ".
		"addname VARCHAR(100)  NULL COMMENT '添加权限人员', ".	
		"endtime datetime  NULL COMMENT '有效期', ".
        "PRIMARY KEY (id ))ENGINE=myisam DEFAULT CHARSET=utf8; ");
		mysql_query("CREATE TABLE if not exists gmlog( ".
			"id INT NOT NULL AUTO_INCREMENT , ".
			"user VARCHAR(100) NOT NULL COMMENT '用户', ".
			"create_time datetime NOT NULL COMMENT '时间', ".
			"name VARCHAR(100) NULL COMMENT '游戏账号', ".
			"remark VARCHAR(1000) NOT NULL COMMENT '备注', ".
			"ip VARCHAR(100) NOT NULL COMMENT 'ip地址', ".
			"PRIMARY KEY (id ))ENGINE=myisam DEFAULT CHARSET=utf8;  ");
	mysql_select_db($gmdb, $con);
	if(mysql_num_rows(mysql_query("SHOW TABLES LIKE 'user'"))==1) {		
	mysql_query("INSERT INTO user (`id`, `user`, `password`,`status`,`qu`,`roleid`,`endtime`) VALUES ('1', '$admin', '$adminpass','admin','1','','$now')");
	mysql_query("INSERT INTO gmlog (`id`, `user`, `create_time`,`name`,`remark`,`ip`) VALUES ('1', '$admin', now(),'管理员','新数据库创建成功','$user_IP')");
	echo "<script>alert('数据库创建成功,首次登陆账号：$admin 密码：$adminpass');history.go(-1)</script>";
	}  
	}else{
	$user=$_POST['user'];
	$pass=$_POST['pass'];
	$v = md5($key);	
	$mysqli = new mysqli($db_host,$db_username,$db_password,$gmdb,$dbport);
	if(!$mysqli){
	echo "<script>alert('系统提示：数据库连接失败');history.go(-1)</script>";
	exit;	
	}
	$mysqli->set_charset('utf8');	
	$query = $mysqli->prepare("select * from `user` where `user`=? and `password`=? limit 1");
	$query->bind_param('ss', $user, $pass);
	$query->execute();
	$result = $query->get_result();
	if($result==null || $result->num_rows==0){
	echo "<script>alert('系统提示：帐号或者密码错误');history.go(-1)</script>";
	exit;	
	}
	$row = mysqli_fetch_array($result);
	$check = md5($row['user'] . $row['password']);
	$status= $row['status'];
	$qu= $row['qu'];
	$endtime=$row['endtime'];
	$name = $row['name'];
	$_SESSION["user"] = $row['user'];
	$_SESSION["password"] = $row['password'];
    $_SESSION['name'] = $name;  
	$_SESSION['check'] = $check; 
	$_SESSION['status'] = $status; 
	$_SESSION['endtime'] = $endtime;  	
	$_SESSION['expiretime'] = time();
	$_SESSION['qu'] = $qu; 	
	// if($v!='43eb14ff818a9739114912f8a6042d92'){
	// echo "<script>alert('$eff');history.go(-1)</script>" ;
	// exit;
	// }
	//管理员登录 
	if($status =='admin'){ 
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();	
	$mysqli->close();
	header("Location:gm.php");             
	}
	//代理登录 
	elseif($status =='proxy'){ 
	$query = $mysqli->prepare("INSERT INTO `gmlog` (`user`, `create_time`,`name`,`remark`,`ip`) VALUES ( ?, now(), ?, '登陆成功', ?)");
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();	
	$mysqli->close();
	header("Location:proxy.php");    	               
	}
 //用户VIP1登录
	elseif($status =='vip1'){ 
	if((int)strtotime($endtime) < (int)strtotime($now)){
		echo "<script>alert('账号已过期，请联系GM。');history.go(-1)</script>";
		echo '<script language="javascript">top.location.href="index.php"</script>';
		exit;
	}
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");	 
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();
	$mysqli->close();
	header("Location:player.php");   	
	}
 //用户VIP2登录 
	elseif($status =='vip2'){ 
		if((int)strtotime($endtime) < (int)strtotime($now)){
		echo "<script>alert('账号已过期，请联系GM。');history.go(-1)</script>";
		echo '<script language="javascript">top.location.href="index.php"</script>';
		exit;
	}
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");	
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();
	$mysqli->close();	
	header("Location:player2.php");   
	} 
	 //用户VIP3登录 
	elseif($status =='vip3'){ 
	if((int)strtotime($endtime) < (int)strtotime($now)){
		echo "<script>alert('账号已过期，请联系GM。');history.go(-1)</script>";
		echo '<script language="javascript">top.location.href="index.php"</script>';
		exit;
	}	
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();
	$mysqli->close();	
	header("Location:player3.php");   
	} 
	//用户VIP4登录 
	elseif($status =='vip4'){ 
		if((int)strtotime($endtime) < (int)strtotime($now)){
		echo "<script>alert('账号已过期，请联系GM。');history.go(-1)</script>";
		echo '<script language="javascript">top.location.href="index.php"</script>';
		exit;
	}
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");	
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();
	$mysqli->close(); 	
	header("Location:player4.php");     	
	}
	//用户VIP5登录 
	elseif($status =='vip5'){ 
		if((int)strtotime($endtime) < (int)strtotime($now)){
		echo "<script>alert('账号已过期，请联系GM。');history.go(-1)</script>";
		echo '<script language="javascript">top.location.href="index.php"</script>';
		exit;
	}
	$query = $mysqli->prepare("INSERT INTO gmlog (user, create_time,name,remark,ip) VALUES (?, now(),?,'登陆成功',?)");
	$query->bind_param('sss', $user, $name, $user_IP);
	$query->execute();	
	$mysqli->close(); 	
	header("Location:player5.php");    	
	}
	//用户登录出错时 
	echo "<script>alert('系统异常！');history.go(-1)</script>";
	$mysqli->close();
	echo '<script language="javascript">top.location.href="index.php"</script>';
	}	
?>
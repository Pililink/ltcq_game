<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>玩家后台</title>
</head>
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <title>GM</title>
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="css/bootstrap.min.css">
</head>
<body>
<?php
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
	if ($_SESSION['check'] <> $check || empty($_SESSION['status']) || $_SESSION['status'] <> $status  || $_SESSION['status'] <> 'vip4'){				
	unset($_SESSION);
	echo "<script>alert('您无此权限！');window.location.href='index.php';</script>";
	exit;
	}	
	if(isset($_SESSION['expiretime'])) {   
    if($_SESSION['expiretime'] < time()) {  
    unset($_SESSION['expiretime']);  
	header('Location: exit.php?TIMEOUT'); // 登出  
	exit(0);  
	} else {  
	$_SESSION['expiretime'] = time() + 3600; // 刷新时间戳  
	}  
  
} 	
?>
<div class="text-center col-md-4 center-block">
<h1><?php echo $_SESSION['gmbt'];?>玩家后台</h1>
 <h3 style="color:blue"><?php echo $_SESSION['name'];?> 欢迎登陆</h3> 
  <label style="color:red" for="v">您的账号到期时间：<?php echo $_SESSION['endtime'];?></label> <br>
	 <button class="btn btn-info btn-block" onclick="window.location.href='player4.php'">充值系统</button>
	 <button class="btn btn-info btn-block" onclick="window.location.href='playermail4.php'">邮件系统</button>
	 	<button class="btn btn-info btn-block" onclick="window.location.href='playerpass4.php'">修改密码</button>
	<button class="btn btn-info btn-block" onclick="window.location.href='exit.php'">登陆注销</button><br>
<form id="form1" name="form1" method="post" action="playeredit.php">
        <div class="form-group">
		 <label for="username">后台登陆账号</label>
		<input type="text" readOnly="true" placeholder="后台登陆账号" class="form-control" id="username" name="username" value="<?php echo $_SESSION['user'];?>">
		<input type="password" placeholder="后台登陆密码" class="form-control" id="password" name="password" value="<?php echo $_SESSION['password'];?>">
        </div>	
		<div class="form-group">	
		 <button type="submit" class="btn btn-info btn-block" name="sub" value="playeredit">修改登陆密码</button>
		   </div>
</form>
<div class="form-group">
  <p class="admin_copyright">   <?php echo $_SESSION['copyright'];?></p>  </div>
</body>
</html>
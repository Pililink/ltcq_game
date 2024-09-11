<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>GM后台管理系统</title>
</head>
<head>
    <meta charset="UTF-8">
    <meta name="viewport"
          content="width=device-width, user-scalable=no, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">
    <meta http-equiv="X-UA-Compatible" content="ie=edge">
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="css/bootstrap.min.css">
	<script src="js/bootstrap.min.js"></script>
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
	if ($_SESSION['check'] <> $check || empty($_SESSION['status']) || $_SESSION['status'] <> $status  || $_SESSION['status'] <> 'admin'){				
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
?>
<div class="text-center col-md-4 center-block">
<h1><?php echo $_SESSION['gmbt'];?>授权后台</h1>
 <h3 style="color:blue"><?php echo $_SESSION['name'];?> 欢迎登陆</h3> <br>
	<button class="btn btn-info btn-block" onclick="window.location.href='gmlist.php?page=1'">账号列表</button>
	<button class="btn btn-info btn-block" onclick="window.location.href='gm.php'">返回主菜单</button>
	<button class="btn btn-info btn-block" onclick="window.location.href='exit.php'">登陆注销</button>	
	 <table style='text-align:margin：auto;' class="table table-bordered" border='1'width="40%"> <tr><th style='text-align: center;'>用户名</th><th style='text-align: center;'>账号或角色名</th><th style='text-align: center;'>权限</th><th style='text-align: center;'>分区</th></th><th style='text-align: center;'>绑定角色ID</th><th style='text-align: center;'>代理</th><th style='text-align: center;'>有效时间</th></th><th style='text-align: center;'>改/删</th></tr> 
	<?php
			//引用conn.php文件
        require 'config.php';
        //查询数据表中的数据
		$con = @mysql_connect($db_host,$db_username,$db_password)or die(mysql_error());
		mysql_query("set names UTF8"); 
		mysql_select_db($gmdb, $con);
		$perNumber=10; //每页显示的记录数
		$page=$_GET['page']; //获得当前的页面值
		$count=mysql_query("select count(*) from user"); //获得记录总数
		$rs=mysql_fetch_array($count);
		$totalNumber=$rs[0];
		$totalPage=ceil($totalNumber/$perNumber); //计算出总页数
		if (!isset($page)) {
		$page=1;
		} //如果没有值,则赋值1
		$startCount=($page-1)*$perNumber; //分页开始,根据此方法计算出开始的记录
		$result=mysql_query("select * from user  limit $startCount,$perNumber" ); //根据前面的计算出开始的记录和记录数
		while ($row=mysql_fetch_array($result)) {
		echo "<tr><td>$row[1]</td><td>$row[3]</td><td>$row[4]</td><td>$row[5]区</td><td>$row[6]</td><td>$row[7]</td><td>$row[8]</td><td><a href='gmedit.php?id=$row[0]'>点击</a></td></tr>";
		}				
		if ($page != 1) { //页数不等于1
		?>
		<tr><a href="gmlist.php?page=<?php echo $page - 1;?>">上一页</a></tr>
		<?php
		}
		for ($i=1;$i<=$totalPage;$i++) { //循环显示出页面
		?>
		<tr><a href="gmlist.php?page=<?php echo $i;?>"><?php echo ' 第'.' '.$i.' '.'页  ';?></a></tr>
		<?php
		}
		if ($page<$totalPage) { //如果page小于总页数,显示下一页链接
		?>
		<tr><a href="gmlist.php?page=<?php echo $page + 1;?>">下一页</a></tr>
		<?php
		}
		?>
     </table>
  <p class="admin_copyright">   <?php echo $_SESSION['copyright'];?></p>  
 </div>
</div>
</body>
</html>
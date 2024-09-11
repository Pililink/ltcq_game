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
    <title>GM</title>
    <!-- 最新版本的 Bootstrap 核心 CSS 文件 -->
    <link rel="stylesheet" href="css/bootstrap.min.css">	
  	<script src="js/jquery-1.7.2.min.js"></script>
	<script type="text/javascript" src="js/wangEditor.js"></script>
    <script type="text/javascript">
        var E = window.wangEditor
        var editor = new E('#div1')
        var $yzf = $('#yzf')
        editor.customConfig.onchange = function (html) {
            // 监控变化，同步更新到 textarea
            $yzf.val(html)
        }
        editor.create()
        // 初始化 textarea 的值
        $yzf.val(editor.txt.html())
    </script>
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
<div id="div1" class="text-center col-md-4 center-block">
<h1><?php echo $_SESSION['gmbt'];?>授权后台</h1>
 <h3 style="color:blue"><?php echo $_SESSION['name'];?> 欢迎登陆</h3> <br>
	 <button class="btn btn-info btn-block" onclick="window.location.href='gmlog.php'">操作日志</button>	
	<button class="btn btn-info btn-block" onclick="window.location.href='gm.php'">返回主菜单</button>
	<button class="btn btn-info btn-block" onclick="window.location.href='exit.php'">登陆注销</button><br>	 
 <div class="form-group">
<form id="form" name="form" method="post" action="">
		 <h4>日志列表</h4>
			<select class="form-control selectpicker" id="test" name="test" value="">
			<?php 
			function getDir($path){
			  if(is_dir($path)){
			 
				$dir = scandir($path);
				foreach ($dir as $value){
				  $sub_path =$path .'/'.$value;
				  if($value == '.' || $value == '..'){
					continue;
				  }else if(is_dir($sub_path)){
					getDir($sub_path);
				  }else{
					//.$path 可以省略，直接输出文件名
					$a='<option value="';$b='">';$c='</option>';
				echo $a.$value.$b.$value.$c;
				//    echo $value;
				  }
				}
			  }
			}
			$path = 'log';
			getDir($path); 
			?>
			</select>
		 <button type="submit" class="btn btn-info btn-block" name="submit">查看</button><br>						
</form>
 <p class="admin_copyright">   <?php echo $_SESSION['copyright'];?></p> </div>
 </div>
</body>
 	<?php 
if(isset($_POST['submit'])) {
	$text = $_POST['test'];
	$fileitem='log/'.$text;
	print_r("<pre>");
	print_r(file_get_contents($fileitem,'<br/>'));
}
?>
</html>
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
$vip=$_GET['vip'];
if(isset($_POST['submit'])) {
	if(empty($vip)){
		echo "<script>alert('请选择物品表!');history.go(-1)</script>";
		exit;
	}
	$fileitem='onekey/item.'.$vip.'.txt';
	$text = $_POST['yzf'];
	file_put_contents($fileitem, ''); 	
	file_put_contents($fileitem, $text); 
	echo "<script>alert('保存成功!');history.go(-1)</script>";
}
?>
<div id="div1" class="text-center col-md-4 center-block">
<h1><?php echo $_SESSION['gmbt'];?>授权后台</h1>
 <h3 style="color:blue"><?php echo $_SESSION['name'];?> 欢迎登陆</h3> <br>
	 <button class="btn btn-info btn-block" onclick="window.location.href='gmitem.php'">修改后台物品</button>	
	<button class="btn btn-info btn-block" onclick="window.location.href='gm.php'">返回主菜单</button>
	<button class="btn btn-info btn-block" onclick="window.location.href='exit.php'">登陆注销</button><br>	 
	        <div class="form-group">
			<select class="form-control selectpicker"  onchange="self.location.href=options[selectedIndex].value" id="vip" name="vip" value="">
			<option value="">请选择</option>
			<option value="gmitem.php?vip=admin">管理员</option>
			<option value="gmitem.php?vip=proxy">管理员</option>
			<option value="gmitem.php?vip=vip2">VIP2</option>
			<option value="gmitem.php?vip=vip3">VIP3</option>
			<option value="gmitem.php?vip=vip4">VIP4</option>
			<option value="gmitem.php?vip=vip5">VIP5</option>
			<option value="gmitem.php?vip=yz1">一键礼包1</option>
			<option value="gmitem.php?vip=yz2">一键礼包2</option>
			<option value="gmitem.php?vip=yz3">一键礼包3</option>
			<option value="gmitem.php?vip=yz4">一键礼包4</option>
			<option value="gmitem.php?vip=yz5">一键礼包5</option>
			<option value="gmitem.php?vip=yz6">一键礼包6</option>
			<option value="gmitem.php?vip=yz7">一键礼包7</option>
			<option value="gmitem.php?vip=yz8">一键礼包8</option>
			<option value="gmitem.php?vip=yz9">一键礼包9</option>
			<option value="gmitem.php?vip=yz10">一键礼包10</option>
			</select>
<form id="form" name="form" method="post" action="">
		 <h4>GM增删后台<?php echo $_GET['vip']; ?>物品列表</h4>
		 <label style="color:red">修改提示：物品ID; 数量; 物品名称</label><br>
			<textarea type="text" style="width:100%; height:200px;"  class="form-control" id="yzf" name="yzf"  value=""><?php
			$fileitem='onekey/item.'.$_GET['vip'].'.txt';
			print_r(file_get_contents($fileitem,'<br/>'));
			?></textarea>	
		 <button type="submit" class="btn btn-info btn-block" name="submit">修改保存</button><br>						
</form>
 <p class="admin_copyright"> 。 <?php echo $_SESSION['copyright'];?></p> </div>
 </div>
</body>
</html>
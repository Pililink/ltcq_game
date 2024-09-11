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
	<script src="js/jquery-1.7.2.min.js"></script>
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
<form id="form1" name="form1" method="post" action="playerquery.php">
        <div class="form-group">
            <label for="qu">游戏分区</label>
            <input type="text" readOnly="true" class="form-control" id="qu" name="qu" value="<?php echo $_SESSION['qu'];?>" >
            <label for="username">游戏账号或角色名</label>
            <input type="text" readOnly="true" class="form-control" id="username" name="username" value="<?php echo $_SESSION['name'];?>" >
        </div>
    <div class="form-group">
		<fieldset><legend>邮件系统</legend>
					<select class="form-control selectpicker" id="huobiid" name="huobiid" value="">
			<?php
			  foreach($yzfhuobi as $k=>$v){
				  echo '<option value="'.$k.'">'.$v.'</option>';
			  }
			  ?>
			</select>
		  		<div class="form-group">													
	     <input type="text" value="" id="searchipt" placeholder="物品搜索" class="form-control"><input class="form-control" type="button" value="搜索" id="search" maxlength="20">
                  </div>  
			<div class="form-group">				  
         <select class="form-control selectpicker" id="item" name="item" value="item">
		<?php
        $file = fopen("onekey/item.vip4.txt", "r");
        while(!feof($file))
        {
            $line=fgets($file);
			$txts=explode(';',$line);
			if(count($txts)==2){
				echo '<option value="'.$txts[0].'">'.$txts[1].'</option>';
			}
        }
        fclose($file);
			?>
			</select>
			<input type="text" placeholder="数量" class="form-control" id="num" name="num" value="1" maxlength="12">
		<div class="form-group">
		 <button type="submit" class="btn btn-info btn-block" name="sub" value="mail">发送邮件</button>
		   </div>				
</form>
<script>
$('#search').click(function(){
	  var keyword=$('#searchipt').val();
	  $.ajax({
		  url:'itemquery4.php',
		  type:'post',
		  'data':{keyword:keyword},
          'cache':false,
          'dataType':'json',
		  success:function(data){
			  if(data){
				  $('#item').html('');
				for (var i in data){
				  $('#item').append('<option value="'+data[i].key+'">'+data[i].val+'</option>');
				}
			  }else{
				  $('#item').html('<option value="0">未找到</option>');
			  }
		  },
		  error:function(){
			  alert('操作失败');
		  }
	  });
  });
  </script>
<div class="form-group">
  <p class="admin_copyright">   <?php echo $_SESSION['copyright'];?></p>  </div>
</body>
</html>
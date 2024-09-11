<?php 
header("Content-type: text/html; charset=utf-8");
ini_set('date.timezone','Asia/Shanghai');
include 'config.php';
	$mysqli = new mysqli($db_host,$db_username,$db_password,$gmdb,$dbport);
	if(!$mysqli){
	echo "<script>alert('系统提示：数据库连接失败');history.go(-1)</script>";
	exit;	
	}
	$mysqli->set_charset('utf8');	
	$query = $mysqli->prepare("select * from `user` where `user`=? and `password`=? limit 1");
	$query->bind_param('ss', $_SESSION["user"], $_SESSION["password"]);
	$query->execute();
	$result = $query->get_result();
	$row = mysqli_fetch_array($result);
	$check = md5($row['user'] . $row['password']);
	if (($_SESSION['check'] <> $check || empty($_SESSION['status']) || $_SESSION['status'] != $row['status']) and ($_SESSION['status'] != 'admin')){		
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
	$name = $_POST['username'];
	$mysql1 = new mysqli($db_host,$db_username,$db_password,$dbgame,$dbport);
	if(!$mysql1){
	echo "<script>alert('系统提示：游戏数据库连接失败');history.go(-1)</script>";
	exit;	
	}
	$mysql1->set_charset('utf8');	
	$query1 = $mysql1->prepare("SELECT * FROM actors WHERE accountname LIKE ? or actorname LIKE ? limit 1");
	$query1->bind_param('ss', $name, $name);
	$query1->execute();
	$result1 = $query1->get_result();
	$row1 = mysqli_fetch_array($result1);	
	$accountname=$row1['accountname'];
	$actorid=$row1['actorid']; 
	$serverid=$row1['serverindex']; 
if ($_POST){   
        switch ($_POST['sub']){
			case 'cz':
				if(empty($actorid)){
					echo "<script>alert('数据库无此角色');history.go(-1)</script>";
					exit;
				}
				$num = $_POST['num'];
				if($num<1 || $num>99999999999){
					echo "<script>alert('数量范围：1-99999999999');history.go(-1)</script>";
					exit;
				}	
				$log='log/gm_charge_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if(!empty($num)){
                 $mysql1->set_charset('utf8');
				 $query1 = $mysql1->prepare("insert into `feecallback` (`serverid`,`openid`,`itemid`,`actor_id`) values (?,?,?,?)");
                 $query1->bind_param('ssss', $qu, $accountname, $num, $actorid);
                 $query1->execute();
				file_put_contents($log,$date."\t".$qu."区\t角色名：".$name."\t账号：".$accountname."\t数量：".$num."\t角色ID：".$actorid." 充值成功\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('充值成功');history.go(-1)</script>";
					$mysql1->close();
				}else{
					file_put_contents($log,$date."\t".$serverid."\t".$accountname."\t".$num."\t".$actorid." 充值失败\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('充值失败');history.go(-1)</script>";
					$mysql1->close();
				}
				break;	
			case 'monthcard':
				$log='log/GM_monthcard_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if(!empty($card)){
				 $mysql1->set_charset('utf8');
				 $query1 = $mysql1->prepare("insert into `feecallback` (`serverid`,`openid`,`itemid`,`actor_id`) values (?,?,?,?)");
                 $query1->bind_param('ssss', $qu, $accountname, $card, $actorid);
                 $query1->execute();						
					file_put_contents($log,$date."\t".$qu."区\t角色名：".$name."\t账号：".$accountname."\t卡：".$card."\t角色ID：".$actorid." 月卡发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('月卡发送成功');history.go(-1)</script>";
					$mysql1->close();
				}else{
					file_put_contents($log,$date."\t".$serverid."\t".$accountname."\t".$card."\t".$actorid." 月卡发送失败\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('月卡发送失败');history.go(-1)</script>";
					$mysql1->close();
				}
				break;	
			case 'mail':
				if(empty($actorid)){
					echo "<script>alert('数据库无此角色');history.go(-1)</script>";
					exit;
				}
				$num = $_POST['num'];
				$item=$_POST['item'];
				$huobiid=$_POST['huobiid'];
				$ic = ',';
				if($huobiid!=''){
				$it = '0,';
				$items=$it.$huobiid.$ic.$num;
				}else{
				if($num<1 || $num>$max){
				echo "<script>alert('数量范围：1-$max');history.go(-1)</script>";
				exit;
				}	
				$it = '1,';
				$items=$it.$item.$ic.$num;
				}				
				$log='log/GM_mail_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($num !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmdid, cmd, param1, param2, param3, param4) values (?,'1','sendMail',?, ?, ?, ?)");
                $query1->bind_param('sssss', $qu, $title, $content, $actorid, $items);
                $query1->execute();												
				file_put_contents($log,$date."\t".$qu."区\t角色名：".$name."\t账号：".$actorid."\t物品ID：".$_POST['item']."\t数量".$num."\t"."邮件发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('邮件发送成功');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t".$name."\t".$actorid."\t".$_POST['item']."\t".$num."\t"."邮件发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('邮件发送失败：');history.go(-1)</script>";
				}
				break;	
			case 'allmail':
				$num = $_POST['num'];
				$item=$_POST['item'];
				$huobiid=$_POST['huobiid'];
				$level=$_POST['level'];
				$ic = ',';
				if($huobiid!=''){
				$it = '0,';
				$items=$it.$huobiid.$ic.$num;
				}else{
				if($num<1 || $num>$max){
				echo "<script>alert('数量范围：1-$max');history.go(-1)</script>";
				exit;
				}	
				$it = '1,';
				$items=$it.$item.$ic.$num;
				}				
				$log='log/GM_mail_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($num !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmdid, cmd, param1, param2, param3, param4) select serverindex,'1','sendMail','GM全服邮件','GM全服福利已发送',actorid, ?  from actors where level >?");
				$query1->bind_param('ss', $items, $level);
                $query1->execute();					
				file_put_contents($log,$date."\t".$qu."区\t等级大于".$level."等级\t物品ID：".$_POST['item']."\t数量".$num."\t"."全服邮件发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('全服邮件发送成功');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t等级大于".$level."\t".$_POST['item']."\t".$num."\t"."全服邮件发送失败\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('全服邮件发送失败：');history.go(-1)</script>";
				}
				break;	
			case 'yz':	
				$vip=trim($_POST['vip']);
				$log='log/gmyz_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($actorid !=''){
				$file = fopen("onekey/item.".$vip.".txt", "r");
				while(!feof($file))
				{
				$line=fgets($file);
				$yzitem=explode(';',$line);
				if(count($yzitem)==3){	
				$it = '1,';$ic = ',';
				$items=$it.$yzitem[0].$ic.$yzitem[1];
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmdid, cmd, param1, param2, param3, param4) values (?,'1','sendMail',?, ?, ?, ?)");
                $query1->bind_param('sssss', $qu, $title, $content, $actorid, $items);
                $query1->execute();			
				usleep(30000);
				file_put_contents($log,$date."\t管理员：".$_SESSION["user"].'为'.$qu."区\t角色名：".$name."\t账号：".$actorid."\t物品：".$yzitem[2]."\t数量：".$yzitem[1]."\t".$vip." 一键礼包 发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
				}
				}
				for($i=0;$i<count($yzitem);$i++){
				}
				fclose($file);														
				$mysqli->close();
				echo "<script>alert('一键邮件发送成功');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t代理：".$_SESSION["user"].'为'.$qu."区\t角色名：".$name."\t账号：".$actorid."\t物品：".$yzitem[2]."\t数量：".$yzitem[1]."\t".$vip." 一键礼包 发送失败\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysqli->close();
					echo "<script>alert('一键邮件发送失败：');history.go(-1)</script>";
				}
				break;	
			case 'zhfh':
				$time='1608568913';
				$log='log/other_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($actorid !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmd, param1, param2) values (?,'Sealed',?,?)");
                $query1->bind_param('sss', $serverid, $actorid, $time);
                $query1->execute();																	
				file_put_contents($log,$date."\t".$qu."\t".$actorid."\t"."封禁成功！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('封禁成功！');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t".$actorid.$time."\t"."封禁失败！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('封禁失败！');history.go(-1)</script>";
				}
				break;		
			case 'zhjf':
				$time='0';
				$log='log/other_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($actorid !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmd, param1, param2) values (?,'Sealed',?,?)");
                $query1->bind_param('sss', $serverid, $actorid, $time);
                $query1->execute();												
				file_put_contents($log,$date."\t".$qu."\t".$roleid."\t"."解封成功！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('解封成功！');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t".$actorid.$time."\t"."解封失败！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('解封失败！');history.go(-1)</script>";
				}
				break;		
			case 'jy':
				$time='1608568913';
				$log='log/other_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($actorid !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmd, param1, param2) values (?,'shutup',?,?)");
                $query1->bind_param('sss', $serverid, $actorid, $time);
                $query1->execute();													
				file_put_contents($log,$date."\t".$qu."区\t角色ID".$roleid."\t"."禁言成功！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('禁言成功！');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t".$actorid.$time."\t"."禁言失败！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('禁言失败！');history.go(-1)</script>";
				}
				break;				
			case 'jj':
				$time='0';
				$log='log/other_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($actorid !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmd, param1, param2) values (?,'shutup',?,?)");
                $query1->bind_param('sss', $serverid, $actorid, $time);
                $query1->execute();								
				file_put_contents($log,$date."\t".$qu."区\t角色ID：".$actorid."\t"."解禁成功！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('解禁成功！');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t".$qu."\t".$actorid.$time."\t"."解禁失败！\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('解禁失败！');history.go(-1)</script>";
				}
				break;					
            default:
                echo "<script>alert('未知操作');history.go(-1)</script>";
                break;
				exit;
        }
}
	
?>
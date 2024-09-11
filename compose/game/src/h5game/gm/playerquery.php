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
	$status= $row['status'];
	if (($_SESSION['check'] <> $check  || empty($_SESSION['status']) || $_SESSION['status'] <> $status) and ($_SESSION['status'] != 'vip1' || $_SESSION['status'] != 'vip2' || $_SESSION['status'] != 'vip3' || $_SESSION['status'] != 'vip4' || $_SESSION['status'] != 'vip5')){		
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
	$name = $_SESSION["name"];
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
	if($row['roleid']!=$actorid || $_SESSION['qu'] != $serverid ){
	echo "<script>alert('玩家账号异常!');history.go(-1)</script>";
	exit;
	}
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
				$log='log/Player_charge_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if(!empty($num)){
                 $mysql1->set_charset('utf8');
				 $query1 = $mysql1->prepare("insert into `feecallback` (`serverid`,`openid`,`itemid`,`actor_id`) values (?,?,?,?)");
                 $query1->bind_param('ssss', $qu, $accountname, $num, $actorid);
                 $query1->execute();
				file_put_contents($log,$date."\t区：".$qu."\t角色名：".$name."\t账号：".$accountname."\t数量:".$num."\t 角色ID:".$actorid." 充值成功\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('充值成功');history.go(-1)</script>";
					$mysql1->close();
				}else{
					file_put_contents($log,$date."\t".$serverid."\t".$accountname."\t".$num."\t".$actorid." 充值失败\t".$user_IP.PHP_EOL,FILE_APPEND);
					echo "<script>alert('充值失败');history.go(-1)</script>";
					$mysql1->close();
				}
				break;
			case 'monthcard':
				$log='log/Player_monthcard_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if(!empty($card)){
				 $mysql1->set_charset('utf8');
				 $query1 = $mysql1->prepare("insert into `feecallback` (`serverid`,`openid`,`itemid`,`actor_id`) values (?,?,?,?)");
                 $query1->bind_param('ssss', $qu, $accountname, $card, $actorid);
                 $query1->execute();						
					file_put_contents($log,$date."\t区：".$qu."\t角色名：".$name."\t账号：".$accountname."\t卡：".$card."\t角色ID：".$actorid." 月卡发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
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
				$find=false;
				$file = fopen("onekey/item.".$status.".txt", "r");
				while(!feof($file))
				{
					$line=fgets($file);
					$txts=explode(';',$line);
					if($txts[0]==$item){
						$find=true;
						break;
					}
				}
				fclose($file);
				if($find==false){
					$return=array(
						'errcode'=>0,						
					);
				echo "<script>alert('物品ID不存在!');history.go(-1)</script>";
				exit(json_encode($return));
				}
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
				$log='log/Player_mail_'.date('Y-m-d').'.log';
				$date=date('Y-m-d H:i:s');
				if($num !=''){
				$mysql1->set_charset('utf8');
				$query1 = $mysql1->prepare("INSERT INTO gmcmd (serverid, cmdid, cmd, param1, param2, param3, param4) values (?,'1','sendMail',?, ?, ?, ?)");
                $query1->bind_param('sssss', $qu, $title, $content, $actorid, $items);
                $query1->execute();												
				file_put_contents($log,$date."\t区".$qu."\t角色名：".$name."\t角色ID：".$actorid."\t物品ID：".$_POST['item']."\t数量：".$num."\t"." 邮件发送成功\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
				echo "<script>alert('邮件发送成功');history.go(-1)</script>";
				}else{
					file_put_contents($log,$date."\t区".$qu."\t角色名：".$name."\t角色ID：".$actorid."\t物品ID：".$_POST['item']."\t数量：".$num."\t"."邮件发送失败：\t".$user_IP.PHP_EOL,FILE_APPEND);
				$mysql1->close();
					echo "<script>alert('邮件发送失败：');history.go(-1)</script>";
				}
				break;					
            default:
                echo "<script>alert('未知操作');history.go(-1)</script>";
				exit;
                break;
        }
}

?>
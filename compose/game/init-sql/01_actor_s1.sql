/*
Navicat MySQL Data Transfer

Source Server         : localhost_3306
Source Server Version : 50553
Source Host           : localhost:3306
Source Database       : 3

Target Server Type    : MYSQL
Target Server Version : 50553
File Encoding         : 65001

Date: 2021-02-25 19:53:18
*/

SET FOREIGN_KEY_CHECKS=0;
CREATE DATABASE IF NOT EXISTS actor_s1 CHARACTER SET utf8 COLLATE utf8_general_ci;
USE actor_s1;

-- ----------------------------
-- Table structure for actorbinarydata
-- ----------------------------
DROP TABLE IF EXISTS `actorbinarydata`;
CREATE TABLE `actorbinarydata` (
  `actorid` bigint(20) NOT NULL COMMENT '玩家的actorid',
  `quest` varbinary(1000) DEFAULT NULL COMMENT '任务数据',
  PRIMARY KEY (`actorid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actorbinarydata
-- ----------------------------

-- ----------------------------
-- Table structure for actorguild
-- ----------------------------
DROP TABLE IF EXISTS `actorguild`;
CREATE TABLE `actorguild` (
  `actorid` int(11) NOT NULL COMMENT '角色id',
  `guildid` int(11) NOT NULL COMMENT '公会的id',
  `pos` int(11) DEFAULT '0' COMMENT '公会地位',
  `total_contrib` int(11) DEFAULT '0' COMMENT '公会累计贡献',
  `today_contrib` int(11) DEFAULT '0' COMMENT '本日贡献',
  PRIMARY KEY (`actorid`),
  KEY `actorguild_id` (`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actorguild
-- ----------------------------

-- ----------------------------
-- Table structure for actorlogin
-- ----------------------------
DROP TABLE IF EXISTS `actorlogin`;
CREATE TABLE `actorlogin` (
  `account` varchar(64) DEFAULT NULL COMMENT '玩家字符串账号',
  `lastlogin` datetime DEFAULT NULL COMMENT '最后登陆时间',
  `serverid` int(11) DEFAULT NULL COMMENT '几服',
  KEY `actorlogin_account` (`account`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actorlogin
-- ----------------------------

-- ----------------------------
-- Table structure for actormsg
-- ----------------------------
DROP TABLE IF EXISTS `actormsg`;
CREATE TABLE `actormsg` (
  `msgid` bigint(20) NOT NULL AUTO_INCREMENT,
  `actorid` int(11) DEFAULT NULL COMMENT '消息对应的角色id，表示这个消息要发送的对象',
  `msg` varbinary(1024) DEFAULT NULL COMMENT '消息的内容，二进制数据',
  PRIMARY KEY (`msgid`),
  KEY `actormsg_id` (`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actormsg
-- ----------------------------

-- ----------------------------
-- Table structure for actoroldname
-- ----------------------------
DROP TABLE IF EXISTS `actoroldname`;
CREATE TABLE `actoroldname` (
  `actorid` int(11) DEFAULT '0' COMMENT '阵营id',
  `oldname` varchar(32) DEFAULT NULL COMMENT '角色名',
  `serverindex` int(11) DEFAULT '0' COMMENT '服务器的id',
  KEY `key1` (`oldname`) USING BTREE,
  KEY `key2` (`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actoroldname
-- ----------------------------

-- ----------------------------
-- Table structure for actors
-- ----------------------------
DROP TABLE IF EXISTS `actors`;
CREATE TABLE `actors` (
  `accountid` int(11) DEFAULT NULL COMMENT '玩家的账户id',
  `accountname` varchar(80) DEFAULT NULL COMMENT '账户名',
  `actorid` int(11) NOT NULL AUTO_INCREMENT COMMENT '玩家的角色id',
  `actorname` varchar(32) DEFAULT NULL COMMENT '角色名',
  `job` tinyint(1) DEFAULT '0' COMMENT '第一个角色职业',
  `sex` tinyint(1) DEFAULT '0' COMMENT '第一个角色性别',
  `status` int(11) DEFAULT '1' COMMENT '0位:已删除,1位:已禁用,2位:有效,3位:首选,4位:是否在线',
  `level` int(11) DEFAULT '1' COMMENT '等级',
  `exp` int(20) DEFAULT '0' COMMENT '玩家的经验',
  `serverindex` int(11) DEFAULT '0' COMMENT '玩家所在的服务器的编号',
  `createtime` datetime DEFAULT NULL COMMENT '角色的创建时间',
  `updatetime` datetime DEFAULT NULL COMMENT '服务器的存盘时间，在这个点最后一次更新db',
  `lastonlinetime` int(11) DEFAULT '0' COMMENT '最后登录时间,minitime格式的',
  `lastloginip` bigint(20) unsigned DEFAULT '0' COMMENT '上次登录的ip',
  `baggridcount` int(11) DEFAULT '100' COMMENT '背包的格子数量',
  `gold` bigint(20) DEFAULT '5000000' COMMENT '金钱',
  `yuanbao` bigint(20) DEFAULT '5000000' COMMENT '元宝',
  `totalpower` bigint(20) DEFAULT '0' COMMENT '总战斗力',
  `recharge` int(11) DEFAULT '0' COMMENT '充值元宝数',
  `paid` int(11) DEFAULT '0' COMMENT '消费元宝数',
  `fbuid` bigint(20) DEFAULT '0' COMMENT '副本的handle',
  `sceneid` int(11) DEFAULT '0' COMMENT '进入副本前的场景的id',
  `totalonline` int(11) DEFAULT '0' COMMENT '总的在线时间(秒)',
  `dailyonline` int(11) DEFAULT '0' COMMENT '单日在线时间(秒)',
  `chapterlevel` int(11) DEFAULT '0' COMMENT '章节等级记录',
  `vip_level` int(10) unsigned DEFAULT '15' COMMENT 'vip等级',
  `essence` int(10) unsigned DEFAULT '0' COMMENT '精魄',
  `zhuansheng_lv` int(10) unsigned DEFAULT '0' COMMENT '转生等级',
  `zhuansheng_exp` int(10) unsigned DEFAULT '0' COMMENT '转生经验',
  `monthcard` tinyint(4) DEFAULT '0',
  `tianti_level` int(11) DEFAULT '0',
  `tianti_dan` int(11) DEFAULT '0',
  `tianti_win_count` int(11) DEFAULT '0',
  `tianti_week_refres` int(11) DEFAULT '0',
  `total_wing_power` bigint(20) DEFAULT '0',
  `warrior_power` bigint(20) DEFAULT '0',
  `mage_power` bigint(20) DEFAULT '0',
  `taoistpriest_power` bigint(20) DEFAULT '0',
  `train_level` int(11) DEFAULT '0',
  `train_exp` int(11) DEFAULT '0',
  `total_stone_level` int(11) DEFAULT '0',
  `guildid` int(11) DEFAULT '0',
  `zhan_ling_star` int(11) DEFAULT '0',
  `zhan_ling_stage` int(11) DEFAULT '0',
  `total_loongsoul_level` int(11) DEFAULT '0',
  `feats` bigint(20) DEFAULT '0' COMMENT '功勋',
  `ex_ring_lv` tinyblob COMMENT '特戒等级',
  `shatter` bigint(20) DEFAULT '0' COMMENT '符文碎片',
  `spcshatter` bigint(20) DEFAULT '0' COMMENT '特殊符文精华',
  `knighthood_lv` int(11) unsigned DEFAULT '0' COMMENT '勋章等级',
  `togeatter` bigint(20) unsigned DEFAULT '0' COMMENT '合击装备碎片',
  `rankpower` bigint(20) unsigned DEFAULT '0' COMMENT '排行榜专用战力',
  `total_wing_lv` int(11) unsigned DEFAULT '0' COMMENT '翅膀总等级',
  `total_tujian_power` bigint(20) unsigned DEFAULT '0' COMMENT '图鉴总战力',
  `total_equip_power` bigint(20) unsigned DEFAULT '0' COMMENT '装备基础战力',
  `togeatterhigh` bigint(20) DEFAULT '0' COMMENT '高级合击装备碎片',
  `total_zhuling_level` int(11) DEFAULT '0' COMMENT ' 铸造总等级',
  `prestige_exp` int(11) DEFAULT '0' COMMENT '威望值',
  `reincarnate_lv` int(11) DEFAULT '0' COMMENT '轮回等级',
  `reincarnate_exp` int(11) DEFAULT '0' COMMENT '轮回修为',
  `appid` varchar(128) DEFAULT NULL COMMENT '渠道ID',
  `pfid` varchar(128) DEFAULT NULL COMMENT '平台ID',
  `guild_name` varchar(32) NOT NULL DEFAULT '' COMMENT '工会名',
  PRIMARY KEY (`actorid`),
  KEY `ak_key_2` (`accountid`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=9502731 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actors
-- ----------------------------

-- ----------------------------
-- Table structure for actorvariable
-- ----------------------------
DROP TABLE IF EXISTS `actorvariable`;
CREATE TABLE `actorvariable` (
  `actorid` bigint(20) NOT NULL COMMENT '玩家id',
  `variable` mediumblob COMMENT '脚本用数据data staticVar',
  `storedata` mediumblob COMMENT '商店数据',
  `together_hit_equip` mediumblob COMMENT '合击装备数据',
  `cs_variable` mediumblob COMMENT '跨服静态变量数据',
  PRIMARY KEY (`actorid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of actorvariable
-- ----------------------------

-- ----------------------------
-- Table structure for auction
-- ----------------------------
DROP TABLE IF EXISTS `auction`;
CREATE TABLE `auction` (
  `id` bigint(20) NOT NULL DEFAULT '0' COMMENT '序列号',
  `addtime` int(11) DEFAULT '0' COMMENT '上架时间',
  `guildendtime` int(11) DEFAULT '0' COMMENT '公会拍卖结束时间',
  `globalendtime` int(11) DEFAULT '0' COMMENT '全服拍卖结束时间',
  `owners` varchar(512) DEFAULT NULL COMMENT '收益者',
  `guildid` int(11) DEFAULT '0' COMMENT '公会id',
  `auctionid` int(11) DEFAULT '0' COMMENT '拍卖id',
  `bid` tinyint(4) DEFAULT '0' COMMENT '竞拍次数',
  `bidder` int(11) DEFAULT '0' COMMENT '全服竞拍者actorid',
  `gbidder` int(11) DEFAULT '0' COMMENT '公会竞拍者actorid',
  `serverid` int(11) DEFAULT '0' COMMENT '服务器id',
  `flag` int(11) DEFAULT '0' COMMENT '标记位',
  `hylimit` int(11) DEFAULT '0' COMMENT '花费活跃额度',
  `yblimit` int(11) DEFAULT '0' COMMENT '花费充值额度',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of auction
-- ----------------------------

-- ----------------------------
-- Table structure for chatmonitoring
-- ----------------------------
DROP TABLE IF EXISTS `chatmonitoring`;
CREATE TABLE `chatmonitoring` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `actorid` int(11) DEFAULT '0',
  `type` int(11) DEFAULT '0',
  `msgid` int(11) DEFAULT '0',
  `guildid` int(11) DEFAULT '0',
  `actorname` varchar(64) DEFAULT NULL COMMENT '名字',
  `account` varchar(64) DEFAULT NULL COMMENT '账号',
  `msg` varchar(128) DEFAULT NULL COMMENT '消息',
  `chat_time` int(11) DEFAULT '0',
  `server` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of chatmonitoring
-- ----------------------------

-- ----------------------------
-- Table structure for feecallback
-- ----------------------------
DROP TABLE IF EXISTS `feecallback`;
CREATE TABLE `feecallback` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0',
  `openid` varchar(124) DEFAULT NULL COMMENT '账户名',
  `itemid` int(11) DEFAULT '0' COMMENT '套餐里面的礼包的id',
  `num` int(11) DEFAULT '0' COMMENT '购买的数量',
  `token` varchar(32) DEFAULT NULL,
  `amt` int(11) DEFAULT '0',
  `actor_id` int(11) DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of feecallback
-- ----------------------------

-- ----------------------------
-- Table structure for filternames
-- ----------------------------
DROP TABLE IF EXISTS `filternames`;
CREATE TABLE `filternames` (
  `namestr` varchar(256) NOT NULL COMMENT '屏蔽词',
  PRIMARY KEY (`namestr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8 COMMENT='名称屏蔽词表';

-- ----------------------------
-- Records of filternames
-- ----------------------------

-- ----------------------------
-- Table structure for friends
-- ----------------------------
DROP TABLE IF EXISTS `friends`;
CREATE TABLE `friends` (
  `actorid` int(11) DEFAULT '0' COMMENT '角色id',
  `friendid` int(11) DEFAULT '0' COMMENT '对方id',
  `f_type` int(11) DEFAULT '0' COMMENT '类型:好友,最近联系人,申请列表,黑名单',
  `addfriendtime` int(11) DEFAULT '0' COMMENT '添加好友时间',
  `lastcontact` int(11) DEFAULT '0' COMMENT '最近联系时间',
  KEY `friends_actorid` (`actorid`) USING BTREE,
  KEY `friends_actorid_fid` (`actorid`,`f_type`,`friendid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of friends
-- ----------------------------

-- ----------------------------
-- Table structure for globalmails
-- ----------------------------
DROP TABLE IF EXISTS `globalmails`;
CREATE TABLE `globalmails` (
  `uid` bigint(20) NOT NULL AUTO_INCREMENT,
  `sendtime` int(11) DEFAULT '0',
  `head` varchar(128) DEFAULT NULL,
  `context` varchar(1024) DEFAULT NULL,
  `award` tinyblob,
  PRIMARY KEY (`uid`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of globalmails
-- ----------------------------

-- ----------------------------
-- Table structure for globaluser
-- ----------------------------
DROP TABLE IF EXISTS `globaluser`;
CREATE TABLE `globaluser` (
  `userid` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT '用户唯一id，自增字段',
  `account` varchar(64) DEFAULT NULL COMMENT '用户帐户的字符串',
  `passwd` varchar(32) DEFAULT NULL COMMENT '玩家的密码',
  `identity` varchar(32) DEFAULT NULL COMMENT '玩家的身份证号码',
  `createtime` datetime DEFAULT NULL COMMENT '帐号的创建时间',
  `updatetime` datetime DEFAULT NULL COMMENT '上次登录时间',
  `updateip` bigint(20) DEFAULT NULL COMMENT '用户上次登录的ip地址，64位整形ip地址，支持ipv6',
  `ipstr` varchar(128) DEFAULT NULL COMMENT '用户上次登录的ip地址',
  `gmlevel` int(11) DEFAULT '0' COMMENT '玩家的gm等级，普通玩家是0.gm等级越高表示权限越高。1-10级gm',
  `pwtime` bigint(20) DEFAULT '0' COMMENT '密码的有效时间，使用的是unix的时间戳，这里记录的是密码创建的时间',
  `closed` int(11) DEFAULT '0' COMMENT '用户是否被关闭，0否，1被关闭',
  `openkey` varchar(64) DEFAULT NULL,
  `pfkey` varchar(64) DEFAULT NULL,
  `manyouid` varchar(64) DEFAULT NULL,
  `pf` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`userid`),
  UNIQUE KEY `ak_key_account` (`account`) USING BTREE
) ENGINE=MyISAM AUTO_INCREMENT=121101 DEFAULT CHARSET=utf8 COMMENT='账号表';

-- ----------------------------
-- Records of globaluser
-- ----------------------------

-- ----------------------------
-- Table structure for gmcmd
-- ----------------------------
DROP TABLE IF EXISTS `gmcmd`;
CREATE TABLE `gmcmd` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0' COMMENT '服务器id',
  `cmdid` int(11) DEFAULT '0' COMMENT '命令的id',
  `cmd` varchar(256) DEFAULT NULL COMMENT '命令名称',
  `param1` varchar(256) DEFAULT NULL COMMENT '参数1',
  `param2` varchar(256) DEFAULT NULL COMMENT '参数2',
  `param3` varchar(256) DEFAULT NULL COMMENT '参数3',
  `param4` varchar(256) DEFAULT NULL COMMENT '参数4',
  `param5` varchar(256) DEFAULT NULL COMMENT '参数5',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=46 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of gmcmd
-- ----------------------------

-- ----------------------------
-- Table structure for gmcmd_cdk
-- ----------------------------
DROP TABLE IF EXISTS `gmcmd_cdk`;
CREATE TABLE `gmcmd_cdk` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0' COMMENT '服务器id',
  `cmdid` int(11) DEFAULT '0' COMMENT '命令的id',
  `cmd` varchar(256) DEFAULT NULL COMMENT '命令名称',
  `param1` varchar(256) DEFAULT NULL COMMENT '参数1',
  `param2` varchar(256) DEFAULT NULL COMMENT '参数2',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of gmcmd_cdk
-- ----------------------------

-- ----------------------------
-- Table structure for gmcmd_log
-- ----------------------------
DROP TABLE IF EXISTS `gmcmd_log`;
CREATE TABLE `gmcmd_log` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0' COMMENT '服务器id',
  `cmdid` int(11) DEFAULT '0' COMMENT '命令的id',
  `cmd` varchar(256) DEFAULT NULL COMMENT '命令名称',
  `param1` varchar(256) DEFAULT NULL COMMENT '参数1',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of gmcmd_log
-- ----------------------------

-- ----------------------------
-- Table structure for guildchat
-- ----------------------------
DROP TABLE IF EXISTS `guildchat`;
CREATE TABLE `guildchat` (
  `guildid` int(11) DEFAULT NULL COMMENT '公会id',
  `type` int(11) DEFAULT '0' COMMENT '类型',
  `date` int(11) DEFAULT '0' COMMENT '时间',
  `actorid` int(11) DEFAULT NULL COMMENT '玩家id',
  `content` varchar(128) DEFAULT NULL COMMENT '聊天内容',
  KEY `guildchat_guildid` (`guildid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of guildchat
-- ----------------------------

-- ----------------------------
-- Table structure for guildlist
-- ----------------------------
DROP TABLE IF EXISTS `guildlist`;
CREATE TABLE `guildlist` (
  `guildid` int(11) NOT NULL COMMENT '公会的id',
  `guildname` varchar(32) DEFAULT NULL COMMENT '公会的名字',
  `serverindex` int(11) DEFAULT NULL COMMENT '公会所在的服务器编号',
  `variable` mediumblob COMMENT '保存脚本二进制数据',
  `variable2` mediumblob COMMENT '保存脚本二进制数据',
  `variable3` mediumblob COMMENT '保存脚本二进制数据',
  `changenamenum` int(10) DEFAULT '0' COMMENT '可改名次数'
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of guildlist
-- ----------------------------

-- ----------------------------
-- Table structure for guildlog
-- ----------------------------
DROP TABLE IF EXISTS `guildlog`;
CREATE TABLE `guildlog` (
  `guildid` int(11) DEFAULT NULL COMMENT '公会id',
  `date` int(11) DEFAULT '0' COMMENT '日期',
  `type` int(11) DEFAULT '0' COMMENT '类型',
  `param1` int(11) DEFAULT '0' COMMENT '参数1',
  `param2` int(11) DEFAULT '0' COMMENT '参数2',
  `param3` int(11) DEFAULT '0' COMMENT '参数3',
  `enname1` varchar(32) DEFAULT NULL COMMENT '玩家名字1',
  `enname2` varchar(32) DEFAULT NULL COMMENT '玩家名字2',
  KEY `guildlog_guildid_date` (`guildid`,`date`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of guildlog
-- ----------------------------

-- ----------------------------
-- Table structure for guildstorelog
-- ----------------------------
DROP TABLE IF EXISTS `guildstorelog`;
CREATE TABLE `guildstorelog` (
  `logdate` int(10) unsigned DEFAULT '0' COMMENT '日期',
  `guildid` int(11) DEFAULT '0' COMMENT '公会id',
  `actorid` int(11) DEFAULT '0' COMMENT '玩家id',
  `itemid` int(11) DEFAULT '0' COMMENT '道具id',
  UNIQUE KEY `logdate` (`logdate`,`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of guildstorelog
-- ----------------------------

-- ----------------------------
-- Table structure for items
-- ----------------------------
DROP TABLE IF EXISTS `items`;
CREATE TABLE `items` (
  `uid` bigint(20) NOT NULL COMMENT '物品唯一id',
  `actorid` int(10) NOT NULL COMMENT '玩家id',
  `bag_type` int(4) unsigned NOT NULL COMMENT '背包类型',
  `id` int(10) unsigned NOT NULL COMMENT '物品配置id',
  `count` int(10) unsigned NOT NULL COMMENT '物品数量',
  `attrs` tinyblob COMMENT '物品属性',
  KEY `key2` (`actorid`) USING BTREE,
  KEY `key1` (`uid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of items
-- ----------------------------

-- ----------------------------
-- Table structure for mails
-- ----------------------------
DROP TABLE IF EXISTS `mails`;
CREATE TABLE `mails` (
  `uid` bigint(20) NOT NULL COMMENT '邮件ID',
  `actorid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `readstatus` int(11) DEFAULT '0' COMMENT '邮件读取状态',
  `sendtime` int(11) DEFAULT '0' COMMENT '发信的unix时间',
  `head` varchar(128) DEFAULT NULL COMMENT '邮件标题',
  `context` varchar(1024) DEFAULT NULL COMMENT '邮件内容',
  `award` tinyblob COMMENT '保存附件二进制数据',
  `awardstatus` int(11) DEFAULT '0' COMMENT '邮件领奖状态',
  KEY `key1` (`actorid`) USING BTREE,
  KEY `key2` (`uid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of mails
-- ----------------------------

-- ----------------------------
-- Table structure for offlinemails
-- ----------------------------
DROP TABLE IF EXISTS `offlinemails`;
CREATE TABLE `offlinemails` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT '邮件ID',
  `actorid` int(11) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `head` varchar(128) DEFAULT NULL COMMENT '邮件标题',
  `context` varchar(1024) DEFAULT NULL COMMENT '邮件内容',
  `file0_type` int(11) DEFAULT '0' COMMENT '类型',
  `file0_id` int(11) DEFAULT '0' COMMENT 'ID',
  `file0_num` int(11) DEFAULT '0' COMMENT '数量',
  PRIMARY KEY (`id`),
  KEY `key1` (`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of offlinemails
-- ----------------------------

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles` (
  `actorid` int(11) NOT NULL DEFAULT '0' COMMENT '角色id',
  `roleid` int(4) NOT NULL DEFAULT '1' COMMENT '子角色序号',
  `job` tinyint(4) DEFAULT NULL COMMENT '职业 ',
  `sex` tinyint(4) DEFAULT NULL COMMENT '性别',
  `power` bigint(20) DEFAULT NULL COMMENT '战力',
  `skill_data` tinyblob COMMENT '技能数据',
  `wing_data` tinyblob COMMENT '翅膀数据,lv,star,exp',
  `wing_equip` mediumblob COMMENT '翅膀装备',
  `equips_data` mediumblob COMMENT '装备数据',
  `ex_rings_data` tinyblob COMMENT '特戒数据',
  `jingmai_data` tinyblob COMMENT '经脉数据',
  `loogsoul_data` tinyblob COMMENT '龙魂数据',
  `fuwen_data` blob COMMENT '符文数据',
  `heirloom` tinyblob COMMENT '传世装备等级',
  `weapon_soul_id` int(11) unsigned DEFAULT '0' COMMENT '使用的兵魂ID',
  KEY `key1` (`actorid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of roles
-- ----------------------------

-- ----------------------------
-- Table structure for servercmd
-- ----------------------------
DROP TABLE IF EXISTS `servercmd`;
CREATE TABLE `servercmd` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0' COMMENT '服务器id',
  `cmdid` int(11) DEFAULT '0' COMMENT '命令的id',
  `cmd` varchar(256) DEFAULT NULL COMMENT '命令名称',
  `param1` varchar(256) DEFAULT NULL COMMENT '参数1',
  `param2` varchar(256) DEFAULT NULL COMMENT '参数2',
  `param3` varchar(256) DEFAULT NULL COMMENT '参数3',
  `param4` varchar(256) DEFAULT NULL COMMENT '参数4',
  `param5` varchar(256) DEFAULT NULL COMMENT '参数5',
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of servercmd
-- ----------------------------

-- ----------------------------
-- Table structure for sysvar
-- ----------------------------
DROP TABLE IF EXISTS `sysvar`;
CREATE TABLE `sysvar` (
  `actorid` int(11) DEFAULT NULL COMMENT '玩家id',
  `actorname` varchar(32) DEFAULT NULL COMMENT '玩家名字',
  `sysid` int(11) DEFAULT '0' COMMENT '系统号',
  `var` mediumblob COMMENT '保存脚本二进制数据',
  KEY `sysvar_actorid_sysid` (`actorid`,`sysid`) USING BTREE
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of sysvar
-- ----------------------------

-- ----------------------------
-- Table structure for txapimsg
-- ----------------------------
DROP TABLE IF EXISTS `txapimsg`;
CREATE TABLE `txapimsg` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serverid` int(11) DEFAULT '0',
  `openid` varchar(128) DEFAULT NULL COMMENT '账户名',
  `type` int(11) DEFAULT '0',
  `para1` varchar(64) DEFAULT NULL COMMENT '参数1',
  `para2` varchar(64) DEFAULT NULL,
  `para3` varchar(64) DEFAULT NULL,
  `para4` varchar(64) DEFAULT NULL,
  `para5` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of txapimsg
-- ----------------------------

-- ----------------------------
-- Procedure structure for addcharmsg
-- ----------------------------
DROP PROCEDURE IF EXISTS `addcharmsg`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addcharmsg`(in nactorid integer, in nsrvid integer, in sactorname varchar(64), in saccountname varchar(80), in smsg varbinary(4096))
begin
    declare actid int;
    if nactorid != 0 then
      insert into actormsg(actorid,msg) values(nactorid, smsg);
      select last_insert_id();
    else
      if sactorname is not null  and  sactorname != '' then
          select actorid into actid from actors where nsvridx=nsrvid and actorname=sactorname;
          if (actid is not null) then
              insert into actormsg(actorid, msg) values(actid, smsg);
              select last_insert_id();
          end if;
      else
         if saccountname is not null and  saccountname != '' then
             select actorid into actid from actors where nsvridx=nsrvid and accountname=saccountname and (status & 2)=2 limit 1;
             if (actid is not null) then
                 insert into actormsg(actorid, msg) values(actid, smsg);
                 select last_insert_id();
             end if;
         end if;
      end if;
    end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for addchatmonitoring
-- ----------------------------
DROP PROCEDURE IF EXISTS `addchatmonitoring`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addchatmonitoring`(aid integer, itype integer, imsgid integer, iguild integer, 
	iactorname varchar(64), iaccount varchar(64), imsg varchar(128), ctime int, iserver integer)
begin
  insert into chatmonitoring(actorid, type, msgid, guildid, actorname, account, msg, chat_time, server) values 
	(aid, itype, imsgid, iguild,iactorname, iaccount, imsg, ctime, iserver);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for addguildlog
-- ----------------------------
DROP PROCEDURE IF EXISTS `addguildlog`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addguildlog`(iguild integer, idate integer, itype integer, iparam1 integer, iparam2 integer, iparam3 integer, iname1 varchar(32), iname2 varchar(32))
begin
  insert into guildlog(guildid, date, type, param1, param2, param3, enname1, enname2) values (iguild, idate, itype, iparam1, iparam2, iparam3, iname1, iname2);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for addguildmember
-- ----------------------------
DROP PROCEDURE IF EXISTS `addguildmember`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addguildmember`(in ngid integer,in nactorid integer,in npos integer)
begin
    declare actid int;
	select actorid into actid from actorguild where actorid = nactorid;
	if actid is null then
      insert into actorguild(actorid,guildid,pos) values(nactorid,ngid,npos);
	else
	  update actorguild set guildid=ngid, pos=npos where actorid=nactorid;
	end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for addoldnamelist
-- ----------------------------
DROP PROCEDURE IF EXISTS `addoldnamelist`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addoldnamelist`(in in_actorid integer,in in_oldname varchar(32),in in_serveridx integer)
begin
    declare cnt integer;
    select count(*) into cnt from actoroldname where `actorid` = in_actorid and `oldname` = in_oldname;
    if cnt <= 0 then
      insert into actoroldname(`actorid`, `oldname`, `serverindex`) values(in_actorid, in_oldname, in_serveridx);
    end if;

end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for addsysvar
-- ----------------------------
DROP PROCEDURE IF EXISTS `addsysvar`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `addsysvar`(aid integer, aname varchar(32), sid integer, vdata mediumblob)
begin
   declare actid int;
   select actorid into actid from sysvar where actorid = aid and sysid = sid;
   if actid is null then
      insert into sysvar(actorid, actorname, sysid, var) values (aid, aname, sid, vdata);
   end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for clientstartplay
-- ----------------------------
DROP PROCEDURE IF EXISTS `clientstartplay`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `clientstartplay`(in nserverindex integer,
  in ncharid integer,
  in saccount varchar(64),
  in naccountid integer,
  in ip    bigint unsigned)
begin
  declare boexists integer default 0;
    declare ncharstate integer default 0;
    select actorid, status into boexists, ncharstate
    from actors
    where actorid = ncharid and
        accountname = saccount and (status & 2)=2  limit 1;
    
    if (boexists <> 0) then
        
        
        
        update actors
        set status = (status | 4),lastloginip=ip
        where accountname = saccount and
              (status & 2)=2  and
              actorid = ncharid;
        select 1;
    else
        select 0;
    end if;
 end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for createguild
-- ----------------------------
DROP PROCEDURE IF EXISTS `createguild`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `createguild`(in ngid integer,
    in sguildname varchar(32),
    in nserverindex integer)
begin
    insert into guildlist(guildid,guildname,serverindex)
      values(ngid, sguildname, nserverindex);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for createnewactor
-- ----------------------------
DROP PROCEDURE IF EXISTS `createnewactor`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `createnewactor`(in naccountid integer,
in saccountname varchar(64),
in nserverid integer,
in nactorid integer,
in sname varchar(32),
in njob integer,
in nsex integer)
begin
 declare boexists integer default null;
     insert into actors(`accountid`,`accountname`,`actorid`,`actorname`,`status`,`updatetime`,`createtime`,`serverindex`,`job`,`sex`)
     values(naccountid,saccountname, nactorid,sname, 2,now(),now(),nserverid,njob,nsex);
		 insert into roles(`actorid`,`roleid`,`job`,`sex`)
		  values(nactorid, 0, njob, nsex);
     insert into actorbinarydata(actorid) values(nactorid);
     insert into actorvariable(actorid) values(nactorid);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for deletecharmsg
-- ----------------------------
DROP PROCEDURE IF EXISTS `deletecharmsg`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `deletecharmsg`(in nactorid integer, in nmsgid bigint)
begin
     delete  from  actormsg where msgid=nmsgid and actorid=nactorid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for deleteguild
-- ----------------------------
DROP PROCEDURE IF EXISTS `deleteguild`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `deleteguild`(in ngid integer)
begin
delete from guildlist where guildid=ngid;
delete from actorguild where guildid=ngid;
delete from guildlog where guildid=ngid;
delete from guildchat where guildid=ngid;
update actors set guildid=0 where guildid=ngid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for delfeecallback
-- ----------------------------
DROP PROCEDURE IF EXISTS `delfeecallback`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delfeecallback`(in nid int)
begin
    delete from feecallback where id = nid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for delfriend
-- ----------------------------
DROP PROCEDURE IF EXISTS `delfriend`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delfriend`(in nactorid integer, in nfriendid integer, in nftype integer)
begin
  delete from friends where actorid=nactorid and friendid = nfriendid and f_type = nftype;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for delgmcmd
-- ----------------------------
DROP PROCEDURE IF EXISTS `delgmcmd`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delgmcmd`(in nid integer)
begin
    delete from gmcmd where id=nid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for delguildlog
-- ----------------------------
DROP PROCEDURE IF EXISTS `delguildlog`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delguildlog`(in iguild integer, in idate integer)
begin
    delete from guildlog where guildid = iguild and date = idate;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for delguildmember
-- ----------------------------
DROP PROCEDURE IF EXISTS `delguildmember`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `delguildmember`(in nactorid integer)
begin
delete from actorguild  where actorid=nactorid;
update actors set guildid=0 where actorid=nactorid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for deltxapimsg
-- ----------------------------
DROP PROCEDURE IF EXISTS `deltxapimsg`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `deltxapimsg`(in nid int)
begin
    delete from txapimsg where id = nid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for getactoridfromactorname
-- ----------------------------
DROP PROCEDURE IF EXISTS `getactoridfromactorname`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getactoridfromactorname`(in nserverindex integer, in objname varchar(32))
begin
     select actorid from actors where actorname=objname and serverindex=nserverindex;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for getcharactoridbyname
-- ----------------------------
DROP PROCEDURE IF EXISTS `getcharactoridbyname`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `getcharactoridbyname`(in sname varchar(32), in nserverindex integer)
begin
    select actorid from actors where actorname=sname and serverindex=nserverindex;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for initdb
-- ----------------------------
DROP PROCEDURE IF EXISTS `initdb`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `initdb`(in nserverindex integer)
begin
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadactorbasic
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadactorbasic`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadactorbasic`(IN `nactorid` integer)
BEGIN
	
	select level,exp,baggridcount,gold,yuanbao,totalpower,paid,fbhandle,sceneid,
   createtime,lastlogouttime,totalonline,dailyonline
  from actors 
  where actorid=nactorid and (status & 2)=2 ;
END
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadallactorname
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadallactorname`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadallactorname`(in serverid integer)
begin
select actorname from actors where serverindex=serverid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadcharmsglist
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadcharmsglist`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadcharmsglist`(in nactorid integer,in nmsgid bigint)
begin
    if nmsgid = 0 then
        select msgid,msg from actormsg where actorid=nactorid;
    else
        select msgid,msg from actormsg where actorid=nactorid and msgid=nmsgid;
    end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadfee
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadfee`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadfee`(in nsid int)
begin
    select openid,itemid,num,id,actor_id,token from feecallback where serverid = nsid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadfilternames
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadfilternames`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadfilternames`()
begin
  select namestr from filternames;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadfriends
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadfriends`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadfriends`(in nactorid integer)
begin
  select friendid, f_type, addfriendtime, lastcontact from friends where actorid = nactorid order by f_type;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadgiftitem
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadgiftitem`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadgiftitem`()
begin
    select id,itemid,needgrid,itemname,itemdesc,icon,dup,flag,grouptype,time,cond_cons_id,cond_cons_count,cond_money_type,cond_money_count,cond_value_str from giftsitem;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadgiftitemconfig
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadgiftitemconfig`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadgiftitemconfig`()
begin
    select id, giftitemid, rewardtype, type, amount, itemid, bind, groupid, rate, noworldrate, quality, strong from giftsitemconfig;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadgmcmd
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadgmcmd`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadgmcmd`(in nserverid integer)
begin
    select id,cmd, param1, param2, param3, param4, param5,cmdid from gmcmd where serverid=nserverid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadgmquestion
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadgmquestion`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadgmquestion`(in nid bigint)
begin
   select id, actorid, answer, answertime from gmquestion where id = nid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadgmquestions
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadgmquestions`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadgmquestions`(in nactorid integer)
begin
   select id, status,hasread, title, type, question, questiontime, answer,answertime from gmquestion
   where actorid = nactorid order by questiontime;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadguildbasicdata
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadguildbasicdata`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadguildbasicdata`(in nserverindex integer)
begin
   select guildid,guildname,changenamenum,variable,variable2,variable3 from guildlist where serverindex=nserverindex;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadguildlog
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadguildlog`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadguildlog`(in iguild integer)
begin
    select guildid, date, type, param1, param2, param3, enname1, enname2 from guildlog where guildid = iguild order by date asc limit 100;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadguildmembers
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadguildmembers`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadguildmembers`(in ngid integer)
begin
select actors.actorid, actorname, pos, total_contrib, today_contrib, actors.sex, actors.job, actors.level, actors.totalpower,actors.lastonlinetime, actors.vip_level, actors.monthcard, actors.zhuansheng_lv from
  actorguild,guildlist,actors where actorguild.guildid=ngid and actorguild.guildid=guildlist.guildid and actors.actorid=actorguild.actorid
  and (actors.status & 2) = 2;
 end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadmaxactoridseries
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadmaxactoridseries`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadmaxactoridseries`(in serverid integer)
begin
select max(actorid >> 16) from actors where serverindex=serverid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadsysvar
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadsysvar`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadsysvar`()
begin
    select actorid, actorname, sysid, var from sysvar;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for loadtxapimsg
-- ----------------------------
DROP PROCEDURE IF EXISTS `loadtxapimsg`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `loadtxapimsg`(in nsid int)
begin
    select openid, type, para1, para2, para3,para4,para5,id from txapimsg where serverid = nsid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for logingetglobaluser
-- ----------------------------
DROP PROCEDURE IF EXISTS `logingetglobaluser`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `logingetglobaluser`(in actorname  varchar(64))
select  userid, passwd, updatetime, updateip,gmlevel,pwtime from globaluser where account = actorname;
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for resetcrosspos
-- ----------------------------
DROP PROCEDURE IF EXISTS `resetcrosspos`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `resetcrosspos`(in nactorid integer)
begin
   update actors set cw_fbhdl_sid=0, cw_scene_xy=0,cw_static_pos=0 where actorid =nactorid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for savefeecallback
-- ----------------------------
DROP PROCEDURE IF EXISTS `savefeecallback`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `savefeecallback`(in nserverid int, in sopenid varchar(124), in nitemid int, in nnum int
                  , in namt int)
begin
    insert into feecallback(serverid, openid, itemid, num, amt) values(nserverid, sopenid, nitemid, nnum, namt);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for savetxapimsg
-- ----------------------------
DROP PROCEDURE IF EXISTS `savetxapimsg`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `savetxapimsg`(in nserverid int, in sopenid varchar(124), in ntype int, in spara1 varchar(64)
                  , in spara2 varchar(64), in spara3 varchar(64), in spara4 varchar(64), in spara5 varchar(64))
begin
    insert into txapimsg(serverid, openid, type, para1, para2, para3,para4,para5)
      values(nserverid, sopenid, ntype, spara1, spara2, spara3,spara4,spara5);
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updateactorlogin
-- ----------------------------
DROP PROCEDURE IF EXISTS `updateactorlogin`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateactorlogin`(in actorname varchar(64), in sid int)
begin
    declare logintime datetime;
    select lastlogin into logintime from actorlogin where account=actorname and serverid=sid;
    if (logintime is not null) then
        update actorlogin set lastlogin=now() where account=actorname and serverid=sid;
        if datediff(logintime, now()) = 0 then
            select 1;
        else
            select 2;
        end if;
    else
        insert into actorlogin(account, lastlogin, serverid) values (actorname, now(), sid);
        select 0;
    end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updatecharbasicdata
-- ----------------------------
DROP PROCEDURE IF EXISTS `updatecharbasicdata`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatecharbasicdata`(in nactorid integer,in nposx integer,in nposy integer,in nsex integer ,in njob integer,
in nlevel integer,in nicon integer, in nlexp bigint, in nfbhandle integer, in nsceneid integer,
in npkvalue integer,
in nweekcharm integer,
in nbaggridcount integer,
in nbindcoin integer,
in nbindyuanbao integer,
in nnonbindcoin integer,
in nnonbindyuanbao integer,
in nxiuwei integer,
in nhp integer,
in nmp integer,
in ncharm integer,
in nrenown integer,
in nguildid integer,
in nteamid integer,
in nsocialmask integer,
in nguildexp integer,
in nlastlogouttime integer,
in nfbteamid integer,
in nfightvalue integer,
in nrecharge integer,
in nenterfbsceneid integer,
in nenterfbpos integer,
in ndirrelated integer,
in nsystemopen integer,
in njumppower integer,
in depotgridcount integer,
in anger integer,
in root_exp integer,
in csrevivepoint bigint,
in fbrevivepoint bigint,
in cityrevivepoint bigint,
in achievepoint integer,
in zycont integer,
in curtitleid integer,
in wingid integer,
in wing_score integer,
in pet_score integer,
in freebaptize integer,
in nonekeyfriend integer,
in zy integer,
in nmountscore integer,
in friendcong integer,
in rootdata integer,
in gemscore integer,
in hp_store integer,
in mp_store integer,
in nhonor integer,
in ndragon integer,
in ngiveyb integer,
in nwar_team_id integer,
in ncw_fbhdl_sid bigint,
in ncw_scene_xy bigint,
in ncw_static_pos bigint,
in ncrosshonor integer,
in petcross integer,
in upgrade_time integer,
in weapon integer,
in model integer,
in hair integer,
in stone_effect integer,
in stage_effect integer,
in wing integer,
in achieve_time integer,
in jingjie_title integer,
in vip_level integer,
in ntotal_online integer,
in ndaily_online integer,
in zm_coin integer,
in quest varbinary(1000),
in cmis_data varchar(128))
begin
  update actors set `icon`=nicon,`sex`=nsex,`level`=nlevel,`job`=njob,`posx`=nposx,`posy`=nposy,`exp`=nlexp,`fbhandle`=nfbhandle,`sceneid`=nsceneid,
  `pkvalue`=npkvalue,
  `baggridcount`=nbaggridcount,
  `weekcharm`=nweekcharm,
  `bindcoin`=nbindcoin,
  `bindyuanbao`=nbindyuanbao,
  `nonbindyuanbao`=nnonbindyuanbao,
  `nonbindcoin`=nnonbindcoin,
  `xiuwei`=nxiuwei,
  `hp`=nhp,
  `mp`=nmp,
  `charm`=ncharm,
  `renown`= nrenown,
  `guildid`=nguildid,
  `teamid`=nteamid,
   `socialmask`=nsocialmask,
  `guildexp`=nguildexp,
  `lastlogouttime`=nlastlogouttime,
  `fbteamid`=nfbteamid,
  `fightvalue`=nfightvalue,
  `recharge`=nrecharge,
  `enterfbsceneid`=nenterfbsceneid,
  `enterfbpos`=nenterfbpos,
  `dirrelated`=ndirrelated,
  `systemopen`=nsystemopen,
 `updatetime`=now(),
 `jumppower`=njumppower,
 `depotgridcount`=depotgridcount,
 `anger`=anger,
 `root_exp`=root_exp,
 `csrevivepoint`=csrevivepoint,
 `fbrevivepoint`=fbrevivepoint,
 `cityrevivepoint`=cityrevivepoint,
 `achievepoint`=achievepoint,
 `zycont`=zycont,
 `curtitleid`=curtitleid,
  `wingid`=wingid,
  `wing_score`=wing_score,
  `pet_score`=pet_score,
  `freebaptize`=freebaptize,
  `onekeyfriend`=nonekeyfriend,
  `zy` =zy,
  `mountscore`=nmountscore,
  `friendcong`=friendcong,
  `rootdata`=rootdata,
  `gemscore`=gemscore,
  `hp_store`=hp_store,
  `mp_store`=mp_store,
  `honor`=nhonor,
  `param1`=ndragon,
  `param2`=ngiveyb,
  `param3`=nwar_team_id,
  `cw_fbhdl_sid`=ncw_fbhdl_sid,
  `cw_scene_xy`=ncw_scene_xy,
  `cw_static_pos`=ncw_static_pos,
  `crosshonor`=ncrosshonor,
  `petcross` = petcross,
  `lastupgradettime` = upgrade_time,
  `weapon` = weapon,
  `model` = model,
  `hair` = hair,
  `stone_effect` = stone_effect,
  `stage_effect` = stage_effect,
  `wing` = wing,
  `achieve_time` = achieve_time,
  `jingjie_title` = jingjie_title,
  `vip_level` = vip_level,
  `totalonline` = ntotal_online,
  `dailyonline` = ndaily_online,
  `zm_coin` = zm_coin,
  `mis_data` = cmis_data
  where `actorid`=nactorid limit 1;
  update actorbinarydata set `quest`=quest  where `actorid`=nactorid limit 1;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updatefriends
-- ----------------------------
DROP PROCEDURE IF EXISTS `updatefriends`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatefriends`(in nactorid integer, in nfriendid integer, in nftype integer,in naddfriendtime integer, in nlastcontact integer)
begin
  declare aid int;
  
  select actorid into aid from friends where actorid=nactorid and friendid = nfriendid and f_type = nftype;

  if aid is null then
    insert into friends(actorid,friendid,f_type,addfriendtime,lastcontact) values(nactorid, nfriendid, nftype,naddfriendtime,nlastcontact);
  else
    update friends set lastcontact=nlastcontact where actorid=nactorid and friendid = nfriendid and f_type = nftype;
  end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updateglobaluserlogin
-- ----------------------------
DROP PROCEDURE IF EXISTS `updateglobaluserlogin`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateglobaluserlogin`(in nsessionid integer,
    in loginip bigint)
begin
     declare boexists integer default null;
     set boexists = (select count(`userid`)  from globaluser
      where `userid`=nsessionid
             limit 1
            );
    if boexists = 1 then
         update globaluser set `updatetime` = now(),`updateip`= loginip  where `userid` = nsessionid;
    else
        select "not exists.";
    end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updategmquestion
-- ----------------------------
DROP PROCEDURE IF EXISTS `updategmquestion`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updategmquestion`(in nid bigint)
begin
   update gmquestion set hasread = 1 where id = nid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updateguildbasedata
-- ----------------------------
DROP PROCEDURE IF EXISTS `updateguildbasedata`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateguildbasedata`(in gid integer, in changecount integer, in name varchar(64))
begin
    update guildlist set `changenamenum`=changecount, `guildname`=name where guildid=gid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updateguildmember
-- ----------------------------
DROP PROCEDURE IF EXISTS `updateguildmember`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateguildmember`(in ngid integer, in nactorid integer,in ntotal_contrib integer,in ntoday_contrib integer,
            in npos integer)
begin
update actorguild set pos=npos, total_contrib=ntotal_contrib, today_contrib=ntoday_contrib where actorid=nactorid and guildid=ngid;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updateguildvar
-- ----------------------------
DROP PROCEDURE IF EXISTS `updateguildvar`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updateguildvar`(in ngid integer,in varid integer,in vardata mediumblob)
begin
    if varid = 0 then
        update guildlist set variable = vardata where guildid=ngid; 
    else 
        if varid = 1 then
            update guildlist set variable2 = vardata where guildid=ngid; 
        else
            update guildlist set variable3 = vardata where guildid=ngid; 
        end if;
    end if;
end
;;
DELIMITER ;

-- ----------------------------
-- Procedure structure for updatesysvar
-- ----------------------------
DROP PROCEDURE IF EXISTS `updatesysvar`;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `updatesysvar`(aid integer, sid integer, vdata mediumblob)
begin
    update sysvar set var = vdata where actorid = aid and sysid = sid;
end
;;
DELIMITER ;

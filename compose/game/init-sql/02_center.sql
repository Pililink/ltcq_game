/*
Navicat MySQL Data Transfer

Source Server         : localhost_3306
Source Server Version : 50553
Source Host           : localhost:3306
Source Database       : 2

Target Server Type    : MYSQL
Target Server Version : 50553
File Encoding         : 65001

Date: 2021-02-25 19:50:14
*/

SET FOREIGN_KEY_CHECKS=0;

CREATE DATABASE IF NOT EXISTS center CHARACTER SET utf8 COLLATE utf8_general_ci;;
USE center;

-- ----------------------------
-- Table structure for code_log
-- ----------------------------
DROP TABLE IF EXISTS `code_log`;
CREATE TABLE `code_log` (
  `idx` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdkey` varchar(32) DEFAULT NULL COMMENT '激活码',
  `gift` varchar(16) DEFAULT NULL COMMENT '配置编号',
  `account` varchar(80) DEFAULT NULL COMMENT '账户名',
  `updatetime` datetime DEFAULT '2019-01-01 00:00:00',
  PRIMARY KEY (`idx`),
  KEY `index_cdkey` (`cdkey`),
  KEY `index_account` (`account`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of code_log
-- ----------------------------

-- ----------------------------
-- Table structure for giftcode
-- ----------------------------
DROP TABLE IF EXISTS `giftcode`;
CREATE TABLE `giftcode` (
  `idx` bigint(20) NOT NULL AUTO_INCREMENT,
  `cdkey` varchar(32) DEFAULT NULL COMMENT '激活码',
  `gift` varchar(16) DEFAULT NULL COMMENT '配置编号',
  `status` int(11) DEFAULT '0' COMMENT '使用情况',
  `amount` int(11) DEFAULT '0' COMMENT ' 兑换码金额',
  `updatetime` datetime DEFAULT '2019-01-01 00:00:00',
  PRIMARY KEY (`idx`),
  KEY `index_cdkey` (`cdkey`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of giftcode
-- ----------------------------

-- ----------------------------
-- Table structure for recharge
-- ----------------------------
DROP TABLE IF EXISTS `recharge`;
CREATE TABLE `recharge` (
  `idx` bigint(20) NOT NULL AUTO_INCREMENT,
  `account` varchar(80) DEFAULT NULL COMMENT '账户名',
  `payno` varchar(128) DEFAULT NULL COMMENT '游戏订单号',
  `orderno` varchar(128) DEFAULT NULL COMMENT 'sdk订单号',
  `amount` int(11) DEFAULT '0' COMMENT '充值数目',
  `itemid` varchar(10) NOT NULL DEFAULT '' COMMENT '限时礼包id',
  `charged` int(11) DEFAULT '0' COMMENT '是否到账',
  `server` int(11) DEFAULT '0' COMMENT '服务器编号',
  `actorid` int(11) DEFAULT '0' COMMENT '角色id',
  `platform` varchar(32) DEFAULT NULL COMMENT '平台',
  `rechargetime` datetime DEFAULT '2019-01-01 00:00:00',
  `is_giftbag` tinyint(4) NOT NULL DEFAULT '0' COMMENT '充值类型 0基本充值 1限时礼包 2月卡',
  `via` tinyint(4) NOT NULL DEFAULT '0' COMMENT '子渠道',
  `is_test` tinyint(4) NOT NULL DEFAULT '0' COMMENT '0：否 1：是',
  PRIMARY KEY (`idx`),
  UNIQUE KEY `uni_orderpf` (`orderno`,`platform`) USING BTREE,
  KEY `index_server` (`server`),
  KEY `index_account` (`account`),
  KEY `index_actorid` (`actorid`),
  KEY `index_time` (`rechargetime`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of recharge
-- ----------------------------

-- ----------------------------
-- Table structure for serverlist
-- ----------------------------
DROP TABLE IF EXISTS `serverlist`;
CREATE TABLE `serverlist` (
  `idx` bigint(20) NOT NULL AUTO_INCREMENT,
  `account` varchar(80) DEFAULT NULL COMMENT '账户名',
  `srvid` varchar(16) DEFAULT NULL COMMENT '服务器编号',
  `updatetime` datetime DEFAULT '2019-01-01 00:00:00',
  PRIMARY KEY (`idx`),
  UNIQUE KEY `idxunique_acount_srvid` (`account`,`srvid`),
  KEY `index_account` (`account`)
) ENGINE=MyISAM AUTO_INCREMENT=82 DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of serverlist
-- ----------------------------

--暗殿boss(游戏服)
module("darkhallbosssystem", package.seeall)

--[[全局变量
	[配置id] = {
		bossRefreshTime  boss剩余刷新时间，0表示已刷新
		fbHandle     副本句柄
		srvId        服务器id
	}
]]

--[[玩家跨服数据
darkhallboss={
	bossbelongleftcount 剩余归属次数
	bossbelongbuycount 今日购买的归属次数
	resBelongCountTime 最近一次刷新归属者次数时间
	scene_cd				下次进入副本的时间
	resurgence_cd  	复活cd
	rebornEid 		复活定时器句柄
	bossReward      boss归属奖励
	id   			当前进入的副本配置id
	needCost        复活需要扣的元宝
	clientset = {
		confid, 
		...
	}
}

	
]]

local function sendTip(actor,tipmsg, type)
	--[[
	local msgtype = 4
	if(type) then
		msgtype = type
	end
	LActor.sendTipmsg(actor, tipmsg .. " SERVER DEBUG", msgtype)
	]]
end

local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:darkhallbosssystem." .. errlog .. " actorid:" .. actorid)
end

local function LOGINFO(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[INFO]:darkhallbosssystem." .. log .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:darkhallbosssystem." .. log .. " actorid:" .. actorid)
	]]
end

globalDarkhallBossData = globalDarkhallBossData or {} -- 暗殿BOSS信息,与跨服文件共用

local function getGlobalData()
	return globalDarkhallBossData
end

function getSystemData()
	local data = System.getStaticVar()
	if not data.darkhallboss then data.darkhallboss = {} end

	return data.darkhallboss
end

local function getCrossStaticData(actor)
    local var = LActor.getCrossVar(actor)
    if nil == var.darkhallboss then var.darkhallboss = {} end
    return var.darkhallboss
end

--[[
    @desc: 获取今日购买的归属次数
    author:{author}
    time:2020-04-09 16:46:33
    --@actor: 
    @return:
]]
local function getBossBelongBuyCount(actor)
	local data = getCrossStaticData(actor)
	return data.bossbelongbuycount or 0
end

--[[
    @desc: 设置今日购买的归属次数
    author:{author}
    time:2020-04-09 16:46:33
    --@actor: 
    @return:
]]
local function setBossBelongBuyCount(actor,count)
	local data = getCrossStaticData(actor)
	data.bossbelongbuycount = count
end

--[[
    @desc: 剩余可归属次数
    author:{author}
    time:2020-04-09 17:03:54
    --@actor: 
    @return:
]]
local function getBossBelongLeftCount(actor)
	local data = getCrossStaticData(actor)
	return data.bossbelongleftcount or 0
end

function setBossBelongLeftCount(actor,count)
	local data = getCrossStaticData(actor)
	data.bossbelongleftcount = count
end

--[[
    @desc: 增加一次归属次数
    author:{author}
    time:2020-04-16 11:10:08
    --@actor: 
    @return:
]]
local function addBossBelongLeftCount(actor)
	local data = getCrossStaticData(actor)
	data.bossbelongleftcount = (data.bossbelongleftcount or 0)+1 
end

--[[
    @desc: 使用道具增加归属次数
    author:{author}
    time:2020-04-20 10:08:53
    --@actor:
	--@count: 使用道具的数量/增加归属的次数
    @return:返回实际使用掉的数量
]]
function itemAddBossBelongLeftCount(actor, itemId, count)
	local leftCount = getBossBelongLeftCount(actor)
	local useCount = 0 -- 使用掉的数量
	if(leftCount + count > CrossBossBase.darkhallbossBelongMaxCount) then
		setBossBelongLeftCount(actor,CrossBossBase.darkhallbossBelongMaxCount)
		useCount =  CrossBossBase.darkhallbossBelongMaxCount - leftCount
	else
		setBossBelongLeftCount(actor,leftCount + count)
		useCount = count
	end
	LActor.costItem(actor, itemId, useCount, "add darkhallboss times")
	sendActorData(actor)
	return useCount
end

--[[
    @desc: 获取boss下次刷新时间
    author:{author}
    time:2020-04-15 09:26:02
    --@bossConfId: 
    @return:
]]
local function getBossRefreshTime(bossConfId)
	local globalData = getGlobalData()
	local refreshTime = globalData.bossList[bossConfId].bossRefreshTime or 0
	return refreshTime
end

-- 获取客户端设置的boss提醒数据
local function getClientBossTips(actor)
	local data = getCrossStaticData(actor)
	if(not data.clientset) then
		data.clientset = {}
	end
	return data.clientset
end

-- 获取客户端设置的boss提醒数据
local function setClientBossTips(actor,confIdTab)
	local data = getCrossStaticData(actor)
	if(not data.clientset) then
		data.clientset = {}
	end
	data.clientset = {}
	for i,confId in pairs(confIdTab) do
		data.clientset[i] = confId
	end
end


--[[
    @desc: 检测进入条件
    author:{author}
    time:2020-04-08 19:28:48
	--@actor: 
	--@conf:DarkHallBossConfig[id]
    @return:
]]
local function checkCondition(actor,conf)
	if(System.getOpenServerDay() + 1 < (CrossBossBase.darkhallbossopenDay or 0)) then
		LOG(actor,"checkCondition day not enough")
		DEBUG(actor,"checkCondition 开服天数不够")
		return false
	end

	local data = getCrossStaticData(actor)  -- 下次进入时间
	if (data.scene_cd or 0) > System.getNowTime() then
		DEBUG(actor,"checkCondition cd了") 
		DEBUG(actor,"scene_cd:" .. data.scene_cd .. " 当前时间:" .. System.getNowTime())
		return false 
	end

	-- 检测BOSS是否复活
	local refreshTime = getBossRefreshTime(conf.id)
	if (refreshTime > System.getNowTime()) then
		LOG(actor,"checkCondition cding,conf.id:" .. conf.id)
		return false
	end
	-- 检测玩家灵力
	local actorDarkpower ={}
	darkhallequip.getDarkPower(actor, actorDarkpower)
	for lingType,lingValue in pairs(conf.darkpowerLimit or {}) do
		if(actorDarkpower[lingType]<lingValue) then
			LOG(actor,"checkCondition lingvalue not enough,lingType:" .. lingType .. " lingValue:" .. actorDarkpower[lingType] .. " conValue:" .. lingValue)
			return false
		end
	end
	return true
end

--扣复活元宝
local function reduceRebornCost(actor)
	local data = getCrossStaticData(actor)
	if 0 < (data.needCost or 0) then
		local value = data.needCost
		local yb = LActor.getCurrency(actor, NumericType_YuanBao)
		if data.needCost > yb then value = yb end
		LActor.changeYuanBao(actor, 0 - value, "action_darkhallbosssystem_buycd") -- 跨服中复活消耗的元宝 大概
		data.needCost = data.needCost - value -- 减去已扣除的元宝
	end
end

--处理掉落记录展示长度
function CheckIsGreatDrop(type, id)
	local isGreat = false
	if CrossDropType.CrossBossType == type then
		if true == table.contains(CrossBossBase.bestDrops or {}, id) then isGreat = true end   --跨服boss掉落
	elseif CrossDropType.DevilBossType == type then
		if true == table.contains(DevilBossBase.bestDrops or {}, id) then isGreat = true end   --恶魔boss掉落
	end

	local var = getSystemData()
	if isGreat then
		if CrossBossBase.showBestSize <= #(var.greatRecord or {}) then table.remove(var.greatRecord, 1) end
	else
		if CrossBossBase.showSize <= #(var.record or {}) then table.remove(var.record, 1) end
	end

	return isGreat
end

--增加记录
local function addRecord(actorName, sceneName, bossName, itemId, aid, srvId)
	local var = getSystemData()
	if nil == var.record then var.record = {} end
	if nil == var.greatRecord then var.greatRecord = {} end

	local isGreat = CheckIsGreatDrop(CrossDropType.CrossBossType, itemId)

	local record = var.record
	if isGreat then record = var.greatRecord end

	table.insert(record, {type=CrossDropType.CrossBossType, time=System.getNowTime(), actorId=aid, srvId=srvId, actorName=actorName,
		sceneName=sceneName, bossName=bossName, itemId=itemId})
end

--发奖励邮件
function sendRewardMail(reward, actorId, actorName, id, actorSrvId, belongFlag)
	if actorSrvId == System.getServerId() then -- 本服才发奖励
		if(belongFlag == 1) then -- 归属者
			mailData = {head=CrossBossBase.darkhallbossTitle , context=CrossBossBase.darkhallbossContent, tAwardList=reward} -- boss归属奖励
		end 
		mailsystem.sendMailById(actorId, mailData) 
	end
end

--获取随机坐标
function getRandomPoint(conf)
    local index = math.random(1, #conf.enterPos)
    return conf.enterPos[index].posX, conf.enterPos[index].posY
end

--等级检测
local function checkLevel(actor, id)
	local level = LActor.getZhuanShengLevel(actor) * 1000
	local isCan = true

	if DarkHallBossConfig[id].levelLimit then
		if level < (DarkHallBossConfig[id].levelLimit[1] or 0) or level > (DarkHallBossConfig[id].levelLimit[2] or 0) then
			isCan = false
		end
	end

	return isCan
end

--下发个人基本数据 归属次数与挑战cd
function sendActorData(actor)
	local var = getCrossStaticData(actor)
	if(not var.bossbelongleftcount) then
		var.bossbelongleftcount = CrossBossBase.darkhallbossBelongCount -- 暗殿BOSS挑战次数
	end
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendDarkhallActorInfo) -- 72-49
	if npack == nil then return end
	LDataPack.writeShort(npack, var.bossbelongleftcount) -- boss剩余归属次数
	LDataPack.writeShort(npack, (var.scene_cd or 0) - System.getNowTime() > 0 and (var.scene_cd or 0) - System.getNowTime() or 0) -- 剩余cd
	LDataPack.writeShort(npack,var.bossBelongBuyCount or 0) -- 今日已购买次数
	LDataPack.flush(npack)
end

--下发boss数据 72-41
function sendBossData(actor)
	local npack = nil
	if actor then
		npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendDarkhallBossInfo) -- 72-41
	else
		npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
		LDataPack.writeByte(npack, Protocol.sCrossBossCmd_SendDarkhallBossInfo) -- 72-41
	end
	if npack == nil then return end
	local data = getGlobalData()


	if not data.bossList then data.bossList = {} end

	LDataPack.writeShort(npack, table.getnEx(data.bossList)) -- boss数量

	for id, info in pairs(data.bossList or {}) do
		local refreshLeftTime = (info.bossRefreshTime or 0) - System.getNowTime() > 0 and (info.bossRefreshTime or 0) - System.getNowTime() or 0 -- boss下次刷新时间
		LDataPack.writeShort(npack, id) -- 配置的索引编号
		LDataPack.writeInt(npack, refreshLeftTime) -- boss剩余刷新时间
		--DEBUG(actor,"sendBossData id:" .. id .. " 剩余刷新时间:" .. refreshLeftTime)
	end
	
	if actor then
		LDataPack.flush(npack)
	else
		System.broadcastData(npack)
	end
end







--请求boss信息
local function onReqBossInfo(actor, packet)
	sendBossData(actor)
end

--请求进入副本
local function onReqEnterFuBen(actor, packet)
	local id = LDataPack.readShort(packet) -- 配置文件的id
	local conf = DarkHallBossConfig[id]
	if not conf then LOG(actor,"onReqEnterFuBen:DarkHallBossConfig[id] nil, id:".. id) return end

	local actorId = LActor.getActorId(actor)

	if(false == checkCondition(actor,conf)) then
		LOG(actor,"onReqEnterFuBen condition fail")
		return
	end

	local x, y = getRandomPoint(conf) -- 坐标
	local data = getGlobalData()
	if not data.bossList[id] then
		LOG(actor,"darkhallbosssystem.onReqEnterFuBen:data nil, id:".. id)
		return
	end
	LActor.loginOtherSrv(actor, csbase.GetBattleSvrId(bsBattleSrv), data.bossList[id].fbHandle, 0, x, y)
end


--[[
    @desc: 购买归属次数
    author:{author}
    time:2020-04-09 16:35:25
    --@actor:
	--@cpacket: 
    @return:
]]
local function onBuyBelongCount(actor,cpacket)
	--判断
	DEBUG(actor,"onBuyBelongCount 请求购买次数")
	local leftCount = getBossBelongLeftCount(actor)
	if(leftCount ~= 0) then return end
	local buyCount = getBossBelongBuyCount(actor) -- 可购买次数
	if(buyCount >= CrossBossBase.darkhallbossbuyBelongCount) then
		DEBUG(actor,"onBuyBelongCount 今日已购买次数:" .. buyCount .. " 超过最大上限:" .. CrossBossBase.darkhallbossbuyBelongCount)
		return
	end
	local hasYuanBao = LActor.getCurrency(actor, NumericType_YuanBao)
	if(hasYuanBao < CrossBossBase.darkhallbossbuyBelongCountPrice) then
		DEBUG(actor,"onBuyBelongCount 钱不够,需要元宝:" .. CrossBossBase.darkhallbossbuyBelongCountPrice)
		return
	end
	
	LActor.changeCurrency(actor, NumericType_YuanBao, -CrossBossBase.darkhallbossbuyBelongCountPrice, "darkhallboss_buy_count")
	setBossBelongLeftCount(actor, leftCount+1) -- 归属次数+1
	setBossBelongBuyCount(actor,buyCount + 1) -- 有购买归属次数+1
	sendActorData(actor)
end


--[[
    @desc: 发送boss提醒的数据
    author:{author}
    time:2020-04-10 14:58:36
    --@actor:
	--@cpacket: client packet
    @return:
]]
local function sendDarkhallBossTips(actor)
	local confIdTab = getClientBossTips(actor)
	local count = #confIdTab
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_DarkhallBossTips) -- 72-48
	LDataPack.writeShort(npack, count) -- 设置提醒的boss量
	for i=1,count do
		LDataPack.writeUInt(npack,confIdTab[i])
	end
	LDataPack.flush(npack)
end

--[[
    @desc: boss提醒的数据
    author:{author}
    time:2020-04-10 14:58:36
    --@actor:
	--@cpacket: client packet
    @return:
]]
local function onDarkhallBossTips(actor,cpacket)
	local confIdTab = {}
	local count = LDataPack.readShort(cpacket)
	for i=1,count do
		local confId = LDataPack.readUInt(cpacket)
		table.insert(confIdTab,confId)
	end
	setClientBossTips(actor,confIdTab)
end


--发送boss/旗帜复活
local function sendMonsterRefresh(id)
	local npack = LDataPack.allocPacket()
	LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
	LDataPack.writeByte(npack, Protocol.sCrossBossCmd_BossDarkhallResurgence) -- 72-45
	LDataPack.writeShort(npack, id) -- 配置的索引
	System.broadcastData(npack)
	DEBUG(actor,"sendMonsterRefresh 发送boss复活,配置id:" .. id)
end

--boss刷新(来自跨服)
local function onRefreshBoss(sId, sType, dp)
	local id = LDataPack.readShort(dp) -- config[id] 配置的索引
	local handle = LDataPack.readUInt(dp) -- 副本的句柄
	local bossRefreshTime = LDataPack.readInt(dp) -- boss刷新时间
	local data = getGlobalData()
	if not data.bossList then data.bossList = {} end

	--游戏服也保存一份跨服boss的刷新信息
	data.bossList[id] = {}
	data.bossList[id].bossRefreshTime = bossRefreshTime
	data.bossList[id].fbHandle = handle
	DEBUG(actor,"onRefreshBoss:receive boss info success. id:"..tostring(id) .. " 下次刷新时间:" .. bossRefreshTime)
	if(bossRefreshTime == 0) then
		sendMonsterRefresh(id)
	end
end

--发奖励邮件(来自跨服)
local function onSendReward(sId, sType, dp)
	local type = LDataPack.readShort(dp) -- 奖励类型(去掉)
	local count = LDataPack.readShort(dp) -- 奖励数量
	local reward = {}
	for i=1, count do
		local rew = {}
		rew.type = LDataPack.readInt(dp)
		rew.id = LDataPack.readInt(dp)
		rew.count = LDataPack.readInt(dp)
		table.insert(reward, rew)
	end

	local actorId = LDataPack.readInt(dp) -- 角色id
	local actorName = LDataPack.readString(dp) -- 角色名称
	local id = LDataPack.readShort(dp) -- 副本索引
	local actorSrvId = LDataPack.readInt(dp) -- 角色的服务器id
	local belongFlag = LDataPack.readInt(dp) -- 是否是归属奖励

	sendRewardMail(reward, actorId, actorName, id, actorSrvId, belongFlag)
	LOG(actor,"darkhallbosssystem.onSendReward:receive reward success. id:"..tostring(id)..", actorid:"..tostring(actorId)..", srvId:"..tostring(actorSrvId))
end

--进入公告
local function onEnterFb(sId, sType, dp)
	local actorName = LDataPack.readString(dp) -- 角色名称
	local actorSrvId = LDataPack.readShort(dp) -- 角色服务器id
	local confId = LDataPack.readShort(dp) -- 副本索引 配置表的索引

	local conf = DarkHallBossConfig[confId]
	if(not conf) then
		SYSLOG("onEnterFb config not exist,fbId:" .. confId .. " actorname:" .. actorName .. " srvid:" .. actorSrvId)
		return
	end
	local bossId = conf.bossId
	noticemanager.broadCastNotice(conf.enterNoticeId, actorName, actorSrvId, MonstersConfig[bossId].name or "")
end

local function onLogin(actor)
	sendActorData(actor) --下发个人基本数据 归属次数与挑战cd
	sendBossData(actor) -- 下发跨服boss数据
	reduceRebornCost(actor) -- 扣除跨服精英BOSS用掉的元宝
	sendDarkhallBossTips(actor) -- boss提醒数据
end

--新的一天到来
local function onNewDay(actor, islogin)
	if(System.getOpenServerDay() + 1 < (CrossBossBase.darkhallbossopenDay or 0)) then
		DEBUG(actor,"onNewDay 开服天数不够不加次数")
		return false
	end

	--补历史天数的次数
	local data = getCrossStaticData(actor)
	local diff_day = 0
	if data.resBelongCountTime then
		diff_day = math.floor((System.getToday() - data.resBelongCountTime)/(3600*24))--获得间隔几天
	end
	diff_day = (diff_day>1) and diff_day or 1 -- 触发onNewDay必然要增加一天的奖励次数
	local data = getCrossStaticData(actor)
	--补充
	if diff_day > 0 then
		data.bossbelongleftcount = (data.bossbelongleftcount or 0) + CrossBossBase.darkhallbossBelongCount * diff_day
		if data.bossbelongleftcount > CrossBossBase.darkhallbossBelongMaxCount then data.bossbelongleftcount = CrossBossBase.darkhallbossBelongMaxCount end
	end

	data.resBelongCountTime = System.getToday()
	setBossBelongBuyCount(actor,0) -- 重置今日购买的购买次数

	sendActorData(actor)
	DEBUG(actor,"onNewDay 刷新玩家跨服精英BOSS次数,diff_day:" .. diff_day)
	LOGINFO(actor,"onNewDay darkhallboss resetCounts diff_day:".. diff_day)
end



--启动初始化
local function initGlobalData()
	if not System.isCommSrv() then return end -- 跨服
	--玩家事件处理
	actorevent.reg(aeNewDayArrive, onNewDay)
    actorevent.reg(aeUserLogin, onLogin)

    --本服消息处理
    netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_ReqDarkhallBossInfo, onReqBossInfo) -- 72-41 请求精英boss信息
	netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_RequestDarkhallEnter, onReqEnterFuBen) -- 72-42 请求进入暗殿副本
	netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_BuyBelongCount, onBuyBelongCount) -- 72-47 购买次数
	netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_DarkhallBossTips, onDarkhallBossTips) -- 72-48 boss提醒数据
    --跨服消息处理(跨服服来的消息)
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_RefreshDarkHallBoss, onRefreshBoss) -- 7-9 刷新单个暗殿BOSS信息
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_sendDarkHallReward, onSendReward) -- 7-10 暗殿BOSS奖励
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_enterDarkHallFb, onEnterFb) -- 7-11 玩家进入了暗殿BOSS,全服发公告
end

table.insert(InitFnTable, initGlobalData)


local gmsystem = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.enterdark = function(actor, args)
	local data = getGlobalData()
	local id = tonumber(args[1])
	local conf = DarkHallBossConfig[id]
	if(not DarkHallBossConfig) then
		SYSDEBUG("DarkHallBossConfig not exist")
		return
	end
	if(not conf) then
		SYSDEBUG("conf not exist,id:" .. id)
		return
	end
	local x, y = getRandomPoint(conf) -- 坐标
	LActor.loginOtherSrv(actor, csbase.GetBattleSvrId(bsBattleSrv), data.bossList[id].fbHandle, 0, x, y)
end

gmHandlers.resetdarkcd = function(actor, args)
	local data = getCrossStaticData(actor)
	data.scene_cd = 0
end

--[[
gmHandlers.myelitedata = function(actor, args)
	local strlog = "个人精英BOSS信息如下:\n"

	local actordata = getCrossStaticData(actor)
	local belongCount = actordata.bossbelongleftcount or 0
	local leftcd = (actordata.scene_cd or 0) - System.getNowTime() > 0 and (actordata.scene_cd or 0) - System.getNowTime() or 0
	strlog = strlog .. "精英BOSS剩余归属次数:" .. belongCount .. "\n 下次可进入时间剩余:" .. leftcd
	sendTip(actor,strlog)
end
]]
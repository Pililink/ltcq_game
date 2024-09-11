--跨服boss(游戏服)
module("crosselitebosssystem", package.seeall)

--[[全局变量
	[配置id] = {
		bossRefreshTime  boss剩余刷新时间，0表示已刷新
		fbHandle     副本句柄
		srvId        服务器id
	}
]]

--[[系统数据
	record = {
		{type,time, actorid, srvid, 玩家名, 场景名, boss名, itemId}
		{type,time, srvid, 帮派名, boss名, 拍卖id}
	}

	greatRecord = {
		{type,time, actorid, srvid, 玩家名, 场景名, boss名, itemId}
		{type,time, srvid, 帮派名, boss名, 拍卖id}
	}

]]

--[[玩家跨服数据
	bossBelongLeftCount 可获得boss归属次数
	flagBelongLeftCount 可获得旗帜归属次数
	resBelongCountTime 最近一次刷新归属者次数时间
	scene_cd				下次进入副本的时间
	resurgence_cd  	复活cd
	rebornEid 		复活定时器句柄
	bossReward      boss归属奖励
	flagReward      采棋奖励
	id   			当前进入的副本配置id
	needCost        复活需要扣的元宝
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
	print("[ERROR]:crosselitebosssystem." .. errlog .. " actorid:" .. actorid)
end

local function LOGINFO(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[INFO]:crosselitebosssystem." .. log .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:crosselitebosssystem." .. log .. " actorid:" .. actorid)
	]]
end

globalCrossEliteBossData = globalCrossEliteBossData or {} -- 存储跨服发过来的精英BOSS信息用

local function getGlobalData()
	return globalCrossEliteBossData
end

function getSystemData()
	local data = System.getStaticVar()
	if not data.crosseliteboss then data.crosseliteboss = {} end

	return data.crosseliteboss
end

local function getCrossStaticData(actor)
    local var = LActor.getCrossVar(actor)
    if nil == var.crosseliteboss then var.crosseliteboss = {} end
    return var.crosseliteboss
end

--判断本服boss是否可以开启
function checkCanOpen()
	return System.getOpenServerDay() + 1 >= (CrossBossBase.openDay or 0)
end

--进入cd检测
local function checkIsInEnterCd(actor)
	local data = getCrossStaticData(actor)
	if (data.scene_cd or 0) > System.getNowTime() then return true end -- 下次进入时间
	return false
end

--扣复活元宝
local function reduceRebornCost(actor)
	local data = getCrossStaticData(actor)
	if 0 < (data.needCost or 0) then
		local value = data.needCost
		local yb = LActor.getCurrency(actor, NumericType_YuanBao)
		if data.needCost > yb then value = yb end
		LActor.changeYuanBao(actor, 0 - value, "action_crosselitebosssystem_buycd") -- 跨服中复活消耗的元宝 大概
		data.needCost = data.needCost - value -- 减去已扣除的元宝
	end
end

--[[
function resetCount(actor)
	if false == checkCanOpen() then return end
	local data = getCrossStaticData(actor)
	if not data.fix then
		data.bossBelongLeftCount = (data.bossBelongLeftCount or 0) + CrossBossBase.bossBelongCount
		data.flagBelongLeftCount = (data.flagBelongLeftCount or 0) + CrossBossBase.flagBelongCount

		if data.bossBelongLeftCount > CrossBossBase.bossBelongMaxCount then data.bossBelongLeftCount = CrossBossBase.bossBelongMaxCount end
		if data.flagBelongLeftCount > CrossBossBase.flagBelongMaxCount then data.flagBelongLeftCount = CrossBossBase.flagBelongMaxCount end

		data.fix = 1
		sendActorData(actor)
	end
end
]]

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

--极品奖励公告
local function checkRewardNotice(reward, aid, actorName, id, actorSrvId, srvId)
	local config = EliteBossConfig[id]
	if not config then return end
	local bossName = MonstersConfig[crossbossfb.getBossId(config)].name or ""

    for _, v in ipairs(reward or {}) do
        if v.type == 1 and ItemConfig[v.id] and ItemConfig[v.id].needNotice == 1 then
        	local itemName = item.getItemDisplayName(v.id)
            noticemanager.broadCastNotice(CrossBossBase.eliteBossNoticeId, actorName, actorSrvId, srvId, bossName, itemName)
            addRecord(actorName, config.sceneName, bossName, v.id, aid, actorSrvId)
        end
    end
end

--发奖励邮件
function sendRewardMail(reward, actorId, actorName, id, actorSrvId, belongFlag)
	if actorSrvId == System.getServerId() then -- 本服才发奖励
		local mailData = {head=CrossBossBase.eliteBossJoinTitle , context=CrossBossBase.eliteBossJoinContent, tAwardList=reward} -- 参与奖励
		if(belongFlag == 1) then -- 归属者
			mailData = {head=CrossBossBase.eliteBossBelongTitle , context=CrossBossBase.eliteBossBelongContent, tAwardList=reward} -- boss归属奖励
		end 
		mailsystem.sendMailById(actorId, mailData) 
	end
	-- id 副本索引,找配置用
	-- checkRewardNotice(reward, actorId, actorName, id, actorSrvId, srvId) -- 这里加公告 todo
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

	if EliteBossConfig[id].levelLimit then
		if level < (EliteBossConfig[id].levelLimit[1] or 0) or level > (EliteBossConfig[id].levelLimit[2] or 0) then
			isCan = false
		end
	end

	return isCan
end

--下发个人基本数据 归属次数与挑战cd
function sendActorData(actor)
	local var = getCrossStaticData(actor)
	if(not var.bossBelongLeftCount) then
		var.bossBelongLeftCount = CrossBossBase.eliteBossBelongCount -- 精英BOSS挑战次数
	end
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendEliteActorInfo) -- 72-29
	if npack == nil then return end
	LDataPack.writeShort(npack, var.bossBelongLeftCount) -- boss剩余归属次数
	LDataPack.writeShort(npack, (var.scene_cd or 0) - System.getNowTime() > 0 and (var.scene_cd or 0) - System.getNowTime() or 0) -- 剩余cd
	LDataPack.flush(npack)
end

--下发boss数据 72-21
function sendBossData(actor)
	local npack = nil
	if actor then
		npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendEliteBossInfo) -- 72-21
	else
		npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
		LDataPack.writeByte(npack, Protocol.sCrossBossCmd_SendEliteBossInfo)
	end
	if npack == nil then return end
	local data = getGlobalData()


	if not data.bossList then data.bossList = {} end

	LDataPack.writeShort(npack, table.getnEx(data.bossList)) -- boss数量

	for id, info in pairs(data.bossList or {}) do
		local refreshLeftTime = (info.bossRefreshTime or 0) - System.getNowTime() > 0 and (info.bossRefreshTime or 0) - System.getNowTime() or 0 -- boss下次刷新时间
		LDataPack.writeShort(npack, id) -- 配置的索引编号
		LDataPack.writeShort(npack, info.tipId) -- 分配的服务器id 这里默认是-1 - -3,先不管
		LDataPack.writeInt(npack, refreshLeftTime) -- boss剩余刷新时间
		LDataPack.writeString(npack, info.belongActorname or " ") -- 归属者名称
		DEBUG(actor,"sendBossData id:" .. id .. " tipId:" .. info.tipId .. " freshtime:" .. refreshLeftTime)
	end
	
	if actor then
		LDataPack.flush(npack)
	else
		System.broadcastData(npack)
	end
end

--写跨服boss掉落数据
local function writeCrossBossDrop(record, npack)
	LDataPack.writeInt(npack, record.time)
	LDataPack.writeInt(npack, record.actorId)
	LDataPack.writeInt(npack, record.srvId)
    LDataPack.writeString(npack, record.actorName or "")
    LDataPack.writeString(npack, record.sceneName or "")
    LDataPack.writeString(npack, record.bossName or "")
    LDataPack.writeInt(npack, record.itemId)
end

--写恶魔入侵掉落数据
local function writeDevilBossDrop(record, npack)
	LDataPack.writeInt(npack, record.time)
	LDataPack.writeInt(npack, record.srvId or 0)
    LDataPack.writeString(npack, record.guildName or "")
    LDataPack.writeString(npack, record.bossName or "")
    LDataPack.writeInt(npack, record.id)
end

--新的一天到来
local function onNewDay(actor, islogin)
	if false == checkCanOpen() then return end
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
		data.bossBelongLeftCount = (data.bossBelongLeftCount or 0) + CrossBossBase.eliteBossBelongCount * diff_day
		if data.bossBelongLeftCount > CrossBossBase.bossBelongMaxCount then data.bossBelongLeftCount = CrossBossBase.bossBelongMaxCount end
	end

	data.resBelongCountTime = System.getToday()

	sendActorData(actor)
	DEBUG(actor,"onNewDay 刷新玩家跨服精英BOSS次数,diff_day:" .. diff_day)
	LOGINFO(actor,"onNewDay crosseliteboss resetCounts diff_day:".. diff_day)
end

local function onLogin(actor)
	sendActorData(actor) --下发个人基本数据 归属次数与挑战cd 由跨服boss模块发 共用
	sendBossData(actor) -- 下发跨服boss数据
	reduceRebornCost(actor) -- 扣除跨服精英BOSS用掉的元宝
end

--请求boss信息
local function onReqBossInfo(actor, packet)
	sendBossData(actor)
end

--请求进入副本
local function onReqEnterFuBen(actor, packet)
	local id = LDataPack.readShort(packet) -- EliteBossConfig 配置的索引
	local conf = EliteBossConfig[id]
	if not conf then LOG(actor,"crossbosssystem.onReqEnterFuBen:conf nil, id:"..tostring(id)..", actorId:"..tostring(actorId)) return end

	local actorId = LActor.getActorId(actor)
	--是否开启了活动
	if false == checkCanOpen() then LOG(actor,"crossbosssystem.onReqEnterFuBen:not open, id:"..tostring(id)..", actorId:"..tostring(actorId)) return end

	--等级检测
	if false == checkLevel(actor, id) then
		LOG(actor,"crossbosssystem.onReqEnterFuBen:checkLevel nil, id:"..tostring(id)..", actorId:"..tostring(actorId))
		return
	end

	--cd检测
	if true == checkIsInEnterCd(actor) then
		LOG(actor,"crossbosssystem.onReqEnterFuBen:in enter cd. actorId:"..tostring(actorId))
		return
	end

	local x, y = getRandomPoint(conf) -- 坐标
	local data = getGlobalData()
	if not data.bossList[id] then
		LOG(actor,"crossbosssystem.onReqEnterFuBen:data nil, id:"..tostring(id))
		return
	end
	LActor.loginOtherSrv(actor, csbase.GetBattleSvrId(bsBattleSrv), data.bossList[id].fbHandle, 0, x, y)
end

--boss刷新(来自跨服)
local function onRefreshBoss(sId, sType, dp)
	local id = LDataPack.readShort(dp) -- config[id] 配置的索引
	local tipId = LDataPack.readShort(dp) -- 该副本分配的服务器(精英BOSS不用,默认是-1 -2 -3)
	local handle = LDataPack.readUInt(dp) -- 副本的句柄
	local bossRefreshTime = LDataPack.readInt(dp) -- boss刷新时间
	local belongActorname = LDataPack.readString(dp) -- 上一个归属者名字
	local data = getGlobalData()
	if not data.bossList then data.bossList = {} end

	--游戏服也保存一份跨服boss的刷新信息
	data.bossList[id] = {}
	data.bossList[id].tipId = tipId
	data.bossList[id].bossRefreshTime = bossRefreshTime
	data.bossList[id].fbHandle = handle
	data.bossList[id].belongActorname = belongActorname
	LOG(actor,"crossbosssystem.onRefreshBoss:receive boss info success. id:"..tostring(id)..", srvId:"..tostring(srvId))
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
	LOG(actor,"crossbosssystem.onSendReward:receive reward success. id:"..tostring(id)..", actorid:"..tostring(actorId)..", srvId:"..tostring(actorSrvId))
end

--进入公告
local function onEnterFb(sId, sType, dp)
	local actorName = LDataPack.readString(dp) -- 角色名称
	local actorSrvId = LDataPack.readShort(dp) -- 角色服务器id
	local fbId = LDataPack.readShort(dp) -- 副本索引 配置表的索引

	local conf = EliteBossConfig[fbId]
	if(not conf) then
		SYSLOG("onEnterFb config not exist,fbId:" .. fbId .. " actorname:" .. actorName .. " srvid:" .. actorSrvId)
		return
	end
	local bossId = conf.bossId
	noticemanager.broadCastNotice(conf.enterNoticeId, actorName, actorSrvId, MonstersConfig[bossId].name or "")
end

--关掉本服副本
local function onCloseFb(sId, sType, dp)
	--crossbossfb.clearFb()
	LOG(actor,"crossbosssystem.onCloseFb:success")
end

--启动初始化
local function initGlobalData()
	if not System.isCommSrv() then return end -- 跨服
	--玩家事件处理
	actorevent.reg(aeNewDayArrive, onNewDay)
    actorevent.reg(aeUserLogin, onLogin)

    --本服消息处理
    netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_ReqEliteBossInfo, onReqBossInfo) -- 72-21 请求精英boss信息
    netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_RequestEliteEnter, onReqEnterFuBen) -- 72-26 请求进入精英副本

    --跨服消息处理(跨服服来的消息)
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_RefreshEliteBoss, onRefreshBoss) -- 7-5 刷新单个精英BOSS信息
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_sendEliteReward, onSendReward) -- 7-6 精英BOSS奖励
    csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_enterEliteFb, onEnterFb) -- 7-7 玩家进入了跨服精英BOSS,全服发公告
    --csmsgdispatcher.Reg(CrossSrvCmd.SCCrossBossCmd, CrossSrvSubCmd.SCBossCmd_closeEliteFb, onCloseFb) -- 这个没用,精英boss不开本服BOSS,区别于跨服BOSS
end

table.insert(InitFnTable, initGlobalData)


local gmsystem = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.enterelite = function(actor, args)
	local data = getGlobalData()
	local id = tonumber(args[1])
	local conf = EliteBossConfig[id]
	if(not EliteBossConfig) then
		SYSDEBUG("EliteBossConfig not exist")
		return
	end
	if(not conf) then
		SYSDEBUG("conf not exist,id:" .. id)
		return
	end
	local x, y = getRandomPoint(conf) -- 坐标
	LActor.loginOtherSrv(actor, csbase.GetBattleSvrId(bsBattleSrv), data.bossList[id].fbHandle, 0, x, y)
end


gmHandlers.myelitedata = function(actor, args)
	local strlog = "个人精英BOSS信息如下:\n"

	local actordata = getCrossStaticData(actor)
	local belongCount = actordata.bossBelongLeftCount or 0
	local leftcd = (actordata.scene_cd or 0) - System.getNowTime() > 0 and (actordata.scene_cd or 0) - System.getNowTime() or 0
	strlog = strlog .. "精英BOSS剩余归属次数:" .. belongCount .. "\n 下次可进入时间剩余:" .. leftcd
	sendTip(actor,strlog)
end

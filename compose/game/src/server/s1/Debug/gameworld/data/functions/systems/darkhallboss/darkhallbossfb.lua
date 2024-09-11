--暗殿boss管理模块(跨服服)
module("darkhallbossfb", package.seeall)
-- 日志
local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:darkhallbossfb." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log) -- 上线后把内容注掉
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:darkhallbossfb." .. log .. " actorid:" .. actorid)
	]]
end

local function LOGINFO(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[INFO]:darkhallbossfb." .. log .. " actorid:" .. actorid)
end

local function SYSINFO(log)
	print("[SYSINFO]:darkhallbossfb." .. log)
end

local function SYSLOG(log)
	print("[SYSERROR]:darkhallbossfb." .. log)
end

local function SYSDEBUG(log) -- 上线后把内容注掉
	--[[
	print("[SYSDEBUG]:darkhallbossfb." .. log)
	]]
end


local function sendTip(actor,tipmsg, type)
	local msgtype = 4
	if(type) then
		msgtype = type
	end
	LActor.sendTipmsg(actor, tipmsg .. " SERVER DEBUG", msgtype)
end
-- 日志结束


--[[玩家跨服数据 -- 数据库
getCrossStaticData(actor)
darkhallboss={
	bossBelongLeftCount BOSS归属今日剩余次数(共用)
	flagBelongLeftCount 旗帜归属今日剩余次数(跨服BOSS共用)
	resBelongCountTime 最近一次刷新归属者次数时间,用于跨天增加次数用(跨服BOSS会刷新这个值,精英boss不用管)
	scene_cd				下一次进入的时间(与跨服BOSS共用)
	resurgence_cd  	复活cd(共用)
	rebornEid 		复活定时器句柄
	id   			当前进入的副本配置id
	needCost        复活需要扣的元宝
	}
]]

--[[
getGlobalData
globalDarkhallBossData = {
	initflag, -- 副本是否已经初始化过
	bossList = {
		[conf.id] = {
			id, -- conf.id
			fbHandle, --创建副本的句柄
			monster, -- 刷新的怪物指针
			bossId, -- monster的id
			bossRefreshTime, -- boss下次刷新时间
			belongActorname, -- 上一个归属者名称
			bossBelong  当前boss归属者
			revEid,      boss回血定时器
			shield, -- 护盾时间
			shieldflag, -- 当前boss是否开启过护盾
		}
		...
	}
}
]]

--[[
	ins.data = {
		bossid,-- 创建的boss的id
		-- confId, -- 配置的编号
		id, -- 配置文件中的编号
		enterlist = { -- 保存进入过副本的角色id列表
			[actorid] = {
				actorname, -- 玩家名称
				srvid, -- 玩家服务器编号
			}
		}
	}


]]


local rewardType ={
	bossReward = 2, --boss归属奖励
}

local config = DarkHallBossConfig
globalDarkhallBossData = globalDarkhallBossData or {}
-- 跨服精英BOSS使用,存储BOSS信息用
local function getGlobalData()
	return globalDarkhallBossData
end

--[[
    @desc: 获取boss信息
    time:2020-03-26 09:12:37
    --@id: 配置文件中的id
    @return:
]]
local function getBossData(id)
	if not config[id] then -- 无配置
		SYSLOG("getBossData config not exist,id:" .. id)
		return
	end
	local globalData = getGlobalData()
	if not globalData.bossList then globalData.bossList = {} end
	if not globalData.bossList[id] then globalData.bossList[id] = {} end
	return globalData.bossList[id]
end

-- 刷新护盾状态
local function refreshShiled(confId)
	SYSDEBUG("试图刷新boss护盾,confId:" .. confId)
	local bossData = getBossData(confId)
	if(not bossData) then 
		return
	end
	bossData.shieldflag = false -- 护盾设置为无
	bossData.shield = 0 
	SYSDEBUG("刷新boss护盾成功,confId:" .. confId)
end

-- 个人跨服BOSS信息
local function getCrossStaticData(actor)
    local var = LActor.getCrossVar(actor)
    if nil == var.darkhallboss then var.darkhallboss = {} end

    return var.darkhallboss 
end

function getSysData()
	local var = System.getStaticVar()
	if nil == var.darkhallboss then var.darkhallboss = {} end
	if nil == var.darkhallboss.bossList then var.darkhallboss.bossList = {} end
	return var.darkhallboss
end

-- 获取进入副本的玩家列表
local function getEnterList(ins)
	if(not ins.data) then
		ins.data = {}
	end
	if(not ins.data.enterlist) then
		ins.data.enterlist = {}
	end
	return ins.data.enterlist
end

--发送boss信息到游戏服 7-9 精英BOSS刷新通知 s2s
-- id:精英BOSS配置的索引 sId:指定通信服务器srvId
local function sendBossInfo(id, srvId)
	if not System.isCommSrv() then -- 跨服
		local fbInfo = getBossData(id)
		local npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, CrossSrvCmd.SCCrossBossCmd) -- 7 - 9 暗殿BOSS
		LDataPack.writeByte(npack, CrossSrvSubCmd.SCBossCmd_RefreshDarkHallBoss)
		LDataPack.writeShort(npack, fbInfo.id) -- 配置索引
		LDataPack.writeUInt(npack, fbInfo.fbHandle) -- 副本句柄,一串数字
		LDataPack.writeInt(npack, fbInfo.bossRefreshTime or 0) -- boss刷新时间
		System.sendPacketToAllGameClient(npack, srvId or 0)
		SYSDEBUG("CONFID=" .. fbInfo.id .. "下次刷新时间:" .. (fbInfo.bossRefreshTime or 0))
	end
end

--发送boss/旗帜复活
local function sendMonsterRefresh(id, type)
	local npack = LDataPack.allocPacket()
	LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
	LDataPack.writeByte(npack, Protocol.sCrossBossCmd_BossDarkhallResurgence) -- 72-45
	LDataPack.writeShort(npack, id) -- 配置的索引
	System.sendPacketToAllGameClient(npack, 0)
end

--是否可以拿归属
local function canGetBelong(actor, type)
	if not actor then 
		SYSDEBUG("canGetBelong not actor")
		return false 
	end
	local var = getCrossStaticData(actor)
	if rewardType.bossReward == type then
		return (var.bossBelongLeftCount or CrossBossBase.darkhallbossBelongCount) > 0
	else
		SYSLOG("canGetBelong rewardType.bossReward ERROR type:" .. type .. " needtype:" .. rewardType.bossReward)
		return false
	end
end

--[[
    @desc: 设置跨服精英BOSS可获得奖励次数
    author:{author}
    time:2020-03-27 15:52:02
    --@actor:
	--@count: 次数
    @return:
]]
local function setEliteBossCount(actor, count)
	local var = getCrossStaticData(actor)
	var.bossBelongLeftCount = count
end
--[[
    @desc: 减少可获取奖励次数
    author:{author}
    time:2020-03-13 10:03:00
    --@actor:
	--@type: 2 boss归属次数 其他无意义
	@return:true 成功 false 失败
	@note1:原本是归属次数,后续要求改为奖励次数,归属者与参与者都扣除这个次数 2020-3-26
]]
local function reduceBelongCount(actor, type)
	if not actor then return false end
	local var = getCrossStaticData(actor)
	if rewardType.bossReward == type then -- 减少boss归属
		var.bossBelongLeftCount = (var.bossBelongLeftCount or CrossBossBase.darkhallbossBelongCount) - 1
		if var.bossBelongLeftCount < 0 then 
			var.bossBelongLeftCount = 0
			LOG(actor,"reduceBelongCount fail,bossBelongLeftCount not enough") -- 可获得奖励的次数不够
			DEBUG(actor,"reduceBelongCount 玩家获得奖励的次数不够")
			return false
		else
			return true
		end
	else -- 类型有问题
		LOG(actor,"reduceBelongCount fail,type error type:" .. type .. " needtype:" .. rewardType.bossReward)
		return false
	end
end

--通知玩家的复活信息 72-43
local function notifyRebornTime(actor, killerHdl)
    local data = getCrossStaticData(actor)
    local rebornCd = (data.resurgence_cd or 0) - System.getNowTime()
    if rebornCd < 0 then rebornCd = 0 end

    local npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_ResurgenceDarkhallInfo)
    LDataPack.writeInt(npack, rebornCd)
    LDataPack.writeDouble(npack, killerHdl or 0)
    LDataPack.flush(npack)
end

--复活定时器
local function reborn(actor, id)
	if not actor then return end

	notifyRebornTime(actor)

	local x, y = crosselitebosssystem.getRandomPoint(DarkHallBossConfig[id])
	LActor.relive(actor, x, y)

	LActor.stopAI(actor)
end

--刷出boss怪物
local function refreshBossTimer(id)
	refreshShiled(id) -- 刷新BOSS护盾
	local conf = DarkHallBossConfig[id]
	if not conf then 
		SYSLOG("darkhallbossfb.refreshBossTimer:conf nil, id:"..tostring(id)) 
		return 
	end

	local fbInfo = getBossData(id)
	if not fbInfo then 
		SYSLOG("darkhallbossfb.refreshBossTimer:fbInfo nil, id:"..tostring(id)) 
		return 
	end

	--刷怪
	local ins = instancesystem.getInsByHdl(fbInfo.fbHandle)
	if ins then
		local bossId = conf.bossId
		local monster = Fuben.createMonster(ins.scene_list[1], bossId)
		if not monster then 
			SYSLOG("refreshBossTimer:monster nil, bossId:"..tostring(bossId)) 
			return 
		end

		ins.data.bossId = bossId -- bossId
		ins.data.confId = conf.id -- 配置编号

		fbInfo.monster = monster
		fbInfo.bossRefreshTime = 0

		sendBossInfo(id)
		--sendMonsterRefresh(id, rewardType.bossReward)

		if conf.refreshNoticeId then
			noticemanager.broadCastNotice(conf.refreshNoticeId, MonstersConfig[bossId].name or "", conf.sceneName)
		end

		print("darkhallbossfb.refreshBossTimer: refresh monster success, id:"..tostring(id))
	end
end

--下发个人基本数据
local function sendActorData(actor)
	crosselitebosssystem.sendActorData(actor)
end


--[[
    @desc: 发送奖励弹框 72-30 7-6
    time:2020-03-26 10:11:21
    --@actor:
	--@reward:
	--@rewardType:奖励类型 2boss奖励
	--@id:配置的编号,看config
	--@isBelong: 是否为归属者
    @return:
]]
local function sendReward(actor, reward, rewardType, id, isBelong)
	DEBUG(actor,"sendReward 准备发送奖励")
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendDarkhallRewardInfo) -- 72-50发送奖励
	LDataPack.writeShort(npack, (isBelong and 1 or 0)) -- 是否为归属者
	LDataPack.writeShort(npack, rewardType) -- boss归属奖励类型
	LDataPack.writeShort(npack, #reward) -- 奖励数量
	for k, v in pairs(reward or {}) do
		LDataPack.writeInt(npack, v.type)
		LDataPack.writeInt(npack, v.id)
		LDataPack.writeInt(npack, v.count)
	end
	LDataPack.flush(npack)

	if not System.isCommSrv() then
		npack = nil
		npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, CrossSrvCmd.SCCrossBossCmd)
		LDataPack.writeByte(npack, CrossSrvSubCmd.SCBossCmd_sendDarkHallReward) -- 7-10 发送奖励

		LDataPack.writeShort(npack, rewardType)
		LDataPack.writeShort(npack, #reward)
		for k, v in pairs(reward or {}) do
			LDataPack.writeInt(npack, v.type)
			LDataPack.writeInt(npack, v.id)
			LDataPack.writeInt(npack, v.count)
		end

		LDataPack.writeInt(npack, LActor.getActorId(actor))
		LDataPack.writeString(npack, LActor.getName(actor))
		LDataPack.writeShort(npack, id) -- 配置id
		LDataPack.writeInt(npack, LActor.getServerId(actor)) -- 玩家服务器编号
		LDataPack.writeInt(npack, (isBelong and 1 or 0)) -- 是否是归属奖励

		System.sendPacketToAllGameClient(npack, 0)
	end
	print("darkhallbossfb.sendReward:send success, isBelong:".. (isBelong and 1 or 0) ..", actorId:"..tostring(LActor.getActorId(actor))
		..", rewardType:"..tostring(rewardType)..", actorSrvId:"..tostring(LActor.getServerId(actor)) .. " 奖励数量:" .. #reward)
end

--发送boss归属者信息
function sendBossBelongInfo(id, actor, oldBelong)
	SYSDEBUG("sendBossBelongInfo 下发归属者信息")
	local npack = nil
    if actor then
        npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_belongDarkhallUpdate) -- 72-46
    else
        npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
        LDataPack.writeByte(npack, Protocol.sCrossBossCmd_belongDarkhallUpdate)
    end

     local data = getBossData(id)

   	LDataPack.writeDouble(npack, oldBelong and LActor.getHandle(oldBelong) or 0)
	LDataPack.writeDouble(npack, data.bossBelong and LActor.getHandle(data.bossBelong) or 0)

	if(data.bossBelong) then
		local actorId = LActor.getActorId(data.bossBelong)
		local actorName = LActor.getActorName(actorId)
		SYSDEBUG("归属者名称:" .. actorName .. " 归属者handle:" .. LActor.getHandle(data.bossBelong))
	end

	if actor then
		if(data.bossBelong) then
			local actorId = LActor.getActorId(data.bossBelong)
			local actorName = LActor.getActorName(actorId)
			local logtmp = "玩家进入副本 归属信息handler:" .. (LActor.getHandle(data.bossBelong) or -1) .. " 归属者名称:" .. actorName
			sendTip(actor,logtmp,4)
			SYSDEBUG(logtmp)
		else
			sendTip(actor,"玩家进本 当前无归属者",4)
			SYSDEBUG("玩家进本 当前无归属者")
		end
        LDataPack.flush(npack)
    else
        Fuben.sendData(data.fbHandle, npack)
    end
end

--清空boss归属者
local function clearBossBelongInfo(id, actor)
    local bossData = getBossData(id)
    if nil == bossData then print("darkhallbossfb.clearBossBelongInfo:bossData is null, id:"..id) return end

    if actor == bossData.bossBelong then
        bossData.bossBelong = nil
		sendBossBelongInfo(id, nil, actor)

		--无归属回血
		if CrossBossBase.revivalTime and not bossData.revEid then
			bossData.revEid = LActor.postScriptEventLite(nil, CrossBossBase.revivalTime * 1000, function(_, bid)
				local data = getBossData(bid)
				data.revEid = nil
				if data.monster then
					LActor.changeHp(data.monster, LActor.getHpMax(data.monster))
					refreshShiled(data.id) -- 刷新BOSS护盾
				end
			end, id)
		end
    end
end

--进入公告
local function sendEnterNoticeId(actor, id) -- 7-11
	local data = getBossData(id)
	--发公告
	local npack = LDataPack.allocPacket()
	LDataPack.writeByte(npack, CrossSrvCmd.SCCrossBossCmd)
	LDataPack.writeByte(npack, CrossSrvSubCmd.SCBossCmd_enterDarkHallFb)
	LDataPack.writeString(npack, LActor.getName(actor)) -- actorname
	LDataPack.writeShort(npack, LActor.getServerId(actor)) -- 玩家服务器id
	LDataPack.writeShort(npack, id) -- 副本索引
	System.sendPacketToAllGameClient(npack, 0)
end

--进入副本的时候
local function onEnterFb(ins, actor)
	LActor.setCamp(actor, LActor.getActorId(actor))
	LActor.stopAI(actor)

	sendActorData(actor) -- 可归属次数信息

	--发送boss归属者信息
	sendBossBelongInfo(ins.data.id, actor, oldBelong)

	--保持副本id
	local var = getCrossStaticData(actor)
	var.id = ins.data.id

	sendEnterNoticeId(actor, ins.data.id)

	-- 进入副本的玩家列表
	local enterList = getEnterList(ins)
	local actorId = LActor.getActorId(actor)
	enterList[actorId] = {}
	enterList[actorId].name = LActor.getName(actor) -- 角色名称
	enterList[actorId].srvid = LActor.getServerId(actor) -- 所属服务器id
end

--退出的处理
local function onExitFb(ins, actor)
	local actorId = LActor.getActorId(actor)
	--local aName = LActor.getActorName(actorId)
	local data = getBossData(ins.data.id)

	--boss归属者退出副本
	clearBossBelongInfo(ins.data.id, actor)

	--记录cd
	local var = getCrossStaticData(actor)
	var.scene_cd = System.getNowTime() + CrossBossBase.cdTime
	var.id = nil

	--删除复活定时器
	if var.rebornEid then LActor.cancelScriptEvent(actor, var.rebornEid) var.rebornEid = nil end

	--退出把AI恢复
	local role_count = LActor.getRoleCount(actor)
	for i = 0,role_count - 1 do
		local role = LActor.getRole(actor,i)
		LActor.setAIPassivity(role, false)
	end

	local enterlist = getEnterList(ins)
	enterlist[actorId] = nil -- 清理玩家
end

--[[
    @desc: 玩家离线
    time:2020-03-26 10:08:37
    --@ins:
	--@actor: 
    @return:
]]
local function onOffline(ins, actor)
	onExitFb(ins, actor)
	LActor.exitFuben(actor)
end

-- 下发护盾信息 72-53
local function notifyShield(hfuben, curshield,maxShield)
    local npack = LDataPack.allocPacket()
    LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
	LDataPack.writeByte(npack, Protocol.sCrossBossCmd_DarkBossShield)
	LDataPack.writeInt(npack, curshield)
    LDataPack.writeInt(npack, maxShield)
    Fuben.sendData(hfuben, npack)
end

--boss收到伤害的时候
local function onBossDamage(ins, monster, value, attacker, res)
	local bossData = getBossData(ins.data.id)
	if monster ~= bossData.monster then
		SYSLOG("onBossDamage monster error")
		return 
	end

	--第一下攻击者为boss归属者,且该玩家在本里
	if nil == bossData.bossBelong and bossData.fbHandle == LActor.getFubenHandle(attacker) then
		--SYSDEBUG("开始设置归属者")
        local actor = LActor.getActor(attacker)
        if actor and false == LActor.isDeath(actor) and canGetBelong(actor, rewardType.bossReward) then
        	--改变归属者
			bossData.bossBelong = actor
			SYSDEBUG("设置归属者为:" .. LActor.getActorId(actor))
			sendBossBelongInfo(ins.data.id, nil, nil)

			--怪物攻击新的归属者
            if bossData.monster then LActor.setAITarget(bossData.monster, LActor.getLiveByJob(actor)) end

			--有新归属的时候清定时器
			if bossData.revEid then
				LActor.cancelScriptEvent(nil, bossData.revEid)
				bossData.revEid = nil
			end
		--else
			--SYSDEBUG("没发现玩家,或者玩家次数用完")
		end
	end

	-- 护盾
	local hpPer = res.ret / LActor.getHpMax(monster) * 100 -- 当前血量百分比 (实际血量/总血量*100)
	if(not DarkHallBossConfig[ins.data.id].shield) then return end -- 策划没配护盾的情况
	local conf = DarkHallBossConfig[ins.data.id].shield[1] or {} -- 策划配了护盾但没设置具体数值的情况
	if not bossData.shield or bossData.shield == 0 then
		if(hpPer <= conf.hp and not bossData.shieldflag) then -- 血量低于20 且没有触发过护盾
			SYSDEBUG("onBossDamage 设置护盾")
			bossData.shieldflag = true -- 已触发过,重置要刷新为false
			LActor.SetInvincible(monster, true) -- 设置无敌护盾
			bossData.shield = System.getNowTime() + conf.shield -- 写死是[1]
			notifyShield(bossData.fbHandle,conf.shield,conf.shield) -- 提醒客户端开盾
			LActor.postScriptEventLite(nil, (conf.shield or 0) * 1000, function() -- 注册定时器取消护盾
				LActor.SetInvincible(monster, false)
				bossData.shield = 0 -- 这个参数可能没用 后面再看看删除
				notifyShield(bossData.fbHandle,0,conf.shield)
			end)
		end
	end

end

local function onActorDie(ins, actor, killerHdl)
	if not actor then return end
	local et = LActor.getEntity(killerHdl)
    if not et then print("darkhallbossfb.onActorDie:et is null") return end

    local bossData = getBossData(ins.data.id)
    if nil == bossData then print("darkhallbossfb.onActorDie:bossData is null, id:"..ins.data.id) return end

    local killer_actor = LActor.getActor(et)

    --boss归属处理
    if actor == bossData.bossBelong then
		--归属者被玩家打死，该玩家是新归属者
        if killer_actor and LActor.getFubenHandle(killer_actor) == ins.handle and canGetBelong(killer_actor, rewardType.bossReward) then
            bossData.bossBelong = killer_actor
			--有新归属的时候清定时器
			if bossData.revEid then
				LActor.cancelScriptEvent(nil, bossData.revEid)
				bossData.revEid = nil
			end
            --怪物攻击新的归属者
            --if bossData.monster then LActor.setAITarget(bossData.monster, et) end
        else
            --bossData.bossBelong = nil
            clearBossBelongInfo(ins.data.id, actor)
        end

        --广播归属者信息
		sendBossBelongInfo(ins.data.id, nil, actor)
    end

    --目标是玩家才停止ai
    if LActor.getActor(LActor.getAITarget(LActor.getLiveByJob(killer_actor))) and
    	LActor.getActor(LActor.getAITarget(LActor.getLiveByJob(killer_actor))) == actor then
    	LActor.stopAI(killer_actor)
    end

    --复活定时器
    local var = getCrossStaticData(actor)
	var.resurgence_cd = System.getNowTime() + CrossBossBase.rebornCd
	var.rebornEid = LActor.postScriptEventLite(actor, CrossBossBase.rebornCd * 1000, reborn, ins.data.id)

    notifyRebornTime(actor, killerHdl)
end

local function sendBossData(actor)
	SYSDEBUG("sendBossData 发送BOSS的刷新信息")
	local npack = nil
	if actor then
		npack = LDataPack.allocPacket(actor, Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendDarkhallBossInfo) -- 72-41
	else
		npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, Protocol.CMD_CrossBoss)
		LDataPack.writeByte(npack, Protocol.sCrossBossCmd_SendDarkhallBossInfo)
	end
	if npack == nil then return end
	local data = getGlobalData()


	if not data.bossList then data.bossList = {} end

	LDataPack.writeShort(npack, table.getnEx(data.bossList)) -- boss数量

	for id, info in pairs(data.bossList or {}) do
		local refreshLeftTime = (info.bossRefreshTime or 0) - System.getNowTime() > 0 and (info.bossRefreshTime or 0) - System.getNowTime() or 0 -- boss下次刷新时间
		LDataPack.writeShort(npack, id) -- 配置的索引编号
		LDataPack.writeInt(npack, refreshLeftTime) -- boss剩余刷新时间
		--DEBUG(actor,"sendBossData 配置索引:" .. id .. " boss剩余刷新时间:" .. refreshLeftTime)
	end
	
	if actor then
		LDataPack.flush(npack)
	else
		System.broadcastData(npack)
	end
end

--BOSS死亡时候的处理
local function onMonsterDie(ins, mon, killerHdl)
	SYSDEBUG("onMonsterDie 怪物死亡触发,bossid:" .. ins.data.bossId)
    local bossId = ins.data.bossId -- 该副本里BOSS的id
    local monId = Fuben.getMonsterId(mon)
    if monId ~= bossId then
		print("darkhallbossfb.onMonsterDieP:monid("..tostring(monId)..") ~= bossId("..tostring(bossId).."), id:"..ins.data.id)
		return
	end
	
	local conf = DarkHallBossConfig[ins.data.id]

	local data = getBossData(ins.data.id)

	--发送奖励
	local enterlist = getEnterList(ins)

	if(data.bossBelong) then -- 有归属者才做发放奖励操作 
		local ret = reduceBelongCount(data.bossBelong, rewardType.bossReward)
		if(ret) then
			local dropId = conf.belongReward
			local rewards = drop.dropGroup(dropId)
			sendReward(data.bossBelong, rewards, rewardType.bossReward, ins.data.id, true)
		end

		--副本广播奖励
		local npack = LDataPack.allocBroadcastPacket(Protocol.CMD_CrossBoss, Protocol.sCrossBossCmd_SendWinInfo) -- 72-12
		LDataPack.writeInt(npack, LActor.getServerId(data.bossBelong)) -- 角色id
		LDataPack.writeString(npack, LActor.getName(data.bossBelong)) -- 归属者名称
		LDataPack.writeDouble(npack, LActor.getHandle(LActor.getLiveByJob(data.bossBelong)))
		LDataPack.writeShort(npack, #(rewards or {}))
		for k, v in pairs(rewards or {}) do
			LDataPack.writeInt(npack, v.type)
			LDataPack.writeInt(npack, v.id)
			LDataPack.writeInt(npack, v.count)
		end
		Fuben.sendData(data.fbHandle, npack)

		local enterList = getEnterList(ins)
		local strlog = "onMonsterDie rewardlist confId:" .. ins.data.id .. " belongActorId:" ..  LActor.getActorId(data.bossBelong) .. " joinActorId:"
		for joinActorId,_ in pairs(enterList) do
			strlog = strlog .. joinActorId .. "    "
		end
		SYSINFO(strlog)

		clearBossBelongInfo(ins.data.id, data.bossBelong)

		local actors = Fuben.getAllActor(data.fbHandle)
		if actors and data.monster then
			for i=1, #actors do
				local target = LActor.getAITarget(LActor.getLiveByJob(actors[i]))
				if target == data.monster then LActor.stopAI(actors[i]) end
			end
		end
	end

	--添加精英BOSS刷新定时器(无论有没有归属者)
	LActor.postScriptEventLite(nil, conf.refreshTime * 1000, function() refreshBossTimer(ins.data.id) end)
	data.bossRefreshTime = System.getNowTime() + conf.refreshTime
	sendBossInfo(ins.data.id) -- 本跨服boss信息
	sendBossData() -- boss信息
	data.monster = nil
	
end

--复活
local function onReqBuyCd(actor, packet)
    local data = getCrossStaticData(actor)

    --没有死光不能复活
	if false == LActor.isDeath(actor) then
		print("crossbossfb.onReqBuyCd: not all die,  actorId:"..LActor.getActorId(actor))
    	return
	end

	--复活时间已到
    if (data.resurgence_cd or 0) < System.getNowTime() then
    	print("crossbossfb.onReqBuyCd: reborn not in cd,  actorId:"..LActor.getActorId(actor))
    	return
    end

    --是否在副本
    if not data.id then print("crossbossfb.onReqBuyCd: reborn not in fb,  actorId:"..LActor.getActorId(actor)) return end

	--扣钱
    local yb = LActor.getCurrency(actor, NumericType_YuanBao)
    if CrossBossBase.rebornCost + (data.needCost or 0) > yb then
    	print("crossbossfb.onReqBuyCd: money not enough, actorId:"..LActor.getActorId(actor))
    	return
    end

    --跨服不扣元宝，回本服再扣
    if System.isCommSrv() then
		LActor.changeYuanBao(actor, 0 - CrossBossBase.rebornCost, "servercrossboss buy cd")
	else
		data.needCost = (data.needCost or 0) + CrossBossBase.rebornCost
	end

    --重置复活cd和定时器
	if data.rebornEid then LActor.cancelScriptEvent(actor, data.rebornEid) end
	data.rebornEid = nil
	data.resurgence_cd = nil

	notifyRebornTime(actor)

	--原地复活
	local x, y = LActor.getPosition(actor)
	LActor.relive(actor, x, y)

	LActor.setCamp(actor, LActor.getActorId(actor))
	LActor.stopAI(actor)
end

--取消归属者
local function onCancelBelong(actor, packet)
    --是否在跨服boss副本里
	local var = getCrossStaticData(actor)
	if not var.id then print("crossbossfb.onCancelBelong: not in fuben, actorId:"..LActor.getActorId(actor)) return end

	local bossData = getBossData(var.id)
	if nil == bossData then print("crossbossfb.onCancelBelong:bossData is null, id:"..tostring(var.id)) return end

	--是否是归属者
	if not bossData.bossBelong or bossData.bossBelong ~= actor then
		print("crossbossfb.onCancelBelong: not belong, actorId:"..LActor.getActorId(actor))
		return
	end

	clearBossBelongInfo(var.id, actor)
	LActor.stopAI(actor)
end



--创建副本
local function createBossFb(conf)
	local data = getGlobalData()
	if not data.bossList then data.bossList = {} end

	if not data.bossList[conf.id] then
		local fbHandle = Fuben.createFuBen(conf.fbid) -- 创建副本
		local ins = instancesystem.getInsByHdl(fbHandle)
		if ins then
			ins.data.id = conf.id
		else
			SYSLOG("createBossFb:ins nil,conf.id:"..conf.id)
			return
		end

		data.bossList[conf.id] = {}
		data.bossList[conf.id].id = conf.id
		data.bossList[conf.id].fbHandle = fbHandle

		refreshBossTimer(conf.id)
		SYSINFO("createBossFb success, conf.id:".. tostring(conf.id))
	end
end

--初始化副本
local function initBossDataFb()
	-- 创建精英BOSS副本
	for i=1, #DarkHallBossConfig do -- 精英BOSS
		createBossFb(DarkHallBossConfig[i]) -- 跨服精英BOSS 这里写-i是为了发公告的时候好确认是哪个精英boss 大于0的数字已经被跨服BOSS用了,0是苍月岛
	end
end

--活动开始
-- createflag 需要创建标志 true:需要创建 false:不要创建
function darkhallBossOpen(createflag)
	SYSINFO("darkhallBossOpen start")
	-- 开启战斗服boss
	if System.isCommSrv() then -- 普通服不开启
		SYSINFO("darkhallBossOpen error,common srv can not open eliteboss") 
		return 
	end
	local initFlag = getGlobalData().initflag
	local data = getSysData()
	if(initFlag) then
		SYSINFO("darkhallBossOpen has been initialized")
		return
	end

	--检测所有游戏服开服时间是否满足了条件
	local srvInfo = csbase.getCommonSrvList()
	for srvId, time in pairs(srvInfo or {}) do -- [id] = 开服时间
		if (CrossBossBase.darkhallbossopenDay or 0) > System.getTimeToNowDay(time)+1 then -- 开服days dmw
			SYSLOG("darkhallBossOpen:time not enough,srvId:" .. srvId)
			return
		end
	end

	--初始副本
	initBossDataFb()
	getGlobalData().initflag = true
	SYSINFO("darkhallBossOpen ok")
end

--服务器连接上来的时候
local function OnServerConn(srvId, sType)
	SYSDEBUG("OnServerConn 服务器连接处理开始 srvId:" .. srvId)
	local data = getGlobalData()
	for id, info in pairs(data.bossList or {}) do
		sendBossInfo(id, srvId)
		SYSINFO("OnServerConn:sendBossInfo scccess, srvId:"..tostring(srvId))
	end
	SYSDEBUG("OnServerConn 服务器连接处理完成 srvId:" .. srvId)
end

local function OnAllServerConn(sevList)
	SYSDEBUG("OnAllServerConn ALL服务器连接处理开始")
	darkhallBossOpen(true) -- 创建副本
	local data = getGlobalData()
	for id, info in pairs(data.bossList or {}) do
		sendBossInfo(id)
		SYSINFO("OnAllServerConn:sendBossInfo scccess, id:"..tostring(id))
	end
	SYSDEBUG("OnAllServerConn ALL服务器连接处理完成")
end

--启动初始化
local function initGlobalData()
	if System.isCommSrv() then -- 普通服不注册
		return
	end
	SYSDEBUG("initGlobalData DMWFLAG 暗殿BOSS初始化 START")
	--注册副本事件
	 for _, conf in pairs(DarkHallBossConfig) do -- 精英BOSS
		insevent.registerInstanceEnter(conf.fbid, onEnterFb) -- 进入副本
		insevent.registerInstanceMonsterDamage(conf.fbid, onBossDamage) -- 怪物受到攻击
		insevent.registerInstanceExit(conf.fbid, onExitFb) -- 玩家退出副本
		insevent.registerInstanceOffline(conf.fbid, onOffline) -- 玩家下线
		insevent.registerInstanceActorDie(conf.fbid, onActorDie) -- 玩家死亡
		insevent.registerInstanceMonsterDie(conf.fbid, onMonsterDie) -- boss死亡
    end

    netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_BuyDarkhallCd, onReqBuyCd) -- 角色花钱复活
	netmsgdispatcher.reg(Protocol.CMD_CrossBoss, Protocol.cCrossBossCmd_CancelDarkhallBelong, onCancelBelong) -- 取消归属


	--游戏服连接的时候
	if not System.isCommSrv() then
		csbase.RegAllConnected(OnAllServerConn) -- 所有游戏服完成连接
		csbase.RegConnected(OnServerConn) -- 单台服务器连接
	end
	SYSDEBUG("initGlobalData DMWFLAG 暗殿BOSS初始化 OVER")
end


table.insert(InitFnTable, initGlobalData)
--[[
local gmsystem = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.darkhallboss = function(actor, args)
	local time = System.getNowTime()
    darkhallBossOpen(true) -- 创建副本
end

-- @setelbleftcount 3
-- 设置跨服精英BOSS可获奖次数为3次
gmHandlers.setelbleftcount = function(actor, args)
	local var = getCrossStaticData(actor)
	local count = tonumber(args[1])
	setEliteBossCount(actor,count)
end
]]
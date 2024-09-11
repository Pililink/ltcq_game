--个人副本 恶魔殿
module("evilroomsystem", package.seeall)


--[[
evilroomdata = { -- 恶魔殿数据
	customsrecord, -- 通关记录,记录当前已通关fbindex
	dailychallengerecord, -- 每日挑战进度记录
	...
}
 ]]
 local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:evilroomsystem." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:evilroomsystem." .. log .. " actorid:" .. actorid)
	]]
end

local function SYSDEBUG(log) -- 上线后把内容注掉
	print("[SYSDEBUG]:evilroomsystem." .. log)
end

local p = Protocol
local EquipBagCount = 20   --扫荡限制空闲格子数
local config = DevilHallBossConfig

-- 获取当前系统数据
local function GetSysData(actor)
	local data = LActor.getStaticVar(actor)
	if data == nil then
		LOG(actor,"GetSysData fail")
		return nil 
	end
	if data.evilroomdata == nil then
		data.evilroomdata = {}
	end
	return data.evilroomdata
end

-- 获取通关记录
local function GetCustomsRecord(actor)
	local sysdata = GetSysData(actor)
	return sysdata.customsrecord or 1
end

local function SetCustomsRecord(actor,num)
	local sysdata = GetSysData(actor)
	sysdata.customsrecord = num
end

-- 获取副本今日挑战进度
local function GetDailyProgress(actor)
	local sysdata = GetSysData(actor)
	return sysdata.dailychallengerecord or 0
end

local function SetDailyProgress(actor,fbIndex)
	local sysdata = GetSysData(actor)
	if(not config[fbIndex]) then
		LOG(actor,"fbId not exist in config,id:" .. fbIndex )
	end
	sysdata.dailychallengerecord = fbIndex
end


-- 发送今日恶魔殿消息
local function SendEvilRoomInfo(actor)
	local data = GetSysData(actor)
	if(not data) then
		return
	end
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Fuben, Protocol.sFubenCmd_EvilRoomInfo) -- 1-41
	LDataPack.writeShort(npack,#config) -- 恶魔殿关卡总数量
	LDataPack.writeShort(npack,GetCustomsRecord(actor)) -- 已解锁最大关数
	LDataPack.writeShort(npack,GetDailyProgress(actor)) -- 今日挑战进度
	LDataPack.flush(npack)
	local strlog="SendEvilRoomInfo " .. " 总关卡:" .. #config .. " 已解锁:" .. GetCustomsRecord(actor) .. " 今日挑战进度:" .. GetDailyProgress(actor)
	DEBUG(actor,strlog)
end

-- 每次登陆
local function OnLogin(actor)
	SendEvilRoomInfo(actor)
end

local function OnNewDay(actor, login)
	DEBUG(actor,"OnNewDay")
	SetDailyProgress(actor,0)

	if not login then
		OnLogin(actor)
	end
end

--[[
    @desc: 检查挑战次数
    author:{author}
    time:2020-03-02 09:25:42
    --@actor: 
    @return:
]]
local function CheckCondition(actor,fbIndex)
	local conf = config[fbIndex] -- 配置
	if(not conf) then
		LOG(actor,"conf not exist,fbIndex:" .. fbIndex)
		return false
	end
	local canChallengeIndex = GetCustomsRecord(actor) + 1 -- 最大可挑战副本索引 参数检查
	if(fbIndex > canChallengeIndex) then
		DEBUG(actor," 未解锁")
		return false
	end
	local dailyNextIndex = GetDailyProgress(actor,fbIndex) + 1 -- 下一关id,通关顺序检查
	if(fbIndex ~= tonumber(dailyNextIndex)) then
		DEBUG(actor,"CheckCondition 下一关id不对,应该是:" .. dailyNextIndex .. " 实际是:" .. fbIndex)
		return false
	end
	local zsLevel = LActor.getZhuanShengLevel(actor) -- 转生等级检查
	if(1000*zsLevel < (conf.levelLimit or 0)) then
		LOG(actor,"CheckCondition item not engough")
		return false
	end
	--mmp
	for _,v in pairs(conf.cost) do -- 道具数量检查
		local itemId = v.id
		local itemCount = v.count
		local haveCount = LActor.getItemCount(actor, itemId)
		if(haveCount < itemCount) then -- 数量不够
			DEBUG(actor,"道具数量不足")
			return false
		end
	end
	return true
end

-- 挑战恶魔殿
local function OnChallenge(actor, packet)
	DEBUG(actor,"OnChallenge 收到1-42消息")
	local actorId = LActor.getActorId(actor)
	local fbIndex = LDataPack.readShort(packet) -- 配置中的索引
	DEBUG(actor,"OnChallenge fbIndex:" .. fbIndex)
	if(not CheckCondition(actor,fbIndex)) then -- 检查条件
		return
	end
	DEBUG(actor,"OnChallenge 完成条件检查")
	local conf = config[fbIndex]
--[[
	if LActor.isInFuben(actor) then -- 检查是否在副本中
		LOG(actor,"OnChallenge actor is in fuben,now exist")
		LActor.exitFuben(actor)
		return
	end
]]
	--获取副本Id
	local fbId = conf.fbid
	if not fbId then
		DEBUG(actor," not fbid")
		return
	end
	DEBUG(actor,"OnChallenge 即将挑战的副本id:" .. fbId)
	--创建副本
	local handleFuben = Fuben.createFuBen(fbId)
	if handleFuben == 0 then
		LOG(actor,"OnChallenge create fuben failed,fbid:".. fbId)
		return
	end
	DEBUG(actor,"OnChallenge 完成副本创建:" .. fbId .. " handle:" .. handleFuben)
	--记录进入前的数据, 在副本里有可能升级
	local ins = instancesystem.getInsByHdl(handleFuben)
	if ins ~= nil then
		ins.data.did = conf.id
		ins.data.lv = LActor.getLevel(actor)
	end
	local bossId = conf.bossId
	local monster = Fuben.createMonster(ins.scene_list[1], bossId)
	if(not monster) then
		LOG(actor,"OnChallenge monster create fail")
		return
	end
	DEBUG(actor,"OnChallenge 完成boss创建:" .. bossId)
	-- 随机一个点
	local randompos = math.random(1,#conf.enterPos)
	local posX = conf.enterPos[randompos].posX
	local posY = conf.enterPos[randompos].posY
	--进入副本
	LActor.enterFuBen(actor, handleFuben, ins.scene_list[1],posX,posY)
	DEBUG(actor,"OnChallenge 进入副本" .. fbId .. " ".. posX .. "," .. posY)
end

local function onOffline(ins, actor)
	SYSDEBUG("onOffline")
	ins:lose() -- 清理副本
	LActor.exitFuben(actor)
end

local function onMonsterDie(ins,mon)
	SYSDEBUG("onMonsterDie ")
	bossId = config[ins.data.did].bossId
	local monId = Fuben.getMonsterId(mon)
	if monId ~= bossId then
		SYSDEBUG("onMonsterDie 死掉的怪物id:" .. monId .. " 副本的bossId:" .. bossId)
		return
	end
	ins:win() -- 清理副本
	local actor = ins:getActorList()[1]
	if actor == nil then 
		LOG(actor,"onBossWin can't find actor") 
		return 
	end

	local fbIndex = ins.data.did -- 副本索引,自定义结构存的
	local conf = config[fbIndex]
	if conf == nil then 
		LOG(actor,"onMonsterDie conf not exist ins.data.did:".. ins.data.did)
		return 
	end

    local data = GetSysData(actor)
	if data == nil then 
		return 
	end

	SetDailyProgress(actor,ins.data.did) -- 每日记录
	local passFbId = tonumber(GetCustomsRecord(actor)) -- 解锁的最大关卡
	if(fbIndex >= passFbId and passFbId < #config) then --记录通关
		SetCustomsRecord(actor,passFbId+1)
	end
	SendEvilRoomInfo(actor)
	--消耗道具
	for _,v in pairs(conf.cost) do -- 道具数量检查
		local itemId = v.id
		local itemCount = v.count
		LActor.costItem(actor, itemId,itemCount, "action_evilroom_onchallenge")
	end

	local rewards = drop.dropGroup(conf.belongReward) -- 发奖励
	DEBUG(actor,"onBossWin 发放奖励")
	--LActor.giveAwards(actor, rewards, "auction_evilroom_award_" .. fbIndex)
	instancesystem.setInsRewards(ins, actor, rewards) -- 1-3触发客户端界面
end

local function onActorDie(ins, actor, killerHdl)
	SYSDEBUG("onActorDie")
	ins:lose() -- 清理副本
	instancesystem.setInsRewards(ins, actor, nil)
end

actorevent.reg(aeUserLogin, OnLogin)
actorevent.reg(aeNewDayArrive, OnNewDay)

netmsgdispatcher.reg(Protocol.CMD_Fuben, Protocol.cFubenCmd_EvilRoomChallenge, OnChallenge) --1-44 挑战恶魔殿

for _, v in pairs(config) do
	SYSDEBUG("dmwflag1 config.fbid:" .. v.fbid)
	local fbId = v.fbid
	insevent.registerInstanceMonsterDie(fbId, onMonsterDie)
	insevent.registerInstanceActorDie(fbId, onActorDie)
	insevent.registerInstanceOffline(fbId, onOffline)
	-- insevent.registerInstanceExit(fbId, onExitFb) -- 退出后副本让系统到时间自动回收,这里不做特殊处理
end


-- 以下是gm指令
local gmsystem    = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers

gmHandlers.clearevilroom = function(actor, args)
	local data = LActor.getStaticVar(actor)
	data.evilroomdata = nil
	OnLogin(actor)
end
--[[
gmHandlers.enterevilroom = function(actor,args)
	local actorId = LActor.getActorId(actor)
	local fbIndex = tonumber(args[1]) -- 副本索引

	if(not CheckCondition(actor,fbIndex)) then -- 检查条件
		return
	end
	local conf = config[fbIndex]
	--获取副本Id
	local fbId = conf.fbid
	if not fbId then
		DEBUG(actor," not fbid")
		return
	end

	--创建副本
	local handleFuben = Fuben.createFuBen(fbId) -- createInstance
	if handleFuben == 0 then
		LOG(actor,"OnChallenge create fuben failed,fbid:".. fbId)
		return
	end
	
	--记录进入前的数据, 在副本里有可能升级
	local ins = instancesystem.getInsByHdl(handleFuben)
	if ins ~= nil then
		ins.data.did = conf.id
		ins.data.lv = LActor.getLevel(actor)
	end
	local bossId = conf.bossId
	local monster = Fuben.createMonster(ins.scene_list[1], bossId)
	if(not monster) then
		LOG(actor,"OnChallenge monster create fail")
	end
	--进入副本
	LActor.enterFuBen(actor, handleFuben,ins.scene_list[1],conf.enterPos[1].posX,conf.enterPos[1].posY)
end
]]--
gmHandlers.reduceitem = function(actor,args)
	local actorId = LActor.getActorId(actor)
	local itemId = args[1]
	local count = args[2]
	LActor.costItem(actor, itemId, count, "gm operation:" .. actorId)
end

-- 成长基金
module("psubactivitytype23", package.seeall)
--[[
data define:
	data = {
		rewardsRecord 按位领取
		isBuy 是否购买基金
		loginday 购买登录基金后的天数
		expired 购买限时到期时间戳
	}
]]

local p = Protocol
local subType = 23

-- 获取登录天数
--[[
local function getLoginDay(actor, id)
	local basicData = LActor.getActorData(actor)
	local now = System.getNowTime()
	local create_time =  basicData.create_time

	local loginday = math.floor((now - create_time)/utils.day_sec)
	local record = pactivitysystem.getSubVar(actor, id)
	if record and record.data then
		return record.data.loginday = loginday
	end
	return loginday
end
]]

-- 下发数据
local function writeRewardRecord(npack, record, config, id, actor)
	if npack == nil then return end
	local now = System.getNowTime()
	if record and record.data then
		LDataPack.writeInt(npack, record.data.rewardsRecord or 0)
		LDataPack.writeShort(npack, record.data.isBuy and 1 or 0)
		LDataPack.writeShort(npack, record.data.loginday or 1)
		LDataPack.writeInt(npack, record.data.expired or 0)
		--print(LActor.getActorId(actor).." psubactivitytype23 expired: "..(record.data.expired or 0))
	else
		LDataPack.writeInt(npack, 0)
		LDataPack.writeShort(npack, 0)
		LDataPack.writeShort(npack, 1)
		LDataPack.writeInt(npack, System.getNowTime() + (PActivityType23Config[id][1].limittime or 0) * 3600)
	end
end

-- 检测等级达标奖励
local function checkLevelReward(index, config, actor, record, id)
	if config[index] == nil then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward config[index] err "..index)
		return false
	end

	if index <= 0 or index > 32 then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward index err "..index)
		return false
	end

	-- 初始化记录
	if not record.data then record.data = {} end

	if record.data.isBuy ~= 1 then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward not buy")
		return false
	end

	local cfg = config[index]
	
	--等级
	if LActor.getLevel(actor) < (cfg.level or 0) then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward not level("..LActor.getLevel(actor)..") cfg("..(cfg.level or 0)..")")
		return false
	end

	--转生
	if LActor.getZhuanShengLevel(actor) < (cfg.zslevel or 0) then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward not zhuanshenglevel("..LActor.getZhuanShengLevel(actor)..") cfg("..(cfg.zslevel or 0)..")")
		return false
	end

	if record.data.rewardsRecord == nil then
		record.data.rewardsRecord = 0
	end

	if System.bitOPMask(record.data.rewardsRecord, index) then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward has get "..index)
		return false
	end

	if not LActor.canGiveAwards(actor, config[index].rewards) then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLevelReward can't get "..index)
		return false
	end

	return true
end

-- 检测登录达标奖励
local function checkLoginReward(index, config, actor, record, id)
	if config[index] == nil then 
		return false
	end

	if index <= 0 or index > 32 then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLoginReward index err "..index)
		return false
	end

	-- 初始化记录
	if not record.data then record.data = {} end

	if not record.data.isBuy then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLoginReward not buy")
		return false
	end

	local cfg = config[index]
	
	--登录天数
	if (record.data.loginday or 0) < (cfg.loginday or 0) then
		print(LActor.getActorId(actor).." psubactivitytype23.checkLoginReward not loginday("..(record.data.loginday or 0)..") cfg("..(cfg.loginday or 0)..")")
		return false
	end

	if record.data.rewardsRecord == nil then
		record.data.rewardsRecord = 0
	end

	if System.bitOPMask(record.data.rewardsRecord, index) then
		return false
	end

	if not LActor.canGiveAwards(actor, config[index].rewards) then
		return false
	end

	return true
end

-- 获取奖励
local function getReward(id, typeconfig, actor, record, packet)
	local index = LDataPack.readShort(packet)
	local config = typeconfig[id]
	local ret = false

	-- 分基金类型
	if config[index] and config[index].level then
		ret = checkLevelReward(index, config, actor, record, id)
	elseif config[index] and config[index].loginday then
		ret = checkLoginReward(index, config, actor, record, id)
	end

	-- 领取结果及标记
	if ret then
		record.data.rewardsRecord = System.bitOpSetMask(record.data.rewardsRecord, index, true)
		LActor.giveAwards(actor, config[index].rewards, "pactivity type23 rewards")
		--公告广播
		if config[index].notice then
			noticemanager.broadCastNotice(config[index].notice, LActor.getName(actor))
		end
	end
	
	local npack = LDataPack.allocPacket(actor, p.CMD_PActivity, p.sPActivityCmd_GetRewardResult)
	LDataPack.writeByte(npack, ret and 1 or 0)
	LDataPack.writeInt(npack, id)
	LDataPack.writeShort(npack, index)
	LDataPack.writeInt(npack, record.data and record.data.rewardsRecord or 0)
	LDataPack.flush(npack)
end

-- 开启活动事件
local function openActivity(id, typeconfig, actor, record)
	record.data = {}
	local conf = typeconfig[id]
	if conf == nil then
		print(LActor.getActorId(actor).." psubactivitytype23.openActivity conf nil id: "..id)
		return
	end

	record.data.expired = System.getNowTime() + (conf[1].limittime or 0) * 3600
	record.data.loginday = 1
end

local function onNewDayLogin(id, conf)
    return function(actor)
        -- 判断活动是否开启过，未开启的活动不处理
		if not pactivitysystem.isPActivityOpened(actor, id) then
			return
		end
		if pactivitysystem.isPActivityEnd(actor, id) then return end

		local record = pactivitysystem.getSubVar(actor, id)
		if not record then
			print(LActor.getActorId(actor).." psubactivitytype23 onLogin record is nil,actor:"..LActor.getActorId(actor)..",id"..id)
			return
		end

		-- 初始化数据
		if not record.data then record.data = {} end
		record.data.loginday = (record.data.loginday or 0) + 1
		pactivitysystem.sendActivityData(actor, id)
    end
end

local function onLevelUp(id, conf)
	--return function(actor)
	--pactivitysystem.sendActivityData(actor, id)
	--end
end

local function initFunc(id, conf)
	local needRegLoginEvent = false
	local needRegLevelEvent = false
	
	for _,v in pairs(conf) do
		if v.loginday then
			needRegLoginEvent = true
			break
		end
		--if v.level then
		--	needRegLevelEvent = true
		--	break
		--end
	end
	
	if needRegLoginEvent then
		actorevent.reg(aeNewDayArrive, onNewDayLogin(id, conf))
	end
	--if needRegLevelEvent then
	--	actorevent.reg(aeNewDayArrive, onNewDayLogin(id, conf))
	--end
end

function setBuy(actor, id)
	local record = pactivitysystem.getSubVar(actor, id)
	if not record.data then record.data = {} end

	local accountName = LActor.getAccountName(actor)
	local level = LActor.getLevel(actor)
	local actorid = LActor.getActorId(actor)
	System.logCounter(actorid, tostring(accountName), tostring(level or 0), "ptype23", id)

	record.data.isBuy = true
	pactivitysystem.sendActivityData(actor, id)
end

-- 请求购买（元宝）
local function buyFund( actor, packet )
	local id = LDataPack.readInt(packet)
	local conf = PActivityType23Config[id]
	if conf == nil then
		print(LActor.getActorId(actor).." psubactivitytype23.buyFund conf nil id: "..id)
		return
	end
	local price = conf[1]
	if price == nil then
		print(LActor.getActorId(actor).." psubactivitytype23.buyFund price nil id: "..id)
		return
	end

	--过期判断
	local record = pactivitysystem.getSubVar(actor, id)
	if not record.data then record.data = {} end
	if record.data.expired and (record.data.expired < System.getNowTime()) then
		print(LActor.getActorId(actor).." psubactivitytype23.buyFund expired id:"..id)
  		LActor.sendTipmsg(actorPtr, "已过期，无法购买!", ttScreenCenter)
		return 
	end

	--判断钱是否足够
	local yb = LActor.getCurrency(actor, NumericType_YuanBao)
	if (price.yb or 0) > yb then 
		print(LActor.getActorId(actor).." psubactivitytype23.buyFund yuanbao not enough id:"..id)
		--local tip = string.format(online == 1 and LangFriend.fr024 or LangFriend.fr025, name)
  		LActor.sendTipmsg(actorPtr, "元宝不足，请充值!", ttScreenCenter)
		return 
	end
	LActor.changeYuanBao(actor, -price.yb, "psubactivitytype23 buyFund "..price.yb)

	setBuy(actor, id)
end

-- 请求购买（rmb）
function recharge(id, actorid)
	local actor = LActor.getActorById(actorid)
	if actor then
		setBuy(actor, id)
	else
		asynevent.reg(actorid,function(imageActor,srcActorId)
			print("onFeeCallback psubactivitytype23 srcActorId: "..srcActorId.." id: "..id)
            setBuy(imageActor, id)
            LActor.saveDb(imageActor)
            end,actorid)
	end
end

pactivitysystem.regConf(subType, PActivityType23Config)
pactivitysystem.regInitFunc(subType, initFunc)
pactivitysystem.regWriteRecordFunc(subType, writeRewardRecord)
pactivitysystem.regGetRewardFunc(subType, getReward)
pactivitysystem.regOpenActivityFuncs(subType, openActivity)

netmsgdispatcher.reg(p.CMD_PActivity, p.cPActivityCmd_ReqBuyFund, buyFund)

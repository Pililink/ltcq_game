--[[
    工会召唤系统:转发客户端的消息,消耗道具,cd判断
    玩家点击客户端按钮发送对应的协议跳转进入使用者指定的boss副本
]]
module("guildgather", package.seeall)
-- 日志相关
local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:guildgather." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
    --[[
	local actorid = LActor.getActorId(actor)
    print("[DEBUG]:guildgather." .. log .. " actorid:" .. actorid)
    ]]
end

--系统内容
local config = GuildCallConfig
--[[
    guildgatherdata = {
        usecount, -- 今日使用次数
        nextusetime, -- 下一次使用时间
    }
]]
local function getStaticData(actor)
	local var = LActor.getStaticVar(actor)
    if var == nil then
        LOG(actor,"getStaticData fail") 
        return nil 
    end

	if var.guildgatherdata == nil then
		var.guildgatherdata = {}
	end
	return var.guildgatherdata
end

local function clearDailyData(actor)
    local dailyData = getStaticData(actor)
    if(not dailyData) then  return end
    dailyData.usecount = 0
end
--获取当日使用次数
local function getUseCount(actor)
    local dailyData = getStaticData(actor)
    return dailyData.usecount or 0
end

--获取下次使用时间
local function getNextUseTime(actor)
    local dailyData = getStaticData(actor)
    return dailyData.nextusetime or 0 --时间戳
end

-- 37-32使用情况
local function sendInfo(actor,gatherFlag) -- gatherFlag 是否是召唤成功后的信息
    local nextTime = getNextUseTime(actor) -- 下次使用时间
    local leftTime = nextTime - System.getNowTime()  -- 剩余时间
    if(leftTime<0) then
        leftTime = 0
    end
    local flag = gatherFlag and 1 or 0
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_Guild, Protocol.sGuildCmd_GuildGather) -- 37-32 召唤信息,包含道具,cd,是否成功召唤
    LDataPack.writeShort(pack,getUseCount(actor)) -- 今日使用次数
    LDataPack.writeInt(pack,leftTime) -- 下次使用时间倒计时时间
    LDataPack.writeShort(pack, flag) -- 召唤标志位 0 普通时候的信息 1召唤成功的信息
    LDataPack.flush(pack)
end

-- 更新每日信息(每次使用道具成功后调用)
local function updateDailyData(actor)
    local dailyData = getStaticData(actor)
    if(not dailyData) then return end
    dailyData.usecount = (dailyData.usecount or 0) + 1
    dailyData.nextusetime = System.getNowTime() + config.cd
    sendInfo(actor,true)
end

-- 检查使用道具条件
local function checkCondtion(actor)
    local guildId = LActor.getGuildId(actor)
    if(guildId == 0) then return false end -- 没有工会
    local haveCount = LActor.getItemCount(actor, config.costitem)
    if(haveCount < config.count) then -- 道具数量不够
        -- 查元宝
        local curYuanBao = LActor.getCurrency(actor, NumericType_YuanBao)
        if(curYuanBao < config.costyb) then
            LOG(actor,"checkCondtion item is not enough")
            LActor.sendTipmsg(actor,"道具不足")
            return false
        end
    end

    local useCount = getUseCount(actor)
    if(useCount>=config.times) then
        LOG(actor,"checkCondtion config.times limit,useCount:" .. useCount .. " limit:" .. config.times)
        sendInfo(actor)
        return false
    end
    local time = System.getNowTime()
    if(time < getNextUseTime(actor)) then
        LOG(actor,"checkCondtion Time is not up")
        sendInfo(actor)
        return false
    end
end

-- 消耗道具
local function consumeItem(actor,itemId,count,useYubao,log)
    local haveCount = LActor.getItemCount(actor, itemId)
    if(haveCount >= count) then -- 道具数量够
        LActor.costItem(actor, itemId, count, log)
        return true
    end
    -- 查元宝
    local curYuanBao = LActor.getCurrency(actor, NumericType_YuanBao)
    if(curYuanBao >= useYubao) then
        LActor.changeCurrency(actor, NumericType_YuanBao, -useYubao, log)
        return true
    end
    LOG(actor,"consumeItem item not enough")
    return false
end

-- 工会召集
local function onGuildGather(actor, packet)
    local msg = LDataPack.readString(packet)
    DEBUG(actor,msg)
    local guild = LActor.getGuildPtr(actor)
    if(not guild) then
        LOG(actor,"onGuildGather guild not exist")
        return
    end
    if(false == checkCondtion(actor)) then -- 条件检查
        LOG(actor,"onGuildGather mismatch condition")
        return false
    end
    -- 扣除道具
    local bResult = consumeItem(actor,config.costitem,config.count,config.costyb,"action_guildgather_onGuildGather")
    if(bResult == false) then
        LOG(actor,"onGuildGather consumeItem fail")
        return
    end
    updateDailyData(actor) -- 更新cd和使用次数,并通知客户端
    guildchat.sendNotice(guild, msg, true)
end

local function onLogin(actor)
    sendInfo(actor)
end

local function onNewDay(actor, isLogin)
    clearDailyData(actor)
    if(not isLogin) then
        onLogin(actor)
    end
end
-- actor事件
actorevent.reg(aeNewDayArrive, onNewDay)
actorevent.reg(aeUserLogin, onLogin)
netmsgdispatcher.reg(Protocol.CMD_Guild, Protocol.cGuildCmd_GuildGather, onGuildGather) --37-32 工会召集
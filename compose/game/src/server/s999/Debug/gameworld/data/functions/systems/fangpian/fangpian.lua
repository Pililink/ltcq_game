-- 防骗指南
module("fangpian", package.seeall)
--[[
    fangpiandata = {
        awardstatus, -- 今日奖励领取状态
    }
]]

local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:fangpian." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:fangpian." .. log .. " actorid:" .. actorid)
	]]
end

local function sendTip(actor,tipmsg, type)
    --[[
	local msgtype = 4
	if(type) then
		msgtype = type
	end
    LActor.sendTipmsg(actor, tipmsg .. " SERVER DEBUG", msgtype)
    ]]
end

local config = FangPianConfig

-- 获取防骗指南数据
local function getData(actor)
	local var = LActor.getStaticVar(actor)
    if (var == nil) then
        LOG(actor,"getData fail") 
        return 
    end
	if (var.fangpiandata == nil) then
		var.fangpiandata = {}
	end
	return var.fangpiandata
end

-- 获取每日领取状态
local function getAwardStatus(actor)
    local data = getData(actor)
    if(not data) then
        return 1 -- 找不到数据,结果默认1 已领取
    end
    return data.awardstatus or 0
end

local function setAwardStatus(actor,status)
    local data = getData(actor)
    if(not data) then
        return 1 -- 找不到数据,结果默认1 已领取
    end
    data.awardstatus = status
end

-- 发送奖励领取状态 29-4
local function sendAwardInfo(actor)
    local awardStatus = getAwardStatus(actor)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sFangpian_AwardInfo) -- 29-4
    LDataPack.writeShort(npack,awardStatus)
    LDataPack.flush(npack)
    sendTip(actor,"服务器推送协议29-4,领取状态为:" .. awardStatus)
end

-- 发送奖励领取结果 29-5
-- result 0:成功 其他失败
local function sendAwardResult(actor, result)
    local awardStatus = getAwardStatus(actor)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sFangpian_AwardRep) -- 29-5
    LDataPack.writeShort(npack, result)
    LDataPack.flush(npack)  
end

local function getAward(actor,pack)
    local result = 1 -- 领取失败
    local awardStatus = getAwardStatus(actor)
    if(awardStatus == 0) then
        setAwardStatus(actor,1) -- 设置领取状态1已领取
        LActor.giveAward(actor,config[1].rewards, "action_fangpian_getAward")
        result = 0
    end
    sendAwardResult(actor,result)
    sendAwardInfo(actor)
end

local function onLogin(actor)
    sendAwardInfo(actor)
end

local function onNewDay(actor,loginflag)
    setAwardStatus(actor,0)
    if(not loginflag) then
        onLogin(actor)
    end
end

actorevent.reg(aeUserLogin, onLogin)
actorevent.reg(aeNewDayArrive, onNewDay)
netmsgdispatcher.reg(Protocol.CMD_Gift, Protocol.cFangpian_AwardReq, getAward) -- 29-5 请求领取防骗奖励

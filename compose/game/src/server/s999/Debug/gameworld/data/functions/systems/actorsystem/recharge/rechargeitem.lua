--多种充值套餐 ,这功能前提需要保证在actorsystem.lua中，rechargeitem要在dailyrecharge之前require，保证事件调用的顺序

--[[
data define:

    rechargeItemData = {
        record  按位读取
        restmark 充值奖励重置key
    }
--]]

module("rechargeitem", package.seeall)
local postscripttimer = require("base.scripttimer.postscripttimer")
--[[
 {
    restmark 充值奖励充值KEY
 }
]]
local function getSysVar()
    local var = System.getStaticVar()
    if var.rechargeitem == nil then 
        var.rechargeitem = {}
    end
    return var.rechargeitem
end

function hefuCheckRestMark()
    for _,times in ipairs(ChongZhiBaseConfig.hfRestNum or {}) do
        if hefutime.getHeFuCount() == times then
            local svar = getSysVar()
            svar.restmark = System.getNowTime()
            break
        end
    end
end

local function hefuCheckRestRecharge()
	for _,times in ipairs(ChongZhiBaseConfig.hfRestNum or {}) do
		if hefutime.getHeFuCount() == times then
			return times
        end
    end
	return 0
end

local function getStaticData(actor)
    local var = LActor.getStaticVar(actor)
    if nil == var.rechargeItemData then var.rechargeItemData = {} end
    local svar = getSysVar()
    if svar.restmark ~= var.rechargeItemData.restmark then
        var.rechargeItemData.restmark = svar.restmark
        var.rechargeItemData.record = nil
    end
    return var.rechargeItemData
end

--充值双倍记录重置
function resetRecord(actor, times)
    local var = getStaticData(actor)
    if var then
		if var.resetRechargeRecord == nil or var.resetRechargeRecord ~= times then 
            print("rechargeitem.resetRecord aid:"..LActor.getActorId(actor).." times:"..(times or 0))
			var.record = nil
			var.resetRechargeRecord = times
		end
    end
end

function resetAllRecord(resetFlag,nextResetTime)
    local svar = getSysVar()
    if(resetFlag == 0) then
        svar.restmark = System.getNowTime()
        print("[SYSINFO]:rechargeitem.resetAllRecord")
        return
    end
    local now = System.getNowTime()

    local resetTime = nextResetTime - now
    if(resetTime<=0) then 
        print("[SYSERROR]:rechargeitem.resetAllRecord timeout") -- 时间设置太早了
        svar.restmark = System.getNowTime() -- 直接开了
        return 
    end
    postscripttimer.postOnceScriptEvent(nil, resetTime*1000, function(...) svar.restmark = System.getNowTime() end) -- 添加定时器
    print("[SYSINFO]:rechargeitem.resetAllRecord resetlefttime:" .. resetTime)
    -- 不搞取消重置功能了
end

--获取该金额配置
local function getConfig(count)
	local conf = nil
	for k, data in pairs(RechargeItemsConfig or {}) do
		if data.amount == count then conf = data break end
	end

	return conf
end

--判断该索引的金额是否充值过了
local function checkIsRecharge(actor, index)
    local var = getStaticData(actor)
    if not System.bitOPMask(var.record or 0, index) then return false end

    return true
end

local function sendRechargeInfo(actor)
 	local data = getStaticData(actor)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Recharge, Protocol.sRechargeCmd_RechargeItemRecord)
    LDataPack.writeInt(npack, data.record or 0)

    LDataPack.flush(npack)
end

local function onRecharge(actor, count)
	--是否为首充
	if true == dailyrecharge.isFirstRecharge(actor) then return end

	local actorId = LActor.getActorId(actor)
    local config = getConfig(count)
    if not config then print("rechargeitem.onRecharge:config is nil, count:"..tostring(count)..", actorId:"..tostring(actorId)) return end

    if true == checkIsRecharge(actor, config.id) then
    	--print("rechargeitem.onRecharge:already recharge before, count:"..tostring(count)..", actorId:"..tostring(actorId))
    	return
    end

	local data = getStaticData(actor)
    data.record = System.bitOpSetMask(data.record or 0, config.id, true)

    LActor.changeYuanBao(actor, config.award, "rechargeitem award:"..tostring(config.award))
    chargemail.sendMailByChargeItem(actor, count + config.award)

    print("rechargeitem.onRecharge:rechargeItem return payCount:"..tostring(config.award)..",actorId:"..tostring(LActor.getActorId(actor)))

    sendRechargeInfo(actor)
end

local function onLogin(actor)
	local times = hefuCheckRestRecharge()
	if times > 0 then
		resetRecord(actor, times)
	end
    sendRechargeInfo(actor)
end

actorevent.reg(aeRecharge, onRecharge)
actorevent.reg(aeUserLogin, onLogin)

-- 豪华连冲
module("psubactivitytype26", package.seeall)

local subType = 26

--[[
data define:

    dailyrechargeData = {
        rewardRecord = {    -- number    每日充值奖励信息
             [firstReward] = 0,  -- 0不可领取，1可以领取
        }
        payCount -- number      当天已冲金额
        day   --连充天数
        state --每天只能累加一次
    }
--]]

-- 下发数据
local function writeRewardRecord(npack, record, config, id, actor)
    if not record.data then record.data = {} end
    if not record.data.day then record.data.day = 0 end
    if not record.data.state then record.data.state = 0 end
    if not record.data.payCount then record.data.payCount = 0 end
    local count = #PActivityType26Config[id]
    print("下发数据count"..count.."id"..id.."day"..record.data.day)
    LDataPack.writeInt(npack, (record.data.day or 0))
    LDataPack.writeInt(npack, (count or 0))
    for i=1, count do
        LDataPack.writeInt(npack, record.data[i] or 0)
    end
end

-- 领取奖励
local function getReward(id, typeconfig, actor, record, packet)
    print("领取奖励")
    local day = LDataPack.readInt(packet)
    local config = typeconfig[id][day]
    if config then
        if day <= record.data.day and record.data[day] ~= 1 then
             LActor.giveAwards(actor, config.awardList, "pactivity type26 rewards")
         end
         print("发送奖励成功"..record.data.day)
        record.data[day] = 1
    end
    local state = record.data[day] or 0
    print("day"..day.."state"..state)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_PActivity, Protocol.sPActivityCmd_SendReawardData) 
    LDataPack.writeInt(npack, id)
    LDataPack.writeInt(npack, day)
    LDataPack.writeInt(npack, state)
    LDataPack.flush(npack)
end

-- 新开启活动，初始化充值金额
local function openActivity(id, typeconfig, actor, record)
    print("登录"..id)
    record.data = {}
	local conf = typeconfig[id]
	if conf == nil then
		print(LActor.getActorId(actor).." psubactivitytype26.openActivity conf nil id: "..id)
		return
	end
    record.data.payCount = 0
    record.data.state = 0
end

local function onRecharge(id, conf)
    print("充值成功"..id)
    return function(actor, value)
        -- 判断活动是否开启过，未开启的活动不处理
		if not pactivitysystem.isPActivityOpened(actor, id) then
			return
		end
		if pactivitysystem.isPActivityEnd(actor, id) then return end

		local record = pactivitysystem.getSubVar(actor, id)
		if not record then
			print(LActor.getActorId(actor).." psubactivitytype26 onLogin record is nil,actor:"..LActor.getActorId(actor)..",id"..id)
			return
		end

        record.data.payCount = record.data.payCount + (value or 0)  --充值金额达到额度，day+1
        if record.data.payCount >= PActivityType26Config[id][1].val then
            if record.data.state == 0 then
                record.data.day = (record.data.day or 0) + 1
                record.data.state = 1
            end
        end
		pactivitysystem.sendActivityData(actor, id)
    end   
end

local function onReChargeNewDay(id,conf)
    print("新的一天"..id)
    return function(actor, value)
        -- 判断活动是否开启过，未开启的活动不处理
		if not pactivitysystem.isPActivityOpened(actor, id) then
			return
		end
		if pactivitysystem.isPActivityEnd(actor, id) then return end

		local record = pactivitysystem.getSubVar(actor, id)
		if not record then
			print(LActor.getActorId(actor).." psubactivitytype26 onLogin record is nil,actor:"..LActor.getActorId(actor)..",id"..id)
			return
        end
        record.data.payCount = 0
        record.data.state = 0
    end
end


local function initFunc(id, conf)
    print("注册回调"..id)
    actorevent.reg(aeRecharge, onRecharge(id, conf))
    actorevent.reg(aeNewDayArrive, onReChargeNewDay(id,conf))
end

pactivitysystem.regConf(subType, PActivityType26Config)

pactivitysystem.regInitFunc(subType, initFunc)
pactivitysystem.regWriteRecordFunc(subType, writeRewardRecord)
pactivitysystem.regGetRewardFunc(subType, getReward)
pactivitysystem.regOpenActivityFuncs(subType, openActivity)


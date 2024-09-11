
module("rechargelimitbuy", package.seeall)

--[[

限购礼包数据(周期内可购买的礼包数量限制)
rechargelimitbuy = {
	records={
			[id1] = {
				count = 0, -- 已购买次数
				resetdays, -- 上一次被重置的时间,即本期开始时间
			}
			[id2] = {
				count = 0, -- 已购买次数
				resetdays, -- 上一次被重置的时间
			}
			...
	}
	hefuTime, -- 上一次重置时的合服次数
}
]]

local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:rechargelimitbuy." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:rechargelimitbuy." .. log .. " actorid:" .. actorid)
	]]
end

local function getStaticData(actor)
    local var = LActor.getStaticVar(actor)
	if var == nil then
		print("rechargelimitbuy.getStaticData error")
		return nil 
	end
    if var.rechargelimitbuy == nil then
        var.rechargelimitbuy = {}
    end
    return var.rechargelimitbuy
end

local function getRecords(actor)
	local data = getStaticData(actor)
	if(not data) then
		LOG(actor,"getRecords fail")
		return nil
	end
	if(not data.records) then data.records = {} end
	return data.records
end

local function getBuyCount(actor,giftBagId)
	local records = getRecords(actor)
	if(not records) then
		LOG(actor,"getBuyCount fail")
		return nil
	end
	if(not records[giftBagId]) then
		records[giftBagId] = {}
	end
	return records[giftBagId].count or 0
end


local function loadTime(conf)
	if conf.timeType == 0 then
		--startTime
        local d,h,m = string.match(conf.startTime, "(%d+)-(%d+):(%d+)")
        if d== nil or h == nil or m == nil then
            return 0,0,true
        end

        local st = System.getOpenServerStartDateTime()
        st = st + d*24*3600 + h*3600 + m*60 -- 开始时间

        --endTime
        d,h,m = string.match(conf.endTime, "(%d+)-(%d+):(%d+)")
        if d== nil or h == nil or m == nil then
            return 0,0,true
        end

        local et = System.getOpenServerStartDateTime()
        et = et + d*24*3600 + h*3600 + m*60

        return st, et
	elseif conf.timeType == 1 then
		--固定时间
        --startTime
        local Y,M,d,h,m = string.match(conf.startTime, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
        if Y == nil or M == nil or d == nil or h == nil or m == nil then
            return 0,0,true
        end

        local st = System.timeEncode(Y, M, d, h, m, 0)

        --endTime
        local Y,M,d,h,m = string.match(conf.endTime, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
        if Y == nil or M == nil or d == nil or h == nil or m == nil then
            return 0,0,true
        end

        local et = System.timeEncode(Y, M, d, h, m, 0)

        return st, et
	elseif conf.timeType == 2 then
		-- 合服时间
        local hefutime = getHeFuTime() or 0
        -- print("hefutime......" .. hefutime .. ", serveropentime..." .. System.getOpenServerStartDateTime() .. ", nowtime ..." .. System.getNowTime())
        if not hefutime then
            return 0,0,true
        end

        --startTime
        local d,h,m = string.match(conf.startTime, "(%d+)-(%d+):(%d+)")
        if d == nil or h == nil or m == nil then
            return 0,0,true
        end
        local st = hefutime + d*24*3600 + h*3600 + m*60

        -- endTime
        d,h,m = string.match(conf.endTime, "(%d+)-(%d+):(%d+)")
        if d== nil or h == nil or m == nil then
            return 0,0,true
        end
        local et = hefutime + d*24*3600 + h*3600 + m*60

        return st, et
    else
    	return 0,0,true
	end

	--[[
	local Y,M,d,h,m = string.match(conf.opentime, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
	if Y == nil or M == nil or d == nil or h == nil or m == nil then
		return 0,0,true
	end

	local st = System.timeEncode(Y, M, d, h, m, 0)

	--endTime
	local Y,M,d,h,m = string.match(conf.endtime, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
	if Y == nil or M == nil or d == nil or h == nil or m == nil then
		return 0,0,true
	end

	local et = System.timeEncode(Y, M, d, h, m, 0)

	return st, et
	--]]
end

-- 合服重置购买次数
local function hefuCheckRest()
	for _,times in ipairs(BaseTimePackageConfig.hfRestNum or {}) do
		if hefutime.getHeFuCount() == times then
			return times
        end
    end
	return 0
end

-- 购买次数重置(合服原因重置)
function resetRecord(actor, times)
    local var = getStaticData(actor)
    if var then
		if var.hefuTime == nil or var.hefuTime ~= times then 
			var.records = {}
			var.hefuTime = times
		end
    end
end

-- 剩余购买次数
local function getLeftBuyCount(actor, conf)
	if not conf then
		print("conf is nil")
        return
	end
	local data = getStaticData(actor)
	if not data then print("[ERROR] rechargelimitbuy not actor buyRecord") return end
	if not data.records then -- data.records = data.records or {} 这么使用会有问题,原因不明,所以改为了if
        data.records = {}
	end
	if not data.records then
        print("data.records a nil value------------------------------------------------")
	end
	local records = data.records
	if(not records[conf.Id]) then
        records[conf.Id] = {}
	end
	local count = records[conf.Id].count or 0
	--print("剩余可购买次数为".. conf.buyTime - (count or 0))
	return conf.buyTime - (count or 0)
end

--[[
    @desc: 是否能够买
    time:2020-03-23 10:31:17
    --@actor:
	--@conf: TimePackageConfig[Id]
    @return:
]]
local function canBuy(actor, conf)
	local data = getStaticData(actor)
	if not data then print("[ERROR] rechargelimitbuy not actor buyRecord") return false end 
	local buyCount = getBuyCount(actor,conf.Id)
	if(not buyCount) then
		LOG(actor,"canBuy getBuyCount data fail")
		return false
	end
	if(buyCount < conf.buyTime) then
		if(BaseTimePackageConfig.Firstrecharge and BaseTimePackageConfig.Firstrecharge == 1) then -- 首冲才能开启
			if((not conf.type or conf.type == 0) and (not dailyrecharge.hasRecharged(actor))) then -- 200-299是限购礼包,限购礼包需要充值之后才能出现
				DEBUG(actor,"canBuy:actor was not recharged") -- 未充值
				return false
			end
		end
		return true
	else
		DEBUG(actor,"canBuy:buyTime limit")
	end
	return false
end

-- 记录购买
local function buyRecord(actor, conf)
	local data = getStaticData(actor)
	if not data then print("[ERROR] rechargelimitbuy not actor buyRecord") return end 

	if not data.records then 
		data.records = {}
	end
	if not data.records[conf.Id] then
        data.records[conf.Id] = {}
	end
	if not data.records[conf.Id].count then
		data.records[conf.Id].count = 0
	end
	data.records[conf.Id].count = data.records[conf.Id].count + 1
end

-- 获取本阶段结束时间(只有循环的礼包才有阶段结束时间)
local function getStageEndtime(actor, giftid)
	if not TimePackageConfig[giftid].resetday or  TimePackageConfig[giftid].resetday == 0 then -- 非循环活动
		--print("不是循环活动活动id" .. giftid)
		return
	end
	local conf = TimePackageConfig[giftid]
	local dx,h,m = string.match(conf.endTime, "(%d+)-(%d+):(%d+)") -- 获取时,分 日期dx不需要
	local data = getStaticData(actor)
	if(not data.records[giftid] or not data.records[giftid].resetdays ) then
		print("data[giftid].resetdays is nil" .. giftid) -- 不重置的这里找不到
        return
	end
	
	local d = data.records[giftid].resetdays + conf.resetday -- 下次重置时间
	d = d < tonumber(dx) and d or tonumber(dx) -- 取小的,策划要求程序支持非完整周期
	--print("珍宝阁活动:" .. giftid .. " 当前重置时间是开服后:" .. data.records[giftid].resetdays .. " 当前阶段结束时间是开服后:" .. d)
	local endtime = System.getOpenServerStartDateTime() --开服0点
	endtime = endtime + d*24*3600 + h*3600 + m*60 -- 结束时间
    return endtime
end

-- 发送限购礼包信息
local function sendLimitBuyInfo(actor)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Recharge, Protocol.sRechargeCmd_LimitBuy)
	local npos = LDataPack.getPosition(npack)
	LDataPack.writeInt(npack, 0)
	local ncount = 0
	for id, conf in pairs(TimePackageConfig) do -- id是礼包id
		local now_t = System.getNowTime()
		local st, et, err = loadTime(conf)
		if err then 
			print("sendLimitBuyInfo time err; Id: "..id)
		else
			if st <= now_t and now_t < et and canBuy(actor,conf) then
				local percount = getLeftBuyCount(actor,conf) or 0
				-- print("可购买次数" .. percount)
				print("sendLimitBuyInfo send id : "..id)
				et = getStageEndtime(actor, id) or et-- 获取当前阶段结束时间
				LDataPack.writeInt(npack, conf.Id) -- 活动id
				LDataPack.writeInt(npack, et - now_t) -- 剩余时间
				LDataPack.writeInt(npack, percount) -- 可购买数量 
				LDataPack.writeInt(npack, #conf.rew)
				for i,award in ipairs(conf.rew) do
					LDataPack.writeInt(npack, award.type)
					LDataPack.writeInt(npack, award.id)
					LDataPack.writeInt(npack, award.count)
				end
				ncount = ncount + 1
			end
		end
	end
	local npos2 = LDataPack.getPosition(npack)
	LDataPack.setPosition(npack, npos) -- 指针移动
	LDataPack.writeShort(npack, ncount) -- 总礼包数
	LDataPack.setPosition(npack, npos2)
    LDataPack.flush(npack)
end

local function getRecord(actor,giftid) -- 获取某礼包的已购买次数 
	local data = getStaticData(actor)
	if not data then print("[ERROR] rechargelimitbuy not actor buyRecord") return -1 end
	if not data.records then 
		return 0
	end
	if ( not data.records[giftid]) then
        return 0
	end
	return data.records[giftid].count or 0
end

-- 购买礼包
function sendTimePacket(actor,itemid)
	if(itemid == nil) then 
		print("sendTimePacket itemid is nil")
		return false
	end
	local conf = TimePackageConfig[itemid] -- 正常购买礼包
	if not conf then 
		print("rechargelimitbuy.sendTimePacket error, conf is nil; itemid: ".. itemid .. " actorid: " .. LActor.getActorId(actor)) 
		return false 
	end
	-- 检查购买次数限制
    local havebuyCount = getRecord(actor,conf.Id)
	if(havebuyCount >= conf.buyTime) then
		--print("rechargelimitbuy.sendTimePacket" .. LActor.getActorId(actor) .. " rechargelimitbuy to limit")
		return
	end
	local content = nil
	local mailData = nil
	if(not conf.type or conf.type == 0) then
		content = string.format(BaseTimePackageConfig.Content, conf.desc)
		mailData = {head=BaseTimePackageConfig.Title, context=content, tAwardList=conf.rew}
	else
		content = string.format(BaseTimePackageConfig.OneBuyContent, conf.desc)
		mailData = {head=BaseTimePackageConfig.OneBuyTitle, context=content, tAwardList=conf.rew}
	end
    mailsystem.sendMailById(LActor.getActorId(actor), mailData)
    buyRecord(actor,conf) -- 修改个人购买记录

	-- 通知购买更新显示
	sendLimitBuyInfo(actor)
	return true
end
-- 购买礼包,itemid:礼包id
function onRecharge(actorid, itemid)
    local actor = LActor.getActorById(actorid)
    if actor == nil then

    	print("[Error] "..actorid.." rechargelimitbuy onRecharge no actor; itemid = "..itemid)

    	-- 使用镜像
    	asynevent.reg(actorid,function(imageActor,srcActorId)
                   print("rechargelimitbuy asyn sendTimePacket srcActorId: "..srcActorId)
                   sendTimePacket(imageActor, itemid) end
                   ,itemid)

		return false
	end
	
	return sendTimePacket(actor,itemid)
end

-- 检测限购礼包是否到了重置日期
local function checkResetDay(actor, conf)
	local openDay = System.getOpenServerDay() -- 获取开服天数
	local resetDay = conf.resetday
	local startDay = string.match(conf.startTime, "(%d+)-(%d+):(%d+)")
	local endDay = string.match(conf.endTime, "(%d+)-(%d+):(%d+)")
	local difDay = openDay - startDay
	if(difDay < 0) then -- 活动还没开启 不重置
		-- print(conf.Id .. "活动未开始")
        return false
	end
	if(openDay - endDay > 0) then
		-- print(conf.Id .. "活动已结束")
		return false
	end
	if(not resetDay or resetDay == 0) then -- 不填或者填0,不重置
		-- print(conf.Id .. "不是循环活动")
        return false
	end
	
	-- 无数据的时候 (该功能后期开发修改了数据结构,所以做了这步处理)
	local data = getStaticData(actor)
	if not data then print("data is null ") return false end
	if(not data.records or not data.records[conf.Id] or not data.records[conf.Id].resetdays) then -- 还未初始化过
		return true
	end

	if(difDay%resetDay == 0) then -- 符合配置条件
		-- 检查是否已经重置过
		if(data.records[conf.Id].resetdays ~= openDay) then -- 未重置过
			return true
		end
	end
	return false
end

-- 更新重置时间
local function getLastResetday(actor,conf) -- conf:TimePackageConfig[id]
	local openDay = System.getOpenServerDay() -- 获取开服天数
	-- print("今日是开服第".. openDay .. "天")
	local confStartday = string.match(conf.startTime, "(%d+)-(%d+):(%d+)") -- 活动开启日
	local resetDay = conf.resetday -- 重置周期

	local n = math.modf( (openDay - confStartday) / resetDay )
	if(n<0) then
		print("getLastResetday error,can not get the last resetday")
		return
	end
    return confStartday + n*resetDay
end

--定期重置礼包id列表中的购买次数，跨天和每次登陆尝试触发
local function resetGiftRecord(actor) 
	local openDay = System.getOpenServerDay() -- 获取当前距离开服天数
	local data = getStaticData(actor)
	if not data then print("[ERROR] rechargelimitbuy not actor buyRecord") return end 
	if(not data.records) then
		data.records = {}
	end
	local records = data.records
	
	local giftidList = {} -- 要重置的礼包id列表
	for id,activityconf in pairs(TimePackageConfig) do
		if(checkResetDay(actor, activityconf)) then -- 检测是否需要重置
			table.insert(giftidList,id)
		end
	end
	for i,giftid in pairs(giftidList) do
		records[giftid] = {}
		records[giftid].count = 0 -- 重置次数
		records[giftid].resetdays = getLastResetday(actor, TimePackageConfig[giftid]) or 0 -- 修改上一次重置时间为今天
		--print(giftid .. "重置日期:" .. records[giftid].resetdays)
	end
end

--登录
local function onLogin(actor)
	local times = hefuCheckRest() -- 合服次数满足情况直接重置
	if times > 0 then
		resetRecord(actor, times) -- 合服重置购买次数
	end
	resetGiftRecord(actor) -- 尝试定期重置购买次数
    sendLimitBuyInfo(actor)
end
-- 新的一天
local function onNewday(actor)
	resetGiftRecord(actor) -- 尝试定期重置购买次数
    sendLimitBuyInfo(actor)
end
actorevent.reg(aeUserLogin, onLogin)
actorevent.reg(aeNewDayArrive, onNewday)
netmsgdispatcher.reg(Protocol.CMD_Recharge, Protocol.cRechargeCmd_LimitBuy, sendLimitBuyInfo)



-- 以下是调试用
-- 打印信息，gm指令或者调试用
function printRechargeLimitInfo(actor)
	local data = getStaticData(actor)
	local actorid = LActor.getActorId(actor)
	local strlog = "actor:" .. actorid .. " 限购礼包信息如下:\n"
	if(not data) then 
		return 
	end
	if(data) then
		strlog = strlog .. "上一次合服次数是:" .. (data.hefuTime or -1) .. "\n"
	end
	if(not data.records) then 
		print("找不到records")
		return 
	end
	local records = data.records
	for _i,giftconf in pairs(TimePackageConfig) do
		if(records[giftconf.Id]) then
			print("礼包id" .. giftconf.Id)
	    	strlog = strlog .. "礼包:" .. giftconf.Id .. " 已购买次数:" .. (records[giftconf.Id].count or -1) .. " 上次重置时间:" .. (records[giftconf.Id].resetdays or -1) .. "\n"
	    end
	end
	print(strlog)
	LActor.sendTipmsg(actor, strlog)
end

-- 清空所有限购礼包数据
function resetRechargeLimitInfo(actor)
	local data = getStaticData(actor)
	if(data) then
		data.records = {}
		data.hefuTime = nil
	end
	--sendLimitBuyInfo(actor)
end


local gmsystem  = require("systems.gm.gmsystem")
gm = gmsystem.gmCmdHandlers
gm.hasrecharged = function(actor)
	if(dailyrecharge.hasRecharged(actor)) then
		LActor.sendTipmsg(actor, "已经充值过")
	else
		LActor.sendTipmsg(actor, "未充值过")
	end
end

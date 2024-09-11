module("sdkapi", package.seeall)

require("dbprotocol")



--邀请好友分享奖励的appid列表
--SharedChannelAppIdList = {'2000005', '2000004', '2000007', '2000012', '2000003', '2000014', '2000013', '2000010' }


local function getStaticData(actor)
    local var = LActor.getStaticVar(actor)
    if var == nil then return nil end

    if var.SDKData == nil then
        var.SDKData = {}
    end
    return var.SDKData
end
--[[
    微信分享数据
    wxSharedTime    已分享次数
    wxLastSharedTime 上次分享时间
--]]

--充值回调  以下逻辑有些乱，规划不一致
function onFeeCallback(packet)
    if not System.isCommSrv() then return end

    local openid, itemid, num,actorid = LDataPack.readData(packet, 4, dtString, dtInt, dtInt,dtInt) --200<=itemid<300：限购礼包id 其他时候itemid:充值金额 300-399是一元购活动
    print(string.format("recv fee data:%s, %d, %d , %d ", openid, itemid, num, actorid));

    if itemid>=200 and itemid<400 then -- 限购礼包与一元购[200,400)
        print("buy limit gift bag actorid=" .. actorid)
        if not TimePackageConfig[itemid] then
           print("TimePackageConfig[itemid] is nil ,itemid=" .. itemid)
           return
        end
        -- 打日志写数据库 
        local actordata = LActor.getActorDataById(actorid)
        if(itemid>=300) then
            System.logCounter(actorid, actordata.account_name, actordata.level,"TimePackageConfig", tostring("1"), "(一元购)购买限购礼包1份礼包id： " .. itemid)
        else
            System.logCounter(actorid, actordata.account_name, actordata.level,"TimePackageConfig", tostring("1"), "(珍宝阁)购买限购礼包1份礼包id： " .. itemid)
        end
        rechargelimitbuy.onRecharge(actorid, itemid) -- 限购礼包
        return
    end

    local count = itemid
    if count<=0 then return end
	if count == MonthCardConfig.monthCardMoney then -- 月卡
		monthcard.buyMonth(actorid)
    elseif count == PrivilegeData.priviMoney then
        privilegemonthcard.buyPrivilegeMonth(actorid)
	elseif count == PrivilegeData.priviMoney then 
            privilegemonthcard.buyPrivilegeMonth(actorid)

    elseif PActivityType23Config[5007] and (PActivityType23Config[5007][1].rmb * 100 == count) then --等级基金
        psubactivitytype23.recharge(5007, actorid)

    elseif PActivityType23Config[5008] and (PActivityType23Config[5008][1].rmb * 100 == count) then --登录基金
        psubactivitytype23.recharge(5008, actorid)
	else
		LActor.addRechargeOffline(actorid, count, itemid)
		--LActor.addRechargeOffline(openid, itemid)
		--end
		return

	end
    --else
        --LActor.addRecharge(actor, 0, itemid)
        --print("itemid invalid, " .. itemid)
    --end
end

--爱微游5级的时候要上报一次,发给后台/前端处理
local function onlv15(actor, level)
    if level == 15 then
        local npack = LDataPack.allocPacket(actor, Protocol.CMD_PlatformActivity, Protocol.sPlatformActivityCmd_15LevelNotify)
        if npack == nil then return end

        LDataPack.flush(npack)
    end
end

local function onResultCheck(params, retParams)
    --local actor = LActor.getActorById(params[1])
    --if actor == nil then return end

    local content = retParams[1]
    local ret = retParams[2]

    print("ret:"..ret)
    print("content:"..tostring(content))
end

--爱微游创角处理
local function onFirstLogin(actor, isFirst)
    --[[if isFirst == 0 then return end

    local now = System.getNowTime()
    local openServerTime = System.getOpenServerTime()
    if (now - openServerTime) < 3600 * 24 * 3 then
        sendMsgToWeb(string.format("/Api/report?data=%s|%s|%s",
            tostring(System.getServerId()),
            tostring(LActor.getAccountName(actor)),
            tostring(LActor.getActorId(actor))
            )
        , onResultCheck
        )
    end
    --]]
end


--微信分享
--[[
local function checkSharedChannel(pf)
	for _, appid in ipairs(SharedChannelAppIdList) do
		if pf == appid then return true end
	end
	return false
end
]]

local function notifyWXInfo(actor)
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_PlatformActivity, Protocol.sPlatformActivityCmd_WeiXinShare)
    local data = getStaticData(actor)
    if npack == nil or data == nil then return end

    LDataPack.writeInt(npack, data.wxSharedTime or 0)
    LDataPack.writeInt(npack, (data.wxLastSharedTime or 0) + SDKConfig.shareInterval)
    LDataPack.flush(npack)
end

local function onNewDay(actor)
    --local pf = LActor.getPf(actor)
    --微信处理
	--if checkSharedChannel(pf) then
        local data = getStaticData(actor)
        data.wxSharedTime = 0
        data.wxLastSharedTime = 0
        notifyWXInfo(actor)
    --end
end

local function onLogin(actor, isFirst)
    --local pf = LActor.getPf(actor)
    --微信处理
    --if checkSharedChannel(pf) then
        notifyWXInfo(actor)
    --end
end

local function onGetShareReward(actor, packet)
    --local pf = LActor.getPf(actor)
    --if not checkSharedChannel(pf) then return end

    local data = getStaticData(actor)
    --if pf == '2000007' then -- 新浪渠道特殊处理暂时
	--    if (data.wxSharedTime or 0) >= 1 then
	--	    print("wx share invalid. r:count, a:"..LActor.getActorId(actor))
	--	    return
	--    end
    --end
    if (data.wxSharedTime or 0) >= SDKConfig.shareCount then
        print("wx share invalid. r:count, a:"..LActor.getActorId(actor))
        return
    end

    if System.getNowTime() - (data.wxLastSharedTime or 0) < SDKConfig.shareInterval then
        print("wx share invalid. r:interval, a:"..LActor.getActorId(actor))
        return
    end

    data.wxSharedTime = (data.wxSharedTime or 0) + 1
    data.wxLastSharedTime = System.getNowTime()
    --发邮件
    local conf = SDKConfig
    local mailData = {head=conf.mailTitle, context=conf.mailContent, tAwardList=conf.shareReward}
    mailsystem.sendMailById(LActor.getActorId(actor), mailData)
    notifyWXInfo(actor)

    actorevent.onEvent(actor, aeShareGame)
end


dbretdispatcher = require("utils.net.dbretdispatcher")
dbretdispatcher.reg(dbTxApi, DbCmd.TxApiCmd.sFeeCallBack, onFeeCallback)

netmsgdispatcher.reg(Protocol.CMD_PlatformActivity, Protocol.cPlatformActivityCmd_WeiXinShare, onGetShareReward)

--actorevent.reg(aeLevel, onlv15)
--actorevent.reg(aeUserLogin, onFirstLogin)
actorevent.reg(aeUserLogin, onLogin)
actorevent.reg(aeNewDayArrive, onNewDay)

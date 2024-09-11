--[[
    合服邮件
    author:{author}
    time:2020-03-21 13:57:52
]]
module("mergesrvmail", package.seeall)

--[[
    hefumaildata = {
        hefutime, -- 上一次合服的日期
    }
]]
local config = MailIdConfig
local function LOG(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:mergesrvmail." .. log .. " actorid:" .. actorid)
end

local function getStaticData(actor)
    local var = LActor.getStaticVar(actor)
    if var == nil then
        LOG(actor, "getStaticData fail")
        return nil 
    end

    if var.hefumaildata == nil then
        var.hefumaildata = {}
    end
    return var.hefumaildata
end

local function getConfHefuTime(srvId)
    if(not HeFuConfig[srvId]) then
        return 0
    end
    return HeFuConfig[srvId].time
end

local function getHefuTime(actor)
    local data = getStaticData(actor)
    return data.hefutime or 0
end

local function setHefuTime(actor,hefuTime)
    local data = getStaticData(actor)
    data.hefutime = hefuTime
end

local function onInit(actor)
    -- 如何判断是合服
    local srvId = System.getServerId()
    local conf = HeFuConfig[srvId]
    if not conf then -- 没有合过服
        return
    end
    local hefuTime = hefutime.getHeFuDayStartTime()
    if(not hefuTime) then
        LOG(actor,"onInit getHeFuDayStartTime fail")
        return 
    end
    local now = System.getNowTime()
    if(not System.isSameDay(hefuTime, now)) then
        return -- 不是今天合服不管了
    end

    local lastHefuTime = tonumber(getHefuTime(actor)) -- 获取最近一次更新合服的时间
    if(lastHefuTime == hefuTime) then return end -- 已经发过此处合服邮件
    setHefuTime(actor,hefuTime) -- 重新设置时间
    local actorId = LActor.getActorId(actor)
    local mail_data = {}
    -- 策划只配置了邮件表,所以这里写死为101
    if(not MailIdConfig[101]) then
        LOG(actor,"onInit MailIdConfig[101] not exist")
        return
    end
    mail_data.head = MailIdConfig[101].title 
    mail_data.context = MailIdConfig[101].content
    --没有附件
    mailsystem.sendMailById(actorId, mail_data)
end

actorevent.reg(aeUserLogin, onInit)

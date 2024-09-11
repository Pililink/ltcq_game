--礼包兑换码
module("giftcode", package.seeall)


--[[

 giftCodeData = {
    [id]= 1 已领取
 }
--]]

local CODE_SUCCESS = 0
local CODE_INVALID = 1 --已被使用
local CODE_NOTEXIST = 2
local CODE_USED = 3 --已使用过同类型
local CODE_ERR = 4
local TimeCache = {}

local function getStaticData(actor)
    local var = LActor.getStaticVar(actor)
    if var == nil then
        print("get gift code data error.")
    end

    if var.giftCodeData == nil then
        var.giftCodeData = {}
    end
    return var.giftCodeData
end

local function getCodeId(code)
    local len = string.byte(string.sub(code, -1)) - 97
    local pos = string.byte(string.sub(code, -2,-2)) - 97
	local str = string.sub(code, pos + 1, pos + len)
	
	print("gift code len :"..tostring(len))
    print("gift code pos :"..tostring(pos))
	print("gift code str :"..tostring(str))
	
    local id = 0
    for i=1, string.len(str) do
        id = id * 10 + (math.abs(string.byte(string.sub(str, i, i)) - 97))
    end
    return id
end

local function checkCode(actor, code)
    --if string.len(code) ~= 16 then
    --    return CODE_ERR
    --end
    local id = getCodeId(code)
    if id == 0 then
        return CODE_ERR
    end

    local conf = GiftCodeConfig[id]
    if conf == nil or conf.gift == nil then
        print("gift code config is nil :"..tostring(id))
        return CODE_ERR
    end

    local data = getStaticData(actor)
    if (data[id] or 0) >= (conf.count or 1) then
        return CODE_USED
    end

    return CODE_SUCCESS, id
end

--处理web返回
local function onResultCheck(params, retParams)
    local actor = LActor.getActorById(params[1])
    if actor == nil then return end

    local content = retParams[1]
    local ret = retParams[2]
    if ret ~= 0 then return end

    --local res,usetype = string.match(content, "(%d+)")--tonumber(content)
    --res = tonumber(res)
    local res = tonumber(content)
    if res == nil then
        print("onGiftCode response nil.")
        print("content:"..content)
        return
    end

    if res == CODE_SUCCESS then
        local id = params[2]
        local code = params[3]
        local data = getStaticData(actor)

        local conf = GiftCodeConfig[id]
        if conf == nil or conf.gift == nil then
            print("gift code config is nil :"..tostring(id))
            return
        end

        if (data[id] or 0) >= (conf.count or 1) then
            print("onGiftCode result check count:"..(data[id] or 0))
            return
        end --再次检查是否使用过,因为异步问题

        data[id] = (data[id] or 0) + 1

        --LActor.giveAwards(actor, conf.gift, "gift code "..tostring(id))

        --发邮件
        local mailData = {head=conf.mailTitle, context=conf.mailContent, tAwardList=conf.gift}
        mailsystem.sendMailById(LActor.getActorId(actor), mailData)
    end

    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sGiftCodeCmd_Result)
    if npack == nil then return end

    LDataPack.writeByte(npack, res)
    LDataPack.flush(npack)
end

local function findId(id, idlist)
    if idlist and type(idlist) == "table" then
        for _, i in ipairs(idlist) do
            if id == i then
                return true
            end
        end
    end
    if idlist and type(idlist) == "string" then
        local ranges = utils.luaex.lua_string_split(idlist, ',')
        for _, range in ipairs(ranges) do
            local r = utils.luaex.lua_string_split(range, '-')
            if #r == 2 then
                if tonumber(r[1]) <= id and tonumber(r[2]) >= id then
                    return true
                end
            elseif #r  == 1 then
                if id == tonumber(r[1]) then return true end
            else
                print("config error? can't recognise range:"..range)
                print("config:"..idlist)
            end
        end
    end
    return false
end

--检测开服时间比配置小的才开启活动
local function checkOpenTimeLt(conf)
    if not conf.openTimeLt then return true end
    local Y,M,d,h,m = string.match(conf.openTimeLt, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
    if Y == nil or M == nil or d == nil or h == nil or m == nil then
        return false
    end

    local st = System.timeEncode(Y, M, d, h, m, 0)  
    if System.getServerOpenTime() > st then
        return false
    end
    return true
end

--检测开服时间比配置大的才开启活动
local function checkOpenTimeGt(conf)
    if not conf.openTimeGt then return true end
    local Y,M,d,h,m = string.match(conf.openTimeGt, "(%d+)%.(%d+)%.(%d+)-(%d+):(%d+)")
    if Y == nil or M == nil or d == nil or h == nil or m == nil then
        return false
    end

    local st = System.timeEncode(Y, M, d, h, m, 0)
    if System.getServerOpenTime() < st then
        return false
    end
    return true
end

--检测指定服务器不开
local function checkServerIdNotOpen(conf)
    if not conf.idLimit then return true end
    if findId(System.getServerId(), conf.idLimit) then
        return false
    end
    return true
end

--检测指定服务器开
local function checkServerIdOpen(conf)
    if not conf.idOpenLimit then return true end
    if findId(System.getServerId(), conf.idOpenLimit) then
        return true
    end
    return false
end

--加载激活码的有效时间
local function loadTime(conf)
    if conf.timeType == 0 then
        --startTime
        local d,h,m = string.match(conf.startTime, "(%d+)-(%d+):(%d+)")
        if d== nil or h == nil or m == nil then
            return 0,0,true
        end

        local st = System.getOpenServerStartDateTime()
        st = st + d*24*3600 + h*3600 + m*60

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
        local hefutime = hefutime.getHeFuDayStartTime() or 0
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
        return 0,0,false,true
    end
end

local function checkChannelCode(actor, code)
    if code == nil or code == "" then
        return CODE_ERR
    end
    if string.len(code) > 28 then
        return CODE_ERR
    end

    local conf = ChannelGiftCodeConfig[code]
    if conf == nil or conf.gift == nil then
        return CODE_ERR
    end

    if not (checkServerIdNotOpen(conf) and checkServerIdOpen(conf)) then
        return CODE_ERR
    end

    if not (checkOpenTimeLt(conf) and checkOpenTimeGt(conf)) then
        return CODE_ERR
    end

    if TimeCache[code] == nil then
        TimeCache[code] = {}
        TimeCache[code].st, TimeCache[code].et, TimeCache[code].err, TimeCache[code].perm = loadTime(conf)
    end

    if not TimeCache[code].perm then
        local curr_time = System.getNowTime()
        if TimeCache[code].err or (curr_time < TimeCache[code].st) or (curr_time > TimeCache[code].et) then
            return CODE_ERR
        end
    end

    local data = getStaticData(actor)
    if (data[code] or 0) >= 1 then
        return CODE_USED
    end

    if data.pf ~= nil and data.pf ~= LActor.getPf(actor) then
        return CODE_ERR
    end

    if conf.appid ~= nil and tostring(conf.appid) ~= LActor.getAppid(actor) then
        return CODE_ERR
    end

    return CODE_SUCCESS
end

local function giveChannelCodeReward(actor, code)
	local conf = ChannelGiftCodeConfig[code]
	if conf == nil then return end
	local data = getStaticData(actor)
	if data == nil then return end

	data.pf = LActor.getPf(actor)
	data[code] = (data[code] or 0) + 1

    if conf.use and conf.use ~= 0 then
        local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, 2)
        if npack ~= nil then
            LDataPack.writeByte(npack, conf.use)
            LDataPack.writeByte(npack, 1)
            LDataPack.flush(npack)
        end
    end

	--发邮件
	local mailData = {head=conf.mailTitle, context=conf.mailContent, tAwardList=conf.gift}
	mailsystem.sendMailById(LActor.getActorId(actor), mailData)

	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sGiftCodeCmd_Result)
	if npack == nil then return end

	LDataPack.writeByte(npack, CODE_SUCCESS)
	LDataPack.flush(npack)
end

--发送web验证
local function postCodeCheck(code, aid, id, pf, appid, account)
	local url = "/WebServer/CDKey/CheckCode.php?cdkey="..code.."&account="..account.."&aid="..aid.."&sid="..System.getServerId()
    sendMsgToWeb(url, onResultCheck, {aid, id, code})
end

local function getChannelCode(actor, code)
	local ret, id = checkChannelCode(actor, code)
	if ret ~= CODE_SUCCESS then
		local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sGiftCodeCmd_Result)
		if npack == nil then return end

		LDataPack.writeByte(npack, ret)
		LDataPack.flush(npack)
		return
	end
	giveChannelCodeReward(actor, code)
end

local function getNormalCode(actor, code)
    local ret, id = checkCode(actor, code)
    if ret ~= CODE_SUCCESS then
        local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sGiftCodeCmd_Result)
        if npack == nil then return end

        LDataPack.writeByte(npack, ret)
        LDataPack.flush(npack)
        return
    end
    postCodeCheck(code, LActor.getActorId(actor), id, LActor.getPf(actor), LActor.getAppid(actor), LActor.getAccountName(actor))
end

local function isChannelCode(code)
	local conf = ChannelGiftCodeConfig[code]
	if conf then
		return true
	end
	return false
end

local function onGetGift(actor, packet)
	local code = LDataPack.readString(packet)
    if not code then return end
	if isChannelCode(code) then
		getChannelCode(actor, code)
	else
		getNormalCode(actor, code)
	end
end

function gmTest(actor, code)
	local ret, id = checkCode(actor, code)
	if ret ~= CODE_SUCCESS then
		local npack = LDataPack.allocPacket(actor, Protocol.CMD_Gift, Protocol.sGiftCodeCmd_Result)
		if npack == nil then return end
		LDataPack.writeByte(npack, ret)
		LDataPack.flush(npack)
		return
	end
	postCodeCheck(code, LActor.getActorId(actor), id, LActor.getPf(actor), LActor.getAppid(actor), LActor.getAccountName(actor))
end


netmsgdispatcher.reg(Protocol.CMD_Gift, Protocol.cGiftCodeCmd_GetGift, onGetGift)
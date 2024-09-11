--[[
相关协议
78-1  每日红包信息 -服务端推送
int -- 0 不可抢 1 可抢 2已领取
int -- 剩余次数
int --下次再次领取剩余时间 单位s
      --以下已领取状态2有效
int --普通元宝数量 
int --特殊元宝状态 0不可领取 1充值后可领取 2可领取 3已领取
int --特殊元宝数量


78-2 请求领取普通红包 -客户端(抢)
78-2 反馈(服务器)
int -- 领取结果 0 不可领取未到时间 1领取成功 2 已领取
int -- 普通元宝数量,状态1时有效,其他为0

78-3 请求领取特殊红包 -- 客户端
78-3 反馈(服务器)
int -- 领取结果 0 不可领取未到时间 1需要充值才可领取 2领取成功 3 已领取
int -- 特殊元宝数量,状态2时有效,其他为0

]]--


module("dailyredpacket", package.seeall)

local config = HongBaoConfig
--[[
    dailyredpacketrecord = { -- 红包领取记录
        {actorid,ybcount} -- 玩家id,领取元宝数量
        ...
    }
]]

--[[
 dailyredpacket = { -- 每日红包数据
    receivedcount, -- 今日已领取红包次数
    rechargecount, -- 今日充值次数
    onlinetime, -- 今日在线累计时间 min
    awardstatus, -- 普通红包元宝奖励领取状态 0 不可领取(时间未到) 1 可领取 2已领取
    ybcount, -- 普通元宝数量
    extraawardstatus, -- 额外元宝领取状态 0 不可领取(时间未到) 1 充值后可领取 2可领取 3已领取
    extraybcount, -- 额外元宝数量
    initflag, -- 初始化flag,用于该功能第一次上线用
}
]]--

local redpacketrecord = redpacketrecord or {} -- 红包领取记录
-- 每日红包领取记录(最新20条)
local function getDailyRedPacketRecord() 
	local var = System.getStaticVar()
	if var == nil then 
		return nil 
	end
	if var.dailyredpacketrecord == nil then 
		var.dailyredpacketrecord = {}
	end
	return var.dailyredpacketrecord
end

-- 获取每日红包数据
local function getDailyRedPacketVar(actor)
	local var = LActor.getStaticVar(actor)
    if (var == nil) then
        print("[ERROR]:dailyredpacket.getDailyRedPacketVar var is nil")
        return 
    end

	if (var.dailyredpacket == nil) then
		var.dailyredpacket = {}
	end
	return var.dailyredpacket
end

-- 获取已领取次数+1
local function getCurId(actor)
    local var = getDailyRedPacketVar(actor)
    return (var.receivedcount or 0) + 1
end

--随机红包元宝数量
--curid 当前将要领取红包的id
local function randomyb(actor, curid)
    local conf = config[curid]
    local var =getDailyRedPacketVar(actor)
    var.awardstatus = 1 -- 状态设置为可领取
    var.extraawardstatus = 1 -- 充值任意金额后可领取
    -- print("")
    -- 随机普通元宝
    var.ybcount = math.random(tonumber(conf.yb[1]),tonumber(conf.yb[2])) -- 普通元宝
    --print("------------------------------------------------------------------" .. var.ybcount)
    -- 随机特殊元宝
    var.extraybcount = math.random(tonumber(conf.moreyb[1]),tonumber(conf.moreyb[2])) -- 额外元宝
    --print("--------------------------------------------------------------------" .. var.extraybcount)
end

-- 尝试初始化每日红包数据,初始化红包第一次必须可领
local function initVar(actor)
    local var = LActor.getStaticVar(actor)
    if(not var) then return end
    var.dailyredpacket = {
            receivedcount = nil,
            rechargecount = 0,
            onlinetime = 0,
            awardstatus = 1,
            ybcount = 0,
            extraawardstatus = 1,
            extraybcount = 0,
            initflag = 1 -- 已初始化
    }
    randomyb(actor,1) -- 重置红包元宝数量
end

--针对本功能的广播
local function sendBroadCast(actor,ybCount,curId)
    if(not curId) then -- 当前次数,额外红包传入,其他时候为nil
        curId = getCurId(actor)
    end
    local actorname = LActor.getActorName(LActor.getActorId(actor))
    noticemanager.broadCastNotice(config[curId].notice, actorname, ybCount)
end

-- 发送每日红包信息 78-1
local function sendRewardInfo(actor)
    local var = getDailyRedPacketVar(actor)
    local curCount = getCurId(actor) -- 即将领取的次数
    local leftcount = #config - (var.receivedcount or 0)-- 剩余领取次数
    local conf = config[curCount] or config[#config] -- 次数可能超
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_DailyRedPacket, Protocol.sDailyRedPacketInfo) -- 下发可领取奖励通知 78-1
    if pack == nil then
        print("[ERROR]:dailyredpacket.addOnlineTime LDataPack.allocPacket is nil")
        return 
    end
    LDataPack.writeInt(pack, (var.awardstatus or 0)) -- 普通元宝领取状态 0 不可领 1 可领 2已领
    LDataPack.writeInt(pack, leftcount) -- 剩余领取次数
    LDataPack.writeInt(pack, conf.time - 60*(var.onlinetime or 0)) -- 下次领取剩余时间
    --print("dmwflag 下次领取时间剩余:" .. (conf.time - 60*(var.onlinetime or 0)))
    LDataPack.writeInt(pack, (var.ybcount or 0)) -- 随机普通元宝数量
    LDataPack.writeInt(pack, (var.extraawardstatus or 0)) -- 特殊元宝领取状态
    LDataPack.writeInt(pack, (var.extraybcount or 0)) -- 随机特殊元宝数量
    local rechargecondtion = config[(var.receivedcount or 1)].pay
    LDataPack.writeInt(pack, rechargecondtion) -- 领取额外元宝充值条件
	LDataPack.flush(pack) -- 发出去
end

-- 更新领取记录 
local function updateRecord(actor,ybcount)
    if(#redpacketrecord >= 20) then -- 策划要求20条
        table.remove(redpacketrecord,1) -- 移除头部数据
    end
    local actorid = LActor.getActorId(actor)
    table.insert(redpacketrecord,{actorid=actorid,ybcount=ybcount})-- 更新记录
    --print("dmwflag 插入记录" .. "玩家id:" .. actorid .. "   元宝:"  .. ybcount)
end
--增加当日在线时间定时触发
-- addtimeTmp 增加的时长,单位分钟,达到要求还会重置领取状态.不传默认是1
-- 精度是1min 所以配置必须是60的整数倍
function addOnlineTime(addtimeTmp)
    local actorlist = System.getAllActorList() -- 在线玩家列表
    for _,actor in pairs(actorlist or {}) do
        repeat
            local addtime = (addtimeTmp or 1)
	        local var = getDailyRedPacketVar(actor)
            if (not var) then
	        	return
	        end
            if(var.awardstatus and var.awardstatus == 1) then -- 可领取状态需要领取之后才累加时间
                break
            end
            if(60*(var.onlinetime or 0) >= config[#config].time) then -- 时间不累加 下一个玩家
                addtime = 0
                break
            end
            var.onlinetime = (var.onlinetime or 0) + addtime
            local conf = config[(var.receivedcount or 0)+1] -- HongBaoConfig[id]
            if(60*(var.onlinetime or 0) == conf.time) then
                var.awardstatus = 1 -- 状态设置为可领取
                var.extraawardstatus = 1 -- 充值任意金额后可领取
                -- 随机普通元宝
                var.ybcount = math.random(conf.yb[1],conf.yb[2]) -- 普通元宝
                -- 随机特殊元宝
                var.extraybcount = math.random(conf.moreyb[1],conf.moreyb[2]) -- 额外元宝
            end
            sendRewardInfo(actor) -- 尝试发送领取红包的消息
        until(true)
    end
end

-- 协议 78-4 这个只推一个数据
-- 玩家id 元宝数量
local function SendOneRecord(actorid,ybcount)
    --redpacketrecord
    local actorlist = System.getAllActorList() -- 在线玩家列表
    for _,actor in pairs(actorlist) do
        local count = 1 -- 记录条数
        local pack = LDataPack.allocPacket(actor, Protocol.CMD_DailyRedPacket, Protocol.sDailyRedPacketRecord)
        LDataPack.writeInt(pack, count)
        local actorname = LActor.getActorName(actorid)
        LDataPack.writeString(pack, actorname) -- 玩家名称
        LDataPack.writeInt(pack, ybcount) -- 元宝奖励数量
        LDataPack.flush(pack)
    end
end

--协议 78-4 推全部
local function sendRedPacketRecordList(actor, packet)
    --redpacketrecord
	local count = 0 -- 记录条数
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_DailyRedPacket, Protocol.sDailyRedPacketRecord)
    local pos1 = LDataPack.getPosition(pack) -- count指针记录
    LDataPack.writeInt(pack, count)
    for _,v in pairs(redpacketrecord) do
        local actorname = LActor.getActorName(v.actorid)
        LDataPack.writeString(pack, actorname) -- 玩家名称
        LDataPack.writeInt(pack, v.ybcount) -- 元宝奖励数量
        count = count + 1
    end
	local pos2 = LDataPack.getPosition(pack) -- 当前发送数据位置
	LDataPack.setPosition(pack, pos1)
	LDataPack.writeInt(pack, count)
	LDataPack.setPosition(pack, pos2)
	LDataPack.flush(pack)
end

-- 玩家充值
function onRecharge(actor, rechargeAmount)
    local var = getDailyRedPacketVar(actor)
    if(var.extraawardstatus ~= 1) then -- 充值领取
        return
    end
    local curId = getCurId(actor) - 1
    if((curId > #config) or (curId <= 0)) then return end
    if(rechargeAmount >= config[curId].pay) then -- 充值金额达标
        var.extraawardstatus = 2 -- 可领取
    end
    sendRewardInfo(actor)
end

-- 普通红包领取
local function commonRetPacket_c2s(actor)
    local result = 0 -- 领取结果 0 不可领取未到时间 1领取成功 2 已领取 3领取达到上限 4服务器数据异常
    local count = 0 -- 元宝数量
    repeat
        local var = getDailyRedPacketVar(actor)
        if(not var) then 
            print("[ERROR]:dailyredpacket.commonRetPacket_c2s getDailyRedPacketVar is nil,actorid:" .. LActor.getActorId(actor))
            result = 4 -- 服务端数据异常
            break
        end

        local curcount = (var.receivedcount or 0) + 1 -- 即将领取次数
        if(curcount > #config) then
            print("[ERROR]:dailyredpacket.commonRetPacket_c2s curcount is limit,actorid:" .. LActor.getActorId(actor))
            result = 3 -- 领取达到上限
            break 
        end
        if(not var.awardstatus or var.awardstatus == 0) then
            print("[ERROR]:dailyredpacket.commonRetPacket_c2s time is not enough,actorid:" .. LActor.getActorId(actor))
            result = 0 -- 时间不够
            break
        end
        if(var.awardstatus == 1) then -- 可领取
            result = 1 -- 领取成功
            count = var.ybcount
            var.awardstatus = 2 -- 已领取
            LActor.changeCurrency(actor, NumericType_YuanBao, count, "daily common redpacket") -- 每日红包普通红包奖励
            updateRecord(actor,count) -- 更新记录
            sendBroadCast(actor,count) -- 发广播
            SendOneRecord(LActor.getActorId(actor), count) -- 全服发送领取记录1条
            var.receivedcount = (var.receivedcount or 0) + 1 -- 领取次数加1
            sendRewardInfo(actor) -- 发送红包总信息
            break
        end
    until(true)

    local pack = LDataPack.allocPacket(actor, Protocol.CMD_DailyRedPacket, Protocol.sDailyCommonRedPacket) -- 下发本次领取结果 78-2
    LDataPack.writeInt(pack, result) -- 结果
    LDataPack.writeInt(pack, count) -- 元宝数量
    LDataPack.flush(pack) -- 发出去
end

-- 特殊红包领取
local function extraRetPacket_c2s(actor)
    local result = 0 -- 领取结果 0 不可领取未到时间 1需要充值才可领取 2领取成功 3已领取 4服务器数据异常
    local count = 0 -- 元宝数量
    repeat
        local var = getDailyRedPacketVar(actor)
        if(not var) then 
            print("[ERROR]:dailyredpacket.extraRetPacket_c2s getDailyRedPacketVar is nil,actorid:" .. LActor.getActorId(actor))
            result = 4 -- 服务端数据异常
            break
        end
        local curcount = (var.receivedcount or 0) -- 已領取的次數,特殊紅包當前次數就是普通紅包的已領取次數
        if(not var.extraawardstatus or var.extraawardstatus == 0) then
            result = 0 -- 时间不够
            print("[ERROR]:dailyredpacket.extraRetPacket_c2s time is not enough,actorid:" .. LActor.getActorId(actor))
            break
        end
        if(var.extraawardstatus == 1) then -- 充值才可领取状态
            result = 1 -- 需要充值
            print("[ERROR]:dailyredpacket.extraRetPacket_c2s need recharge,actorid:" .. LActor.getActorId(actor))
            break
        end
        if(var.extraawardstatus == 2) then -- 可领取状态
            result = 2 -- 成功领取
            count = var.extraybcount
            var.extraawardstatus = 3 -- 已领取
            LActor.changeCurrency(actor, NumericType_YuanBao, count, "daily extra redpacket") -- 每日红包普通红包奖励
            updateRecord(actor,count)
            sendBroadCast(actor,count,getCurId(actor) - 1) -- 发广播,额外红包次数总是落后于普通红包一次
            SendOneRecord(LActor.getActorId(actor), count) -- 全服发送领取记录
            sendRewardInfo(actor) -- 发送红包总信息
            break
        end
        if(var.extraawardstatus == 3) then -- 已领取状态
            result = 3 -- 已领取
            print("[ERROR]:dailyredpacket.extraRetPacket_c2s award has been received,actorid:" .. LActor.getActorId(actor))
            break
        end
    until(true)
    
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_DailyRedPacket, Protocol.sDailyExtraRedPacket) -- 下发本次领取结果 78-2
    LDataPack.writeInt(pack, result) -- 结果
    LDataPack.writeInt(pack, count) -- 元宝数量
    LDataPack.flush(pack) -- 发出去
end

-- 新一天时间
local function onNewDay(actor, login)
    local var = getDailyRedPacketVar(actor)
    if (not var) then
        print("[ERROR]:dailyredpacket.onNewDay var is nil")
        return 
    end
    initVar(actor) -- 初始化数据
    print("on dailyredpacket new day. aid:"..LActor.getActorId(actor))
    sendRewardInfo(actor)
end

-- 玩家登录
local function onLogin(actor)
    local var = getDailyRedPacketVar(actor)
    if(not var) then
        print("[ERROR]:dailyredpacket.onLogin var is nil")
        return 
    end
    if(not var.initflag) then -- 这种只有更新本功能当天生效
        initVar(actor) -- 初始化数据
    end
    sendRewardInfo(actor)
    sendRedPacketRecordList(actor) -- 推送红包领取记录
end

local function init()
    if(#config == 0) then -- 空配置则不注册任何每日红包内容
        print("[ERROR]:dailyredpacket.init, HongBaoConfig is not exist")
        return
    end
    --注册消息
    redpacketrecord = getDailyRedPacketRecord()
    actorevent.reg(aeNewDayArrive, onNewDay)
    actorevent.reg(aeUserLogin, onLogin)
    actorevent.reg(aeRecharge, onRecharge)
    netmsgdispatcher.reg(Protocol.CMD_DailyRedPacket, Protocol.cDailyCommonRedPacket, commonRetPacket_c2s) -- 普通红包 78-2
    netmsgdispatcher.reg(Protocol.CMD_DailyRedPacket, Protocol.cDailyExtraRedPacket, extraRetPacket_c2s) -- 额外红包 78-3
    --netmsgdispatcher.reg(Protocol.CMD_DailyRedPacket, Protocol.cDailyRedPacketRecord, sendRedPacketRecordList) -- 记录 78-4 -- 客户端要求主动推
    engineevent.regGameTimer(addOnlineTime) -- 定时器任务分钟级
end

table.insert(InitFnTable, init)




local gmsystem      = require("systems.gm.gmsystem")
local gmCmdHandlers = gmsystem.gmCmdHandlers
gmCmdHandlers.dailyredpacket = function (actor, args)
    local var = getDailyRedPacketVar(actor)
    print("今日已领取红包次数: " .. (var.receivedcount or 0))
    print("今日充值次数: " .. (var.rechargecount or 0))
    print("今日在线累计时间: " .. (var.onlinetime or 0))
    print("奖励领取状态  0 不可领取 1 可领取 2 已领取: " .. (var.awardstatus or 0))
    print("普通元宝数量: " .. (var.ybcount or 0))
    print("额外元宝领取状态 0 不可领取 1 充值后可领取 2可领取 3已领取: " .. (var.extraawardstatus or 0))
    print("额外元宝数量: " .. (var.extraybcount or 0))
    local curId = getCurId(actor)
    local conf = config[curId] or config[#config]
    local lefttime = conf.time - 60*(var.onlinetime or 0)
    print("下次领取时间s: " .. lefttime)

    local strlog = ""
    strlog = strlog .. "\n今日已领取红包次数: " .. (var.receivedcount or 0)
    strlog = strlog .. "\n今日充值次数: " .. (var.rechargecount or 0)
    strlog = strlog .. "\n今日在线累计时间: " .. (var.onlinetime or 0)
    strlog = strlog .. "\n普通元宝领取状态  0 不可领取 1 可领取 2 已领取: " .. (var.awardstatus or 0)
    strlog = strlog .. "\n普通元宝数量: " .. (var.ybcount or 0)
    strlog = strlog .. "\n额外元宝领取状态 0 不可领取 1 充值后可领取 2可领取 3已领取: " .. (var.extraawardstatus or 0)
    strlog = strlog .. "\n额外元宝数量: " .. (var.extraybcount or 0)
    strlog = strlog .. "\n下次领取时间s: " .. lefttime
    LActor.sendTipmsg(actor, strlog, 4)
end

gmCmdHandlers.dailyredpacketrecord = function (actor, args)
    local strlog = ""
    local count = 0 -- 记录条数
    local record = getDailyRedPacketRecord()
    for _,v in pairs(record) do
        local actorname = LActor.getActorName(v.actorid)
        strlog = strlog .. actorname .. " 领取了 " .. v.ybcount .. " 元宝\n"
        count = count + 1
    end
    strlog = "记录总数:" .. count .. "\n" .. strlog
    LActor.sendTipmsg(actor, strlog, 4)
end

gmCmdHandlers.cleardailyredpacketrecord = function (actor, args)
    local var = System.getStaticVar()
    var.dailyredpacketrecord = {}
end

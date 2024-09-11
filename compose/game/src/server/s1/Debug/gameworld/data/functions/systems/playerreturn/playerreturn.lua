--[[
    desc:老玩家回归系统
]]
module("playerreturn", package.seeall)
-- 日志
local function LOG(log, actor)
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[ERROR]:playerreturn." .. log .. " actorid:" .. actorid)
end

local function DEBUG(log, actor) -- 上线稳定后把内容注掉
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[DEBUG]:playerreturn." .. log .. " actorid:" .. actorid)
end

local function INFO(log, actor)
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[INFO]:playerreturn." .. log .. " actorid:" .. actorid)
end

local function sendTip(actor,tipmsg, type)
    --[[
	if(not actor) then return end
	local msgtype = 4
	if(type) then
		msgtype = type
	end
    LActor.sendTipmsg(actor, tipmsg .. " SERVER DEBUG", msgtype)
    ]]
end
-- 日志结束

--[[
    playerreturndata = {
        returnrewardstate, -- 回归奖励/邀请奖励领取状态 0 未领取 1已领取
        invitedata = { -- 邀请数据

        invitenum, -- 召回玩家的数量
        invitenumrecord, -- 数量奖励领取记录 位操作(不会超过30档)
        inviterecharge, -- 受邀者充值总额度
        inviterechargerecord, -- 充值奖励领取记录 位操作(不会超过30档)
        },
        returndata = { -- 回归数据
            lastlogintime,  -- 上一次的登录时间,用于累加登录天数用(回归状态下有效)
            nextstatestarttime, -- 下次回归状态可能的开始时间
            returnstatetime, -- 回归状态持续时间
            invitecode, -- 绑定的邀请码,不可绑定自己

            logindays, -- 登录天数
            logindaysrecord, -- 登录天数奖励领取记录 位操作(不会超过30天)
            recharge, -- 已充值金额
            rechargerecord, -- 充值奖励领取记录 位操作(不会超过30档)
        }
    }
--]]


local baseConfig = ReturnBaseConfig -- 基础配置
local returnConfig = ReturnLandConfig -- 回归登录奖励配置
local returnRechargeConfig = ReturnRechargeConfig -- 回归充值奖励配置
local invNumConfig =  ReturnInviteNumConfig -- 邀请数量奖励配置
local invRechargeConfig = ReturnInviteRechargeConfig -- 邀请充值奖励配置
gMysqlConn = {
    --db, -- 与数据库的连接
}
--[[
-- 初始化数据库 --暂时不用了 长时间可能会断开数据库的连接,还没函数检测
local function initDbConn()
    local db = System.createActorsDbConn()
    if(not db) then
        LOG("initDbConn fail")
        return false
    end
    gMysqlConn.db = db
    return true
end

local function getDbConn()
    if(gMysqlConn.db) then
        System.dbResetQuery(gMysqlConn.db)
    end
    return gMysqlConn.db
end

local function destroyDbConn()
    if(gMysqlConn.db) then
        System.dbClose(gMysqlConn.db)
        System.delActorsDbConn(gMysqlConn.db)
    end
    gMysqlConn.db = nil
end


local function finaFunc()
    destroyDbConn()
end
]]
local function getSystemData()
    local sysData = System.getStaticVar()
    if(not sysData.playerreturndata) then
        sysData.playerreturndata = {}
    end
    return sysData.playerreturndata
end

local function clearSystemData()
    local systemData = System.getStaticVar()
    if(not sysData.playerreturndata) then
        return
    end
    systemData.playerreturndata = nil
end

--[[
    @desc: 添加邀请码到系统数据
    author:{dmw}
    time:2020-06-11 17:52:08
    --@inviteCode: 
    --note:这个功能无法兼容合服,合服的时候system.txt无法一并合入
    @return:
]]
local function addInviteCodeRecord(inviteCode)
    local sysData = getSystemData()
    if(sysData.inviteCode) then
        sysData[inviteCode] = 1 
    end
end

local function delInviteCodeRecord()
    local sysData = getSystemData()
    if(not sysData) then return end
    sysData[inviteCode] = nil
end


local function getActorData(actor)
	local var = LActor.getStaticVar(actor)
	if not var then return end
	if(var.playerreturndata == nil) then var.playerreturndata = {} end
	return var.playerreturndata
end

local function getRetRewardState(actor)
    local actorData = getActorData(actor)
    return actorData.returnrewardstate or 0
end

local function setRetRewardState(actor,num)
    local actorData = getActorData(actor)
    actorData.returnrewardstate = num
end

--[[
    @desc: 清空所有回归玩法数据
    author:{dmw}
    time:2020-06-15 13:57:47
    --@actor: 
    @return:
]]
local function clearActorData(actor)
	local var = LActor.getStaticVar(actor)
	if not var then return end
    var.playerreturndata = {}
end

-- 邀请身份数据
local function getInviteData(actor)
    local actorData = getActorData(actor)
    if(not actorData.invitedata) then actorData.invitedata = {} end
    return actorData.invitedata
end

--[[
    @desc: 清理邀请身份的数据
    author:{dmw}
    time:2020-06-15 13:59:34
    --@actor: 
    @return:
]]
local function clearInviteData(actor)
    local actorData = getActorData(actor)
    actorData.invitedata = {}
end

local function getInviteNum(actor)
    local invData = getInviteData(actor)
    return invData.invitenum or 0
end

local function getInviteNumRecord(actor)
    local invData = getInviteData(actor)
    return invData.invitenumrecord or 0
end

local function getInviteRecharge(actor)
    local invData = getInviteData(actor)
    return invData.inviterecharge or 0
end

local function getInviteRechargeRecord(actor)
    local invData = getInviteData(actor)
    return invData.inviterechargerecord or 0
end


local function setInviteNum(actor, num)
    local invData = getInviteData(actor)
    invData.invitenum = num
end

--邀请身份添加邀请人数
function addInviteNum(actor,num)
    local invData = getInviteData(actor)
    invData.invitenum = (invData.invitenum or 0) + num
end

local function setInviteNumRecord(actor, num)
    local invData = getInviteData(actor)
    invData.invitenumrecord = num
end

local function setInviteRecharge(actor,num)
    local invData = getInviteData(actor)
    invData.inviterecharge = num
end

--[[
    @desc: 添加邀请者被充值额度
    author:{dmw}
    time:2020-06-15 11:15:26
    --@actor:
	--@num: 
    @return:
]]
function addInviteRecharge(actor,num)
    local invData = getInviteData(actor)
    invData.inviterecharge = (invData.inviterecharge or 0) + num
end

local function setInviteRechargeRecord(actor, num)
    local invData = getInviteData(actor)
    invData.inviterechargerecord = num
end



--[[
    @desc: 回归数据
    author:{dmw}
    time:2020-06-11 09:31:24
    --@actor: 
    @return:
]]
local function getReturnData(actor)
    local actorData = getActorData(actor)
    if(not actorData.returndata) then actorData.returndata = {} end
    return actorData.returndata
end

local function clearReturnData(actor)
    local actorData = getActorData(actor)
    actorData.returndata = {}
end

--[[
    @desc: 获取回归期间上一次登录时间
    author:{dmw}
    time:2020-06-15 09:28:15
    --@actor: 
    @return:
    @:note:回归状态下使用,其他时候无意义
]]
local function getLastLoginTime(actor)
    local returnData = getReturnData(actor)
    return returnData.lastlogintime or 0
end

local function getNextStateStartTime(actor)
    local returnData = getReturnData(actor)
    return returnData.nextstatestarttime or 0
end

--[[
    @desc: 获取回归状态持续时间
    author:{dmw}
    time:2020-06-13 14:30:29
    --@actor: 
    @return:
]]
local function getReturnStateTime(actor)
    local returnData = getReturnData(actor)
    return returnData.returnstatetime or 0
end

local function getInviteCode(actor)
    local returnData = getReturnData(actor)
    return returnData.invitecode or ""
end

local function getLoginDays(actor)
    local returnData = getReturnData(actor)
    --DEBUG("login days:" .. (returnData.logindays or 0))
    return returnData.logindays or 0
end


local function getLoginDaysRecord(actor)
    local returnData = getReturnData(actor)
    return returnData.logindaysrecord or 0
end


local function getReturnRecharge(actor)
    local returnData = getReturnData(actor)
    return returnData.recharge or 0
end

--[[
    @desc: 回归充值达标奖励领取记录
    author:{dmw}
    time:2020-06-13 17:50:25
    --@actor: 
    @return:
]]
local function getRechargeRecord(actor)
    local returnData = getReturnData(actor)
    return returnData.rechargerecord or 0
end



--[[
    @desc: 设置上一次登录时间
    author:{dmw}
    time:2020-06-15 09:29:43
    --@actor:
	--@num: 
    @return:
]]
local function setLastLoginTime(actor, num)
    local returnData = getReturnData(actor)
    returnData.lastlogintime = num
end

--[[
    @desc: 设置下次可能开启回归状态的时间
    author:{dmw}
    time:2020-06-13 14:04:49
    --@actor:
	--@num: 
    @return:
]]
local function setNextStateStartTime(actor, num)
    local returnData = getReturnData(actor)
    returnData.nextstatestarttime = num
end

local function setReturnStateTime(actor, num)
    local returnData = getReturnData(actor)
    returnData.returnstatetime = num
end

--[[
    @desc: 设置邀请码
    author:{dmw}
    time:2020-06-13 16:57:27
    --@actor:
	--@num: 
    @return:
]]
local function setInviteCode(actor,num)
    local returnData = getReturnData(actor)
    returnData.invitecode = num
end

local function setLoginDays(actor,num)
    local returnData = getReturnData(actor)
    returnData.logindays = num
end

local function addLoginDays(actor)
    local returnData = getReturnData(actor)
    returnData.logindays = (returnData.logindays or 0) + 1
end


local function setLoginDaysRecord(actor,num)
    local returnData = getReturnData(actor)
    returnData.logindaysrecord = num
end


local function setReturnRecharge(actor,num)
    local returnData = getReturnData(actor)
    returnData.recharge = num
end

--[[
    @desc: 增加回归玩家充值额度
    author:{dmw}
    time:2020-06-15 10:06:36
    --@actor:
	--@num: 
    @return:
]]
local function addReturnRecharge(actor,num)
    local returnData = getReturnData(actor)
    returnData.recharge =  (returnData.recharge or 0) + num
end


--[[
    @desc: 增加回归玩家邀请者的充值额度
    author:{dmw}
    time:2020-06-15 10:07:50
    --@actor:回归玩家
	--@num: 充值额度
    @return:
    @note:这里异步添加给邀请者
]]
local function addRetInvitorRecharge(actor,num)
    local invCode = getInviteCode(actor)
    if("" == invCode) then return end
    local invActorId = LActor.decodeInvCode(invCode)
    local invActor = LActor.getActorById(invActorId) -- 邀请者指针
    if(invActor) then -- 找到了这个玩家 直接添加额度
        addInviteRecharge(invActor, num)
        sendInviteInfo(invActor)
        return
    end
    --开启镜像 -- 这里默认邀请码和角色id有效
    LActor.addReturnRechargeOffline(invActorId, num)
    return
end

--[[
    @desc: 增加回归玩家邀请者的邀请数量
    author:{dmw}
    time:2020-06-15 10:07:50
    --@actor:回归玩家
    @return:
    @note:这里异步添加给邀请者
]]
local function addRetInvitorNum(actor)
    local invCode = getInviteCode(actor)
    if("" == invCode) then return end
    local invActorId = LActor.decodeInvCode(invCode)
    local invActor = LActor.getActorById(invActorId) -- 邀请者指针
    if(invActor) then -- 找到了这个玩家 直接添加额度
        return
        addInviteNum(invActor,1)
    end
    --开启镜像 -- 这里默认邀请码和角色id有效
    DEBUG("添加离线邀请人数")
    LActor.addInvNumOffline(invActorId, 1)
    return
end

local function setRechargeRecord(actor, num)
    local returnData = getReturnData(actor)
    returnData.rechargerecord = num
end

--[[
    @desc: 获取上一次登录时间
    author:{dmw}
    time:2020-06-12 18:30:37
    --@actor: 
    @return:
    @note:这个函数尽可能少调用
]]
local function getLastOnlineTime(actor)
    local db = System.createActorsDbConn()
    local sql = string.format("select lastonlinetime from actors where actorid=%d", LActor.getActorId(actor))
    local err = System.dbQuery(db, sql)
    if err ~= 0 then
        DEBUG("getLastOnlineTime fail, dbQuery fail", actor)
        return nil
    end

    local row = System.dbCurrentRow(db)
    local lastOnlineTime = tonumber(System.dbGetRow(row, 0))

    System.dbResetQuery(db)
    System.dbClose(db)
    System.delActorsDbConn(db)
    return lastOnlineTime
end

--[[
    @desc: 是否是回归状态
    author:{dmw}
    time:2020-06-13 11:48:21
    --@actor: 
    @return:
]]
local function isReturnState(actor)
    --先判断持续时间
    local stateTime = getReturnStateTime(actor)
    if(stateTime > System.getNowTime()) then
        return true
    end
    local nextTime = getNextStateStartTime(actor) -- 下次可能开启回归状态的时间,无回归状态时用
    if(nextTime == 0) then 
        --设置一下时间
        local lastOnlineTime = getLastOnlineTime(actor)
        if(not lastOnlineTime) then
            LOG("isReturnState getLastOnlineTime fail", actor) 
            return false 
        end
        if(lastOnlineTime == 0) then -- 新建号上次时间是0
            lastOnlineTime = System.getNowTime()
        end
        nextTime = lastOnlineTime + baseConfig.offlinetime*3600
    end
    local confZSLv = baseConfig.openzslv or 0
    local confVipLv = baseConfig.returnviplv or 0
    local zsLv = LActor.getVipLevel(actor)
    local vipLv = LActor.getVipLevel(actor)
    if(nextTime<=System.getNowTime() and (zsLv >= confZSLv or vipLv >= confVipLv )) then
        setNextStateStartTime(actor, 0) -- 设为0,方便下次重新获取
        clearReturnData(actor)
        setReturnStateTime(actor,System.getNowTime()+baseConfig.statustime*3600) -- 持续时间设置
        return true
    end
    return false
end

--[[
    @desc: 是否存在该玩家
    author:{dmw}
    time:2020-06-13 16:20:09
    --@actorId: 
    @return:
]]
local function isExistedActor(actorId)
    DEBUG("查询数据库是否存在该玩家")
    
    if(not actorId) then return false end
    if(not tonumber(actorId)) then return false end -- 无法转化成数字的都是错误数据
    local db = System.createActorsDbConn()
    if(not db) then
        LOG("isExistedActor createActorsDbConn fail")
        return false
    end
    local sql = string.format("select count(1) from actors where actorid=%d", actorId)
    local err = System.dbQuery(db, sql)
    if err ~= 0 then
        DEBUG("isExistedActor fail, dbQuery fail,err=" .. err)
        return false
    end
    local row = System.dbCurrentRow(db)
    local count = tonumber(System.dbGetRow(row, 0))
    System.dbResetQuery(db)
    System.dbClose(db)
    System.delActorsDbConn(db)
    if(count == 0) then return false end
    return true
end

--[[
    @desc: 是否是有效的邀请码
    author:{dmw}
    time:2020-06-13 15:36:52
    --@invCode: 邀请码
    @return:
    @note:与缓存中的对比,没有的话会转化为角色id从数据库查找
]]
local function isValidInvCode(invCode)
    DEBUG("邀请码校验invCode:" .. invCode)
    for i = 1, #invCode do
        local as = string.byte(string.sub(invCode,i,i))
        if( not ((as>=48 and as<=57) or (as>=65 and as<=90) or (as>=97 and as<=122))) then -- 无法识别的字符串
            return false
        end
    end
    local sysData = getSystemData()
    DEBUG("开始查询系统变量")
    if(sysData[invCode]) then 
        DEBUG("sysData[invCode 存在" .. invCode)
        return true
    else
        DEBUG("sysData[invCode] 中不存在:" .. invCode)
    end
    DEBUG("系统变量查询完毕")
    local actorId = LActor.decodeInvCode(invCode)
    if(actorId == "") then
        return false
    end
    if(isExistedActor(actorId)) then
        sysData[invCode] = 1
        DEBUG("设置系统变量sysData[invCode]:" .. sysData[invCode] .. "invCode=" .. invCode)
        return true
    end
    return false
end

local function sendInviteInfo(actor)
    local actorId = LActor.getActorId(actor)
    local inviteCode = LActor.genInvCodeById(actorId)
    if(#inviteCode == 0) then 
        LOG("sendInviteInfo genInvCodeById fail",actor)
        return 
    end
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_PlayerReturn, Protocol.sPlayerReturnCmd_InviteInfo) -- 83-1
    if(not pack) then return end
    LDataPack.writeInt(pack, getInviteNum(actor)) -- 人数
    LDataPack.writeInt(pack, getInviteNumRecord(actor)) -- 人数奖励
    LDataPack.writeInt(pack, getInviteRecharge(actor)) -- 充值
    LDataPack.writeInt(pack, getInviteRechargeRecord(actor)) -- 充值奖励
    LDataPack.writeString(pack, inviteCode) -- 我的邀请码
    LDataPack.flush(pack)
end

local function sendReturnInfo(actor) --83-2
    local leftTime = getReturnStateTime(actor) - System.getNowTime()
    if(leftTime<0) then leftTime = 0 end
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_PlayerReturn, Protocol.sPlayerReturnCmd_ReturnInfo) -- 83-2
    if(not pack) then return end
    LDataPack.writeInt(pack, leftTime) -- 剩余时间
    LDataPack.writeString(pack, getInviteCode(actor)) -- 邀请码
    LDataPack.writeInt(pack, getLoginDays(actor)) -- 已登录天数
    LDataPack.writeInt(pack, getLoginDaysRecord(actor)) -- 天数领取记录
    LDataPack.writeInt(pack, getReturnRecharge(actor)) -- 充值
    LDataPack.writeInt(pack, getRechargeRecord(actor)) -- 充值奖励领取记录
    LDataPack.writeInt(pack, getRetRewardState(actor)) -- 回归奖励领取状态
    LDataPack.flush(pack)
end

local function sendInviteCodeRep(actor,result)
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_PlayerReturn, Protocol.sPlayerReturnCmd_InviteCode) -- 83-3
    if(not pack) then return end
    LDataPack.writeInt(pack, result)
    LDataPack.flush(pack)
end

--[[
    @desc: 唯一一份回归/邀请奖励
    author:{dmw}
    time:2020-06-15 16:49:01
    --@actor:
	--@result: 0成功 其他失败
    @return:
]]
local function sendRetRewardRep(actor,result)
    local pack = LDataPack.allocPacket(actor, Protocol.CMD_PlayerReturn, Protocol.sPlayerReturnCmd_GetRetReward) -- 83-8
    if(not pack) then return end
    LDataPack.writeInt(pack, result)
    LDataPack.flush(pack)
end

local function onInviteInfo(actor)
    sendInviteInfo(actor)
end

local function onReturnInfo(actor)
    sendReturnInfo(actor)
end

local function onBindInviteCode(actor,cpack)
    local result = 0 -- 绑定成功
    local inviteCode = LDataPack.readString(cpack)
    if(#inviteCode>16) then return end -- 太长了就不给解析了 肯定不会这么长
    local actorId = LActor.getActorId(actor)
    while(true) do
        if(getInviteCode(actor) ~= "") then
            result = 3 -- 已绑定邀请码
            break
        end -- 已有的不可绑定

        if(not isValidInvCode(inviteCode)) then -- 无效邀请码
            result = 2
            break
        end

        local bindActorId = LActor.decodeInvCode(inviteCode)

        if(tostring(bindActorId) == tostring(actorId)) then -- 自己的邀请码
            sendTip(actor,"不可自己的邀请码",2)
            result = 1
            break
        else
            DEBUG("通过验证,不是自己的邀请码,bindActorId:" .. bindActorId .. " 自己的actorid:" .. actorId)
            break
        end
        break
    end
    if(result == 0) then
        setInviteCode(actor,inviteCode)
        -- 为离线玩家增加一个绑定人数
        addRetInvitorNum(actor)
    end
    sendInviteCodeRep(actor,result)
    sendReturnInfo(actor)
end

--[[
    @desc: 请求邀请数量奖励
    author:{dmw}
    time:2020-06-12 17:53:07
    --@actor:
	--@cpack: 
    @return:
]]
local function onGetInvNumReward(actor,cpack)
    local config = invNumConfig
    local index = LDataPack.readInt(cpack)
    if(not index or index<1 or index>#config) then
        DEBUG("onGetInvNumReward 前端传来的数据有误 index:" .. (index or 0), actor)
        return
    end
    local conf = config[index]
    if(not conf) then return end
    local rewardRecord = getInviteNumRecord(actor) -- 获取领取记录
    -- 检测是否可用获得该项奖励
    local invNum = getInviteNum(actor)
    if(invNum < conf.num) then return end -- 错误的数据不管,前端不该发过来
    if(System.bitOPMask(rewardRecord, index-1)) then return end -- 已领取

    setInviteNumRecord(actor, System.bitOpSetMask(rewardRecord, index-1, true)) -- 设置领取记录标志位
    for i,v in pairs(conf.rewards or {}) do
        LActor.giveItem(actor, v.id, v.count, "InvNumReward index:" .. index) -- 发奖励
    end
    sendInviteInfo(actor) -- 推送消息
    sendTip(actor,"成功领取邀请者数量达标奖励:" .. index, 2)
end

--[[
    @desc: 获取邀请者被充值达标奖励
    author:{dmw}
    time:2020-06-12 14:14:47
    --@actor:
	--@cpack: 
    @return:
]]
local function onGetInvRechargeReward(actor,cpack)
    local config = invRechargeConfig
    local index = LDataPack.readInt(cpack)
    if(not index or index<1 or index>#config) then
        DEBUG("onGetInvNumReward 前端传来的数据有误 index:" .. (index or 0), actor)
        return
    end
    local conf = config[index]
    if(not conf) then return end
    local rewardRecord = getInviteRechargeRecord(actor)
    local invRecharge = getInviteRecharge(actor) -- 邀请者充值金额
    if(conf.val>invRecharge) then return end
    if(System.bitOPMask(rewardRecord, index-1)) then return end -- 已领取
    setInviteRechargeRecord(actor, System.bitOpSetMask(rewardRecord, index-1, true)) -- 设置领取标志位
    
    for i,v in pairs(conf.rewards or {}) do
        LActor.giveItem(actor, v.id, v.count, "InvRechargeReward index:" .. index) -- 发奖励
    end
    sendInviteInfo(actor) -- 推送消息
    sendTip(actor,"成功领取邀请者充值达标奖励:" .. index, 2)
end

--[[
    @desc: 领取回归玩家登录奖励
    author:{dmw}
    time:2020-06-12 14:17:25
    --@actor:
	--@cpack: 
    @return:
    @note:解决登录当天+1天的问题 
]]
local function onGetRetLoginReward(actor,cpack)
    DEBUG("领取回归登录奖励")
    local config = returnConfig
    local index = LDataPack.readInt(cpack)
    if(not index or index<1 or index>#config) then
        DEBUG("onGetRetLoginReward 前端传来的数据有误 index:" .. (index or 0), actor)
        return
    end
    local conf = config[index]
    if(not conf) then return end
    if(getLoginDays(actor) < conf.day) then 
        DEBUG("回归登录天数不够",actor)
        return 
    end
    local rewardRecord = getLoginDaysRecord(actor)
    if(System.bitOPMask(rewardRecord, index-1)) then -- 照顾前端这里index-1
        DEBUG("已经领取过:" .. index .. " rewardRecord:" .. rewardRecord)
        return 
    end -- 已领取
    setLoginDaysRecord(actor, System.bitOpSetMask(rewardRecord, index-1, true)) -- 设置领取标志位
    
    for i,v in pairs(conf.rewards or {}) do
        LActor.giveItem(actor, v.id, v.count, "RetLoginReward index:" .. index) -- 发奖励
    end
    sendReturnInfo(actor) -- 推送消息
    sendTip(actor,"成功领取回归登录奖励:" .. index, 2)
end

--[[
    @desc: 领取回归玩家充值奖励
    author:{dmw}
    time:2020-06-12 14:17:39
    --@actor:
	--@cpack: 
    @return:
]]
local function onGetRetRechargeReward(actor,cpack)
    local config = returnRechargeConfig
    local index = LDataPack.readInt(cpack)
    if(not index or index<1 or index>#config) then
        DEBUG("onGetRetLoginReward 前端传来的数据有误 index:" .. (index or 0), actor)
        return
    end
    local conf = config[index]
    if(not conf) then return end
    local rewardRecord = getRechargeRecord(actor)
    local returnRecharge = getReturnRecharge(actor)
    if(conf.val > returnRecharge) then return end -- 不达标
    if(System.bitOPMask(rewardRecord, index-1)) then return end -- 已领取
    setRechargeRecord(actor, System.bitOpSetMask(rewardRecord, index-1, true)) -- 设置领取标志位
    
    for i,v in pairs(conf.rewards or {}) do
        LActor.giveItem(actor, v.id, v.count, "ReturnRechargeReward index:" .. index) -- 发奖励
    end
    sendReturnInfo(actor) -- 推送消息
    sendTip(actor,"成功领取回归充值奖励奖励:" .. index, 2)
end

--[[
    @desc: 是否可领取回归奖励
    author:{dmw}
    time:2020-06-15 16:34:45
    --@actor: 
    @return:
]]
local function canGetRetReward(actor)
    if(1==getRetRewardState(actor)) then
        return false
    end
    if(isReturnState(actor) and getInviteCode(actor)) then
        return true
    end
    if(getInviteNum(actor)>=1) then
        return true
    end
    return false
end

--[[
    @desc: 领取回归奖励
    author:{dmw}
    time:2020-06-15 16:31:39
    --@actor: 
    @return:
]]
local function onGetRetReward(actor)
    local result = 0
    while(true) do
        if(not canGetRetReward(actor)) then
            result = 1
            break
        end
        break
    end
    if(result == 0) then
        setRetRewardState(actor, 1)
        for _,v in pairs(baseConfig.returnreward) do
            LActor.giveItem(actor,v.id,v.count,"RetReward") -- 回归/邀请奖励
        end
    end
    sendReturnInfo(actor)
    sendRetRewardRep(actor,result)
end

--[[
    @desc: 发送所有回归未领取的奖励
    author:{dmw}
    time:2020-06-13 11:44:21
    --@actor: 
    @return:
    @note:暂时不做
]]
local function sendAllReturnReward(actor)


end

local function onLogin(actor)
    local curTime = System.getNowTime()
    -- 判断一下回归状态是否结束,结束直接把未领取的奖励发了 TODO (先不做比较麻烦)
    if(isReturnState(actor)) then -- 回归状态期间
        -- 增加天数
        local stateLastLoginTime = getLastLoginTime(actor) -- 上一次状态期间登录时间
        if(not System.isSameDay(stateLastLoginTime, curTime)) then -- 非同一天
            addLoginDays(actor)
            setLastLoginTime(actor, curTime) -- 重制下时间
        end
    end
    local actorId = LActor.getActorId(actor)
    local inviteCode = LActor.genInvCodeById(actorId)
    addInviteCodeRecord(inviteCode)
    sendInviteInfo(actor)
    sendReturnInfo(actor)
end


local function onReCharge(actor, rechargeAmount)
    --判断是否处于回归状态
    if(not isReturnState(actor)) then
        return
    end
    --一份充值额度给自己
    addReturnRecharge(actor,rechargeAmount)

    --同样一份充值额度给邀请人
    addRetInvitorRecharge(actor,rechargeAmount)
end

local function initFunc()
    if(not System.isCommSrv()) then return end  -- 只有普通服触发 
    local openDays = System.getOpenServerDay() + 1 -- 当前开服时间
    if(openDays < baseConfig.openserverday) then return end -- 时间不满足
    --initDbConn()
    actorevent.reg(aeUserLogin, onLogin)
    actorevent.reg(aeRecharge, onReCharge)
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_InviteInfo, onInviteInfo) -- 邀请信息 83-1
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_ReturnInfo, onReturnInfo) -- 回归信息 83-2
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_InviteCode, onBindInviteCode) -- 绑定邀请码 83-3
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_GetInvNumReward, onGetInvNumReward) -- 领取邀请人数奖励 83-4
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_GetInvRechargeReward, onGetInvRechargeReward) -- 领取邀请被充值奖励 83-5
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_GetRetLoginReward, onGetRetLoginReward) -- 领取回归登录奖励 83-6
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_GetRetRechargeReward, onGetRetRechargeReward) -- 领取回归充值奖励 83-7
    netmsgdispatcher.reg(Protocol.CMD_PlayerReturn, Protocol.cPlayerReturnCmd_GetRetReward, onGetRetReward) -- 领取回归充值奖励 83-8
end




table.insert(InitFnTable, initFunc)
--table.insert(FinaFnTable, finaFunc)
_G.addInviteRecharge = addInviteRecharge
_G.addInviteNum = addInviteNum

local gmsystem    = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
--@geninv 生成激活码
gmHandlers.geninv = function ( actor, args )
    if(#args < 1) then return false end
	local actorId = args[1]
	local invCode = LActor.genInvCodeById(actorId)
	sendTip(actor,actorId .. "的邀请码是:" .. invCode ,4)
	return true
end

gmHandlers.decodeinv = function ( actor, args )
    if(#args < 1) then return false end
	local invCode = args[1]
	local actorId = LActor.decodeInvCode(invCode)
	sendTip(actor,invCode .. "的角色id是:" .. actorId ,4)
	return true
end

-- 查看回归状态结束时间
gmHandlers.retinfo = function ( actor, args )
    local actorId = LActor.getActorId(actor)
    local strlog = "回归/邀请奖励领取状态: " .. getRetRewardState(actor) .. "\n"
    strlog = strlog ..  "我的邀请码: " .. LActor.genInvCodeById(actorId) .. "\n"
    strlog = strlog .. "召回玩家的数量: " ..  getInviteNum(actor) .. "\n"
    strlog = strlog .. "被充值额度:" .. getInviteRecharge(actor) .. "\n"
    strlog = strlog .. "上次登录时间:" .. getLastLoginTime(actor) .. "\n"
    strlog = strlog .. "下次可能开启时间: " .. getNextStateStartTime(actor) .. "\n"
    strlog = strlog .. "回归持续时间: " .. getReturnStateTime(actor)+1262275200 .. "\n"
    strlog = strlog .. "绑定的邀请码: " .. getInviteCode(actor) .. "\n"
    strlog = strlog .. "登录天数: " .. getLoginDays(actor) .. "\n"
    strlog = strlog .. "充值金额: " .. getReturnRecharge(actor) .. "\n"


    strlog = strlog .. "召回玩家的数量领取记录: " .. getInviteNumRecord(actor) .. "\n"
    strlog = strlog .. "被充值额度领取记录: " .. getInviteRechargeRecord(actor) .. "\n"
    strlog = strlog .. "登录天数领取记录: " .. getLoginDaysRecord(actor) .. "\n"
    strlog = strlog .. "充值金额领取记录: " .. getRechargeRecord(actor) .. "\n"

    sendTip(actor,strlog)
end


gmHandlers.bindcode = function ( actor, args )
    local invCode = args[1]

end

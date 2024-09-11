module("equipsystem", package.seeall)

--元宝回收

local function LOG(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:equipsystem." .. log .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:equipsystem." .. log .. " actorid:" .. actorid)
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


local ybLimit = RecoverConfig.recoverlimit or 100
local logNum = 20
local config = EquipConfig -- 装备属性表
local equipSmeltYbRecord = equipSmeltYbRecord or {} --{{actorId,ybCount}}
--[[
	systemdata:系统数据
	equipsystemdata = {
		{actorid=123,ybcount=456}, -- 玩家123 获得了456元宝
		...
	}
]]

--[[
	--玩家个人数据
	equipsystemdata = {
		todayrewardyb, -- 今日获得的元宝数
		doubleybtime, -- 元宝双倍时间到期时间
	}
]]

-- 获取玩家数据
local function getActorData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.equipsystemdata == nil then
		var.equipsystemdata = {}
	end
	return var.equipsystemdata
end

--[[
    @desc: 获取今日获取元宝数量
    author:{author}
    time:2020-04-23 19:36:33
    --@actor: 
    @return:
]]
local function getTodayYbCount(actor)
	local actordata = getActorData(actor)
	return actordata.todayrewardyb or 0
end

--[[
    @desc: 增加今日获取元宝的数量
    author:{author}
    time:2020-04-23 19:41:05
    --@actor:
	--@yb: 新增的元宝
    @return:
]]
local function addTodayYbCount(actor, yb)
	local actordata = getActorData(actor)
	actordata.todayrewardyb = (actordata.todayrewardyb or 0) + yb
end

local function setTodayYbCount(actor, yb)
	local actordata = getActorData(actor)
	actordata.todayrewardyb = yb
end

local function getDoubleTime(actor)
	local actordata = getActorData(actor)
	return actordata.doubleybtime or 0
end

local function setDoubleTime(actor, time)
	local actordata = getActorData(actor)
	actordata.doubleybtime = time
end

local function addDoubleTime(actor, time)
	local actordata = getActorData(actor)
	local now = System.getNowTime()
	if((actordata.doubleybtime or 0) < now) then -- 过期了
		actordata.doubleybtime = now + time
		return
	end
	actordata.doubleybtime = (actordata.doubleybtime or 0) + time
end

--[[
    @desc: 今日是否还能获取元宝
    author:{author}
    time:2020-04-23 19:42:20
    --@actor: 
    @return:今日是否可继续获得元宝
]]
local function canGetYb(actor)
	local yb = getTodayYbCount(actor)
	if yb < ybLimit then -- 未达到上限
		return true
	end
	return false
end

--[[
    @desc: 获取倍率
    author:{author}
    time:2020-04-23 19:46:03
    --@actor: 
    @return:1 2
]]
local function getMultiple(actor)
	--if(not canGetYb(actor)) then
	--	return 0
	--end
	local doubleTime = getDoubleTime(actor)
	local now = System.getNowTime()
	return (doubleTime < now) and 1 or 2
end

local equipsmeltrecord = equipsmeltrecord or {} -- 熔炼获取元宝记录
-- 熔炼获取元宝记录(最新20条)
local function getEquipSmeltRecord() 
	local var = System.getStaticVar()
	if var == nil then 
		return nil 
	end
	if var.equipsmeltrecord == nil then 
		var.equipsmeltrecord = {}
	end
	return var.equipsmeltrecord
end



local function isEquip(actor, uid)
	return true
end

--[[
    @desc: 是否可用熔炼
    author:{author}
    time:2020-04-23 16:38:53
    --@type:不知道什么用
	--@uid: 
    @return:
]]
local function canSmelt(actor, uid)
	--检测是否有这个道具
	local itemId = LActor.getItemIdByUid(actor,uid)
	if(itemId == 0) then return false end
	 -- 类型检测 先认为客户端不会传来错误的装备
	 if(not EquipConfig[itemId]) then return false end
	 if (false == LActor.isEquip(actor, uid)) then return false end
	 return true
end

--[[
    @desc: 发送奖励信息
    author:{author}
    time:2020-04-23 18:36:24
    --@currencyList:货币奖励列表
--@itemList: 道具奖励列表
    @return:
]]
local function sendReqEquipSmelt(actor, currencyList, itemList)
	local currencyCount = 0
	local itemCount = 0
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_EquipSmelt)
	local posCurrency = LDataPack.getPosition(pack)
	LDataPack.writeShort(pack, currencyCount)
	for type,value in pairs(currencyList) do
		LDataPack.writeInt(pack, type) -- 货币类型
		LDataPack.writeInt(pack, value) -- 货币数量
		currencyCount = currencyCount + 1
	end
	local posItem = LDataPack.getPosition(pack)
	LDataPack.setPosition(pack, posCurrency)
	LDataPack.writeShort(pack, currencyCount)
	LDataPack.setPosition(pack, posItem)

	LDataPack.writeShort(pack, itemCount) -- 道具数量
	for itemId,count in pairs(itemList) do
		LDataPack.writeInt(pack, itemId) -- 道具id
		LDataPack.writeInt(pack, count) -- 道具数量
		itemCount = itemCount + 1
	end
	local posFinal = LDataPack.getPosition(pack)
	LDataPack.setPosition(pack, posItem)
	LDataPack.writeShort(pack, itemCount)
	LDataPack.setPosition(pack, posFinal)
	LDataPack.flush(pack)
end

--[[
    @desc: 广播最新一条消息(废弃)
    author:{author}
    time:2020-04-23 20:51:30
    @return:
]]
local function sendEquipSmeltOneRecord()
	local lastNum = #equipSmeltYbRecord
	local actorId = equipSmeltYbRecord[lastNum].actorId
	local ybCount = equipSmeltYbRecord[lastNum].ybCount
	local actorName = LActor.getActorName(actorId)

	local pack = LDataPack.allocPacket()
	LDataPack.writeByte(pack, Protocol.CMD_Equip)
	LDataPack.writeByte(pack, Protocol.sEquipCmd_EquipSmeltOneBroadCast) -- 4-25
	LDataPack.writeString(pack, actorName)
	LDataPack.writeInt(pack, ybCount)
	System.broadcastData(pack)
end

--[[
    @desc: 添加元宝记录
    author:{author}
    time:2020-04-23 20:29:40
    --@actor: 
    @return:
]]
local function updateSmeltYbRecord(actor,actorId,ybCount)
	if(ybCount == 0) then return end
	if(#equipSmeltYbRecord > logNum) then
		table.remove(equipSmeltYbRecord,1) -- 移除头部数据
	end
	table.insert(equipSmeltYbRecord,{actorId=actorId,ybCount=ybCount})
	sendEquipSmeltOneRecord() -- 全服广播
end

--[[
    @desc: 发送今日元宝回收量和双倍剩余时间
    author:{author}
    time:2020-04-24 17:18:06
    --@actor: 
    @return:
]]
local function sendDoubleTime(actor)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_EquipSmeltDoubleTime) -- 4-24
	local leftTime = getDoubleTime(actor) - System.getNowTime()
	if(leftTime<0) then leftTime = 0 end
	local todayYbCount = getTodayYbCount(actor)
	LDataPack.writeInt(pack, leftTime)
	LDataPack.writeInt(pack, todayYbCount)
	LDataPack.flush(pack)
end

--[[
    @desc: 装备分解
    author:{author}
    time:2020-04-23 16:19:25
    --@actor:
	--@cpacket: 
    @return:
]]
local function onReqEquipSmelt(actor,cpacket)
	--print("收到协议 4-2")
	local actorId = LActor.getActorId(actor)
	local uidTab = {} -- 装备uid列表
	local type = LDataPack.readInt(cpacket) -- 大概没什么用
	local count = LDataPack.readInt(cpacket) -- 发送的数量

	for i=1,count do
		local uid = LDataPack.readInt64(cpacket) -- 道具uid
		table.insert(uidTab, uid)
	end

	local smeltCount = 0 -- 分解掉的数量
	local itemRewardList = {} -- 道具奖励
	local currencyRewardList = {} -- 货币奖励
	--熔炼流程
	for _,uidTmp in pairs(uidTab) do
		if(canSmelt(actor, uidTmp)) then
			local itemId = LActor.getItemIdByUid(actor,uidTmp) -- 道具id
			--LActor.costItemByUid(actor, uid, 1, "equip smelt") -- 不写日志到数据库 否则太多
			LActor.deleteItemByUid(actor, uidTmp, 1) -- 删装备
			smeltCount = smeltCount + 1

			-- 整合奖励
			local conf = EquipConfig[itemId]
			-- 获得更高级奖励
			local curRate = math.random(100) -- 获得高阶装备 原始逻辑 移植
			local qualityAdd = false
			for i,v in pairs(conf.equipRate or {}) do
				if(curRate < v.rate) then
					local newItemId = itemId + 100 * (v.qualityAdd)
					if(EquipConfig(newItemId)) then
						itemRewardList[newItemId] = (itemRewardList[newItemId] or 0) + 1
					end
					qualityAdd = true
					DEBUG(actor,"onReqEquipSmelt 少发一次奖励")
					break
				end
				curRate = curRate - v.rate
			end
                       		
			if(qualityAdd == false) then -- 没有获得装备才能获得元宝 强化石奖励
				-- 货币奖励 NumericType_YuanBao
				for i,v in pairs(conf.moneyType or {}) do
					currencyRewardList[v.type] = (currencyRewardList[v.type] or 0) + v.count
				end
				currencyRewardList[NumericType_Gold] = (currencyRewardList[NumericType_Gold] or 0) + (conf.moneyNum or 0) -- 原始配置金币与其他货币是分开的,所以额外做一份
				-- 强化石
				if(conf.stoneId and conf.stoneNum) then
					itemRewardList[conf.stoneId] = (itemRewardList[conf.stoneId] or 0) + conf.stoneNum
				end
			end
		end
	end

	-- 给奖励
	local ybMultiple = getMultiple(actor) -- 元宝倍率
	if(currencyRewardList[NumericType_YuanBao]) then
		currencyRewardList[NumericType_YuanBao] = ybMultiple * 10 * currencyRewardList[NumericType_YuanBao]
		--currencyRewardList[NumericType_YuanBao] = 2 * currencyRewardList[NumericType_YuanBao]
        --        currencyRewardList[NumericType_YuanBao] = 1
		updateSmeltYbRecord(actor,actorId, currencyRewardList[NumericType_YuanBao])
	end
	for type,value in pairs(currencyRewardList) do
		LActor.changeCurrency(actor, type, value, "equip smelt")
		DEBUG(actor,"onReqEquipSmelt 货币类型:" .. type .. " 货币数量:" .. value)
	end
	for id,count in pairs(itemRewardList) do
		LActor.giveItem(actor, id, count, "equip smelt")
		--print("发送熔炼奖励,id:" .. id .. " 数量:" .. count)
	end
	sendReqEquipSmelt(actor, currencyRewardList, itemRewardList) -- 回包

	if(currencyRewardList[NumericType_YuanBao] and currencyRewardList[NumericType_YuanBao] ~= 0) then
		addTodayYbCount(actor, currencyRewardList[NumericType_YuanBao])
		sendDoubleTime(actor)
	end

	actorevent.onEvent(actor, aeSmeltEquip, smeltCount) -- 触发事件
end

--[[
    @desc: 发送熔炼元宝公告
    author:{author}
    time:2020-04-23 20:21:45
    --@actor: 
    @return:
]]
local function sendSmeltBroadCast(actor)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_EquipSmeltBroadCast) -- 4-23
	LDataPack.writeShort(pack, #equipSmeltYbRecord)
	for _,v in ipairs(equipSmeltYbRecord) do
		local actorName = LActor.getActorName(v.actorId)
		local ybCount = v.ybCount
		LDataPack.writeString(pack, actorName)
		LDataPack.writeInt(pack, ybCount)
	end
	LDataPack.flush(pack)
end

--[[
    @desc: 获取公告(废弃)
    author:{author}
    time:2020-04-23 20:20:37
    --@actor: 
    @return:

local function onReqSmeltBroadCast(actor, cpacket)
	sendSmeltBroadCast(actor)
end
]]


--[[
    @desc: 使用双倍道具
    author:{author}
    time:2020-04-24 17:17:14
    --@actor:
	--@time: 
    @return:
]]
function useItemAddDoubleTime(actor, time)
	addDoubleTime(actor, time)
	sendDoubleTime(actor)
end

--[[
    @desc: 双倍剩余时间与今日领取数量
    author:{author}
    time:2020-04-23 20:20:45
    --@actor: 
    @return:
]]
local function onReqDoubleTime(actor, cpacket)
	sendDoubleTime(actor)
end

local function onNewDay(actor)
	setTodayYbCount(actor, 0) -- 重置玩家当日获取元宝量
end

local function onLogin(actor)
	sendDoubleTime(actor)
	sendSmeltBroadCast(actor)
end


local function init()
    --注册消息
    equipSmeltYbRecord = getEquipSmeltRecord()
    actorevent.reg(aeNewDayArrive, onNewDay)
    actorevent.reg(aeUserLogin, onLogin)
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_ReqEquipSmelt, onReqEquipSmelt) -- 装备分解 4-2
	--netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_EquipSmeltBroadCast, onReqSmeltBroadCast) -- 获取公告 4-23,上线主动推送不再请求
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_EquipSmeltDoubleTime, onReqDoubleTime) -- 双倍时间剩余和今日已领取元宝 4-24
end

table.insert(InitFnTable, init)

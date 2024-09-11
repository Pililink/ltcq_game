module("darkhallequip", package.seeall)

local personalSystemID = 3 -- 个人系统编号是3,这是我做的第三个属性相关的系统所以是3.编号用于显示战力/属性信息用 daimengwe 2020-4-9
local function LOG(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:darkhallequip." .. log .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:darkhallequip." .. log .. " actorid:" .. actorid)
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
--[[
	darkhallequipdata = { -- 暗殿装备数据
		darkhallexp,--强化用的经验
		[roleid] = {
			magicstonelv, -- 暗殿魔石等级
			lingstonelv, -- 暗殿灵石等级
			[slot] = { -- 部位 EquipIndex
				strengthenlv, -- 强化等级
				equipitemid, -- 装备的道具id
			}
			...
		}
		...
	}
]]

local EquipType = { -- 装备类型 1魔2圣
	DevilType = 1, -- 魔
	HolyType = 2, -- 圣
}

local EquipIndex = {
	--DarkhallType_Begin = 0,
	--魔
	DarkhallType_Helmet = 1,--头盔
	DarkhallType_Necklace = 3,--项链
	DarkhallType_Wrist = 4,--护腕
	DarkhallType_Belt = 5,--腰带
	DarkhallType_Ring = 6,--戒指
	DarkhallType_Shoes = 7,--鞋子

	--圣
	DarkhallType_Hats = 9,  --斗笠
	DarkhallType_Weapon = 0,--武器
	DarkhallType_Coat = 2,--衣服
	DarkhallType_Mark = 10,  --面甲
	DarkhallType_Shield = 12,  --盾牌
	DarkhallType_Cloak = 11,  --披风
	--DarkhallType_End = 13,
}

local StoneIndex = {
	--石头
	--DarkhallStoneType_Begin = 0,
	DarkhallStoneType_MagicStone = 1,  --魔石
	DarkhallStoneType_LingStone = 2,  --灵石
	--DarkhallStoneType_End = 3,
}

local DarkPowerType = { -- 暗殿灵力类型
	SunType = 1,
	MonType = 2,
	StarType = 3,
	ChenType = 4,
	DarkType = 5,
}

-- 获取玩家数据
local function getActorData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.darkhallequipdata == nil then
		var.darkhallequipdata = {}
	end
	return var.darkhallequipdata
end

-- 获取角色数据
local function getRoleData(actor,roleId)
	if(not roleId) then
		LOG(actor,"getRoleData roleId is nil")
        return
	end
	local actordata = getActorData(actor)
	if(not actordata[roleId]) then
        actordata[roleId] = {}
	end
    return actordata[roleId]
end

local function getDarkhallExp(actor)
	local actorData = getActorData(actor)
	return actorData.darkhallexp or 0
end

local function setDarkhallExp(actor,exp)
	local actorData = getActorData(actor)
	actorData.darkhallexp = exp
end

--[[
    @desc: 增加/减少暗殿经验
    author:{author}
    time:2020-04-03 10:20:28
    --@actor:
	--@addexp: 增加的经验(可正可负)
    @return:
]]
local function addDarkhallExp(actor,addexp)
	local actorData = getActorData(actor)
	actorData.darkhallexp = (actorData.darkhallexp or 0) + addexp
end

--[[
    @desc: 获取角色魔石/灵石等级
    author:{author}
    time:2020-04-01 19:55:01
    --@actor:
	--@roleId:
	--@stoneindex: 1魔石 2灵石
    @return:
]]
local function getStoneLv(actor,roleId,stoneIndex)
	if(not roleId or not stoneIndex) then
		LOG(actor,"getStoneLv roleId,stoneIndex is nil")
        return
	end
	local roleData = getRoleData(actor,roleId)
	if(stoneIndex == 1) then
		DEBUG(actor,"getStoneLv 获取魔石等级:" .. tonumber(roleData.magicstonelv or 0))
		return tonumber(roleData.magicstonelv or 0) 
	else
		DEBUG(actor,"getStoneLv 获取灵石等级:" .. tonumber(roleData.lingstonelv or 0))
		return tonumber(roleData.lingstonelv or 0) 
	end
end

--[[
    @desc: 设置角色魔石/灵石等级
    author:{author}
    time:2020-04-01 19:55:01
    --@actor:
	--@roleId:
	--@stoneindex: 1魔石 2灵石
    @return:
]]
local function setStoneLv(actor, roleId, stoneIndex, lv)
	if(not roleId or not stoneIndex) then
		LOG(actor,"getStoneLv roleId,stoneIndex is nil")
        return
	end
	local roleData = getRoleData(actor,roleId)
	if(stoneIndex == tonumber(StoneIndex.DarkhallStoneType_MagicStone)) then
		
		roleData.magicstonelv = lv -- 魔石
		DEBUG(actor,"setStoneLv 角色:" .. roleId .." 设置魔石等级:" .. roleData.magicstonelv .. " stoneIndex:" .. stoneIndex)
	else
		roleData.lingstonelv = lv -- 灵石
		DEBUG(actor,"setStoneLv 角色:" .. roleId .." 设置灵石等级:" .. roleData.lingstonelv .. " stoneIndex:" .. stoneIndex)
	end
	DEBUG(actor,"setStoneLv 魔石等级:" .. (roleData.magicstonelv or 0))
	DEBUG(actor,"setStoneLv 灵石等级:" .. (roleData.lingstonelv or 0))
	return
end

--[[
    @desc: 获取装备信息
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
local function getEquipInfo(actor,roleId,slot)
	local roledata = getRoleData(actor, roleId)
	if(not roledata) then
		LOG(actor,"getEquipInfo roledata is nil")
		return 
	end
	if(not roledata[slot]) then roledata[slot] = {} end
	return roledata[slot]
end

--[[
    @desc: 获取部位强化等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
local function getEquipStrengthenLv(actor,roleId,slot)
	local equipInfo = getEquipInfo(actor,roleId,slot)
	return equipInfo.strengthenlv or 0
end

--[[
    @desc: 设置部位强化等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
local function setEquipStrengthenLv(actor,roleId,slot,lv)
	local equipInfo = getEquipInfo(actor,roleId,slot)
	equipInfo.strengthenlv = lv
end

--[[
    @desc: 获取部位装备的itemid
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
local function getEquipItemId(actor,roleId,slot)
	local equipInfo = getEquipInfo(actor,roleId,slot)
	return equipInfo.equipitemid or 0
end

--[[
    @desc: 设置部位装备的itemid
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
local function setEquipItemId(actor,roleId,slot,equipItemId)
	local equipInfo = getEquipInfo(actor,roleId,slot)
	equipInfo.equipitemid = equipItemId
end

--[[
    @desc: 获取玩家暗殿灵力
    author:{author}
    time:2020-04-08 15:22:39
    --@actor: 
    @return:
]]
function getDarkPower(actor,powerTab)
	local roleCount = LActor.getRoleCount(actor)

	for roleId=0,roleCount-1 do
		for _,slot in pairs(EquipIndex) do
			local equipItemid = getEquipItemId(actor,roleId,slot)
			local conf = DarkHallEquipConfig[equipItemid]
			if(conf) then 
				for type,value in pairs (conf.darkpower or {}) do
					powerTab[type] = (powerTab[type] or 0) + value
				end
			end
		end
	end
	for type=1,5 do 
		powerTab[type] = powerTab[type] or 0 -- 5个灵力填满
	end
	DEBUG(actor,"getDarkPower 灵力槽数据:" .. #powerTab)
end

--[[
    @desc: 发送玩家灵力信息 4-19
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function sendLingPower(actor)
	local lingPower = {}
	getDarkPower(actor, lingPower)
	local count = #lingPower
	DEBUG(actor,"sendLingPower count:" .. count)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallLingPower)
	LDataPack.writeShort(npack,count) -- 数量
	for type,value in ipairs(lingPower) do
		LDataPack.writeInt(npack,value) -- 灵力
		DEBUG(actor,"sendLingPower ling:" .. value)
	end
	LDataPack.flush(npack)
end

--[[
    @desc: 发送玩家强化经验 4-20
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function sendStrengthExp(actor)
	local exp = getDarkhallExp(actor)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallStrengthExp)
	LDataPack.writeUInt(npack,exp) -- 强化经验
	LDataPack.flush(npack)
end

--[[
    @desc: 发送部位装备id信息
    author:{author}
    time:2020-04-01 20:29:28
	--@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function sendSlotItemId(actor,roleId,slot)
	local slotItemId = getEquipItemId(actor,roleId,slot)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallItemIdInfo) -- 4-13
	LDataPack.writeShort(npack,roleId) -- 角色编号
	LDataPack.writeShort(npack,slot) -- 部位
	LDataPack.writeUInt(npack,slotItemId) -- 道具id
	LDataPack.flush(npack)
end

--[[
    @desc: 发送部位强化信息
    author:{author}
    time:2020-04-01 20:29:28
	--@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function sendQianghuaInfo(actor,roleId,slot)
	local strengthenLv = getEquipStrengthenLv(actor,roleId,slot)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallLv) -- 4-15
	LDataPack.writeShort(npack,roleId) -- 角色编号
	LDataPack.writeShort(npack,slot) -- 部位
	LDataPack.writeShort(npack,strengthenLv) -- 强化等级
	LDataPack.flush(npack)
end

--[[
    @desc: 发送石头信息 4-16
    author:{author}
    time:2020-04-01 20:29:28
	--@actor:
	--@roleId:
	--@stoneIndex: 1魔石 2 灵石
    @return:
]]
local function sendStoneInfo(actor,roleId,stoneIndex)
	local lv = getStoneLv(actor,roleId,stoneIndex)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallStoneInfo) -- 4-16
	LDataPack.writeShort(npack,roleId) -- 角色编号
	LDataPack.writeShort(npack,stoneIndex) -- 石头索引
	LDataPack.writeShort(npack,lv) -- 等级
	LDataPack.flush(npack)
	DEBUG(actor,"sendStoneInfo 石头编号:" .. stoneIndex .. " 石头等级:" .. lv)
end

--[[
    @desc: 发送当前强化经验信息
    author:{author}
    time:2020-04-07 15:32:59
    --@actor:
	--@addexp: 
    @return:
]]
local function sendEquipSmeltInfo(actor,addexp)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallEquipSmelt)
	LDataPack.writeShort(npack,addexp or 0) -- 增加的经验
	LDataPack.writeUInt(npack,getDarkhallExp(actor)) -- 当前剩余经验
	LDataPack.flush(npack)
end


--[[
    @desc: 更换装备 4-13
    author:{author}
    time:2020-04-02 10:50:31
    --@actor:
	--@cpacket: 客户端的数据包
    @return:
]]
local function changeDarkhallEquip(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号
	local equipItemId = LDataPack.readUInt(cpacket)--要更换的道具id
	if(not roleId or not slot or not equipItemId) then
		LOG(actor,"changeDarkhallEquip cpacket error")
		return
	end

	-- 传参校验
	local roleCount = LActor.getRoleCount(actor)
	if(roleId > roleCount -1) then
		LOG(actor,"changeDarkhallEquip not exist role,roleId:" .. roleId .. " maxRoleId:" .. roleCount-1)
		return
	end

	local conf = DarkHallEquipConfig[equipItemId]
	if(not conf) then --配置道具是否存在
		LOG(actor,"changeDarkhallEquip conf not exist,equipItemId:" .. equipItemId)
		return
	end

	if(slot ~= conf.slot) then 
		LOG(actor,"changeDarkhallEquip slot not match,slot:" .. slot .. " conf.slot:" .. conf.slot)
		return
	end

	-- 玩家道具校验
	local hasCount = LActor.getItemCount(actor, equipItemId)
	if(hasCount < 1 ) then 
		LOG(actor,"changeDarkhallEquip itemcount not enough,equipItemId:" .. equipItemId)
		return 
	end

	-- 等级检查
	local zslv = LActor.getZhuanShengLevel(actor)
	if(zslv < (conf.zslevel or 0)) then return end

	local oldEquipItemId = getEquipItemId(actor,roleId,slot)
	setEquipItemId(actor,roleId,slot,equipItemId)
	LActor.costItem(actor,equipItemId,1,"changeDarkhallEquip")

	if(oldEquipItemId ~= 0) then
		LActor.giveItem(actor, oldEquipItemId, 1, "changeDarkhallEquip")
	end
	sendSlotItemId(actor,roleId,slot)
	sendLingPower(actor)
	updateAttr(actor,roleId)
end

--[[
    @desc: 脱装备
    author:{author}
    time:2020-04-02 10:50:31
    --@actor:
	--@cpacket: 客户端的数据包
    @return:
]]
local function takeoffDarkhallEquip(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号
	if(not roleId or not slot) then
		LOG(actor,"takeoffDarkhallEquip cpacket error")
		return
	end

	-- 传参校验
	local roleCount = LActor.getRoleCount(actor)
	if(roleId > roleCount -1) then
		LOG(actor,"takeoffDarkhallEquip not exist role,roleId:" .. roleId .. " maxRoleId:" .. roleCount-1)
		return
	end
	--[[ -- 不做判断了,出错也没影响 历史设计问题,部位从0开始且不连续
	if(slot > #EquipIndex or slot < EquipIndex.DarkhallType_Helmet) then
		LOG(actor,"takeoffDarkhallEquip slot not match,slot:" .. slot)
		return
	end
	]]
	local curEquipItemId = getEquipItemId(actor,roleId,slot)
	if(curEquipItemId == 0) then
		return
	end

	setEquipItemId(actor,roleId,slot,0)
	LActor.giveItem(actor, curEquipItemId, 1, "takeoffDarkhallEquip")
	sendSlotItemId(actor,roleId,slot)
	sendLingPower(actor)
	updateAttr(actor,roleId)
end

--[[
    @desc: 强化部位
    author:{author}
    time:2020-04-02 10:50:31
    --@actor:
	--@cpacket: 客户端的数据包
    @return:
]]
local function strengthenDarkhallEquip(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号
	if(not roleId or not slot) then
		LOG(actor,"takeoffDarkhallEquip cpacket error")
		return
	end
	-- 传参校验
	local roleCount = LActor.getRoleCount(actor)
	if(roleId > roleCount -1) then
		LOG(actor,"strengthenDarkhallEquip not exist role,roleId:" .. roleId .. " maxRoleId:" .. roleCount-1)
		return
	end
	--[[
	if(slot > #EquipIndex or slot < EquipIndex.DarkhallType_Helmet) then
		LOG(actor,"strengthenDarkhallEquip slot error,slot:" .. slot)
		return
	end
	]]

	local slotLv = getEquipStrengthenLv(actor,roleId,slot) 
	if(slotLv >= #DarkHallEquipLevelConfig[slot]) then 
		return 
	end
	local conf = DarkHallEquipLevelConfig[slot][slotLv]
	local darkhallExp = getDarkhallExp(actor)

	if(darkhallExp < conf.exp) then return end

	-- 扣经验 升级 发送强化信息 发送经验剩余
	addDarkhallExp(actor,-conf.exp)
	setEquipStrengthenLv(actor,roleId,slot,slotLv+1)
	sendQianghuaInfo(actor,roleId,slot)
	sendEquipSmeltInfo(actor,-conf.exp)

	updateAttr(actor,roleId)
end

--[[
    @desc: 获取当前石头上限等级
    author:{author}
    time:2020-04-03 14:16:43
    --@actor:
	--@stoneIndex: 1魔石 2灵石
    @return:
]]
local function getStoneLvUpLimit(actor,stoneIndex)
	local zsLv = LActor.getZhuanShengLevel(actor)
	local conf = nil
	if(stoneIndex == StoneIndex.DarkhallStoneType_MagicStone) then
		conf = DarkHallEquipBaseConfig.magicstonenum
	elseif(stoneIndex == StoneIndex.DarkhallStoneType_LingStone) then
		conf = DarkHallEquipBaseConfig.spiritstonenum
	else
		return 0
	end
	return conf[zsLv] or 0
end

--[[
    @desc: 石头升级
    author:{author}
    time:2020-04-02 10:50:31
    --@actor:
	--@cpacket: 客户端的数据包
    @return:
]]
local function stoneLvUp(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local stoneIndex = LDataPack.readShort(cpacket)--部位编号 1魔石 2灵石
	if(not roleId or not stoneIndex) then
		LOG(actor,"stoneLvUp cpacket error")
		return
	end
	-- 传参校验
	local roleCount = LActor.getRoleCount(actor)
	if(roleId > roleCount -1) then
		LOG(actor,"stoneLvUp not exist role,roleId:" .. roleId .. " maxRoleId:" .. roleCount-1)
		return
	end
	if(stoneIndex > 2 or stoneIndex < 1) then
		LOG(actor,"stoneLvUp stoneIndex error,stoneIndex:" .. stoneIndex)
		return
	end

	local curStoneLv = getStoneLv(actor,roleId,stoneIndex) -- 当前等级
	local lvLimit = getStoneLvUpLimit(actor,stoneIndex) -- 上限等级
	if(curStoneLv>=lvLimit) then return end

	-- 道具数量判断
	local stoneItemId = stoneIndex == tonumber(StoneIndex.DarkhallStoneType_MagicStone) and DarkHallEquipBaseConfig.magicstone or DarkHallEquipBaseConfig.spiritstone
	local hasCount = LActor.getItemCount(actor,stoneItemId)
	if(hasCount < 1) then return end

	--消耗道具 设置等级 发送石头消息
	LActor.costItem(actor, stoneItemId, 1, "darkhallequip_stoneLvUp")
	setStoneLv(actor,roleId,stoneIndex,curStoneLv+1) -- 设置等级
	sendStoneInfo(actor,roleId,stoneIndex) -- 发送石头等级

	updateAttr(actor,roleId)
end

-- 神圣装备进阶
local function holyEquipmentExchange(actor,cpacket)
	local jieLv = LDataPack.readShort(cpacket)--装阶等级 6
	local slot = LDataPack.readShort(cpacket)--部位 11 611106

	if(not DarkHallEquipLvUpConfig[jieLv]) then
		return
	end

	if(not DarkHallEquipLvUpConfig[jieLv][slot]) then
		return
	end

	local conf = DarkHallEquipLvUpConfig[jieLv][slot]
	if(not conf) then
		LOG(actor,"holyEquipmentExchange conf not exist,itemid:" .. equipItemId)
		return
	end
	local equipItemId = conf.itemid -- 要合成的道具

	local expend = {} -- 材料列表
	for _,v in pairs(conf.expend) do
		expend[v.id] = (expend[v.id] or 0) + v.count
	end

	for expendItemId,expendItemCount in pairs(expend) do
		local hasCount = LActor.getItemCount(actor, expendItemId)
		if(hasCount < expendItemCount) then
			LOG(actor,"holyEquipmentExchange item not enough,itemid:" .. expendItemId) -- 检查材料数量
			return
		end
	end

	for expendItemId,expendItemCount in pairs(expend) do
		LActor.costItem(actor, expendItemId, expendItemCount, "holyEquipmentExchange:" .. equipItemId) -- 装备进阶
	end

	LActor.giveItem(actor, equipItemId, 1, "holyEquipmentExchange:" .. equipItemId) -- 存在背包满的情况
end

--[[
    @desc: 装备熔炼
    author:{author}
    time:2020-04-03 16:30:57
    --@actor:
	--@cpacket: 
    @return:
]]
local function equipSmelt(actor,cpacket)
	DEBUG(actor,"equipSmelt 装备被熔炼")
	local num = LDataPack.readShort(cpacket)--道具种类数目
	DEBUG(actor,"equipSmelt 装备总数量:" .. num)
	local addexp = 0
	for i=1,num do
		local equipItemId = LDataPack.readUInt(cpacket) -- 道具id
		local count = LDataPack.readShort(cpacket) -- 该道具数量
		DEBUG(actor,"equipSmelt 熔炼装备id:" .. equipItemId .. " 装备数量:" .. count)
		if(DarkHallSmelt[equipItemId]) then
			local hasCount = LActor.getItemCount(actor, equipItemId)
			if(hasCount>=count) then
				LActor.costItem(actor, equipItemId, count, "darkhallequip.equipSmelt")
				addexp = addexp + DarkHallSmelt[equipItemId].exp*count
			else
				LOG(actor,"equipSmelt amount not enough,itemid:" .. equipItemId .. " costcount:" .. count ..  " realcount:" .. hasCount)
			end
		else
			LOG(actor,"equipSmelt conf not exist,itemid:" .. equipItemId)
		end
	end
	DEBUG(actor,"equipSmelt 增加了经验:" .. addexp)
	addDarkhallExp(actor,addexp)
	sendEquipSmeltInfo(actor,addexp)
end

--[[
    @desc: 发送角色暗殿装备信息 4-22
    author:{author}
    time:2020-04-02 10:11:28
    --@actor:
	--@roleId: 
    @return:
]]
local function sendRoleDarkhallInfo(actor,roleId)
	local slotCount = 0
	for slot in pairs(DarkHallEquipLevelConfig) do
		slotCount = slotCount + 1
	end

	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_DarkhallRoleInfo) -- 4-22
	LDataPack.writeShort(npack,roleId) -- 角色编号
	LDataPack.writeShort(npack,slotCount) -- 部位数量
	DEBUG(actor,"sendRoleDarkhallInfo 部位数量:" .. slotCount)
	for slot in pairs(DarkHallEquipLevelConfig) do
		LDataPack.writeShort(npack,slot) -- 部位编号
		DEBUG(actor,"sendRoleDarkhallInfo 部位编号:" .. slot)
		LDataPack.writeUInt(npack,getEquipItemId(actor,roleId,slot)) -- 部位装备id
		LDataPack.writeShort(npack,getEquipStrengthenLv(actor,roleId,slot))-- 部位强化等级
	end

	LDataPack.writeShort(npack,2) -- 宝石数量
	for stoneIndex=1,2 do -- 这么写是因为没有配置文件可用
		local stoneLv = getStoneLv(actor,roleId,stoneIndex)
		LDataPack.writeShort(npack, stoneIndex) -- 类型
		LDataPack.writeShort(npack, stoneLv) -- 石头等级
		DEBUG(actor,"sendRoleDarkhallInfo 石头类型1魔 2灵:" .. stoneIndex .. " 石头等级:" .. stoneLv)
	end
	LDataPack.flush(npack)
end

--[[
    @desc: 暗殿装备属性计算
    author:{author}
    time:2020-04-14 11:16:59
    --@actor:
	--@roleId [in]:角色编号
	--@magicAttr [in]:魔装属性
	--@holyAttr [in]: 圣装属性
    @return:
]]
local function darkEquipAttr(actor,roleId,darkEquipTab)
	darkEquipTab.devilEquipAttr = darkEquipTab.devilEquipAttr or {}
	darkEquipTab.devilEquipAttr.attrTab = darkEquipTab.devilEquipAttr.attrTab or {}
	darkEquipTab.devilEquipAttr.exAttrTab = darkEquipTab.devilEquipAttr.exAttrTab or {}
	local devilAttrTab = darkEquipTab.devilEquipAttr.attrTab -- 魔属性表
	local devilExAttrTab = darkEquipTab.devilEquipAttr.exAttrTab -- 魔额外属性表

	darkEquipTab.holyEquipAttr = darkEquipTab.holyEquipAttr or {}
	darkEquipTab.holyEquipAttr.attrTab = darkEquipTab.holyEquipAttr.attrTab or {}
	darkEquipTab.holyEquipAttr.exAttrTab = darkEquipTab.holyEquipAttr.exAttrTab or {}
	local holyAttrTab = darkEquipTab.holyEquipAttr.attrTab -- 圣属性表
	local holyExAttrTab = darkEquipTab.holyEquipAttr.exAttrTab -- 圣额外属性表


	for _,slot in pairs(EquipIndex) do
		-- 身上装备道具属性
		local equipId = getEquipItemId(actor,roleId,slot)
		if(equipId ~= 0) then 
			DEBUG(actor,"darkEquipAttr 部位:" .. slot .. " 道具id:" .. equipId)
		end
		local equipConf = DarkHallEquipConfig[equipId]
		
		if(equipConf) then
			--DEBUG(actor,"darkEquipAttr 部位:" .. slot .. " 道具id:" .. equipId .. " 找到配置文件")
			local attrTabTmp = (equipConf.type == EquipType.DevilType) and devilAttrTab or holyAttrTab
			local exAttrTabTmp = (equipConf.type == EquipType.DevilType) and devilExAttrTab or holyExAttrTab
			if(equipConf.type == EquipType.DevilType) then
				DEBUG(actor,"darkEquipAttr 魔属性装备")
			else
				DEBUG(actor,"darkEquipAttr 圣属性装备")
			end

			for i,v in pairs(equipConf.attrs or {}) do 
				attrTabTmp[v.type] = (attrTabTmp[v.type] or 0) + v.value
			end
			for i,v in pairs(equipConf.exattrs or {}) do 
				exAttrTabTmp[v.type] = (exAttrTabTmp[v.type] or 0) + v.value
			end
			darkEquipTab.extraPower = (darkEquipTab.extraPower or 0) + (equipConf.expower or 0)
		else
			--DEBUG(actor,"darkEquipAttr 部位:" .. slot .. " 道具id:" .. equipId .. " 没有找到配置文件")
		end
	end
end

--[[
    @desc: 部位强化的属性
    author:{author}
    time:2020-04-14 13:49:26
    --@actor:
	--@roleId:
	--@attrTab: 
    @return:
]]
local function darkEquipQianghuaAttr(actor,roleId,darkEquipTab)
	darkEquipTab.qianghuaAttr = darkEquipTab.qianghuaAttr or {}
	darkEquipTab.qianghuaAttr.attrTab = darkEquipTab.qianghuaAttr.attrTab or {}
	darkEquipTab.qianghuaAttr.exAttrTab = darkEquipTab.qianghuaAttr.exAttrTab or {}
	local attrTab = darkEquipTab.qianghuaAttr.attrTab
	local exAttrTab = darkEquipTab.qianghuaAttr.exAttrTab

	for _,slot in pairs(EquipIndex) do
		local equipItemId = getEquipItemId(actor,roleId, slot)
		if(equipItemId ~= 0) then -- 有装备才计算它的强化属性
			-- 部位强化属性
			local strengthenLv = getEquipStrengthenLv(actor,roleId,slot)
			local strengthConf = DarkHallEquipLevelConfig[slot][strengthenLv]
			if(strengthConf) then
				for i,v in pairs(strengthConf.attrs or {}) do 
					attrTab[v.type] = (attrTab[v.type] or 0) + v.value
					--DEBUG(actor,"darkEquipQianghuaAttr 部位强化属性 角色编号:" .. roleId .. " 部位编号:" .. slot .. " 基础属性类型:" .. v.type .. " 基础属性数值:" .. v.value)
				end
				for i,v in pairs(strengthConf.exattrs or {}) do 
					exAttrTab[v.type] = (exAttrTab[v.type] or 0) + v.value
					--DEBUG(actor,"darkEquipQianghuaAttr 部位强化属性 角色编号:" .. roleId .. " 部位编号:" .. slot .. " 额外属性类型:" .. v.type .. " 额外属性数值:" .. v.value)
				end
				darkEquipTab.extraPower = (darkEquipTab.extraPower or 0) + (strengthConf.expower or 0) -- 额外战力值
			end
		end
	end
end

--[[
    @desc: 暗殿套装属性
    author:{author}
    time:2020-04-14 14:34:40
    --@actor:
	--@roleId:
	--@darkEquipTab [in]: 属性总表
    @return:
]]
local function darkEquipSuitAttr(actor,roleId,darkEquipTab)
	darkEquipTab.equipSuit = darkEquipTab.equipSuit or {}
	darkEquipTab.equipSuit[EquipType.DevilType] = {}
	darkEquipTab.equipSuit[EquipType.HolyType] = {}
	darkEquipTab.equipSuit.devilcombo = {}
	darkEquipTab.equipSuit.holycombo = {}
	darkEquipTab.equipSuit.attrTab = {}
	darkEquipTab.equipSuit.exAttrTab = {}

	local equipClass = darkEquipTab.equipSuit
	local devilcombo = darkEquipTab.equipSuit.devilcombo -- 魔套属性
	local holycombo = darkEquipTab.equipSuit.holycombo -- 神圣属性
	local attrTab = darkEquipTab.equipSuit.attrTab
	local exAttrTab = darkEquipTab.equipSuit.exAttrTab

	for _,slot in pairs(EquipIndex) do -- 部位索引
		local equipItemId = getEquipItemId(actor, roleId, slot) -- 该部位的装备道具id
		local equipConf = DarkHallEquipConfig[equipItemId]
		if(equipConf) then
			if(equipConf.type == EquipType.DevilType) then --魔
				for classLv=1,equipConf.equipclass do -- 装阶等级
					equipClass[EquipType.DevilType][classLv] = (equipClass[EquipType.DevilType][classLv] or 0) + 1 -- 该装阶以下的数量+1
				end
			elseif(equipConf.type == EquipType.HolyType) then -- 圣
				for classLv=1,equipConf.equipclass do -- 装阶等级
					equipClass[EquipType.HolyType][classLv] = (equipClass[EquipType.HolyType][classLv] or 0) + 1 -- 该装阶以下的数量+1
				end
			else
				DEBUG(actor,"updateAttr HOLY SHIT!!!!")
			end
		end
	end

	-- 魔套2件套 4件套 6件套
	local equipClass = darkEquipTab.equipSuit or {}
	for classLv=#DarkhallEquipSuit[EquipType.DevilType][2],1,-1 do -- 最高级  这里从1-最高装阶等级,但配置文件不行 所以使用了2件套的最高等级 默认可行
		if ((equipClass[EquipType.DevilType][classLv] or 0) >=2 and not devilcombo[2]) then -- s数量大于2激活,2件套
			devilcombo[2] = classLv
			DEBUG(actor,"darkEquipSuitAttr 魔套2件套激活,角色编号:" .. roleId .. "等级:" .. classLv)
		end
		if ((equipClass[EquipType.DevilType][classLv] or 0) >=4 and not devilcombo[4]) then -- s数量大于2激活,2件套
			devilcombo[4] = classLv
			DEBUG(actor,"darkEquipSuitAttr 魔套4件套激活,角色编号:" .. roleId .. "等级:" .. classLv)
		end
		if ((equipClass[EquipType.DevilType][classLv] or 0) >=6 and not devilcombo[6]) then -- s数量大于2激活,2件套
			devilcombo[6] = classLv
			DEBUG(actor,"darkEquipSuitAttr 魔套6件套激活,角色编号:" .. roleId .. "等级:" .. classLv)
		end
	end

	-- 圣套2件套 4件套 6件套
	for classLv=#DarkhallEquipSuit[EquipType.HolyType][2],1,-1 do -- 找出2阶最高套装属性
		if (equipClass[EquipType.HolyType][classLv] >=2 and holycombo[2] == nil) then -- s数量大于2激活,2件套
			holycombo[2] = classLv -- 套装激活
			DEBUG(actor," 神圣套装2件套激活,等级:" .. classLv)
		end
		if (equipClass[EquipType.HolyType][classLv] >=4 and holycombo[4] == nil) then -- s数量大于2激活,2件套
			holycombo[4] = classLv
			DEBUG(actor," 神圣套装4件套激活,等级:" .. classLv)
		end
		if (equipClass[EquipType.HolyType][classLv] >=6 and holycombo[6] == nil) then -- s数量大于2激活,2件套
			holycombo[6] = classLv
			DEBUG(actor," 神圣套装6件套激活,等级:" .. classLv)
		end
	end

	for num,combosInfo in pairs(DarkhallEquipSuit[EquipType.DevilType] or {}) do -- 魔套装2,4,6属性计算
		if(devilcombo[num]) then -- 套装被激活
			local devilSuitConf = combosInfo[devilcombo[num]]
			local confAttr = devilSuitConf.attrs or {}
			local confExattr = devilSuitConf.exattrs or {}
			for i,v in pairs(confAttr) do -- 装备属性
				attrTab[v.type] = (attrTab[v.type] or 0) + v.value
			end
			for i,v in pairs(confExattr) do 
				exAttrTab[v.type] = (exAttrTab[v.type] or 0) + v.value 
			end
			darkEquipTab.extraPower = (darkEquipTab.extraPower or 0) + (devilSuitConf.expower or 0)
		end
	end

	for num,combosInfo in pairs(DarkhallEquipSuit[EquipType.HolyType] or {}) do -- 圣套装2,4,6属性计算
		if(holycombo[num]) then -- 套装被激活
			local holySuitConf = combosInfo[holycombo[num]]
			local confAttr = holySuitConf.attrs or {}
			local confExattr = holySuitConf.exattrs or {}
			for i,v in pairs(confAttr) do -- 装备属性
				attrTab[v.type] = (attrTab[v.type] or 0) + v.value
			end
			for i,v in pairs(confExattr) do 
				exAttrTab[v.type] = (exAttrTab[v.type] or 0) + v.value 
			end
			darkEquipTab.extraPower = (darkEquipTab.extraPower or 0) + (holySuitConf.expower or 0)
		end
	end
end

local function darkEquipStoneAttr(actor,roleId,darkEquipTab)
	darkEquipTab.stoneAttr = darkEquipTab.stoneAttr or {}
	darkEquipTab.stoneAttr.attrTab = darkEquipTab.stoneAttr.attrTab or {}
	local stoneTab = darkEquipTab.stoneAttr.attrTab
	local devilEquipAttr = darkEquipTab.devilEquipAttr or {}
	local holyEquipAttr = darkEquipTab.holyEquipAttr or {}

	-- 两块石头 万分比(根据装备) 魔石+魔属性装备 灵石全加
	for _,stoneIndex in pairs(StoneIndex) do
		local stoneLv = getStoneLv(actor,roleId,stoneIndex)
		local stoneAttrs = (stoneIndex==1) and (DarkHallEquipBaseConfig.magicstoneattr or {}) or (DarkHallEquipBaseConfig.spiritstoneattr or {}) -- 1魔石/2灵石
		for i,v in pairs(stoneAttrs) do -- 石头本身的属性
			stoneTab[v.type] = (stoneTab[v.type] or 0) + v.value * stoneLv
			--DEBUG(actor,"darkEquipStoneAttr 石头 type:" .. v.type .. " value:" .. v.value)
		end
		-- 石头加成的属性
		local rate = stoneLv*((stoneIndex==1) and (DarkHallEquipBaseConfig.magicstoneprecent or 0) or (DarkHallEquipBaseConfig.spiritstoneprecent or 0))/10000 -- 石头加成率

		for type,value in pairs(devilEquipAttr.attrTab or {}) do -- 装备属性
			stoneTab[type] = (stoneTab[type] or 0) + value*rate
		end
		if(stoneIndex==2) then -- 灵属性要加成圣属性
			for type,value in pairs(holyEquipAttr.attrTab or {}) do -- 装备属性
				stoneTab[type] = (stoneTab[value] or 0) + value*rate
			end
		end
	end
end

--[[
    @desc: 属性计算
    author:{author}
    time:2020-04-08 15:11:50
    --@actor:
	--@roleId: 
    @return:
]]
function updateAttr(actor,roleId)
	local extraPower = 0 -- 额外战力,用于无法计算战力的属性
	local actorId = LActor.getActorId(actor)
	local role = LActor.getRole(actor, roleId)
	if not role then 
		DEBUG(actor,"updateAttr 没有角色")
		return 
	end
	local attr = LActor.getDarkhallAttr(actor, roleId)
	if not attr then 
		DEBUG(actor,"updateAttr 没有属性")
		return 
	end
	attr:Reset()
	
	local exAttr = LActor.getDarkhallExAttr(actor, roleId)
	if not exAttr then
		DEBUG(actor,"updateAttr 没有额外属性") 
		return 
	end
	exAttr:Reset()

	local darkEquipTab = { -- 全属性表
--[[
		devilEquipAttr = { -- 魔属性
			attrTab = {},
			exAttrTab = {
				
			},

		},
		holyEquipAttr = { -- 圣属性
			attrTab = {},
			exAttrTab = {

			}
		},

		qianghuaAttr = {
			attrTab = {},
			exAttrTab = {
			}
		},
		
		equipSuit = {
			[EquipType.DevilType] = {
				[classLv] = 1, -- 件数

			},
			[EquipType.HolyType] = {
				[classLv] = 1, -- 件数

			}
			devilcombo = {}
			holycombo = {}
			attrTab ={}
			exAttrTab = {

			}
		},
		stoneAttr = {
			attrTab ={}
			exAttrTab = {

			}
			devilRate, -- 魔属性加成
			LingRate, -- 灵属性加成
		}
		extraPower,
]]
	}

	darkEquipAttr(actor,roleId,darkEquipTab)
	darkEquipQianghuaAttr(actor,roleId,darkEquipTab)
	darkEquipSuitAttr(actor,roleId,darkEquipTab)
	darkEquipStoneAttr(actor,roleId,darkEquipTab)

	local extraPower = (darkEquipTab.extraPower or 0)
	darkEquipTab.extraPower = nil -- 方便下面遍历
	for _,v in pairs(darkEquipTab) do
		for type,value in pairs (v.attrTab or {}) do
			attr:Add(tonumber(type),tonumber(value))
		end
		for type,value in pairs (v.exAttrTab or {}) do
			exAttr:Add(tonumber(type),tonumber(value))
		end
	end

	attr:SetExtraPower(extraPower)
	LActor.reCalcAttr(role)
	LActor.reCalcExAttr(role)
end

-- 初始化 计算属性
local function onInit(actor)
	for i=0, LActor.getRoleCount(actor) - 1 do 
		updateAttr(actor, i) 
	end
end


local function onLogin(actor)
	sendLingPower(actor) -- 灵力
	sendStrengthExp(actor) -- 经验
	for roleId=0, LActor.getRoleCount(actor) - 1 do -- 身上装备等级与id
		sendRoleDarkhallInfo(actor,roleId)
	end
end

local function initGlobalData()
	actorevent.reg(aeInit, onInit)
	actorevent.reg(aeUserLogin, onLogin)
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipChange, changeDarkhallEquip) -- 更换装备 4-13
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipTakeOff, takeoffDarkhallEquip) -- 卸载装备 4-14
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipStrengthen, strengthenDarkhallEquip) -- 装备部位强化 4-15
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipStoneLvUp, stoneLvUp) -- 石头升级 4-16
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipExchange, holyEquipmentExchange) -- 神圣装备进阶 4-17
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_DarkhallEquipSmelt, equipSmelt) -- 装备熔炼 4-18
end

table.insert(InitFnTable, initGlobalData)

-- 计算战斗力,gm调试用
local function calcFight(actor,roleId)

	local darkEquipTab = {}

	darkEquipAttr(actor,roleId,darkEquipTab)
	darkEquipQianghuaAttr(actor,roleId,darkEquipTab)
	darkEquipSuitAttr(actor,roleId,darkEquipTab)
	darkEquipStoneAttr(actor,roleId,darkEquipTab)

	local rolePowerCalc = { -- 战力计算结果存储

	}
	function rolePowerCalc:init()
		self.strengthenFight = 0
		self.devilequipFight = 0
		self.holyequipFight = 0
		self.stoneFight = 0
		self.suitFight = 0
		self.extrapower = 0
		self.suitlog = "" -- 套装激活
		self.strengthenAttr = {}
		self.devilequipAttr = {}
		self.holyequipAttr = {}
		self.stoneAttr = {}
		self.suitAttr = {}
	end
	function rolePowerCalc:strengthenAdd(type,value)
		self.strengthenAttr[type] = (self.strengthenAttr[type] or 0) + value
	end

	function rolePowerCalc:equipAdd(type,value)
		self.equipAttr[type] = (self.equipAttr[type] or 0) + value
	end

	function rolePowerCalc:stoneAdd(type,value)
		self.stoneAttr[type] = (self.stoneAttr[type] or 0) + value
	end

	function rolePowerCalc:suitAdd(type,value)
		self.suitAttr[type] = (self.suitAttr[type] or 0) + value
	end

	function rolePowerCalc:calcAttr()
		--战斗力=攻*3.6+血量*0.2+(物+法)*1.8
		local strengthenTab = self.strengthenAttr or {} -- 强化
		self.strengthenFight = 3.6*(strengthenTab[4] or 0) + 0.2*(strengthenTab[2] or 0) + 1.8*((strengthenTab[5] or 0) + (strengthenTab[6] or 0))

		local equipTab = self.devilequipAttr or {} -- 魔装备
		self.devilequipFight = 3.6*(equipTab[4] or 0) + 0.2*(equipTab[2] or 0) + 1.8*((equipTab[5] or 0) + (equipTab[6] or 0))

		local holyequipTab = self.holyequipAttr or {} -- 圣装备
		self.holyequipFight = 3.6*(holyequipTab[4] or 0) + 0.2*(holyequipTab[2] or 0) + 1.8*((holyequipTab[5] or 0) + (holyequipTab[6] or 0))


		local stoneTab = self.stoneAttr or {} -- 石头
		self.stoneFight = 3.6*(stoneTab[4] or 0) + 0.2*(stoneTab[2] or 0) + 1.8*((stoneTab[5] or 0) + (stoneTab[6] or 0))

		local suitTab = self.suitAttr or {} -- 套装
		self.suitFight = 3.6*(suitTab[4] or 0) + 0.2*(suitTab[2] or 0) + 1.8*((suitTab[5] or 0) + (suitTab[6] or 0))

	end

	rolePowerCalc:init()

	rolePowerCalc.strengthenAttr = darkEquipTab.qianghuaAttr.attrTab or {}
	rolePowerCalc.devilequipAttr = darkEquipTab.devilEquipAttr.attrTab or {}
	rolePowerCalc.holyequipAttr = darkEquipTab.holyEquipAttr.attrTab or {}
	rolePowerCalc.stoneAttr = darkEquipTab.stoneAttr.attrTab or {}
	rolePowerCalc.suitAttr = darkEquipTab.equipSuit.attrTab or {}
	rolePowerCalc.extrapower = darkEquipTab.extraPower or 0

	rolePowerCalc:calcAttr()
	local strlog = " 角色编号:" .. roleId .. "\n 强化战力:" .. rolePowerCalc.strengthenFight
	strlog = strlog .. "\n 装备魔装战力:" .. rolePowerCalc.devilequipFight .. "\n 装备圣装战力:" .. rolePowerCalc.holyequipFight
	strlog = strlog .. "\n 石头战力(包含加成):" .. rolePowerCalc.stoneFight
	strlog = strlog .. "\n 套装战力:" .. rolePowerCalc.suitFight .. "\n 额外总战力:" .. rolePowerCalc.extrapower
	strlog = strlog .. rolePowerCalc.suitlog

	sendTip(actor,strlog)
	DEBUG(actor,strlog)
end

local gmsystem = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.darkhallequip = function(actor, args)
	local roleId = args[1]
	calcFight(actor,roleId)
    return true
end

gmHandlers.adddarkexp = function(actor, args)
	local num = tonumber(args[1])
	addDarkhallExp(actor,num)
    return true
end

gmHandlers.resetdark = function(actor, args)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	var.darkhallequipdata = {}
	sendLingPower(actor) -- 灵力
	sendStrengthExp(actor) -- 经验
	for roleId=0, LActor.getRoleCount(actor) - 1 do -- 身上装备等级与id
		sendRoleDarkhallInfo(actor,roleId)
	end
	return true
end

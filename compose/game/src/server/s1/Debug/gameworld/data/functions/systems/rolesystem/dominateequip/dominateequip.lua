module("dominateequip", package.seeall)

-- 日志
local function LOG(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:dominateequip." .. log .. " actorid:" .. actorid)
end

local function DEBUG(actor,log) -- 上线后把内容注掉
	
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:dominateequip." .. log .. " actorid:" .. actorid)
	
end

local function INFO(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[INFO]:dominateequip." .. log .. " actorid:" .. actorid)
end

local function SYSINFO(log)
	print("[SYSINFO]:dominateequip." .. log)
end

local function SYSLOG(log)
	print("[SYSERROR]:dominateequip." .. log)
end

local function SYSDEBUG(log) -- 上线后把内容注掉
	--[[
	print("[SYSDEBUG]:dominateequip." .. log)
	]]
end



--[[
	dominatedata = { -- 主宰装备属性
		[roleId] = { -- 角色编号
			[slot] = {
				equipid, -- 装备的id
				randomattr = { -- 额外属性的值
					[1]={type,value}, -- 写成这样是让随机属性显示位置保持不变
					...
				}
			[slot] = { 9-12 饰品
				lv, -- 饰品等级
			}
			}
		}
	}
]]--

local EquipSlot = {
	-- 装备
	DominateType_Weapon = 0,--武器
	DominateType_Helmet = 1,--头盔
	DominateType_Coat = 2,--衣服
	DominateType_Necklace = 3,--项链
	DominateType_Wrist = 4,--护腕
	DominateType_Belt = 5,--腰带
	DominateType_Ring = 6,--戒指
	DominateType_Shoes = 7,--鞋子

	--无法分类的东西
	DominateType_LingStone = 8,--灵坯

	--饰品
	DominateType_Hats = 9,  --吊坠
	DominateType_Mark = 10,  --面甲
	DominateType_Cloak = 11,  --肩饰
	DominateType_Shield = 12,  --护膝
}

local Slot_Equip = {0,1,2,3,4,5,6,7} -- 0-7装备
local Slot_Decorations={9,10,11,12} -- 9-12 饰品
local randomMaxNum = 8
--获取玩家静态变量数据
local function getVarData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.dominatedata == nil then
		var.dominatedata = {}
	end
	return var.dominatedata
end

local function getRoleData(actor, roleId)
	local actordata = getVarData(actor)
	if(not actordata[roleId]) then
        actordata[roleId] = {}
	end
    return actordata[roleId]
end

local function getSlotInfo(actor,roleId,slot)
	local roleData = getRoleData(actor, roleId)
	if(not roleData[slot]) then
		roleData[slot] = {}
	end
	return roleData[slot]
end

local function getEquipId(actor,roleId,slot)
	local slotInfo = getSlotInfo(actor,roleId,slot)
	return slotInfo.equipid or 0
end

--[[
    @desc: 获取装备当前星级(衣服 武器)
    author:{author}
    time:2020-04-30 17:55:25
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function getEquipWCLv(actor,roleId,slot)
	local equipId = getEquipId(actor,roleId,slot)
	local conf = ZhuZaiEquipConfig[equipId]
	if(not conf) then
		return 0
	end
	return conf.starlv or 0
end

--[[
    @desc: 设置部位装备id
    author:{author}
    time:2020-04-20 17:01:38
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function setEquipId(actor,roleId,slot,equipId)
	local slotInfo = getSlotInfo(actor,roleId,slot)
	slotInfo.equipid = equipId
end

--[[
    @desc: 获取部位的随机属性列表
    author:{author}
    time:2020-04-17 16:49:50
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function getRandomAttr(actor,roleId,slot)
	local slotInfo = getSlotInfo(actor,roleId,slot)
	if(not slotInfo.randomattr) then
		slotInfo.randomattr = {}
	end
	return slotInfo.randomattr
end

local function getRandomAttrCount(actor,roleId,slot)
	local randomAttr = getRandomAttr(actor,roleId,slot)
	for index = 1,randomMaxNum do --随机条数不超过8条
		if(not randomAttr[index]) then
			return index - 1
		end
	end
	return randomMaxNum
end

--[[
    @desc: 设置随机属性 与部位的道具id
    author:{author}
    time:2020-04-17 17:17:12
    --@actor:
	--@roleId:
	--@slot:
	--@randomAttr:
	--@equipId: 
    @return:
]]
local function setRandomAttr(actor, roleId, slot, randomAttr, equipId)
	DEBUG(actor,"setRandomAttr 身上部位设置随机属性,slot:" .. slot .. " 随机属性条数:" .. #randomAttr .. " 装备id:" .. equipId)
	if(#randomAttr > randomMaxNum) then
		LOG(actor,"setRandomAttr fail, #randomAttr > randomMaxNum")
		return false
	end
	local slotInfo = getSlotInfo(actor,roleId,slot)
	slotInfo.randomattr = {}
	for _,singleAttrTab in ipairs(randomAttr) do
		local attrCount = getRandomAttrCount(actor, roleId, slot)
		slotInfo.randomattr[attrCount+1] = {}
		slotInfo.randomattr[attrCount+1].type = singleAttrTab.type
		slotInfo.randomattr[attrCount+1].value = singleAttrTab.value
	end
	setEquipId(actor, roleId, slot, equipId)
	return true
end

--[[
    @desc: 为当前部位增加一条指定的随机属性
    author:{author}
    time:2020-04-17 17:17:12
    --@actor:
	--@roleId:
	--@slot:
	--@randomAttr:
    @return:
]]
local function addRandomAttr(actor, roleId, slot, attrType, attrValue)
	local randomAttr = getRandomAttr(actor,roleId,slot)
	local randomAttrCount = getRandomAttrCount(actor,roleId,slot)
	for i=1, randomAttrCount do
		if(randomAttr[i].type == attrType) then
			randomAttr[i].value = attrValue
			return true
		end
	end
	-- 没有该属性则尝试增加一条
	if(randomAttrCount >= 5) then
		LOG(actor,"addRandomAttr fail nums greater than 5") -- 策划案不可超过5条
		return false
	end
	randomAttr[randomAttrCount+1] = {}
	randomAttr[randomAttrCount+1].type = attrType
	randomAttr[randomAttrCount+1].value = attrValue
end

--[[
    @desc: 将身上的装备属性赋值到背包中
    author:{author}
    time:2020-04-17 15:23:33
	--@equipItemData: 道具的属性指针
	--@roleId: 角色id
	--@slot: 部位
    @return:
]]
local function setEquipData(actor, roleId, slot, equipItemData, uid)
	local oldEquipId = getEquipId(actor, roleId, slot) -- 当前身上的装备
	if(oldEquipId == 0) then
		DEBUG(actor,"setEquipData 该部位没有旧装备")
		LActor.costItemByUid(actor, uid, 1, "dominateequip.changeEquip")
		return true
	end

	--重置背包中道具属性与id
	equipItemData:setItemId(oldEquipId)
	local result = LActor.resetItemByItemId(actor, uid, oldEquipId) -- 清理背包的道具属性
	if(result == false) then
		LOG(actor,"changeEquip resetitembyItemId fail")
		return false
	end

	local randomAttrTab = getRandomAttr(actor, roleId, slot)
	local randomAttrCount = getRandomAttrCount(actor,roleId,slot)
	for i=1,randomAttrCount do
		equipItemData:addOneLineAttr(randomAttrTab[i].type,randomAttrTab[i].value)
	end

	-- 提醒一下客户端更新
	LActor.notifyUpdateByUid(actor,uid) -- 提示某个道具属性更新
	return true
end

--[[
    @desc: 获取饰品等级
    author:{author}
    time:2020-04-20 18:05:34
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function getEquipLv(actor,roleId,slot)
	local slotInfo = getSlotInfo(actor,roleId,slot) -- 获取饰品等级
	return slotInfo.lv or 0
end

--[[
    @desc: 获取饰品阶数
    author:{author}
    time:2020-04-21 13:37:55
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function getEquipStage(actor,roleId,slot)
	local slotInfo = getSlotInfo(actor,roleId,slot) -- 获取饰品等级
	if(ZhuZaiOrnamentConfig[slot]) then
		local lv = getEquipLv(actor,roleId,slot)
		if(lv == 0) then 
			return 0 
		end
		return ZhuZaiOrnamentConfig[slot][lv] and ZhuZaiOrnamentConfig[slot][lv].stage or 0
	end
	return 0
end

local function setEquipLv(actor,roleId,slot,lv)
	local slotInfo = getSlotInfo(actor,roleId,slot) -- 获取饰品等级
	slotInfo.lv = lv
end

local function setEquipId(actor,roleId,slot,equipId)
	local slotInfo = getSlotInfo(actor,roleId,slot) -- 获取饰品等级
	slotInfo.equipid = equipId
end



--[[
    @desc: 发送部位信息 80-1
    author:{author}
    time:2020-04-17 17:31:51
    --@actor:
	--@roleId:
	--@slot: 
    @return:
]]
local function sendSlotInfo(actor, roleId, slot)
	local equipId = getEquipId(actor,roleId,slot)
	local randomAttrCount = getRandomAttrCount(actor,roleId,slot)
	local randomAttrTab = getRandomAttr(actor,roleId,slot)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DominateEquip, Protocol.sDominateEquipCmd_EquipSlotInfo) -- 80-1
	LDataPack.writeShort(npack, roleId) -- 角色id
	LDataPack.writeShort(npack, slot) -- 部位
	LDataPack.writeInt(npack, equipId) -- 装备id
	LDataPack.writeShort(npack, randomAttrCount) -- 随机属性数量
	for i=1,randomAttrCount do
		LDataPack.writeInt(npack, randomAttrTab[i].type) -- 随机属性类型
		LDataPack.writeInt(npack, randomAttrTab[i].value) -- 随机属性的值
		DEBUG(actor,"sendSlotInfo random.i:" .. i .. " type:" .. randomAttrTab[i].type .. " value:" .. randomAttrTab[i].value)
	end
	LDataPack.flush(npack)
end

--[[
    @desc: 返回合成结果
    author:{author}
    time:2020-04-30 15:53:03
    --@actor:
	--@resultFlag: 合成结果 0成功 其他失败
    @return:
]]
local function sendCompoundEquipResult(actor, resultFlag)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DominateEquip, Protocol.sDominateEquipCmd_EquipCompound) -- 80-2
	LDataPack.writeShort(npack, (resultFlag or 0)) --成功与否
	LDataPack.flush(npack)
end

--[[
    @desc: 发送饰品等级信息
    author:{author}
    time:2020-04-20 18:29:37
    @return:
]]
local function sendSlotLv(actor, roleId, slot)
	local lv = getEquipLv(actor, roleId, slot)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DominateEquip, Protocol.sDominateEquipCmd_EquipLvUp) -- 80-3
	LDataPack.writeShort(npack, roleId) -- 角色id
	LDataPack.writeShort(npack, slot) -- 部位
	LDataPack.writeShort(npack, lv) -- 饰品等级
	LDataPack.flush(npack)
end

--[[
    @desc: 更换装备
    author:{author}
    time:2020-04-16 17:13:09
    --@actor:
	--@cpacket: 
    @return:
]]
local function changeEquip(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号 装备的部位
	local uid = LDataPack.readInt64(cpacket) -- 即将要穿的装备uid
	if(not roleId or not slot or not uid) then
		LOG(actor,"changeEquip cpacket error")
		return
	end

	-- 传参校验
	local roleCount = LActor.getRoleCount(actor)
	if(roleId > roleCount -1) then
		LOG(actor,"changeEquip not exist role,roleId:" .. roleId .. " maxRoleId:" .. roleCount-1)
		return
	end

	-- uid装备校验
	local bagEquipId = LActor.getItemIdByUid(actor,uid) -- 背包道具的id

	local conf = ZhuZaiEquipConfig[bagEquipId]
	if(not conf) then --配置道具是否存在
		LOG(actor,"changeEquip conf not exist,equipId:" .. bagEquipId .. " uid:" .. uid)
		return
	end
	if(slot ~= conf.slot) then 
		LOG(actor,"changeEquip slot not match,slot:" .. slot .. " conf.slot:" .. conf.slot)
		return
	end

	--转生等级判断
	if LActor.getZhuanShengLevel(actor) < conf.zslv then
		LOG(actor,"changeEquip zslv not enough,readzslv:" .. LActor.getZhuanShengLevel(actor) .. "conflv:" .. conf.zslv)
		return
	end

	local equipItemData = LActor.getEquipItemDataByUid(actor,uid)
	if(not equipItemData) then
		LOG(actor,"changeEquip equip not found,equipId:" .. bagEquipId .. " uid:" .. uid)
		return
	end
	-- 检测完成 下面不认为有非法数据

	local randomAttr = {} -- 背包里主宰装备的属性取出
	for i=0, randomMaxNum-1 do
		local attrType = equipItemData:getOneLineAttrType(i)
		local attrValue = equipItemData:getOneLineAttrValue(i)
		if(attrType~=0 and attrValue~=0) then -- 有数据的才导出
			local attrTab = {type=attrType,value=attrValue}
			table.insert(randomAttr,attrTab)
		end
	end


	local ret = setEquipData(actor, roleId, slot, equipItemData, uid) -- 给背包的装备重置属性,这里可能会删掉装备
	if(ret == false) then
		return
	end
	
	setRandomAttr(actor, roleId, slot, randomAttr, bagEquipId) -- 设置部位随机属性与装备id

	sendSlotInfo(actor, roleId, slot)
	updateAttr(actor,roleId)
end


--[[
    @desc: 装备合成 武器,衣服/饰品 两套逻辑用一个协议
    author:{author}
    time:2020-04-20 14:41:28
    --@actor:
	--@cpacket: 
	@return:
	@note:需求太乱(修改ZhuZaiEquipComPoseConfig 表格式的时候要同时修改函数 compoundLingStone)
]]
local function compoundEquip(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号
	local num = LDataPack.readShort(cpacket) -- 消耗的物品表
	local uidTab = {} -- 消耗的装备uid
	local sigTab = {} -- 去重用
	for i=1,num do
		local uid = LDataPack.readInt64(cpacket) --唯一uid
		if(not uid) then 
			LOG(actor,"compoundEquip uid is nil")
			return
		end
		DEBUG(actor,"compoundEquip uid:" .. uid)
		for _,v in pairs(uidTab) do
			if v == uid then
				LOG(compoundEquip,"")
				return
			end
		end
		sigTab[uid] = (sigTab[uid] or 0) + 1
		table.insert(uidTab,uid)
	end

	--入参验证
	for _,v in pairs(sigTab) do
		if(v>1) then
			LOG(actor,"compoundEquip Repeat uid") -- 重复的uid
			return 
		end
	end
	if(not roleId or not slot) then
		LOG(actor,"compoundEquip cpacket error")
		return
	end
	
	if( not ZhuZaiEquipComPoseConfig[slot]) then
		LOG(actor,"compoundEquip conf not exist,slot:" .. slot)
		return
	end

	local conf = nil -- 确认配置

	-- 武器衣服逻辑 穿身上的
	if(slot == EquipSlot.DominateType_Weapon or slot == EquipSlot.DominateType_Coat) then -- 武器衣服
		local equipId = getEquipId(actor, roleId, slot)
		local nextEquipLv = (ZhuZaiEquipConfig[equipId] and ZhuZaiEquipConfig[equipId].starlv or 0) + 1 -- 装备合成的星级,从装备属性表获得下一级装备星级
		if(not ZhuZaiEquipComPoseConfig[slot][nextEquipLv]) then
			LOG(actor,"compoundEquip conf not exist,slot:" .. slot .. " nextEquipLv:" .. nextEquipLv)
			return
		end
		conf = ZhuZaiEquipComPoseConfig[slot][nextEquipLv] -- 合成配置
	end

	-- 饰品 给道具的
	if(slot > EquipSlot.DominateType_LingStone and slot <= EquipSlot.DominateType_Shield) then
		conf = ZhuZaiEquipComPoseConfig[slot][1] -- 饰品
	end

	if(not conf) then
		LOG(actor,"compoundEquip conf not exist,ZhuZaiEquipComPoseConfig[slot][lv],slot:" .. slot)
		return
	end

	if LActor.getZhuanShengLevel(actor) < conf.zslv then -- 转生等级判断
		LOG(actor,"compoundEquip zslv not enough,readzslv:" .. LActor.getZhuanShengLevel(actor) .. "conflv:" .. conf.zslv)
		return
	end

	if(num < conf.equipMaterials.count) then -- 装备数量不够
		LOG(actor,"compoundEquip num not enough,num:" .. num .. " conf.num:" .. conf.equipMaterials.count)
		return
	end
	
	for _,uidTmp in pairs(uidTab) do -- 消耗品检查
		local itemIdTmp = LActor.getItemIdByUid(actor, uidTmp)
		if(not ZhuZaiEquipConfig[itemIdTmp]) then
			LOG(actor,"compoundEquip conf not exist,uid:" .. uidTmp .. " itemId:" .. itemIdTmp) 
			return 
		end
		local equipConfTmp = ZhuZaiEquipConfig[itemIdTmp]
		if(equipConfTmp.starlv < conf.equipMaterials.lv) then
			LOG(actor,"equipMaterials lv not enough") -- 材料装备等级不够
			DEBUG(actor,"equipMaterials lv not enough,材料装备等级:" .. equipConfTmp.starlv .. " 配置要求等级:" .. conf.equipMaterials.lv)  -- 材料装备等级不够
			return
		end
	end

	local itemMaterials = conf.itemMaterials -- 材料检查
	for _,v in pairs(itemMaterials or {}) do
		local hasCount = LActor.getItemCount(actor, v.id)
		if(hasCount<v.count) then
			LOG(actor,"compoundEquip itemMaterials not enough,hascount:" .. hasCount .. " needCount:" .. v.count)
			return
		end
	end

	-- 消耗材料
	for _,v in pairs(itemMaterials or {}) do
		LActor.costItem(actor, v.id, v.count, "ZZComb") -- 主宰合成
	end
	
	-- 消耗装备
	for _,uid in pairs(uidTab) do
		LActor.costItemByUid(actor, uid, 1, "ZZComb,uid:" .. uid) -- 主宰合成
	end

	if(slot == EquipSlot.DominateType_Weapon or slot == EquipSlot.DominateType_Coat) then -- 穿上身的
		-- 装备上身
		setEquipId(actor,roleId,slot,conf.equipId)
		sendSlotInfo(actor, roleId, slot) -- 发送部位信息
		updateAttr(actor,roleId) -- 更新属性
		sendCompoundEquipResult(actor,0) -- 合成失败不管
		return
	end
	if(slot > EquipSlot.DominateType_LingStone and slot <= EquipSlot.DominateType_Shield) then -- 给东西的
		-- 饰品
		LActor.giveItem(actor, conf.equipId, 1, "ZZComb") -- 合成
		sendCompoundEquipResult(actor,0) -- 合成失败不管
		return
	end
	return
end

--[[
    @desc: 饰品升级 9-12
    author:{author}
    time:2020-04-20 18:02:08
    --@actor:
	--@cpacket: 
    @return:
]]
local function equipLvUp(actor,cpacket)
	local roleId = LDataPack.readShort(cpacket)--角色编号
	local slot = LDataPack.readShort(cpacket)--部位编号
	if(slot<9 or slot > 12) then return end
	local equipLv = getEquipLv(actor, roleId, slot)
	local nextLv = equipLv + 1
	local conf = ZhuZaiOrnamentConfig[slot][nextLv]
	if(not conf) then return end

	-- 判断材料
	for i,v in pairs(conf.expend) do
		local hasCount = LActor.getItemCount(actor, v.id)
		if(hasCount<v.count) then
			LOG(actor,"equipLvUp expend not enough,itemid:" .. v.id .. " hascount:" .. hasCount .. " confCount:" .. v.count)
			return
		end
	end
	-- 消耗材料
	for i,v in pairs(conf.expend) do
		LActor.costItem(actor, v.id, v.count, "dominateequip.equipLvUp") -- 饰品升级
	end
	setEquipLv(actor,roleId,slot,nextLv)
	sendSlotLv(actor, roleId, slot)
	updateAttr(actor,roleId)
end

--[[
    @desc: 装备属性萃取/洗练
    author:{author}
    time:2020-04-20 18:48:54
    --@actor:
	--@cpacket: 
	@return:
	@note:
]]
local function equipPextraction(actor,cpacket)
	local attrIndexTab = {} -- 萃取的条目
	local attrTV = {} -- 萃取出来的属性 {[type]=value}
	local roleId = LDataPack.readShort(cpacket) -- 角色编号
	local slot = LDataPack.readShort(cpacket) -- 部位
	local uid = LDataPack.readInt64(cpacket) -- uid
	local count = LDataPack.readShort(cpacket) -- 属性数量

	local itemId = getEquipId(actor, roleId, slot) -- 身上该部位的道具
	if(not ZhuZaiEquipConfig[itemId]) then
		DEBUG(actor,"equipPextraction conf not exist,ZhuZaiEquipConfig[itemId],itemId:" .. itemId)
		return 
	end

	local confItemId = ZhuZaiEquipConfig[itemId].extract.id -- 洗练道具id
	local confNum = ZhuZaiEquipConfig[itemId].extract.count -- 消耗道具的数量
	local hasCount = LActor.getItemCount(actor, confItemId)
	if(hasCount<confNum) then
		LOG(actor,"equipPextraction item not enough,itemid:" .. confItemId) -- 道具不足
		return
	end
	LActor.costItem(actor, confItemId, confNum, "dominateequip.equipPextraction") -- 消耗道具

	for i=1,count do
		local index = LDataPack.readShort(cpacket)
		table.insert(attrIndexTab,index)
	end
	local itemData = LActor.getEquipItemDataByUid(actor, uid) -- 道具的属性
	if(not itemData) then
		LOG(actor,"equipPextraction getEquipItemDataByUid fail")
		return
	end
	for _,index in pairs(attrIndexTab) do
		local type = itemData:getOneLineAttrType(index) -- 获取属性类型
		local value = itemData:getOneLineAttrValue(index) -- 获取属性值
		attrTV[type] = value
	end

	-- 相同属性优先替换,不同属性直接添加,超过5个不写
	for attrType,attrValue in pairs(attrTV) do
		addRandomAttr(actor, roleId, slot, attrType, attrValue)
	end
	LActor.costItemByUid(actor, uid, 1,"dominateequip.equipPextraction") -- 装备萃取
	-- 通知客户端
	sendSlotInfo(actor, roleId, slot)
	updateAttr(actor,roleId) -- 更新属性
end

--[[
    @desc: 灵坯合成
    author:{author}
    time:2020-05-11 16:29:38
    --@actor:
	--@cpacket: 
    @return:
]]
local function compoundLingStone(actor,cpacket)
	local slot = EquipSlot.DominateType_LingStone -- 灵坯8
	local starLv = LDataPack.readShort(cpacket) -- 灵坯星级
	local num = LDataPack.readShort(cpacket) -- 消耗的物品表
	if(not starLv or not num) then return end
	local uidTab = {} -- 消耗的装备uid
	local sigTab = {} -- 去重用
	for i=1,num do
		local uid = LDataPack.readInt64(cpacket) --唯一uid
		if(not uid) then 
			LOG(actor,"compoundLingStone uid is nil")
			return
		end
		DEBUG(actor,"compoundLingStone uid:" .. uid)
		for _,v in pairs(uidTab) do
			if v == uid then
				LOG(compoundEquip,"")
				return
			end
		end
		sigTab[uid] = (sigTab[uid] or 0) + 1
		table.insert(uidTab,uid)
	end

	--入参验证
	for _,v in pairs(sigTab) do
		if(v>1) then
			LOG(actor,"compoundLingStone Repeat uid") -- 重复的uid
			return 
		end
	end

	local conf = ZhuZaiEquipComPoseConfig[slot][starLv]
	if(not conf) then 
		DEBUG(actor,"灵坯合成没有配置,灵坯星级:" .. starLv)
		return 
	end

	-- 装备与材料数量检测
	if(num < conf.equipMaterials.count) then -- 装备数量检测
		LOG(actor,"compoundLingStone num not enough,num:" .. num .. " conf.num:" .. conf.equipMaterials.count)
		return
	end
	for _,uidTmp in pairs(uidTab) do -- 装备等级检测
		local itemIdTmp = LActor.getItemIdByUid(actor, uidTmp)
		if(not ZhuZaiEquipConfig[itemIdTmp]) then
			LOG(actor,"compoundEquip conf not exist,uid:" .. uidTmp .. " itemId:" .. itemIdTmp) 
			return 
		end
		local equipConfTmp = ZhuZaiEquipConfig[itemIdTmp]
		if(equipConfTmp.starlv < conf.equipMaterials.lv) then
			LOG(actor,"equipMaterials lv not enough") -- 材料装备等级不够
			DEBUG(actor,"equipMaterials lv not enough,材料装备等级:" .. equipConfTmp.starlv .. " 配置要求等级:" .. conf.equipMaterials.lv)  -- 材料装备等级不够
			return
		end
	end

	local itemMaterials = conf.itemMaterials -- 材料检查
	for _,v in pairs(itemMaterials or {}) do
		local hasCount = LActor.getItemCount(actor, v.id)
		if(hasCount<v.count) then
			LOG(actor,"compoundEquip itemMaterials not enough,hascount:" .. hasCount .. " needCount:" .. v.count)
			return
		end
	end

	-- 消耗材料
	for _,v in pairs(itemMaterials or {}) do
		LActor.costItem(actor, v.id, v.count, "ZZComb") -- 主宰合成
	end
	
	-- 消耗装备
	for _,uid in pairs(uidTab) do
		LActor.costItemByUid(actor, uid, 1, "ZZComb,uid:" .. uid) -- 主宰合成
	end

	LActor.giveItem(actor, conf.equipId, 1, "ZZStoneComb") -- 灵坯合成
	sendCompoundEquipResult(actor,0) -- 合成失败不管
end

--[[
    @desc: 主宰装备的属性
    author:{author}
    time:2020-04-20 11:15:00
    --@actor:
	--@roleId:
	--@dominateEquipTab: 
    @return:
]]
local function dominateEquipAttr(actor, roleId, dominateEquipTab)
	dominateEquipTab.equipAttr = dominateEquipTab.equipAttr or {} -- 装备属性表
	dominateEquipTab.equipAttr.attrTab = dominateEquipTab.equipAttr.attrTab or {} -- 普通属性表
	dominateEquipTab.equipAttr.exAttrTab = dominateEquipTab.equipAttr.exAttrTab or {} -- 额外属性表

	dominateEquipTab.equipRandomAttr = dominateEquipTab.equipRandomAttr or {} -- 装备随机属性表
	dominateEquipTab.equipRandomAttr.attrTab = dominateEquipTab.equipRandomAttr.attrTab or {} -- 普通随机属性表
	dominateEquipTab.equipRandomAttr.exAttrTab = dominateEquipTab.equipRandomAttr.exAttrTab or {} -- 额外随机属性表

	local equipAttr = dominateEquipTab.equipAttr --装备属性
	local attrTab = equipAttr.attrTab
	local exAttrTab = equipAttr.exAttrTab

	local equipRandomAttr = dominateEquipTab.equipRandomAttr -- 装备随机属性
	local randomAttrTab = equipRandomAttr.attrTab -- 随机属性表

	local promoteTab = {} -- 属性提升,用于conf.attrper字段
	for _,slot in pairs(Slot_Equip) do
		local itemId = getEquipId(actor,roleId,slot)
		local conf = ZhuZaiEquipConfig[itemId]
		if(conf) then
			-- 基础属性
			local attrConf = conf.attrs or {}
			for i,v in pairs(attrConf) do -- 属性列表
				attrTab[v.type] = (attrTab[v.type] or 0) + v.value
			end

			-- 特殊属性
			local exattrConf = conf.exattrs or {}
			for i,v in pairs(exattrConf) do -- 特殊属性列表
				exAttrTab[v.type] = (exattrConf[v.type] or 0) + v.value
			end
			dominateEquipTab.extraPower = (dominateEquipTab.extraPower or 0) + (conf.expower or 0) -- 额外战力

			-- 随机属性
			local randomAttrs = getRandomAttr(actor, roleId, slot)
			local randomAttrCount = getRandomAttrCount(actor, roleId, slot)
			for i=1,randomAttrCount do
				local randomAttr = randomAttrs[i]
				randomAttrTab[randomAttr.type] = (randomAttrTab[randomAttr.type] or 0) + randomAttr.value -- 随机属性里面只有基础属性,不会出现特殊属性
			end

			-- 装备对随机属性的加成
			if(conf.attrper) then
				promoteTab[conf.attrper.type] = (promoteTab[conf.attrper.type] or 0) + conf.attrper.value
			end
		end

		-- 衣服 武器对随机属性中部分属性的加成
		equipAttr.equipPromoteAttr = equipAttr.equipPromoteAttr or {}
		equipAttr.equipPromoteAttr.attrTab = equipAttr.equipPromoteAttr.attrTab or {}
		equipAttr.equipPromoteAttr.exAttrTab = equipAttr.equipPromoteAttr.exAttrTab or {}

		for type,value in pairs(promoteTab) do
			equipAttr.equipPromoteAttr.attrTab[type] = (randomAttrTab[type] or 0) * value/10000 -- 提升的属性
		end
	end

end

--[[
    @desc: 主宰装备饰品
    author:{author}
    time:2020-04-21 10:17:40
    --@actor:
	--@roleId:
	--@dominateEquipTab: 
    @return:
]]
local function dominateDecorationsAttr(actor, roleId, dominateEquipTab)
	local equipTab = dominateEquipTab.equipAttr.attrTab -- 装备基础属性
	dominateEquipTab.decorationsAttr = dominateEquipTab.decorationsAttr or {}
	dominateEquipTab.decorationsAttr.attrTab = dominateEquipTab.decorationsAttr.attrTab or {}
	dominateEquipTab.decorationsAttr.exAttrTab = dominateEquipTab.decorationsAttr.exAttrTab or {}
	local attrTab = dominateEquipTab.decorationsAttr.attrTab -- 饰品基础属性表
	local exAttrTab = dominateEquipTab.decorationsAttr.exAttrTab -- 饰品特殊属性表 用不上
	local config = ZhuZaiOrnamentConfig
	--饰品共4个 9-12
	local minStage = #ZhuZaiEquipSuit + 1 -- 饰品最低阶
	local minDecorationsStage = #ZhuZaiEquipSuit + 1 -- 默认最高+1,不存在的套装,找到
	for _,slot in pairs(Slot_Decorations) do
		local lv = getEquipLv(actor,roleId,slot) -- 获取饰品等级
		local conf = config[slot][lv]
		if(conf) then
			for _,v in pairs(conf.attrs or {}) do
				attrTab[v.type] = (attrTab[v.type] or 0) + v.value
			end
		end

		-- 饰阶套装
		local stageTmp = getEquipStage(actor,roleId,slot)
		if(stageTmp < minStage) then
			minStage = stageTmp -- 找出套装中最低的一个饰品阶数
		end
	end

	if(ZhuZaiEquipSuit[minStage]) then -- 饰品套装强化饰品以外的装备(憨批设定)
		local attrRate = ZhuZaiEquipSuit[minStage].promote/10000 -- 属性提升比率
		for type,value in pairs(equipTab) do
			attrTab[v.type] = (attrTab[v.type] or 0) + value*attrRate
		end
	end

end

--[[
    @desc: 获取单一角色主宰装备评分
    author:{author}
    time:2020-05-11 13:59:29
    --@actor:
	--@roleId: 
    @return:
]]
local function getRoleDominateScore(actor,roleId)
	local roleScore = 0 -- 角色装备评分
	for _,slot in pairs(Slot_Equip) do -- 计算装备
		local equipId = getEquipId(actor,roleId,slot)
		if(0 ~= equipId) then
			local conf = ZhuZaiEquipConfig[equipId]
			roleScore = roleScore + (conf.zhuzaimark or 0)
		end
	end
	for _,slot in pairs(Slot_Decorations) do -- 计算饰品
		local lv = getEquipLv(actor,roleId,slot)
		local conf = ZhuZaiOrnamentConfig[slot][lv]
		if(conf) then
			roleScore = roleScore + (conf.zhuzaimark or 0)
		end
	end
	return roleScore
end

--[[
    @desc: 套装技能属性
    author:{author}
    time:2020-05-11 13:53:37
    --@actor:
	--@roleId:
	--@dominateEquipTab: 
    @return:
]]
local function dominateSuitSkillAttr(actor,roleId,dominateEquipTab) -- 套装技能属性

	dominateEquipTab.suitSkillAttr = dominateEquipTab.suitSkillAttr or {}
	dominateEquipTab.suitSkillAttr.attrTab = dominateEquipTab.suitSkillAttr.attrTab or {}
	dominateEquipTab.suitSkillAttr.exAttrTab = dominateEquipTab.suitSkillAttr.exAttrTab or {}

	local attrTab = dominateEquipTab.suitSkillAttr.attrTab
	local exAttrTab = dominateEquipTab.suitSkillAttr.exAttrTab
	local dominateScore = getRoleDominateScore(actor,roleId) -- 角色主宰装备评分
	for id,conf in ipairs(ZhuZaiSkillConfig) do
		if(conf.zhuzaimark>dominateScore) then
			return
		end
		DEBUG(actor,"dominateSuitSkillAttr 角色编号:" .. roleId .. " 开启技能:" .. id)
		for _,attr in pairs(conf.attrs or {}) do
			attrTab[attr.type] = (attrTab[attr.type] or 0) + attr.value
		end
		for _,exattr in pairs(conf.exattrs or {}) do
			exAttrTab[exattr.type] = (attrTab[exattr.type] or 0) + exattr.value
		end
		dominateEquipTab.extraPower = (dominateEquipTab.extraPower or 0) + (conf.extraPower or 0)
	end
end

function updateAttr(actor,roleId)
	local extraPower = 0 -- 额外战力,用于无法计算战力的属性
	local actorId = LActor.getActorId(actor)
	local role = LActor.getRole(actor, roleId)
	if not role then 
		DEBUG(actor,"updateAttr 没有角色,roleId:" .. roleId)
		return 
	end
	local attr = LActor.getZhuZaiAttr(actor, roleId)
	if not attr then 
		DEBUG(actor,"updateAttr 没有属性")
		return 
	end
	attr:Reset()
	
	local exAttr = LActor.getZhuZaiExAttr(actor, roleId)
	if not exAttr then
		DEBUG(actor,"updateAttr 没有额外属性") 
		return 
	end
	exAttr:Reset()

	local dominateEquipTab = { -- 全属性表
--[[
		extraPower, -- 额外属性
		equipAttr = { -- 装备属性
			attrTab = {},
			exAttrTab = {},
		},
		equipRandomAttr = { -- 随机属性
			attrTab = {},
			exAttrTab = {},
		},
		equipPromoteAttr = { -- 武器和衣服对某些属性的万分比提升
			attrTab = {},
			exAttrTab = {},
		},
		decorationsAttr = { -- 饰品属性
			attrTab = {},
			exAttrTab = {},
		},
		suitSkillAttr = { -- 套装技能属性
			attrTab = {},
			exAttrTab = {},
		},	
]]
	}

	dominateEquipAttr(actor,roleId,dominateEquipTab) -- 主宰装备属性表,包含基础属性和随机属性
	dominateDecorationsAttr(actor,roleId,dominateEquipTab) -- 主宰饰品属性表,包含饰品基础属性和套装对装备的提升
	dominateSuitSkillAttr(actor,roleId,dominateEquipTab) -- 套装技能属性

	local extraPower = (dominateEquipTab.extraPower or 0)
	dominateEquipTab.extraPower = nil -- 方便下面遍历
	for _,v in pairs(dominateEquipTab) do
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

--[[
    @desc: 玩家所有角色主宰装备信息 上线推送 80-5
    author:{author}
    time:2020-04-22 10:03:25
    --@actor:
	--@roleId: 
    @return:
]]
local function sendDominateInfo(actor)
	local roleCount = LActor.getRoleCount(actor)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DominateEquip, Protocol.sDominateEquipCmd_EquipInfo) -- 80-5
	LDataPack.writeShort(npack, roleCount) -- 角色数量
	for roleId = 0,roleCount-1 do

		LDataPack.writeShort(npack, roleId) -- 角色编号
		LDataPack.writeShort(npack, #Slot_Equip) -- 装备数量
		for _,slot in pairs(Slot_Equip) do
			local randomAttrCount = getRandomAttrCount(actor,roleId,slot)
			local randomAttr = getRandomAttr(actor,roleId,slot)

			LDataPack.writeShort(npack, slot) -- 装备部位
			LDataPack.writeInt(npack, getEquipId(actor,roleId,slot)) -- 装备id
			LDataPack.writeShort(npack, randomAttrCount) -- 随机属性数量
			for index=1,randomAttrCount do
				LDataPack.writeInt(npack,randomAttr[index].type) -- 类型
				LDataPack.writeInt(npack,randomAttr[index].value) -- 值
			end
		end

		LDataPack.writeShort(npack, #Slot_Decorations) -- 饰品数量
		for _,slot in pairs(Slot_Decorations) do
			LDataPack.writeShort(npack, slot) -- 饰品部位
			LDataPack.writeShort(npack, getEquipLv(actor,roleId,slot)) -- 饰品等级
		end
	end
	LDataPack.flush(npack)
end

local function onLogin(actor)
	sendDominateInfo(actor)
end

local function onInit(actor)
	local roleCount = LActor.getRoleCount(actor)
	for roleId=0,roleCount-1 do
		updateAttr(actor, roleId) -- 属性更新
	end
end

local function initGlobalData()
	actorevent.reg(aeInit, onInit) -- 初始化主宰属性
	actorevent.reg(aeUserLogin, onLogin) -- 发送主宰等级信息
	netmsgdispatcher.reg(Protocol.CMD_DominateEquip, Protocol.cDominateEquipCmd_EquipChange, changeEquip) -- 更换装备 80-1
	netmsgdispatcher.reg(Protocol.CMD_DominateEquip, Protocol.cDominateEquipCmd_EquipCompound, compoundEquip) -- 合成装备 80-2
	netmsgdispatcher.reg(Protocol.CMD_DominateEquip, Protocol.cDominateEquipCmd_EquipLvUp, equipLvUp) -- 饰品升级 80-3
	netmsgdispatcher.reg(Protocol.CMD_DominateEquip, Protocol.cDominateEquipCmd_EquipPextraction, equipPextraction) -- 装备萃取 80-4
	netmsgdispatcher.reg(Protocol.CMD_DominateEquip, Protocol.cDominateEquipCmd_LingStoneCompound, compoundLingStone) -- 灵坯合成 80-6
end

table.insert(InitFnTable, initGlobalData)

--[[
    @desc: 获取主宰总评分
    author:{author}
    time:2020-04-28 15:14:55
    --@actor: 
    @return:
]]
function getEquipTotalScore(actor)
	local totalScore = 0
	local roleCount = LActor.getRoleCount(actor)
	for roleId=0,roleCount-1 do
		for _,slot in pairs(Slot_Equip) do -- 计算装备
			local equipId = getEquipId(actor,roleId,slot)
			if(0 ~= equipId) then
				local conf = ZhuZaiEquipConfig[equipId]
				totalScore = totalScore + (conf.zhuzaimark or 0)
			end
		end
		for _,slot in pairs(Slot_Decorations) do -- 计算饰品
			local lv = getEquipLv(actor,roleId,slot)
			local conf = ZhuZaiOrnamentConfig[slot][lv]
			if(conf) then
				totalScore = totalScore + (conf.zhuzaimark or 0)
			end
		end
	end
	return totalScore
end


--dominateRandomAttr 函数专用 
--tab: ZhuZaiEquipConfig[itemId].randomattrs[attrType] -- 表中表太多 不命名了
local function getValueByRateNum(tab,rateNum)
	local value = 1 -- 防止策划配错表,权重达不到100% 写个1 以便及时发现问题
	for _,v in pairs(tab) do
		if(rateNum<=v.rate) then
			value = math.random(v.value[1],v.value[2])
			break
		end
		--DEBUG(actor,"getValueByRateNum  ")
		rateNum = rateNum - v.rate
	end
	return value
end

--[[
    @desc: 为装备添加随机属性
    author:{author}
    time:2020-04-16 15:38:09
    --@itemDataPtr: 
    @return:
]]
function dominateRandomAttr(itemDataPtr)
	DEBUG(actor,"dominateRandomAttr 随机属性开始-----------------")
	local itemData = LActor.getItemData(itemDataPtr)
	local itemId = itemData:getItemId()
	local randomAttrCount = math.random(1,ZhuZaiEquipBaseConfig.attrmaxrcount) -- 随机次数
	if(randomAttrCount>4) then -- 不可能超过4 超过了找策划确认原因
		LOG(actor,"dominateRandomAttr randomAttrCount greater than 4")
		return
	end
	DEBUG(actor,"dominateRandomAttr 随机属性条数:" .. randomAttrCount)
	-- 获取属性类型
	local attrType = {}
	for i=1,randomAttrCount do -- 随机n次
		local randomNum = math.random(1,100)
		for _,v in pairs(ZhuZaiEquipBaseConfig.attrtyperate) do -- 权重
			if(randomNum <= v.rate) then
				attrType[v.attrtype] = 1
				DEBUG(actor,"dominateRandomAttr 随机到类型:" .. v.attrtype)
				break
			end
			randomNum = randomNum - v.rate
		end
	end
	if(not ZhuZaiEquipConfig[itemId]) then 
		LOG(actor,"dominateRandomAttr config not exist ZhuZaiEquipConfig[itemId],itemId:" .. itemId)
		return
	end
	local equipAttrConf = ZhuZaiEquipConfig[itemId].randomattrs or {}
	local rateNum = math.random(1,100) -- 取对应属性中的具体数值用
	DEBUG(actor,"dominateRandomAttr 概率值:" .. rateNum)
	for type,_ in pairs(attrType) do
		if(equipAttrConf[type]) then -- 配置里得有这个类型才能随机
			DEBUG(actor,"dominateRandomAttr 开始查找属性随机值type:" .. type)
			local value = getValueByRateNum((equipAttrConf[type] or {}), rateNum)
			itemData:addOneLineAttr(type, value) -- 添加属性
			DEBUG(actor,"dominateRandomAttr 添加属性 type:" .. type .. " value:" .. value)
		end
	end
	DEBUG(actor,"dominateRandomAttr 随机属性结束-----------------")
end
_G.dominateRandomFun = dominateRandomAttr

--[[
local gmsystem      = require("systems.gm.gmsystem")
local gmCmdHandlers = gmsystem.gmCmdHandlers


gmCmdHandlers.send80_1 = function (actor, args) -- 发送80-1 协议,伪数据
	local roleId = 0
	local slot = 1 -- 头盔
	local equipId = 620101
	local randomNum = 1
	local type = 4
	local value = 1000
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DominateEquip, Protocol.sDominateEquipCmd_EquipSlotInfo) -- 80-1
	LDataPack.writeShort(npack, roleId) -- 角色id
	DEBUG(actor,"gmCmdHandlers.send80_1 short roleId:" .. roleId)
	LDataPack.writeShort(npack, slot) -- 部位
	DEBUG(actor,"gmCmdHandlers.send80_1 short slot:" .. slot)
	LDataPack.writeInt(npack, equipId) -- 装备id
	DEBUG(actor,"gmCmdHandlers.send80_1 int equipId:" .. equipId)
	LDataPack.writeShort(npack, randomNum) -- 随机属性数量
	DEBUG(actor,"gmCmdHandlers.send80_1 short randomNum:" .. randomNum)
	LDataPack.writeInt(npack, type) -- 随机属性类型
	DEBUG(actor,"gmCmdHandlers.send80_1 int type:" .. type)
	LDataPack.writeInt(npack, value) -- 随机属性的值
	DEBUG(actor,"gmCmdHandlers.send80_1 int value:" .. value)
	LDataPack.flush(npack)
	return true
end
]]
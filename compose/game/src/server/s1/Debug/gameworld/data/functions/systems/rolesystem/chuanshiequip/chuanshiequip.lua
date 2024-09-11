module("chuanshiequip", package.seeall)

-- local systemId = Protocol.CMD_ChuanShi

local function DEBUG(actor,log)
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:chuanshiequip." .. log .. " actorid:" .. actorid)
end

--[[
    chuanshiequipdata = {
            -- [神器编号] = {神器数据}
            [slot] = {
                chuanshilv, -- 神器等级
				chuanshistar, -- 升星等级
				state, -- 神器是否激活		
				chuanshitype, -- 神器类型
            }
            [2] = {
                ...
                ...
            }
            [3] = {
                ...
                ...
            }
    }
]]

local chuanShiEquipIndex = {
	--ChuanshiType_Begin = 0,
	--先天神器
	ChuanshiType_fulongzhu = 1,--缚龙柱
	ChuanshiType_lianhunding = 2,--炼魂鼎
	ChuanshiType_yitianjian = 3,--倚天剑
	ChuanshiType_shenghuoling = 4,--圣火令

	--鸿蒙神器
	ChuanshiType_changshengu = 5,--长生骨玉杖
	ChuanshiType_binghuoshan = 6,--冰火逍遥扇
	ChuanshiType_duopojian = 7,--夺魄金蛇剑
	ChuanshiType_lieyandao = 8,--烈焰屠龙刀

	--混沌神器
	ChuanshiType_zhexiansan = 9,--弑神谪仙伞
	ChuanshiType_haotianjing = 10,--寰宇昊天镜
	ChuanshiType_wuxinglun = 11,--天地五行轮
	ChuanshiType_shenlongling = 12,--九霄神龙令
}

local xianTianEquipIndex = {
	--ChuanshiType_Begin = 0,
	--先天神器
	ChuanshiType_fulongzhu = 1,--缚龙柱
	ChuanshiType_lianhunding = 2,--炼魂鼎
	ChuanshiType_yitianjian = 3,--倚天剑
	ChuanshiType_shenghuoling = 4,--圣火令
}

local hongMengEquipIndex = {
	--鸿蒙神器
	ChuanshiType_changshengu = 5,--长生骨玉杖
	ChuanshiType_binghuoshan = 6,--冰火逍遥扇
	ChuanshiType_duopojian = 7,--夺魄金蛇剑
	ChuanshiType_lieyandao = 8,--烈焰屠龙刀
}

local hunDunEquipIndex = {
	--混沌神器
	ChuanshiType_zhexiansan = 9,--弑神谪仙伞
	ChuanshiType_haotianjing = 10,--寰宇昊天镜
	ChuanshiType_wuxinglun = 11,--天地五行轮
	ChuanshiType_shenlongling = 12,--九霄神龙令
}

--[[
local shenqiType = {
	xiantianType = 1,
	hongmengType = 2,
	hunduntType = 3,
}
]]

-- 获取玩家数据
local function getActorData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.chuanshiequipdata == nil then
		var.chuanshiequipdata = {}
	end
	return var.chuanshiequipdata
end

-- 获取神器数据
local function getShenQiData(actor, itemId)
	local actorData = getActorData(actor)
	if not actorData then
		DEBUG(actor, "getShenQiData is nil")
		return
	end
	if (not actorData[itemId]) then actorData[itemId] = {} end
	return actorData[itemId]
end

-- 获取神器状态
local function getChuanShiState(actor, itemId)
	local chuanshidata = getShenQiData(actor ,itemId)
	return chuanshidata.state or 0
end

--[[
    @desc: 获取神器强化等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@itemId: 部位 EquipIndex
    @return:
]]
local function getChuanShiLv(actor, itemId)
	local chuanshidata = getShenQiData(actor ,itemId)
	return chuanshidata.chuanshilv or 0
end

--[[
    @desc: 设置神器强化等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@itemId: 部位 EquipIndex
    @return:
]]
local function setChuanShiLv(actor, itemId, lv)
	local chuanshidata = getShenQiData(actor ,itemId)
	chuanshidata.chuanshilv = lv + 1
end

--[[
    @desc: 获取神器升星等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@itemId: 部位 EquipIndex
    @return:
]]
local function getChuanShiStarLv(actor, itemId)
	local chuanshidata = getShenQiData(actor ,itemId)
	return chuanshidata.chuanshistar or 0
end

--[[
    @desc: 设置神器升星等级
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@itemId: 部位 EquipIndex
    @return:
]]
local function setChuanShiStarLv(actor, itemId, lv, state)
	local chuanshidata = getShenQiData(actor ,itemId)
	if state == 1 then
		 chuanshidata.chuanshistar = lv + 1
	end
end

--[[
    @desc: 获取神器类型
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@itemId: 部位 EquipIndex
    @return:
]]
local function getChuanShiType(actor, itemId)
	local chuanshidata = getShenQiData(actor ,itemId)
	return chuanshidata.type or 0
end

-- 设置神器为激活状态 
local function setChuanShiState(actor, itemId, state)
	local chuanshidata = getShenQiData(actor ,itemId)
	chuanshidata.state = state
end

--[[
    @desc: 发送神器强化等级 81-2
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function sendChuanShiLv(actor, itemId)
	local chuanShiLv = getChuanShiLv(actor, itemId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_ChuanShi, Protocol.sChuanShiCmd_SendChuanShiLvInfo) -- 81-2
	LDataPack.writeShort(npack,itemId) -- 神器ID
	LDataPack.writeShort(npack,chuanShiLv) -- 强化等级
	LDataPack.flush(npack)	
end

--[[
    @desc: 发送神器星级等级 81-3
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function sendChuanShiStarLv(actor, itemId)
	local chuanShiStarLv = getChuanShiStarLv(actor, itemId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_ChuanShi, Protocol.sChuanShiCmd_SendChuanShiStarLvInfo) -- 81-3
	LDataPack.writeShort(npack,itemId) -- 神器ID
	LDataPack.writeShort(npack,chuanShiStarLv) -- 升星等级
	LDataPack.flush(npack)	
end

--[[
    @desc: 获取传世装备的itemid
    author:{author}
    time:2020-04-01 20:00:25
    --@actor:
	--@roleId:
	--@slot: 部位 EquipIndex
    @return:
]]
--[[ 获取神器天赋
local function getEquipTalent(actor, slot)
	local equipIv = getChuanShiLv(actor, slot)
	if not equipIv and equipIv == 0 then
		DEBUG(actor, "not activation Talent")
		return
	end
	local talentID = 0
	local equipConf = ChuanShiShenQiBaseConfig[slot].talent
	for i,v in pairs(equipConf or {}) do
		if equipIv >= v.open then
			 talentID = v.id
		end
	end
	return talentID
end]]

-- 获取技能ID
local function getSkillId(actor, slot)
	local starLv = getChuanShiStarLv(actor, slot)
	local sKillId = ChuanShiShenQiStarConfig[slot][starLv].skill
	return tonumber(sKillId or 0)
end

--[[
    @desc: 传世装备属性计算
    author:{author}
    time:2020-04-14 11:16:59
    --@actor:
	--@itemId [in]:神器编号
	--@starAttr [in]:升星属性
	--@stengAttr [in]:强化属性
    @return:
]]
-- 用于计算天赋属性
local function chuanShiBasicsAttr(actor, shenQiAttrTap)
	-- 先天神器基础属性
	shenQiAttrTap.xiantianAttr = shenQiAttrTap.xiantianAttr or {}
	shenQiAttrTap.xiantianAttr.attrTab = shenQiAttrTap.xiantianAttr.attrTab or {}
	local xiantianEquipTap = shenQiAttrTap.xiantianAttr.attrTab

	for _,slot in pairs(xianTianEquipIndex) do
		local equipStarIv = getChuanShiStarLv(actor, slot)	
		local state = getChuanShiState(actor, slot)
		-- 升星属性
		local equipStarConf = ChuanShiShenQiStarConfig[slot]
		if equipStarConf and state == 1 then			
			local equipAttrsConf = equipStarConf[equipStarIv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				xiantianEquipTap[v.type] = (xiantianEquipTap[v.type] or 0) + v.value	
			end
		end
		-- 等级属性
		local equipLv = getChuanShiLv(actor, slot)
		local equipIvConf = ChuanShiShenQiLevelConfig[slot]
		if equipIvConf and state == 1 then			
			local equipAttrsConf = equipIvConf[equipLv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				xiantianEquipTap[v.type] = (xiantianEquipTap[v.type] or 0) + v.value
			end
		end
		shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (equipIvConf.expower or 0) + (equipStarIvConf or 0) 
	end

	-- 鸿蒙神器基础属性
	shenQiAttrTap.hongmengAttr = shenQiAttrTap.hongmengAttr or {}
	shenQiAttrTap.hongmengAttr.attrTab = shenQiAttrTap.hongmengAttr.attrTab or {}
	local hongmengEquipTap = shenQiAttrTap.hongmengAttr.attrTab

	for _,slot in pairs(hongMengEquipIndex) do
		local equipStarIv = getChuanShiStarLv(actor, slot)	
		local state = getChuanShiState(actor, slot)
		-- 升星属性
		local equipStarConf = ChuanShiShenQiStarConfig[slot]
		if equipStarConf and state == 1 then			
			local equipAttrsConf = equipStarConf[equipStarIv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				hongmengEquipTap[v.type] = (hongmengEquipTap[v.type] or 0) + v.value	
			end
		end
		-- 等级属性
		local equipLv = getChuanShiLv(actor, slot)
		local equipIvConf = ChuanShiShenQiLevelConfig[slot]
		if equipIvConf and state == 1 then			
			local equipAttrsConf = equipIvConf[equipLv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				hongmengEquipTap[v.type] = (hongmengEquipTap[v.type] or 0) + v.value
			end
		end
		shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (equipIvConf.expower or 0) + (equipStarIvConf or 0) 
	end

	-- 混沌神器基础属性
	shenQiAttrTap.hundunAttr = shenQiAttrTap.hundunAttr or {}
	shenQiAttrTap.hundunAttr.attrTab = shenQiAttrTap.hundunAttr.attrTab or {}
	local hundunEquipTap = shenQiAttrTap.hundunAttr.attrTab

	for _,slot in pairs(hunDunEquipIndex) do
		local equipStarIv = getChuanShiStarLv(actor, slot)	
		local state = getChuanShiState(actor, slot)
		-- 升星属性
		local equipStarConf = ChuanShiShenQiStarConfig[slot]
		if equipStarConf and state == 1 then			
			local equipAttrsConf = equipStarConf[equipStarIv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				hundunEquipTap[v.type] = (hundunEquipTap[v.type] or 0) + v.value	
			end
		end
		-- 等级属性
		local equipLv = getChuanShiLv(actor, slot)
		local equipIvConf = ChuanShiShenQiLevelConfig[slot]
		if equipIvConf and state == 1 then			
			local equipAttrsConf = equipIvConf[equipLv]
			for i,v in pairs(equipAttrsConf.attrs or {}) do
				hundunEquipTap[v.type] = (hundunEquipTap[v.type] or 0) + v.value
			end
		end
		shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (equipIvConf.expower or 0) + (equipStarIvConf or 0) 
	end
end

--[[ -- 和上面的属性重复，先注掉，后期可能会用到
-- 神器基础属性
local function shenQiBasicsAttr(actor , shenQiAttrTap)
	shenQiAttrTap.basicsAttr = shenQiAttrTap.basicsAttr or {}
	shenQiAttrTap.basicsAttr.attrTab = shenQiAttrTap.basicsAttr.attrTab or {}

	local chuanShiAttrTab = shenQiAttrTap.basicsAttr.attrTab

	for _,slot in pairs(chuanShiEquipIndex) do
		local equipId = slot
		local equipIv = getChuanShiLv(actor, equipId)
		local equipStarIv = getChuanShiStarLv(actor, equipId)
		local equipIvConf = ChuanShiShenQiLevelConfig[equipId][equipIv]
		local equipStarIvConf = ChuanShiShenQiStarConfig[equipId][equipStarIv]

		if equipIvConf and equipStarIvConf then
			for i,v in pairs(equipIvConf.attrs or {}) do
				chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + v.value			
			end
			for i,v in pairs(equipStarIvConf.attrs or {}) do
				chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + v.value	
			end
			shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (equipIvConf.expower or 0) + (equipStarIvConf or 0) 
		end
	end
end
]]
-- 神器技能属性
local function shenQiShillAttr(actor, shenQiAttrTap)
	shenQiAttrTap.skillAttr = shenQiAttrTap.skillAttr or {}
	shenQiAttrTap.skillAttr.attrTab = shenQiAttrTap.skillAttr.attrTab or {}

	local chuanShiAttrTab = shenQiAttrTap.skillAttr.attrTab

	-- 技能属性
	for _,slot in pairs(chuanShiEquipIndex) do
		local state = getChuanShiState(actor, slot)
		local sKillId = tonumber(getSkillId(actor, slot))
		local equipSkillConf = ChuanShiShenQiSkillConfig[sKillId]
		if equipSkillConf and state == 1 then			
			for i,v in pairs(equipSkillConf.attrs or {}) do
				chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + v.value
				print("skill1: type: "..v.type.."value: "..v.value)
			end
			shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (equipSkillConf.expower or 0)
		end	
	end
end

-- 神器天赋属性
local function shenQiTalentAttr(actor, shenQiAttrTap)
	shenQiAttrTap.talentAttr = shenQiAttrTap.talentAttr or {}
	shenQiAttrTap.talentAttr.attrTab = shenQiAttrTap.talentAttr.attrTab or {}

	local chuanShiAttrTab = shenQiAttrTap.talentAttr.attrTab
	local basicsAttrTab = {}

	for _,slot in pairs(chuanShiEquipIndex) do
		local equipIv = getChuanShiLv(actor, slot)
		local equipStarIv = getChuanShiStarLv(actor, slot)
		local equipIvConf = ChuanShiShenQiLevelConfig[slot][equipIv]
		local equipStarIvConf = ChuanShiShenQiStarConfig[slot][equipStarIv]
		local equipConf = ChuanShiShenQiBaseConfig[slot].talent
		basicsAttrTab[slot] = basicsAttrTab[slot] or{}

		if equipIvConf and equipStarIvConf then
			for i,v in pairs(equipIvConf.attrs or {}) do
				basicsAttrTab[slot][v.type] = (basicsAttrTab[slot][v.type] or 0) + v.value			
			end
			for i,v in pairs(equipStarIvConf.attrs or {}) do
				basicsAttrTab[slot][v.type] = (basicsAttrTab[slot][v.type] or 0) + v.value
			end
		end

		for i,v in pairs(equipConf or {}) do
			if equipIv >= v.open then
				local talentID = v.id
				local talentConf = ChuanShiShenQiTalentConfig[talentID]
				if talentConf then
					if talentConf.type == 0 then
						for i,v in pairs(talentConf.attrPer or {}) do
							chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + ((v.rate or 0) / 10000) * (basicsAttrTab[slot][v.type] or 0)
							print("天赋类型为0： type:"..(v.type or 0).."value: "..((v.rate or 0)/ 10000) * (basicsAttrTab[slot][v.type] or 0))
						end
					end
					if talentConf.type == 1 then
						for i,v in pairs(talentConf.attrPer or {}) do
							chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + ((v.rate or 0) / 10000) * (shenQiAttrTap.xiantianAttr.attrTab[v.type] or 0)
							print("天赋类型为1： type:"..(v.type or 0).."value: "..((v.rate or 0) / 10000) * (shenQiAttrTap.xiantianAttr.attrTab[v.type] or 0))
						end
					end
					if talentConf.type == 2 then
						for i,v in pairs(talentConf.attrPer or {}) do
							chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + ((v.rate or 0) / 10000) * (shenQiAttrTap.hongmengAttr.attrTab[v.type] or 0)
							print("天赋类型为2： type:"..(v.type or 0).."value: "..((v.rate or 0) / 10000) * (shenQiAttrTap.hongmengAttr.attrTab[v.type] or 0))
						end
					end
					if talentConf.type == 3 then
						for i,v in pairs(talentConf.attrPer or {}) do
							chuanShiAttrTab[v.type] = (chuanShiAttrTab[v.type] or 0) + ((v.rate or 0) / 10000) * (shenQiAttrTap.hundunAttr.attrTab[v.type] or 0)
							print("天赋类型为3： type:"..(v.type or 0).."value: "..((v.rate or 0) / 10000) * (shenQiAttrTap.hundunAttr.attrTab[v.type] or 0))
						end
					end
					shenQiAttrTap.expower = (shenQiAttrTap.expower or 0) + (talentConf.expower or 0)
				end
			end
		end
	end
end

-- 更新属性
local function updateAttr(actor)
	local attr = LActor.getActorsystemAttr(actor, attrChuanShi)
	if attr == nil then
		DEBUG(actor, "updateAttr attr is nil")
		return
	end
	attr:Reset()

	
	local shenQiAttr = {
		--[[
				basicsAttr = { -- 基础属性表
					attrTab = {}
				},

				skillAttr = { -- 技能属性表
					attrTab = {}
				},

				talentAttr = { -- 天赋属性表
					attrTab = {}
				},

				xiantianAttr = { -- 先天属性表
					attrTab = {}
				},
				hongmengAttr = { -- 鸿蒙属性表
					attrTab = {}
				},
				hundunAttr = { --混沌属性表
					attrTab = {}
				},
				expower, --额外战力
		]]
	}

	chuanShiBasicsAttr(actor, shenQiAttr)
	-- shenQiBasicsAttr(actor, shenQiAttr)
	shenQiShillAttr(actor, shenQiAttr)
	shenQiTalentAttr(actor, shenQiAttr)
	
	local extraPower = (shenQiAttr.expower or 0)
	shenQiAttr.expower = nil
	for _,v in pairs(shenQiAttr) do
		for type,value in pairs (v.attrTab or {}) do
			print("天赋属性: type: "..type.."value: "..value)
			attr:Add(tonumber(type), tonumber(value))
		end
	end
	attr:SetExtraPower(extraPower)
	LActor.reCalcAttr(actor)
end

--[[
    @desc: 请求激活神器/神器升星 81-3
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function chuanShiLevelUpStar(actor, packet)
	local Id = LDataPack.readChar(packet)
	local state = getChuanShiState(actor, Id) 
	local chuanShiStarLv = getChuanShiStarLv(actor, Id)
	local itemCount = (LActor.getItemCount(actor, ChuanShiShenQiStarConfig[Id][chuanShiStarLv].itemid) or 0)
	local costCount = ChuanShiShenQiStarConfig[Id][chuanShiStarLv].costcount

	if Id <= 0 or Id > #ChuanShiShenQiBaseConfig then
        DEBUG(actor, "onReqLevelUpStar id error, id:"..tostring(Id))
		return
	end
	if costCount == 0 then
		DEBUG(actor, "等级达到上限"..tostring(Id))
		return
	end	

    -- 是否有此物品
	if itemCount < costCount then
		DEBUG(actor, "chuanShiLevelUpStar item not enough, id:"..tostring(Id))
		return
	end
	-- 扣除材料
	LActor.costItem(actor, ChuanShiShenQiStarConfig[Id][chuanShiStarLv].itemid, costCount, "chuanShiLevelUpStar")

	setChuanShiStarLv(actor, Id, chuanShiStarLv, state)
    sendChuanShiStarLv(actor, Id)
	if state ~= 1 then
		setChuanShiState(actor, Id, 1)
	end

	updateAttr(actor)
end

--[[
    @desc: 请求强化神器 81-2
    author:{author}
    time:2020-04-08 16:21:37
    --@actor: 
    @return:
]]
local function chuanShiStrengLv(actor, packet)
	local Id = LDataPack.readChar(packet)
	local state = getChuanShiState(actor, Id) 
	local chuanShiStrengLv = getChuanShiLv(actor, Id)
	local itemCount = (LActor.getItemCount(actor, ChuanShiShenQiLevelConfig[Id][chuanShiStrengLv].itemid) or 0)
	local costCount = ChuanShiShenQiLevelConfig[Id][chuanShiStrengLv].count

	if Id <= 0 or Id > #ChuanShiShenQiBaseConfig then
        DEBUG(actor, "chuanShiStrengLv id error, id:"..tostring(Id))
		return
	end
	if costCount == 0 then
		DEBUG(actor, "等级达到上限"..tostring(Id))
		return
	end	
	if state ~= 1 then
		DEBUG(actor, "神器未激活")
		return
	end
	
	--getChuanShiType(actor, Id) -- 获取传世装备类型，便于天赋计算
    --是否有此物品
	if itemCount < costCount then
		DEBUG(actor, "chuanShiStrengLv item not enough, id:"..tostring(Id))
		return
	end
	--扣除材料
	LActor.costItem(actor, ChuanShiShenQiLevelConfig[Id][chuanShiStrengLv].itemid, costCount, "chuanShiStrengLv")

	setChuanShiLv(actor, Id, chuanShiStrengLv)
	sendChuanShiLv(actor, Id)
	
	updateAttr(actor)
end

--检查系统/神器是否开启
function checkOpen(actor, noLog, id)
	if System.getOpenServerDay() + 1 < ChuanShiShenQiConfig.openserverday
		or LActor.getZhuanShengLevel(actor) < ChuanShiShenQiConfig.openzhuanshenglv then
		if not noLog then actor_log(actor, "checkOpen false") end
		return false
	end

	if (id or 0) ~= 0 then
		--神器是否开放
		local state = getChuanShiState(actor, id)
		if state == 0 and state then
			return false
		end
	end	
	return true
end

--玩家登陆推送
local function sendInfo(actor)
	local count = 0
	for itemId in pairs(ChuanShiShenQiBaseConfig) do
		count = count + 1
	end
	local chuanShiData = getActorData(actor)
	if not chuanShiData then
		DEBUG(actor, "chuanShiData is nill")
		return
	end
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_ChuanShi, Protocol.sChuanShiCmd_SendInfo) -- 81-1
	LDataPack.writeShort(pack,count) -- 神器数量
	for i=1, count do	
		local equipData = chuanShiData[i]
		if equipData ~= nil then
			LDataPack.writeShort(pack, i)
			LDataPack.writeShort(pack, equipData.state or 0)
			LDataPack.writeShort(pack, equipData.chuanshilv or 0)
			LDataPack.writeShort(pack, equipData.chuanshistar or 0)
		end
	end
	LDataPack.flush(pack)
end

-- 初始化 
local function onInit(actor)
	if not checkOpen(actor, true) then return end
	updateAttr(actor) 
end

--玩家登录
local function onLogin(actor)
	if not checkOpen(actor, true) then return end
	sendInfo(actor)
end

local function initGlobalData()
	actorevent.reg(aeInit, onInit)
	actorevent.reg(aeUserLogin, onLogin)
	netmsgdispatcher.reg(Protocol.CMD_ChuanShi, Protocol.cChuanShiCmd_ReqChuanShiStarLvInfo, chuanShiLevelUpStar) -- 81-3
	netmsgdispatcher.reg(Protocol.CMD_ChuanShi, Protocol.cChuanShiCmd_ReqChuanShiLvInfo, chuanShiStrengLv) -- 81-2	
end

table.insert(InitFnTable, initGlobalData)
--[[
	shenQiAttr = {
		basicsAttr = {
			[equipId] = { attrtab = {} }
	}
]]

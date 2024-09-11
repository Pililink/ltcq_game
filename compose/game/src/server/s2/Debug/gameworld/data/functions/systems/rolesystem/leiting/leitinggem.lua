module("leitinggem", package.seeall)

--[[
	--雷霆装备淬炼(强化)
    leitinggem={
		roleId={ -- 角色编号
			[posIndex]={ -- 身体装备部位索引
				[gemIndex]={ -- 装备宝石索引
				    level, -- 当前宝石等级
				}
				... 5个
			}
			... 8个
		}
		... 当前3个
	}
]]--
local gemconf = LeiTingEquipLevel
--获取玩家静态变量数据
local function getVarData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.leitinggem == nil then
		var.leitinggem = {}
	end
	return var.leitinggem
end

local function getRoleData(actor, roleId)
	local actordata = getVarData(actor)
	if(not actordata[roleId]) then
        actordata[roleId] = {}
	end
    return actordata[roleId]
end



local function getPosGemLevel(actor,roleIndex,posIndex,gemIndex)
	local roledata = getRoleData(actor, roleIndex)
	if(not roledata[posIndex] or not roledata[posIndex][gemIndex] or not roledata[posIndex][gemIndex].level) then
        return 0
	end
	return roledata[posIndex][gemIndex].level
end

local function setPosGemLevel(actor,roleIndex,posIndex,gemIndex,level)
	if(not roleIndex or not posIndex or not gemIndex or not level) then
		print("flag1 异常错误")
		return
	end
	local roledata = getRoleData(actor, roleIndex)
	if not roledata then
		print("roledata 为空")
		return
	end
	if not roledata[posIndex] then
		roledata[posIndex] = {}
	end
	if not roledata[posIndex][gemIndex] then
        roledata[posIndex][gemIndex]={}
	end
	roledata[posIndex][gemIndex].level = level
	print("宝石升级 pos:" .. posIndex .. " gemIndex:" .. gemIndex .. "更新后等级:" .. roledata[posIndex][gemIndex].level)
end
-- 发送升级结果
function sendInfo(actor, roleIndex, posIndex, gemIndex, level)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_ReqLeiTingLevelUpRep)
	LDataPack.writeShort(npack, roleIndex) -- 角色index
	LDataPack.writeShort(npack, posIndex) -- 部位index
	LDataPack.writeShort(npack, gemIndex) -- 宝石index
	LDataPack.writeShort(npack, level) -- 宝石当前等级
	LDataPack.flush(npack)
end

--检测是否已开启 actor,角色index,部位index，宝石索引
local function checkOpenCondition(actor, roleIndex, posIndex, gemIndex)
	--配置条件检查
	local curlevel = getPosGemLevel(actor,roleIndex,posIndex,gemIndex)
	local conf = gemconf[posIndex][gemIndex] -- 当前宝石配置信息
	if(curlevel >= #conf) then -- 等级超过配置
		print("level is already full")
        	return false
	end
	-- 等级限制
	for i,vconf in pairs(conf[1].open or {}) do
		local gemIndex = vconf.type
		local condlevel = vconf.level
		local curlv = getPosGemLevel(actor,roleIndex,posIndex,gemIndex) -- 当前部位等级
		if(curlv < condlevel) then
			--print("升级部位:" .. posIndex .. " 宝石:" .. gemIndex)
			--print("level not enough 条件宝石索引:" ..  gemIndex .. "需求等级:" .. condlevel ..  " 实际等级:"  .. curlv)
			return false
		end
	end

    --道具数量检测
	local itemCount = LActor.getItemCount(actor, conf[curlevel+1].costItem)
	if(itemCount< conf[curlevel+1].costNum) then
		print("item is not enough")
		return false
	end
	return true
end


-- 计算雷霆装备属性
local function updateAttr(actor, roleId)
	--local roledata = getRoleData(actor, roleId)
	local role = LActor.getRole(actor, roleId)
	local attr = LActor.getLeiTingGemAttr(actor, roleId)
	if not attr then return end
	attr:Reset()

	local exAttr = LActor.getLeiTingGemExAttr(actor, roleId)
	if not exAttr then return end
	exAttr:Reset()

	for posIndex = 0, #gemconf do -- 从0开始,0-7
		local posConf = gemconf[posIndex]
		for gemIndex=1, #posConf do -- 配置表从1开始
			local curLevel = getPosGemLevel(actor, roleId, posIndex, gemIndex)
			if(curLevel ~= 0) then
				local conf = posConf[gemIndex][curLevel]
				for _, v in pairs(conf.attrs or {}) do attr:Add(v.type, v.value) end
				for _, v in pairs(conf.exAttrs or {}) do exAttr:Add(v.type, v.value) end
			end
		end
	end

	LActor.reCalcAttr(role)
	LActor.reCalcExAttr(role)
end

local function onLevelUp(actor, packet)
	local roleIndex = LDataPack.readShort(packet) -- 角色索引
	local posIndex = LDataPack.readShort(packet) -- 升级部位
	local gemIndex = LDataPack.readShort(packet) -- 升级宝石编号
	if(not roleIndex or not posIndex or not gemIndex) then
		print("leitingequipsystem.onLevelUp recv data error")
		return
	end
    local actorId = LActor.getActorId(actor)
	--检测是否可升级
	if false == checkOpenCondition(actor, roleIndex, posIndex, gemIndex) then 
		print("leitingequipsystem.onLevelUp: level limit, actorId:"..tostring(actorId)) 
		return 
	end
	
	local curlevel = getPosGemLevel(actor, roleIndex, posIndex, gemIndex)
	local conf = gemconf[posIndex][gemIndex][curlevel + 1]

	LActor.costItem(actor, conf.costItem, conf.costNum, "leitingGemlevelup") -- 消耗道具
	setPosGemLevel(actor, roleIndex, posIndex, gemIndex, curlevel + 1) -- 升级
	updateAttr(actor, roleIndex)
	sendInfo(actor, roleIndex, posIndex, gemIndex, curlevel + 1)
end

-- 给C++发数据用 雷霆宝石等级
local function packleitingGemData(actor, roleId, npack)

	if not actor then return end
	if not roleId then return end
	if not npack then print("packleitingGemData:npack nil, actorId:"..LActor.getActorId(actor)) return end
    local count = 0
	local roledata = getRoleData(actor, roleId)
	-- 将所有等级写入
	local slotmaxIndex = #gemconf -- LeiTingEquipLevel
	for posIndex=0, slotmaxIndex do -- 注:表从0开始,所以计算#LeiTingEquipLevel是7,索引最大到7 0-7
		local confTmp = gemconf[posIndex]
		for gemIndex=1, #confTmp do
			if(not roledata[posIndex] or not roledata[posIndex][gemIndex]) then
				LDataPack.writeShort(npack, 0)
				--print("gemleitingdata  " .. posIndex .. ":" .. gemIndex .. "->0")
			else
				LDataPack.writeShort(npack, roledata[posIndex][gemIndex].level or 0)
				--print("gemleitingdata  " .. posIndex .. ":" .. gemIndex .. "gem有数据---->" .. (roledata[posIndex][gemIndex].level or 0))
			end
			count = count + 1
		end
	end
	--print("宝石数据发送完成,数量:" .. count)
end

local function onInit(actor)
	for i=0, LActor.getRoleCount(actor) - 1 do 
		updateAttr(actor, i) 
	end
end

local function initGlobalData()
	actorevent.reg(aeInit, onInit)
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_ReqLeiTingLevelUpReq, onLevelUp) -- 雷霆淬炼升级
end

table.insert(InitFnTable, initGlobalData)
_G.packleitingGemData = packleitingGemData
--[[
function resetlegem(actor)
	print("gm resetltgem")
	local data = getVarData(actor)

	local var = LActor.getStaticVar(actor)
    
	if(var.leitinggem) then
		var.leitinggem = {}
	end
end


-- 打印雷霆装备信息，gm指令或作为调试用,这里无法使用
function printInfo(actor)
	for roleindex=0, LActor.getRoleCount(actor) - 1 do 
		local strlog = "roleindex:" .. roleindex 
		for posIndex = 0, #gemconf do
			strlog = strlog .. " pos:" .. posIndex
			posconf = gemconf[posIndex]
			for gemIndex=1, #posConf do
				local curLevel = getPosGemLevel(actor,roleId,posIndex,gemIndex)
				strlog = strlog .. " gem:" .. gemIndex .. " level:" .. curLevel .. ", "
			end
		end
		print(strlog)
		-- roleindex:0 pos:0-> gem:1 level:20, gem:2 level:20, ...
	end
end
]]--
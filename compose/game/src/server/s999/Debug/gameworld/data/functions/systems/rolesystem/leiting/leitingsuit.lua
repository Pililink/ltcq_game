module("leitingsuit", package.seeall)

--[[
	--雷霆套装(升级)
    leitingsuit={
		roleId={ -- 角色编号
			[slot]={ -- 身体装备部位索引
                level， -- 该部位装备等级 
			}
			... 8个, 武器 头盔 衣服 ......
			combo8noticelv, -- 8件套发过公告的等级
		}
		... 当前3个
	}
]]--

local suitconf = LeiTingSuitLevel -- 套装单件属性
local suitcomboconf = LeiTingSetConfig -- 套装组合属性
--获取玩家静态变量数据
local function getVarData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.leitingsuit == nil then
		var.leitingsuit = {}
	end
	return var.leitingsuit
end

-- 获取角色数据
local function getRoleData(actor,roleIndex)
	if(not roleIndex) then
        return
	end
	local actordata = getVarData(actor)
	if(not actordata[roleIndex]) then
        actordata[roleIndex] = {}
	end
    return actordata[roleIndex]
end

-- 获取某部位当前等级
local function getPosLevel(actor,roleIndex,posIndex)
	local roledata = getRoleData(actor,roleIndex)
	if(not roledata[posIndex]) then
        return 0
	end
	return roledata[posIndex].level or 0
end
-- 设置某部位当前等级
local function setPosLevel(actor,roleIndex,posIndex,level)
	if(not roleIndex) then print("not roleIndex") end
	if(not posIndex) then print("not posIndex") end
	if(not level) then print("not level")end
	local roledata = getRoleData(actor,roleIndex)
	if(not roledata[posIndex]) then
		roledata[posIndex] = {}
	end
	roledata[posIndex].level = level
end

-- 返回的是2件套 4件套 8件套 的最高等级
local function getSuitCombInfo(actor,roleIndex)
	-- 1-8级装备数量
	local combolv2 = 0
	local combolv4 = 0
	local combolv8 = 0
	local lvCount = {} -- 每个等级拥有的数量
	-- 获取所有套装的等级
	for posIndex,_v in pairs(suitconf) do -- 遍历所有装备获得等级
		local level = getPosLevel(actor,roleIndex,posIndex)
		if(level ~= 0) then
			for leveltmp=1,level do
                lvCount[leveltmp] = (lvCount[leveltmp] or 0) + 1
			end
		end
	end
	-- 最高等级->最低等级 配置套装
	for lv=#suitcomboconf,1,-1 do
		if((lvCount[lv] or 0) >= 8 and combolv8 == 0) then
			combolv8 = lv
		end
		if((lvCount[lv] or 0) >= 4 and combolv4 == 0) then
			combolv4 = lv
	     end
	    if((lvCount[lv] or 0) >= 2 and combolv2 == 0) then
		    combolv2 = lv 
        end            
	end
	--print("套装结果,2件套:" .. combolv2)
	--print("套装结果,4件套:" .. combolv4)
	--print("套装结果,8件套:" .. combolv8)
    return combolv2,combolv4,combolv8 -- 2件套,4件套,8件套的最高
end

-- 发公告
local function sendnotice(actor,roleIndex)
	local cb2,cb4,cb8=getSuitCombInfo(actor,roleIndex)
	local roledata = getRoleData(actor,roleIndex)
	if((roledata.combo8noticelv or 0) < cb8) then
		roledata.combo8noticelv = cb8
		local noticeid = suitcomboconf[cb8][8].notice
		local actorname = LActor.getName(actor)
		local suitname = suitcomboconf[cb8][8].name
        noticemanager.broadCastNotice(noticeid, actorname, suitname)
	end
end
-- 发送升级结果
function sendInfo(actor, roleIndex, posIndex, level)
	if(not actor or not roleIndex) then print("not actor or not roleIndex") end
	if(not posIndex) then print("not posIndex") end
	if(not level) then print("not level") end
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_ReqLeiTingTaozhuangLevelUp)
	LDataPack.writeShort(npack, roleIndex) -- 角色index
	LDataPack.writeShort(npack, posIndex) -- 部位index
	LDataPack.writeShort(npack, level) -- 当前等级
	LDataPack.flush(npack)
end

--检测是否已开启 actor,角色index,部位index，宝石索引
local function checkOpenCondition(actor, roleIndex, posIndex)
	-- 开服天数与角色转生等级检测
	if System.getOpenServerDay() + 1 < LeiTingEquipBaseConfig.openDay or LActor.getZhuanShengLevel(actor) < LeiTingEquipBaseConfig.openZSlevel then
	    return false
	end
	local conf = suitconf[posIndex] -- 当前部位配置信息
	local Roledata = getRoleData(actor,roleIndex)

	if(not suitconf or not suitconf[posIndex]) then
		print("leitingtzhequipsystem.checkOpenCondition conf is not exist")
		return false
	end

	--配置条件检查
	local curlevel = getPosLevel(actor, roleIndex, posIndex)
	if(curlevel >= #conf) then -- 等级超过配置
		print("level is already full")
        return false
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
	local power = 0 -- 额外战力,用于无法计算战力的属性
	local actorId = LActor.getActorId(actor)
	local role = LActor.getRole(actor, roleId)
	if not role then return end
	local attr = LActor.getLeiTingSuitAttr(actor, roleId)
	if not attr then return end
	attr:Reset()

	local exAttr = LActor.getLeiTingSuitExAttr(actor, roleId)
	if not exAttr then return end
	exAttr:Reset()

	-- 计算规则
	for posIndex = 0, #suitconf do
		local curlevel = getPosLevel(actor, roleId, posIndex)
		if(curlevel ~= 0) then
			local conf = suitconf[posIndex][curlevel]
			for _, v in pairs(conf.attrs or {}) do attr:Add(v.type, v.value) end
			for _, v in pairs(conf.exAttrs or {}) do exAttr:Add(v.type, v.value) end
			power = power + (conf.ex_power or 0)
		end
	end
--[[ -- 套装属性暂时不做了
	-- 叠加套装组合属性
	local combo2,combo4,combo8 = getSuitCombInfo(actor,roleId) -- 2件套,4件套,8件套的最高等级
	
	if(combo2 ~= 0) then
		for _, v in pairs(suitcomboconf[combo2][2].attrs or {}) do attr:Add(v.type, v.value) end
		for _, v in pairs(suitcomboconf[combo2][2].ex_attrs or {}) do exAttr:Add(v.type, v.value) end
		print("2件套" .. combo2 .. "级")
	end
	if(combo4 ~= 0) then
		for _, v in pairs(suitcomboconf[combo4][4].attrs or {}) do attr:Add(v.type, v.value) end
		for _, v in pairs(suitcomboconf[combo4][4].ex_attrs or {}) do exAttr:Add(v.type, v.value) end
		print("4件套" .. combo4 .. "级")
	end
	if(combo8 ~= 0) then
		for _, v in pairs(suitcomboconf[combo8][8].attrs or {}) do attr:Add(v.type, v.value) end
		for _, v in pairs(suitcomboconf[combo8][8].ex_attrs or {}) do exAttr:Add(v.type, v.value) end
		print("8件套" .. combo8 .. "级")
	end
	]]--
	attr:SetExtraPower(power)
	LActor.reCalcAttr(role)
	LActor.reCalcExAttr(role)
end



local function onLevelUp(actor, packet)
	local roleIndex = LDataPack.readShort(packet) -- 角色索引
	local posIndex = LDataPack.readShort(packet) -- 升级部位
	if(not roleIndex or not posIndex) then
		if(not roleIndex) then print("not roleIndex") end
		if(not posIndex) then print("not posIndex") end
		print("leitingtzhequipsystem.onLevelUp recv data error")
		return
	end

	local actorId = LActor.getActorId(actor)
	local role = LActor.getRole(actor, roleIndex)
	if not role then 
		print("leitingtzhequipsystem.onLevelUp:role nil, roleId:"..tostring(roleIndex)..", actorId:"..tostring(actorId)) 
		return 
	end

	--检测开启条件
	if false == checkOpenCondition(actor, roleIndex, posIndex) then 
		print("leitingtzhequipsystem.onLevelUp: condition not pass, actorId:"..tostring(actorId)) 
		return 
	end
	
	local data = getVarData(actor)
	local curlevel = getPosLevel(actor,roleIndex, posIndex)
	local conf = suitconf[posIndex][curlevel + 1]

	LActor.costItem(actor, conf.costItem, conf.costNum, "leitingsuitlevelup") -- 消耗道具
	setPosLevel(actor, roleIndex, posIndex, curlevel + 1) -- 升级
	updateAttr(actor, roleIndex) -- 更新属性
	sendInfo(actor, roleIndex, posIndex, curlevel + 1) -- 升级结果
	--sendnotice(actor, roleIndex) -- 公告
end

local function onInit(actor)
	for i=0, LActor.getRoleCount(actor) - 1 do 
		updateAttr(actor, i) 
	end
end

local function initGlobalData()
	actorevent.reg(aeInit, onInit)
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_ReqLeiTingTaozhuangLevelUp, onLevelUp) -- 雷霆套装升级
end

table.insert(InitFnTable, initGlobalData)

local function packleitingSuitData(actor, roleId, npack)
	if not actor then return end
	if not roleId then return end
	if not npack then print("packleitingSuitData:npack nil, actorId:"..LActor.getActorId(actor)) return end
	-- 将所有等级写入
	local count = 0
	local roledata = getRoleData(actor, roleId)
	local maxslotIndex = #LeiTingSuitLevel
	for posIndex=0, maxslotIndex do
		if(not roledata[posIndex]) then
			LDataPack.writeShort(npack, 0)
			--print("套装传了0")
			--print("gemsuitdata  " .. " actorid:" .. LActor.getActorId(actor) .. " suit传了0->" .. " posindex:" .. posIndex)
			--print("gemsuitdata  " .. posIndex .. "->0")
		else
			LDataPack.writeShort(npack, roledata[posIndex].level or 0)
			--print("gemsuitdata  " .. " actorid:" .. LActor.getActorId(actor) .. " suit有数据---->" .. " posindex:" .. posIndex .. roledata[posIndex].level or 0)
		end
		count = count + 1
	end
	--print("套装数据发送完成,数量:" .. count)
end
_G.packleitingSuitData = packleitingSuitData

local gmsystem    = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.resetltsuit = function(actor)
	print("gm resetltsuit")
	local data = getVarData(actor)

	local var = LActor.getStaticVar(actor)
    
	if(var.leitingsuit) then
		var.leitingsuit = {}
	end

end

gmHandlers.lt = function(actor)
	LActor.giveItem(actor, 2100003, 100, "gm")
	LActor.giveItem(actor, 2100004, 100, "gm")
	LActor.giveItem(actor, 2100005, 100, "gm")
	LActor.giveItem(actor, 2100006, 100, "gm")
	LActor.giveItem(actor, 2100007, 100, "gm")
	LActor.giveItem(actor, 2100008, 100, "gm")
	LActor.giveItem(actor, 2100009, 100, "gm")
	LActor.giveItem(actor, 2100010, 100, "gm")

end
--[[

-- 打印雷霆套装信息，gm指令或作为调试用
function printInfo(actor)
	for roleindex=0, LActor.getRoleCount(actor) - 1 do 
		local strlog = "roleindex:" .. roleindex 
		for posIndex = 0, #LeiTingEquipLevel-1 do
			local curlevel = getPosLevel(actor,posIndex)
            strlog = strlog .. " pos:" .. posIndex .. " level:" .. curlevel
		end
		print(strlog )
		-- roleindex:0 pos:0 level:20 pos:1 level:20 ... 
	end
end
]]--
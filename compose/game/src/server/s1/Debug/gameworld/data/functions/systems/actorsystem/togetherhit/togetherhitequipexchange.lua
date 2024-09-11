module("togetherhitequipexchange", package.seeall)
--合击装备兑换

--计算齐鸣套装属性
local function togetherHitQmAttr(actor, isEquip, count, ...)
	local attr = LActor.getTogetherHitAttr(actor)
	if attr == nil then return end
	local ex_attr = LActor.getTogetherHitExAttr(actor)
	if ex_attr == nil then return end
	local zs_lv_num = {}
	for i = 1,count do
		local num = math.floor(arg[i] / 10000000)
		local zslv = math.floor((arg[i] % 10000000) / 10000)
		local level = arg[i] % 10000
		table.insert(zs_lv_num, {zs=zslv, lv=level, num=num})
	end
	--向下累加
	local tmp = utils.table_clone(zs_lv_num)
	for _,v in ipairs(tmp) do
		for _,val in ipairs(zs_lv_num) do 
			if v.zs > val.zs then
				val.num = val.num + v.num
			elseif v.zs == val.zs and v.lv > val.lv then
				val.num = val.num + v.num
			end
		end
	end
	--加属性
	for zslv,zcfg in pairs(TogetherHitEquipQmConfig) do --转生等级层
		for lv,lcfg in pairs(zcfg) do --等级层
			for num,cfg in pairs(lcfg) do --数量层
				--循环所有已经存在的装备数据
				for _,val in ipairs(zs_lv_num) do
					--转生等级比现有的小,或者, 等级比现有的小
					if zslv <= val.zs or (zslv == val.zs and lv <= val.lv) then
						if num <= val.num then --数量满足
							--加属性
							for k,v in ipairs(cfg.attr or {}) do
								attr:Add(v.type, v.value)
							end
							for k,v in ipairs(cfg.exAttr or {}) do
								ex_attr:Add(v.type, v.value)
							end

							--print("togetherHitQmAttr:zslv="..zslv..", lv="..lv..", num="..num..", notice="..(cfg.noticeId or 0))
							if isEquip and cfg.noticeId and val.zs == zslv and val.lv == lv then
								--print("togetherHitQmAttr:val.zs="..val.zs..", val.lv="..val.lv..", notice="..(cfg.noticeId or 0))
								togetherhit.broadcastNotice(actor, val.zs, val.lv, cfg.noticeId)
							end
							
							break --这个配置项已经满足
						end
					end
				end
				--end 循环所有已经存在的装备数据
			end
		end
	end
	--加属性结束
end

_G.togetherHitQmAttr = togetherHitQmAttr

--请求装备兑换
local function reqEquipExchange(actor, packet)
	local idx = LDataPack.readShort(packet) --兑换ID
	--获取对应项的配置
	local ExchangeCfg = TogetherHitEquipExchangeConfig[idx]
	if not ExchangeCfg then
		print("TogetherHitEquipExchange: reqEquipExchange id("..idx..") is not have config")
		return
	end
	--[[检测消耗
	local consumeTable = {} --所需要的消耗
	local haveCount = 0 --已经有了的数量
	for k,v in ipairs(ExchangeCfg.exchangeMaterial) do
		local needCount = ExchangeCfg.exchangeAmount - haveCount --还需要的数量
		local count = LActor.getItemCount(actor, v)
		local useCount = count --使用数量
		if count > needCount then
			useCount = needCount
		end
		--放入消耗表
		if useCount > 0 then
			table.insert(consumeTable, {item=v,count=useCount})
			haveCount = haveCount + useCount
		end
		--已经够了
		if haveCount >= ExchangeCfg.exchangeAmount then
			break
		end
	end
	--兑换材料不足
	if haveCount < ExchangeCfg.exchangeAmount then
		print("TogetherHitEquipExchange: reqEquipExchange id("..tostring(idx)..") consume is insufficient")
		return
	end
	--扣除消耗
	for k,v in ipairs(consumeTable) do
		LActor.costItem(actor, v.item, v.count, "together hit equip exchange")
	end]]
	--消耗
	for _, v in pairs(ExchangeCfg.exchangeMaterial) do
		local ret = true
		if v.type == AwardType_Numeric then
			local count = LActor.getCurrency(actor, v.id)
			if count < v.count then
				ret = false
			end			
		elseif v.type == AwardType_Item then
			local count = LActor.getItemCount(actor, v.id)
			if count < v.count then
				ret = false
			end
		else
			ret = false
		end
		if ret == false then 
			print(LActor.getActorId(actor).." TogetherHitEquipExchange: reqEquipExchange idx("..idx.."),type="..(v.type)..",id="..(v.id).." consume is insufficient")
			return
		end
	end
	--扣除消耗
	for _, v in pairs(ExchangeCfg.exchangeMaterial) do
		if v.type == AwardType_Numeric then
			LActor.changeCurrency(actor, v.id, -v.count, "together hit equip exchange")
		elseif v.type == AwardType_Item then
			LActor.costItem(actor, v.id, v.count, "together hit equip exchange")
		end
	end
	--获取道具
	local awards = {ExchangeCfg.getItem}
	if LActor.canGiveAwards(actor, awards) == false then
		print(LActor.getActorId(actor).." TogetherHitEquipExchange: reqEquipExchange id("..idx..") can not give awards")
		return
	end
	--获得奖励
	LActor.giveAwards(actor, awards, "together hit equip exchange")
end

--请求高级碎片替换低级碎片
local function reqTogeatterExchange(actor, packet)
	local count = LDataPack.readInt(packet)
	if not count or count <= 0 then
		return
	end
	if not TogerherHitBaseConfig.TogExgRate then
		print(LActor.getActorId(actor).." TogetherHitEquipExchange.reqTogeatterExchange not TogExgRate cfg")
		return
	end
	--扣除高级碎片
	local haveCount = LActor.getCurrency(actor, NumericType_TogeatterHigh)
	if haveCount < count then
		print(LActor.getActorId(actor).." TogetherHitEquipExchange.reqTogeatterExchange haveCount("..haveCount..") < count("..count..")")
		return
	end
	LActor.changeCurrency(actor, NumericType_TogeatterHigh, -count, "TogeatterExchange")
	--获得低级碎片
	LActor.changeCurrency(actor, NumericType_Togeatter, count*TogerherHitBaseConfig.TogExgRate, "TogeatterExchange")
end

-- 神装内容开始
-- 神装数据,这里面存神装碎片每天的兑换次数

--[[
	shenzhuang = {
		[id] = count, -- 碎片今日兑换次数
	}
]]

local function getShenzhuangData(actor)
	local var = LActor.getStaticVar(actor)
    if var == nil then 
        return nil
    end
    if var.shenzhuang == nil then 
        var.shenzhuang = {}
	end
	return var.shenzhuang
end

local function clearShenzhuangData(actor)
	local actorid = LActor.getActorId(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then
		print("clearShenzhuangData fail , actorid:" .. actorid) 
        return
	end
	var.shenzhuang = nil
end

local function getShenzhuangData(actor)
	local var = LActor.getStaticVar(actor)
    if var == nil then 
        return nil
    end
    if var.shenzhuang == nil then 
        var.shenzhuang = {}
	end
	return var.shenzhuang
end

local function clearShenzhuangData(actor)
	local actorid = LActor.getActorId(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then
		print("clearShenzhuangData fail , actorid:" .. actorid) 
        return
	end
	var.shenzhuang = nil
end

-- 发送神装碎片兑换信息 4-12
local function sendShenzhuangDebrisExchangeInfo(actor)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_ShengZhuangDebrisExchangeInfo)
	if not pack then return end
	local shenzhuangdata = getShenzhuangData(actor)
	LDataPack.writeShort(pack, #LegendExchangeConfig) -- 兑换id总数量

	for id,_ in pairs(LegendExchangeConfig) do
		LDataPack.writeShort(pack, id) -- 兑换id
		LDataPack.writeShort(pack, (shenzhuangdata[id] or 0)) -- 已兑换次数
	end
	LDataPack.flush(pack)
end
-- 神装碎片兑换
-- 因为神装本身的功能在C++里面,所以这里跟合击碎片挤一挤
local function shenzhuangDebrisExchange(actor, packet) -- 4-11
	local id = LDataPack.readShort(packet) -- 兑换的商品id
	local count = LDataPack.readShort(packet) -- 兑换数量

	local result = 0 -- 0成功兑换 1失败 具体什么原因不定了,其他功能开发比较急
	repeat
		if not id or not type then
			print("shenzhuangDebrisExchange read id err")
			result = 1
			break
		end
		if not LegendExchangeConfig or not LegendExchangeConfig[id] then
			print("shenzhuangDebrisExchange config not exist,type:" .. type .. " id:" .. id)
			result = 1
			break
		end
		local config = LegendExchangeConfig[id]
		local shenzhuangdata = getShenzhuangData(actor)
		if(not shenzhuangdata) then
			result = 1
			print("shenzhuangDebrisExchange is nil")
			break
		end
		if(config.dailyCount and (shenzhuangdata[id] or 0) >= config.dailyCount) then
			result = 1
			break
		end
		if(LActor.getZhuanShengLevel(actor) < config.zsLevel) then
			result = 1
			break
		end

		local havecount = LActor.getItemCount(actor, config.exchangeMaterial.id)
		if(havecount >= count*config.exchangeMaterial.count) then
			-- 扣除材料
			LActor.costItem(actor, config.exchangeMaterial.id, count*config.exchangeMaterial.count, "action_shenzhuangDebris_exchange")
			--给奖励
			LActor.giveItem(actor, config.getItem.id, config.getItem.count*count, "action_shenzhuangDebris_exchange")
			shenzhuangdata[id] = (shenzhuangdata[id] or 0) + count
		else
			result = 1
		end
	until(true)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_Equip, Protocol.sEquipCmd_ShengZhuangDebrisExchange)
	if not pack then return end
	LDataPack.writeShort(pack, id) -- id
	LDataPack.writeShort(pack, result) -- 结果
	LDataPack.flush(pack)
	sendShenzhuangDebrisExchangeInfo(actor)
end
--[[
    @desc: 清理神装碎片的兑换数据
    author:{author}
    time:2020-02-19 17:44:47
    --@actor: 
    @return:
]]
local function onNewDay(actor)
	-- 每日清理神装数据
	local var = LActor.getStaticVar(actor)
    var.shenzhuang = nil
end

local function onLogin(actor)
	sendShenzhuangDebrisExchangeInfo(actor)
end
--神装内容结束

local function init()
	actorevent.reg(aeNewDayArrive, onNewDay) -- 清理神装碎片的兑换数据,与合击装备无关
	actorevent.reg(aeUserLogin, onLogin) -- 神装碎片,与合击装备无关
	netmsgdispatcher.reg(Protocol.CMD_Equip, Protocol.cEquipCmd_ShengZhuangDebrisExchange, shenzhuangDebrisExchange) -- 神装碎片兑换,与合击装备无关
	netmsgdispatcher.reg(Protocol.CMD_Skill, Protocol.cSkillCmd_TogetherHitEquipExchange, reqEquipExchange)
	netmsgdispatcher.reg(Protocol.CMD_Skill, Protocol.cSkillCmd_TogeatterExchange, reqTogeatterExchange)
	
end

table.insert(InitFnTable, init)

module("demoncircle", package.seeall)
--[[
	注意事项:法阵系统是后期开发功能,影响到铸造,强化,精炼,龙魂等系统,所以该lua文件一定要放在这些系统的文件后面
]]
--[[
	--法阵数据
    demoncircledata={
		[roleId]={ -- 角色编号 * 3
			huanhuaid, -- 幻化id 0-6 0是取消,1-6的显示客户端自己决定
			subdemoncircleinfo={
				[subId]={ -- 子法阵id * 6
					arrayeyelv, -- 子法阵阵眼等级
					nutritionlv, -- 蕴养等级
					nutritionexp, -- 蕴养经验
					studycount, -- 潜能的领悟次数(一个子法阵用同一个)
					tezhiinfo = { -- 特质激活至第几重
						[1] = 0, -- 未激活状态
						... 特质*4
					}
					potentialpoint = { -- 潜能点信息
						[index] = { -- 潜能点编号*5
							extravalue, -- 激活后的额外属性
						}
						... *10 潜能点数量
					}
				}
				... *6 子法阵数量
			}
		}
		... * 3 角色法阵信息数量
	}
]]--

--[[ -- 5个配置
	config1 = DemonCirConfig 开启条件配置
	config2 = DemonCirBaseConfig 子法阵的id和开启条件 6个
	config3 = DemonCirTalentConfig 阵眼属性 6个种类,系统级别额外强化
	config4 = DemonCirLevelConfig  蕴养,阵法的属性加成
	config5 = DemonCirQianNengConfig 潜能属性
	config6 = DemonCirSkillConfig 特质
]]

local attrdesc = {
	[0] = "当前hp",
	[1] = "当前mp",
	[2] = "血量上限:",
	[3] = "最大mp",
	[4] = "物攻:",
	[5] = "物防",
	[6] = "魔防",
}

local fightnum = {}

-- 跟DemonCirTalentConfig配置的index相同
local arrayeyeIndex = {
	e_zhuzao = 1, -- 铸造阵眼id
	e_qianghua = 2, -- 强化阵眼id
	e_jinglian = 3, -- 精炼阵眼id
	e_longhun = 4, -- 龙魂阵眼id
}

local RATE = 10000 -- 万分比

local function sendTip(actor,tipmsg, type)
	--[[
	local msgtype = 4
	if(type) then
		msgtype = type
	end
	LActor.sendTipmsg(actor, tipmsg .. " SERVER DEBUG", msgtype)
	]]
end

local function LOG(actor,errlog)
	local actorid = LActor.getActorId(actor)
	print("[ERROR]:demoncircle." .. errlog .. " actorid:" .. actorid)
end

local function DEBUG(actor,log)
	--[[
	local actorid = LActor.getActorId(actor)
	print("[DEBUG]:demoncircle." .. log .. " actorid:" .. actorid)
	]]
end

--[[
    @desc: 计算战力
    author:{author}
    time:2020-02-22 17:56:55
    --@actor:
	--@attrtab:属性表
	--@rate: 战力折扣
    @return:战力值
]]
local function calcFight(actor,attrtab,rate)
	--[[ 
		attrtab = {
		[4] = 1000, --攻击力
		...
	}
	]]
	local fight = 0
	local rateTmp = 1
	if(rate) then
		rateTmp = rate
	end
	--战斗力=攻*3.6+血量*0.2+(物+法)*1.8
	if(type(attrtab) ~= 'table') then
		LOG(actor, "calcFight error type")
		return 0 
	end
	if(not attrtab) then
		LOG(actor,"calcFight 属性表为空")
		return 0
	end
	fight = rateTmp*(3.6*(attrtab[4] or 0) + 0.2*(attrtab[2] or 0) + 1.8*((attrtab[5] or 0) + (attrtab[6] or 0)))
	return fight
end

--获取玩家静态变量数据
local function getVarData(actor)
	local var = LActor.getStaticVar(actor)
	if var == nil then 
		return nil
	end
	--初始化静态变量的数据
	if var.demoncircledata == nil then
		var.demoncircledata = {}
	end
	return var.demoncircledata
end

-- 获取角色信息
local function getRoleData(actor, roleId)
	local actordata = getVarData(actor)
	if(not actordata[roleId]) then
        actordata[roleId] = {}
	end
    return actordata[roleId]
end

-- 获取角色幻化编号
local function GetHuanhuaId(actor, roleId)
	local roleInfo = getRoleData(actor, roleId)
	return roleInfo.huanhuaid or 0
end


-- 设置角色幻化编号
local function SetHuanhuaId(actor, roleId, huanhuaId)
	local roleInfo = getRoleData(actor, roleId)
	roleInfo.huanhuaid = huanhuaId
end


-- 获取角色的所有子法阵信息
local function GetSubDemonInfo(actor, roleId)
	local roleInfo = getRoleData(actor, roleId)
	if (not roleInfo.subdemoncircleinfo) then
		roleInfo.subdemoncircleinfo = {}
	end
	return roleInfo.subdemoncircleinfo
end



-- 获取角色的子法阵指定法阵信息
local function GetSpecificSubDemonInfo(actor, roleId,subId)
	local subDemonInfo = GetSubDemonInfo(actor, roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	return subDemonInfo[subId]
end

-- 获取某一角色子法阵阵眼等级
local function GetArrayEyeLevel(actor,roleId,subId)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	return (subDemonInfo[subId].arrayeyelv or 0)
end

-- 设置子法阵阵眼等级
local function SetArrayEyeLevel(actor,roleId,subId,lv)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	subDemonInfo[subId].arrayeyelv = lv
end

--[[
    @desc: 法阵对玩家的野外经验金币的加成
    author:{author}
    time:2020-02-17 18:17:23
    --@actor: 玩家
    @return: 金币加成,经验加成(百分比)
]]
local function GetGoldExpJiaCheng(actor)
	local roleCount = LActor.getRoleCount(actor)
	local goldadd = 0
	local expadd = 0
	for roleId=0,roleCount-1 do
		--法阵5 金币 加成
		--法阵6 经验加成
		-- 这部分代码策划通过配置只能改改数值,不可修改功能,法阵5必须是金币加成,法阵6必须是经验加成
		local eyelv5 = GetArrayEyeLevel(actor,roleId,5) -- 5阵眼等级
		local eyelv6 = GetArrayEyeLevel(actor,roleId,6) -- 6阵眼等级
		if(DemonCirTalentConfig[5][eyelv5]) then
			goldadd = goldadd + (DemonCirTalentConfig[5][eyelv5].increasePer or 0)
		end
		if(DemonCirTalentConfig[6][eyelv6]) then
			expadd = expadd + (DemonCirTalentConfig[6][eyelv6].increasePer or 0)
		end
	end
	DEBUG(actor,"GetExpGoldJiaCheng 经验加成:" .. expadd .. "金币加成:" .. goldadd)
	return goldadd/100,expadd/100 -- 本身是万分比,兼容以前的系统
end


--[[
    @desc: 获取子法阵特质等级
    author:{author}
    time:2020-02-11 10:51:36
    --@actor:
	--@roleId: 角色id
	--@subId:子法阵编号
    @return:特质等级
]]
local function GetSubTezhiLevel(actor,roleId,subId,tezhiId)
	local specificSubInfo = GetSpecificSubDemonInfo(actor, roleId,subId)
	if(not specificSubInfo) then
		LOG(actor,"GetSubTezhiLevel data not exist")
		return 0
	end
	if(not specificSubInfo.tezhiinfo) then
		specificSubInfo.tezhiinfo={}
	end
	return (specificSubInfo.tezhiinfo[tezhiId] or 0)
end

--[[
    @desc: 设置特质等级
    author:{author}
    time:2020-02-13 12:33:26
    --@actor:
	--@roleId:
	--@subId:
	--@tezhiId: 
    @return:
]]
local function SetSubTezhiLevel(actor,roleId,subId,tezhiId,lv)
	local specificSubInfo = GetSpecificSubDemonInfo(actor, roleId,subId)
	if(not specificSubInfo) then
		LOG(actor,"SetSubTezhiLevel data not exist")
		return 0
	end
	if(not specificSubInfo.tezhiinfo) then
		specificSubInfo.tezhiinfo={}
	end
	specificSubInfo.tezhiinfo[tezhiId] = lv
end


--[[
    @desc: 获取蕴养等级
    author:{author}
    time:2020-02-11 15:38:17
    --@actor:
	--@roleId:
	--@tAttrPerList: 
    @return:
]]
local function GetNutritionLevel(actor,roleId,subId)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	return (subDemonInfo[subId].nutritionlv or 0)
end

--[[
    @desc: 设置子阵蕴养等级
    author:{author}
    time:2020-02-11 15:55:15
    --@actor:
	--@roleId:
	--@subId:
	--@lv: 要设置的等级
    @return:
]]
local function SetNutritionLevel(actor,roleId,subId,lv)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	subDemonInfo[subId].nutritionlv = lv
end

--[[
    @desc: 获取子阵蕴养经验
    author:{author}
    time:2020-02-11 15:55:15
    --@actor:
	--@roleId:
	--@subId:
    @return:
]]
local function GetNutritionExp(actor,roleId,subId)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	return subDemonInfo[subId].nutritionexp or 0
end

--[[
    @desc: 设置子阵蕴养经验
    author:{author}
    time:2020-02-11 15:55:15
    --@actor:
	--@roleId:
	--@subId:
    @return:
]]
local function SetNutritionExp(actor,roleId,subId,exp)
	local subDemonInfo = GetSubDemonInfo(actor,roleId)
	if(not subDemonInfo[subId]) then
		subDemonInfo[subId] = {}
	end
	subDemonInfo[subId].nutritionexp = exp
end

--[[
    @desc: 获取指定潜能点信息
    author:{author}
    time:2020-02-13 13:41:36
    --@actor:
	--@roleId:
	--@subId: 
    @return:
]]
local function GetSpecificQiannengInfo(actor,roleId,subId,qiannengId)
	local subInfo = GetSpecificSubDemonInfo(actor,roleId,subId)
	if(not subInfo.potentialpoint) then
		subInfo.potentialpoint = {}
	end
	if(not subInfo.potentialpoint[qiannengId]) then
		subInfo.potentialpoint[qiannengId] = {}
	end
	return subInfo.potentialpoint[qiannengId]
end

--[[
    @desc: 获取角色的潜能点领悟总次数
    author:{author}
    time:2020-02-13 13:35:19
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId: 潜能点id
    @return:
]]
local function GetQiannengStudycount(actor,roleId,subId)
	local subInfo = GetSpecificSubDemonInfo(actor,roleId,subId)
	return subInfo.studycount or 0
end

--[[
    @desc: 具体潜能点是否已激活
    author:{author}
    time:2020-02-14 11:43:03
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId: 
    @return:0 没有 1 已激活
]]
local function GetQiannengActiveFlag(actor,roleId,subId,qiannengId)
	local studycount = GetQiannengStudycount(actor,roleId,subId)
	local flag = 0
	if(not DemonCirQianNengConfig[qiannengId]) then
		LOG(actor,"GetQiannengActiveFlag config not exist,qiannengId:" .. qiannengId)
	end
	local eyelv = GetArrayEyeLevel(actor,roleId,subId)
	if ((eyelv > 0) and studycount >= (DemonCirQianNengConfig[qiannengId].count or 0)) then
		flag = 1
	end
	--DEBUG(actor,"潜能数据: 子阵id:" .. subId .. " 潜能id:" .. qiannengId .. " 领悟状态:" .. flag)
	return flag
end

--[[
    @desc: 获取指定潜能点激活状态以外的属性值或加成
    author:{author}
    time:2020-02-13 14:01:21
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId: 
    @return:
]]
local function GetQiannengExtravalue(actor,roleId,subId,qiannengId)
	local subQiannengInfo = GetSpecificQiannengInfo(actor,roleId,subId,qiannengId)
	return subQiannengInfo.extravalue or 0
end

--[[
    @desc: 设置属性值或者加成
    author:{author}
    time:2020-02-13 14:02:49
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId:
	--@value: 属性值或加成
    @return:
]]
local function SetQiannengExtravalue(actor,roleId,subId,qiannengId,value)
	local subQiannengInfo = GetSpecificQiannengInfo(actor,roleId,subId,qiannengId)
	subQiannengInfo.extravalue = value
end

--[[
    @desc: 设置潜能点领悟次数
    author:{author}
    time:2020-02-13 13:35:19
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId: 潜能点id
    @return:
]]
local function SetQiannengStudycount(actor,roleId,subId,count)
	local subInfo = GetSpecificSubDemonInfo(actor,roleId,subId)
	subInfo.studycount = count
end


--[[
    @desc:铸造叠加的属性
    author:{author}
    time:2020-02-10 18:25:23
    --@actor:
	--@roleId:角色id
	--@tAttrList:铸造叠加的属性列表
    @return:无
]]
local function GetZhuzaoAttr(actor,roleId)
	local attr = LActor.getDemonAttr(actor, roleId)
	local tZhulingInfo = LActor.getZhulingInfo(actor, roleId)
	if (not tZhulingInfo) then
		return
	end	
	--把铸造所有位置的属性汇总
	local tAttrList = {}
	for posId, level in pairs(tZhulingInfo) do
		local config = zhulingcommon.getZhulingAttrConfig(posId, level)
		if (config) then
			for _,tb in pairs(config.attr  or {}) do
				tAttrList[tb.type] = tAttrList[tb.type] or 0
				tAttrList[tb.type] = tAttrList[tb.type] + tb.value
			end
		end
	end
	--子法阵1属性百分比加成
	local curlv = GetArrayEyeLevel(actor,roleId,arrayeyeIndex.e_zhuzao) -- 1是铸造系统加成
	local percent = 0
	if(DemonCirTalentConfig[arrayeyeIndex.e_zhuzao][curlv]) then
		percent = DemonCirTalentConfig[arrayeyeIndex.e_zhuzao][curlv].increasePer/RATE -- 铸造属性加成
	end
	

	for type,attrval in pairs(tAttrList) do
		local value= math.floor(percent*attrval) -- 计算属性
		attr:Add(type, value)
		DEBUG(actor,"GetZhuzaoAttr 法阵铸造加成type:" .. type .. " value:" .. value)
	end

	local fight = calcFight(actor,tAttrList,percent)
	DEBUG(actor,"GetZhuzaoAttr 法阵的铸造战力值:" .. fight)
end

--[[
    @desc:强化叠加的属性
    author:{author}
    time:2020-02-10 18:25:23
    --@actor:
	--@roleId:角色id
	--@tAttrList:强化叠加的属性列表
    @return:无
]]
local function GetQianghuaAttr(actor,roleId)
	local attr = LActor.getDemonAttr(actor, roleId)
	local tEnhanceInfo = LActor.getEnhanceInfo(actor, roleId)
	if (not tEnhanceInfo) then
		return
	end

	--把所有位置的属性汇总
	local tAttrList = {}
	for posId, level in pairs(tEnhanceInfo) do
		local config = enhancecommon.getEnhanceAttrConfig(posId, level)
		if (config) then
			for _,tb in pairs(config.attr) do
				tAttrList[tb.type] = tAttrList[tb.type] or 0
				tAttrList[tb.type] = tAttrList[tb.type] + tb.value
			end
		end
	end
	--子法阵2属性百分比加成
	local curlv = GetArrayEyeLevel(actor,roleId,arrayeyeIndex.e_qianghua) -- 2是对强化系统加成
	local percent = 0
	if(DemonCirTalentConfig[arrayeyeIndex.e_qianghua][curlv]) then
		percent = DemonCirTalentConfig[arrayeyeIndex.e_qianghua][curlv].increasePer/RATE -- 强化属性加成
	end
	

	for type,attrval in pairs(tAttrList) do
		local value= math.floor(percent*attrval) -- 计算属性
		attr:Add(type, value)
		DEBUG(actor,"GetZhuzaoAttr 法阵强化加成type:" .. type .. " value:" .. value)
	end

	local fight = calcFight(actor,tAttrList,percent)
	DEBUG(actor,"GetQianghuaAttr 法阵的强化战力值:" .. fight)
end

--[[
    @desc:精炼叠加的属性
    author:{author}
    time:2020-02-10 18:25:23
    --@actor:
	--@roleId:角色id
	--@tAttrList:精炼叠加的属性列表
    @return:无
]]
local function GetJinglianAttr(actor,roleId)
	local attr = LActor.getDemonAttr(actor, roleId)
	local stoneInfo = LActor.getStoneInfo(actor, roleId)
	if (not stoneInfo) then
		return
	end
	local tAttrList = {}
	for pos, level in pairs(stoneInfo) do
		local config = stonecommon.getPosLevelConfig(pos, level)
		if (config) then
			for _,tb in pairs(config.attr or {}) do
				tAttrList[tb.type] = tAttrList[tb.type] or 0
				tAttrList[tb.type] = tAttrList[tb.type] + tb.value
			end
		end
	end

	local curlv = GetArrayEyeLevel(actor,roleId,arrayeyeIndex.e_jinglian) -- 3是对精炼系统加成
	local percent = 0
	if(DemonCirTalentConfig[arrayeyeIndex.e_jinglian][curlv]) then
		percent = DemonCirTalentConfig[arrayeyeIndex.e_jinglian][curlv].increasePer/RATE -- 精炼属性加成
	end
	 
	for type,attrval in pairs(tAttrList) do
		local value = math.floor(percent*attrval)
		attr:Add(type, value)
		DEBUG(actor,"GetZhuzaoAttr 法阵精炼加成type:" .. type .. " value:" .. value)
	end

	local fight = calcFight(actor,tAttrList,percent)
	DEBUG(actor,"GetJinglianAttr 法阵的精炼战力值:" .. fight)
end

--[[
    @desc:龙魂叠加的属性
    author:{author}
    time:2020-02-10 18:25:23
    --@actor:
	--@roleId:角色id
	--@tAttrList:铸造叠加的属性列表
    @return:无
]]
local function GetLonghunAttr(actor,roleId)
	local attr = LActor.getDemonAttr(actor, roleId)
	local stage,soulLevel,exp,act = LActor.getSoulShieldinfo(actor, roleId, ssLoongSoul)
	if act ~= 1 then return end
	local tAttrList = {}
	local config = soulshieldcommon.getLevelConfig(ssLoongSoul, soulLevel)
	if (config) then
		local value = 0
		for _, tb in pairs(config.attr) do
			tAttrList[tb.type] = tAttrList[tb.type] or 0
			tAttrList[tb.type] = tAttrList[tb.type] + tb.value
		end
	end
	--子法阵4属性百分比加成
	local curlv = GetArrayEyeLevel(actor,roleId,arrayeyeIndex.e_longhun) -- 4龙魂
	local percent = 0
	if(DemonCirTalentConfig[arrayeyeIndex.e_longhun][curlv]) then
		percent = DemonCirTalentConfig[arrayeyeIndex.e_longhun][curlv].increasePer/RATE -- 龙魂加成
	end

	for type,attrval in pairs(tAttrList) do
		local value = math.floor(percent*attrval)
		attr:Add(type, value)
		DEBUG(actor,"GetZhuzaoAttr 法阵龙魂加成type:" .. type .. " value:" .. value)
	end

	local fight = calcFight(actor,tAttrList,percent)
	DEBUG(actor,"GetZhuzaoAttr 法阵的龙魂战力值:" .. fight)
end

--[[
    @desc: 特质提升的百分比
    author:{author}
    time:2020-02-11 12:46:50
    --@actor:
	--@roleId:
	--@tAttrPerList: 特质提升的百分比列表
	tAttrPerList= {
		[subId] = { -- 子阵id
			[type] = rate, -- 属性提升率 0.1表示百分之10
			... 不缺定个数,蕴养提升属性时用
		}
		... 6个子阵
	}
    @return:
]]
local function GetTezhiAttr(actor,roleId,tAttrPerList) 
	local attr = LActor.getDemonAttr(actor, roleId)
	for subId,_ in pairs(DemonCirBaseConfig) do -- 所有子法阵
		for tezhiId,config in pairs(DemonCirSkillConfig) do -- 所有特质
			local tezhiLv = GetSubTezhiLevel(actor,roleId,subId,tezhiId)
			if(config[tezhiLv]) then -- 存在等级是0的情况
				local specificConf = config[tezhiLv] -- 具体使用的特质配置行
				if (not tAttrPerList[subId]) then
					tAttrPerList[subId] = {} -- 子阵数据
				end
				local attrType = specificConf.attrPer.type
				local rate = specificConf.attrPer.rate/RATE
				tAttrPerList[subId][attrType] = (tAttrPerList[subId].attrType or 0) + rate
			end
		end
	end
end

--[[
    @desc: 潜能点的加成和属性
    author:{author}
    time:2020-02-11 17:30:47
    --@actor:
	--@roleId:
	--@increaseRate: 
    @return:
]]
local function GetPotentialPointAttr(actor,roleId,increaseRate)
	local attr = LActor.getDemonAttr(actor, roleId)
	--已激活才有属性
	for subId,_ in pairs(DemonCirBaseConfig) do -- 所有子法阵
		for _,qiannengId in ipairs(DemonCirBaseConfig[subId].qianneng) do -- 子阵的潜能列表
			local specificConf = DemonCirQianNengConfig[qiannengId]
			local activeFlag = GetQiannengActiveFlag(actor,roleId,subId,qiannengId)
			if(activeFlag == 1) then -- 已激活
				if(specificConf.increasePer == 1) then -- 类型1直接累加 类型2是万分比
					local extravalue = GetQiannengExtravalue(actor,roleId,subId,qiannengId)
					-- 所有基础属性均加上额外属性
					for _,v in pairs(specificConf.attr) do
						local sumvalue = v.value + extravalue -- 总属性
						attr:Add(v.type,sumvalue)
						DEBUG(actor,"qianneng 子阵id:" .. subId .. "潜能id:" ..qiannengId .. "提升类型:累加" .. " 属性type:" .. v.type .. " value:" .. sumvalue)
					end
				elseif(specificConf.increasePer == 2) then-- 万分比累加
					for i,v in pairs(specificConf.attr) do
						local extravalue = GetQiannengExtravalue(actor,roleId,subId,qiannengId)
						local sumvalue = v.value + extravalue
						sumvalue = math.floor(sumvalue/(RATE/10))*(RATE/10) -- 保留一位小数
						local rate = math.floor(sumvalue/RATE)
						if(not increaseRate[subId]) then
							increaseRate[subId] = {}
						end
						increaseRate[subId][v.type] = (increaseRate[subId][v.type] or 0) + rate
						DEBUG(actor,"qianneng 子阵id:" .. subId .. "潜能id:" ..qiannengId .. "提升类型:万分比" .. " 属性type:" .. v.type .. " value:" .. sumvalue)
					end
				else
					LOG(actor,"GetPotentialPointAttr unknown increasePer:" .. (specificConf.increasePer or -1))
				end
			end
		end
	end
end


--[[
    @desc: 法阵蕴养的属性(子法阵属性)
    author:{author}
    time:2020-02-11 15:00:23
    --@actor:
	--@roleId:
	--@tAttrPerList: 特质传进来的加成表
    @return:
]]
local function GetNutritionAttr(actor,roleId,tAttrPerList)
	local typeattr = {} -- 测试用表
	local attr = LActor.getDemonAttr(actor, roleId)
	for subId,config in pairs(DemonCirLevelConfig) do
		local subNutritionlv = GetNutritionLevel(actor,roleId,subId) -- 子阵蕴养等级
		if(config[subNutritionlv]) then -- 存在为0的情况
			for _,v in pairs(config[subNutritionlv].attr or {}) do --读属性行,不用{}防止异常,出错直接游戏内报错,所有配置均不该出现问题
				local type = v.type
				if(not tAttrPerList[subId]) then
					tAttrPerList[subId] = {}
				end
				local addRate = tAttrPerList[subId][type] or 0 -- 子阵的增强率
				local value = math.floor(v.value*(1+addRate))
				--DEBUG(actor,"GetNutritionAttr type:" .. type .. " value:" .. value)
				attr:Add(type, value)
				typeattr[type] = (typeattr[type] or 0) + value
			end
			local fight = calcFight(actor,typeattr)
			DEBUG(actor,"GetZhuzaoAttr 子阵蕴养战力值:" .. fight .. " 子阵id:" .. subId)
		end
	end
end

--[[
    @desc:更新法阵属性
    author:{author}
    time:2020-02-10 16:07:03
    --@actor:
	--@roleId: 
    @return:
]]
function updateDemonAttr(actor, roleId)
	local role = LActor.getRole(actor, roleId)
	local attr = LActor.getDemonAttr(actor, roleId)
	if not attr then return end
	attr:Reset() 	--先把原来的清零

	-- 铸造加成
	GetZhuzaoAttr(actor, roleId)

	-- 强化加成
	GetQianghuaAttr(actor,roleId)

	-- 精炼加成
	GetJinglianAttr(actor,roleId)

	-- 龙魂加成
	GetLonghunAttr(actor,roleId)

	-- 计算所有子法阵*6 所有特质对法阵的加成
	-- 特质属性加成
	local increaseRate = {} -- 属性提升表
	GetTezhiAttr(actor,roleId,increaseRate)
	-- 潜能属性加成与属性
	GetPotentialPointAttr(actor,roleId,increaseRate)
	-- 法阵蕴养属性
	GetNutritionAttr(actor,roleId,increaseRate)

	-- 野外挂机经验加成
	-- 金币加成
	specialattribute.updateAttribute(actor)

	--刷新角色属性
	LActor.reCalcAttr(role)
	--LActor.reCalcExAttr(role)
end

-------------------------------------------------------------------------

--检测是否已开启 actor,角色index,子法阵id
local function checkOpenCondition(actor, roleIndex, subId)
	if(LActor.getZhuanShengLevel(actor) < DemonCirConfig.openzhuansheng) then -- 转生等级检查
		LOG(actor,"checkOpenCondition zslevel is not enough")
		return false
	end
	--配置条件检查
	local curlevel = GetArrayEyeLevel(actor, roleIndex, subId) -- 当前阵眼等级
	if(not DemonCirTalentConfig[subId]) then
		LOG(actor,"checkOpenCondition error subId:" .. subId)
		return false
	end
	if(curlevel >= #DemonCirTalentConfig[subId]) then -- 等级超过配置
		LOG(actor,"checkOpenCondition level is already full")
		--sendTip(actor,"level is already full")
        return false
	end
	local conf = DemonCirTalentConfig[subId] -- 特定子法阵配置
	local itemid = conf[curlevel+1].costCount.id -- 升级消耗道具id
	local costcount = conf[curlevel+1].costCount.count -- 升级需要消耗的数量
	
    --道具数量检测
	local itemCount = LActor.getItemCount(actor, itemid) -- 拥有数量
	if(itemCount < costcount) then
		LOG(actor,"item is not enough,itemid:" .. itemid .. " 拥有数量:" .. itemCount .. " 需要消耗数量:" .. costcount)
		sendTip(actor,"item is not enough,itemid:" .. itemid .. " 拥有数量:" .. itemCount .. " 需要消耗数量:" .. costcount)
		return false
	end
	return true
end


--[[
    @desc: 发送指定阵眼信息
    author:{author}
    time:2020-02-12 12:02:34
    --@actor:
	--@roleId:角色编号0-2
	--@subId: 子阵id
    @return:
]]
local function sendArrayEyeInfo(actor, roleId, subId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DemonCircle, Protocol.sDemonCircleCmd_ArrayeyeInfo)
	LDataPack.writeShort(npack, roleId) -- 角色index
	LDataPack.writeShort(npack, subId) -- 子法阵id
	local eyelv = GetArrayEyeLevel(actor,roleId,subId)
	LDataPack.writeShort(npack, eyelv) -- 阵眼当前等级
	LDataPack.flush(npack)
end

--[[
    @desc: 发送指定子阵的蕴养信息
    author:{author}
    time:2020-02-13 24:02:28
    --@actor:
	--@roleId: 角色编号
	--@subId: 子阵id
    @return:
]]
local function sendNutritionInfo(actor,roleId,subId)
	local nutritionlv = GetNutritionLevel(actor,roleId,subId)
	local nutritionexp = GetNutritionExp(actor,roleId,subId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DemonCircle, Protocol.sDemonCircleCmd_NutritionInfo) -- 79-2
	LDataPack.writeShort(npack, roleId) -- 角色index
	LDataPack.writeShort(npack, subId) -- 子法阵id
	LDataPack.writeShort(npack, nutritionlv) -- 蕴养等级
	LDataPack.writeInt(npack, nutritionexp) -- 蕴养经验
	LDataPack.flush(npack)
end

--[[
    @desc: 发送指定子阵特质信息
    author:{author}
    time:2020-02-13 24:02:28
    --@actor:
	--@roleId: 角色编号
	--@subId: 子阵id
    @return:
]]
local function sendSubTezhiInfo(actor,roleId,subId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DemonCircle, Protocol.sDemonCircleCmd_TezhiInfo) -- 79-4
	LDataPack.writeShort(npack, roleId) -- 角色index
	LDataPack.writeShort(npack, subId) -- 子法阵id
	DEBUG(actor,"特质信息发送 subId:" .. subId)
	if(not DemonCirSkillConfig) then
		DEBUG(actor,"没找到特质配置:" .. subId)
	end
	LDataPack.writeShort(npack, #DemonCirSkillConfig) -- 特质数量
	for tezhiId,v in ipairs(DemonCirSkillConfig) do
		local tezhilv = GetSubTezhiLevel(actor,roleId,subId,tezhiId)
		LDataPack.writeShort(npack, tezhiId) -- 特质id
		LDataPack.writeShort(npack, tezhilv) -- 特质等级
		DEBUG(actor,"子阵id:" .. subId .. " 特质id:" .. tezhiId .. " 特质等级:" .. tezhilv)
	end
	LDataPack.flush(npack)
end

--[[
    @desc: 特质升级
    author:{author}
    time:2020-02-20 16:59:59
    --@actor:
	--@roleId:
	--@subId: 
    @return:
]]
local function TeZhiTryLevelUp(actor, roleId, subId)
	DEBUG(actor,"特质升级,子阵id:" .. subId)
	local flag = false -- flag,标志本次是否升级
	local nutritionLv = GetNutritionLevel(actor, roleId, subId) -- 获取角色子阵蕴养等级
	-- 看一下是否激活新特质
	for tezhiId,tezhiconfig in pairs(DemonCirSkillConfig) do
		local tezhiCurLv = GetSubTezhiLevel(actor,roleId,subId,tezhiId) -- 特质当前等级
		for tezhiNextLv = tezhiCurLv+1, #tezhiconfig do -- 遍历所有等级
			--DEBUG(actor,"特质尝试升级 subId:" .. subId .. " 特质id:" .. tezhiId)
			local specificTezhiConf = tezhiconfig[tezhiNextLv]
			if(nutritionLv >= specificTezhiConf.needLevel) then -- 达到激活标准
				SetSubTezhiLevel(actor,roleId,subId,tezhiId,tezhiNextLv) -- 特质升到下一级
				--DEBUG(actor,"特质升级成功 subId:" .. subId .. " 特质id:" .. tezhiId .. " 当前等级:" .. tezhiNextLv)
				flag = true
			else
				--DEBUG(actor,"特质尝试升级失败了 subId:" .. subId .. " 特质id:" .. tezhiId .. " 当前等级:" .. GetSubTezhiLevel(actor,roleId,subId,tezhiId))
				break -- 继续下一个特质升级
			end
		end
	end
	if(flag) then
		sendSubTezhiInfo(actor, roleId, subId) -- 发送特质信息
	end
end
--[[
    @desc: 升级角色子阵的蕴养等级
    author:{author}
    time:2020-02-20 16:49:47
    --@actor:玩家对象
	--@roleId:角色id
	--@subId: 子阵id
    @return:
]]
local function NutritionTryLevelUp(actor, roleId, subId)
	DEBUG(actor,"NutritionTryLevelUp 蕴养升级流程,子阵id:" .. subId)
	local flag = false -- 标志,角色子阵蕴养是否升级了
	local curlv = GetNutritionLevel(actor,roleId,subId) -- 子阵蕴养等级
	local curexp = GetNutritionExp(actor,roleId,subId) -- 子阵蕴养经验
	local conf = DemonCirLevelConfig[subId] -- 子阵属性表
	for nextlv=curlv + 1,#conf do -- 防止一次经验加太多,循环 等级已满直接跳过
		local limitexpTmp = conf[nextlv].exp -- 升级条件
		if(curexp >= limitexpTmp) then
			curlv = curlv + 1 -- 等级提升
			curexp = curexp - limitexpTmp -- 经验消耗
			SetNutritionLevel(actor,roleId,subId,curlv) -- 设置等级
			SetNutritionExp(actor,roleId,subId,curexp) -- 设置经验
			flag = true
			DEBUG(actor,"NutritionTryLevelUp 蕴养升级成功,子阵id:" .. subId .. " 当前等级:" .. curlv .. " 当前经验:" .. curexp)
		else
			break
		end
	end
	sendNutritionInfo(actor, roleId, subId) -- 发送蕴养信息
	if(flag) then
		
		TeZhiTryLevelUp(actor, roleId, subId) -- 升级特质
		updateDemonAttr(actor,roleId) -- 属性修改
	else
		DEBUG(actor,"NutritionTryLevelUp 蕴养未升级,子阵id:" .. subId .. " 当前等级:" .. curlv .. " 当前经验:" .. curexp)
	end
end

--[[
    @desc: 蕴养增加经验
    author:{author}
    time:2020-02-12 17:36:49
    --@actor:
	--@packet: 
    @return:
]]
local function NutritionExpAdd(actor, packet)
	local roleId = LDataPack.readShort(packet) -- 角色索引
	local subId = LDataPack.readShort(packet) -- 子法阵编号
	DEBUG(actor,"蕴养增加经验,子阵id:" .. subId)
	local curlv = GetNutritionLevel(actor,roleId,subId)
	if curlv >= #DemonCirLevelConfig[subId] then
		LOG(actor,"NutritionExpAdd lv limit") -- 达到上限
		return
	end
	-- 判断当前阵眼等级限制的蕴养等级
	local eyelv = GetArrayEyeLevel(actor,roleId,subId)
	if(not DemonCirTalentConfig[subId]) then
		LOG(actor," NutritionExpAdd DemonCirTalentConfig[subId] not exist,subId:" .. subId)
		return
	end
	if(not DemonCirTalentConfig[subId][eyelv]) then
		LOG(actor," NutritionExpAdd DemonCirTalentConfig[subId][eyelv] not exist,subId:" .. subId .. " eyelv:" .. eyelv)
		return
	end
	local eyelimitlv = (DemonCirTalentConfig[subId][eyelv].limintlevel or -1)
	if(curlv >= eyelimitlv) then
		LOG(actor,"NutritionExpAdd arrayeye lv limit this level,limit lv:" .. eyelimitlv .. " curlv:" .. curlv) -- 阵眼等级限制蕴养等级上限
		return
	end

	local specificConf = DemonCirLevelConfig[subId][curlv+1]

	-- 判断物品是否足够
	local costItemid = specificConf.cost.id
	local costCount = specificConf.cost.count
	local addexp = specificConf.specialBaseExp*costCount -- 累加的经验
	local limitexp = specificConf.exp

	local itemCount = LActor.getItemCount(actor, costItemid)
	if(itemCount<costCount) then
		LOG(actor,"NutritionExpAdd item is not enough")
		return
	end
	LActor.costItem(actor, costItemid, costCount, "action_demoncircle_NutritionExp") -- 消耗道具,阵眼升级
	local curexp = GetNutritionExp(actor,roleId,subId)
	curexp = curexp + addexp
	SetNutritionExp(actor,roleId,subId,curexp)
	-- 蕴养升级
	NutritionTryLevelUp(actor, roleId, subId) 
end

--[[
    @desc: 发送指定潜能点信息
    author:{author}
    time:2020-02-13 15:16:33
    --@actor:
	--@roleId:
	--@subId:
	--@qiannengId: 
    @return:
]]
local function SendQiannengInfo(actor,roleId,subId)
	local studycount = GetQiannengStudycount(actor,roleId,subId)
	if(studycount>=20000) then -- 防止short后期太大,限定在1W-2W
		studycount = 10000 -- 配置里目前没这个高
	end

	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DemonCircle, Protocol.sDemonCircleCmd_PotentialpointInfo) -- 79-3
	LDataPack.writeShort(npack, roleId) -- 角色index
	LDataPack.writeShort(npack, subId) -- 子法阵id
	LDataPack.writeShort(npack, #DemonCirBaseConfig[subId].qianneng) -- 子阵潜能数量
	LDataPack.writeShort(npack, studycount) -- 领悟次数
	if(not DemonCirBaseConfig[subId]) then
		DEBUG(actor,"SendQiannengInfo DemonCirBaseConfig[subId] not exist,subId:" .. subId)
		sendTip(actor,"SendQiannengInfo DemonCirBaseConfig[subId] not exist,subId:" .. subId, 2)
		return
	end
	for _,qiannengIdTmp in pairs(DemonCirBaseConfig[subId].qianneng or {}) do
		local activeFlag = GetQiannengActiveFlag(actor,roleId,subId,qiannengIdTmp)
		local extravalue = GetQiannengExtravalue(actor,roleId,subId,qiannengIdTmp)
		LDataPack.writeShort(npack, qiannengIdTmp) -- 潜能id
		LDataPack.writeShort(npack, activeFlag) -- 激活状态
		LDataPack.writeInt(npack, extravalue) -- 额外值
		DEBUG(actor,"角色编号:" .. roleId .. " 子阵id:" .. subId .. " 潜能id:" .. qiannengIdTmp .. " 激活标志:" .. activeFlag .. " 领悟次数:" .. studycount .. " 额外:" .. extravalue)
	end
	LDataPack.flush(npack)
end

--[[
    @desc: 修改子阵潜能的信息,这个函数每次领悟的时候调用
    author:{author}
    time:2020-02-21 17:24:12
    --@actor:
	--@roleId:
	--@subId: 
    @return:
]]
local function ChangeSubQiannengInfo(actor,roleId,subId)
	local curStudyCount = GetQiannengStudycount(actor,roleId,subId) -- 当前子阵的领悟次数
	for i,qiannengIdTmp in pairs(DemonCirBaseConfig[subId].qianneng or {}) do
		if(curStudyCount > DemonCirQianNengConfig[qiannengIdTmp].count) then -- 需要随机
			-- 权重随机
			local randomNum = math.random(1.100)
			local addextravalue = 0
			for quanzhong,v in pairs(DemonCirQianNengConfig[qiannengIdTmp].randomattr) do
				if(randomNum > quanzhong) then
					randomNum = randomNum - quanzhong
				else
					addextravalue = math.random(v[1],v[2])
					break
				end
			end
			local oldextravalue = GetQiannengExtravalue(actor,roleId,subId,qiannengIdTmp)
			local sumextravalue = addextravalue + oldextravalue
			SetQiannengExtravalue(actor,roleId,subId,qiannengIdTmp,sumextravalue)
		end
	end
end
-- 角色子法阵升级
local function ArrayeyeLvUp(actor, packet)
	local roleIndex = LDataPack.readShort(packet) -- 角色索引
	local subId = LDataPack.readShort(packet) -- 子法阵编号
	if(not roleIndex or not subId) then
		LOG(actor,"ArrayeyeLvUp roleIndex or subId is nil")
		return
	end
	if (not DemonCirTalentConfig[subId]) then
		LOG(actor,"ArrayeyeLvUp subIdconfig not exist,subId:" .. subId)
		sendTip(actor,"ArrayeyeLvUp subIdconfig not exist,subId:" .. subId)
		return
	end
    local actorId = LActor.getActorId(actor)
	--检测是否可升级
	if false == checkOpenCondition(actor, roleIndex, subId) then 
		return 
	end
	
	local curlevel = GetArrayEyeLevel(actor, roleIndex, subId)
	local conf = DemonCirTalentConfig[subId][curlevel+1] -- 下一级的升级信息
	local itemId = conf.costCount.id
	local costCount = conf.costCount.count

	LActor.costItem(actor, itemId, costCount, "action_demoncircle_eyelvup") -- 消耗道具,阵眼升级
	SetArrayEyeLevel(actor, roleIndex, subId, curlevel + 1) -- 升级
	if(curlevel == 0) then
		NutritionTryLevelUp(actor, roleIndex, subId) -- 蕴养在激活时要升到1级
		DEBUG(actor,"蕴养激活,角色index:" .. roleIndex .. " 法阵编号:" .. subId)
	end
	updateDemonAttr(actor, roleIndex) -- 计算属性
	sendArrayEyeInfo(actor,roleIndex,subId)
	DEBUG(actor,"升级结果,角色id:" .. roleIndex .. " 法阵编号:" .. subId .. " 法阵目前等级:" .. curlevel + 1)
end

--[[
    @desc: 技能点领悟
    author:{author}
    time:2020-02-13 13:19:28
    --@actor:
	--@packet: 
    @return:
]]
local function QiannengStudy(actor, packet)
	local roleId = LDataPack.readShort(packet) -- 角色索引
	local subId = LDataPack.readShort(packet) -- 子法阵编号
	local qiannengId = LDataPack.readShort(packet) -- 潜能点编号

	local nutritionlv = GetNutritionLevel(actor,roleId,subId)
	local curcount = GetQiannengStudycount(actor,roleId,subId) -- 当前子阵的领悟次数
	if(not DemonCirLevelConfig[subId]) then
		DEBUG(actor,"DemonCirLevelConfig[subId] not exist,subId:" .. subId)
		return
	end
	if(not DemonCirLevelConfig[subId][nutritionlv]) then
		DEBUG(actor,"DemonCirLevelConfig[subId] not exist,subId:" .. subId .. " nutritionlv:" .. nutritionlv)
		return
	end
	if(curcount >= (DemonCirLevelConfig[subId][nutritionlv].lingwuLimint or 0) ) then
		LOG(actor,"QiannengStudy study limit,curstudycount:" .. curcount .. " limitcount:" .. DemonCirLevelConfig[subId][nutritionlv].lingwuLimint) -- 领悟次数达到当前等级上限
		DEBUG(actor, "领悟次数达到上限,当前已领悟:" .. curcount .. " 子阵id:" .. subId .. " 蕴养等级:" .. nutritionlv .. " 限制领悟次数:" .. DemonCirLevelConfig[subId][nutritionlv].lingwuLimint)
		--sendTip(actor,"领悟次数达到上限,当前已领悟:" .. curcount .. " 子阵id:" .. subId .. " 蕴养等级:" .. nutritionlv .. " 限制领悟次数:" .. DemonCirLevelConfig[subId][nutritionlv].lingwuLimint)
		return
	end

	local costitemid = DemonCirQianNengConfig[qiannengId].costandcount.id
	local costcount = DemonCirQianNengConfig[qiannengId].costandcount.count

	local owncount = LActor.getItemCount(actor, costitemid)  -- 拥有的道具数量
	if(owncount<costcount) then
		LOG(actor,"QiannengStudy item is not enough")
		return 
	end
	LActor.costItem(actor, costitemid, costcount, "action_demoncircle_QiannengStudy") -- 消耗道具,阵眼升级
	local curcount = GetQiannengStudycount(actor,roleId,subId) -- 当前领悟次数
	curcount = curcount + 1
	SetQiannengStudycount(actor,roleId,subId,curcount)
	ChangeSubQiannengInfo(actor,roleId,subId) -- 修改子阵潜能信息
	SendQiannengInfo(actor,roleId,subId) -- 发送子阵潜能点信息
	updateDemonAttr(actor,roleId) -- 重新计算属性
end

local function SendHuanhuaInfo(actor,roleId)
	local huanhuaId = GetHuanhuaId(actor, roleId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_DemonCircle, Protocol.sDemonCircleCmd_Huanhua) -- 79-5
	LDataPack.writeShort(npack, roleId) -- 角色index
	LDataPack.writeShort(npack, huanhuaId) -- 幻化id
	LDataPack.flush(npack)
end

-- 请求幻化 79-5
local function Huanhua(actor,packet)
	DEBUG(actor,"设置幻化")
	local roleId = LDataPack.readShort(packet) -- 角色索引
	local huanhuaId = LDataPack.readShort(packet) -- 设置的幻化id
	SetHuanhuaId(actor, roleId, huanhuaId)
	SendHuanhuaInfo(actor,roleId)
end

-- 给C++发数据用 法阵系统等级
local function packDemonCircleData(actor, roleId, npack)
	if not actor then return end
	if not roleId then return end
	if not npack then LOG(actor,"packDemonCircleData:npack nil") return end
	
	local huanhuaId = GetHuanhuaId(actor,roleId)
	LDataPack.writeShort(npack, huanhuaId)
	LDataPack.writeShort(npack, #DemonCirBaseConfig) -- 子法阵数量
	for subId,_ in ipairs(DemonCirBaseConfig) do -- 按顺序来
		LDataPack.writeShort(npack, subId) -- 子阵Id
		local eyelv = GetArrayEyeLevel(actor,roleId,subId)
		--DEBUG(actor,"角色编号:" .. roleId ..  "法阵id:" .. subId .. " 等级:" .. eyelv)
		LDataPack.writeShort(npack, eyelv) -- 子阵眼等级
		local nutritionlv = GetNutritionLevel(actor,roleId,subId) 
		LDataPack.writeShort(npack, nutritionlv) -- 蕴养等级
		local nutritionexp = GetNutritionExp(actor,roleId,subId) 
		LDataPack.writeInt(npack, nutritionexp) -- 蕴养经验
		local tezhicount = #DemonCirSkillConfig 
		LDataPack.writeShort(npack, tezhicount) -- 特质数量
		for tezhiId,_2 in ipairs(DemonCirSkillConfig) do
			LDataPack.writeShort(npack, tezhiId) -- 特质id
			local tezhilv = GetSubTezhiLevel(actor,roleId,subId,tezhiId)
			LDataPack.writeShort(npack, tezhilv) -- 特质等级
		end
		local studycount = GetQiannengStudycount(actor,roleId,subId)
		LDataPack.writeShort(npack, studycount) -- 子阵的领悟次数
		local qiannengcount = #(DemonCirBaseConfig[subId].qianneng or {})
		LDataPack.writeShort(npack, qiannengcount) -- 潜能数量
		for _3,qiannengId in ipairs(DemonCirBaseConfig[subId].qianneng) do
			LDataPack.writeShort(npack, qiannengId) -- 潜能点id
			local activeflag = GetQiannengActiveFlag(actor,roleId,subId,qiannengId)
			LDataPack.writeShort(npack, activeflag) -- 激活状态
			local extravalue = GetQiannengExtravalue(actor,roleId,subId,qiannengId)
			LDataPack.writeInt(npack, extravalue) -- 额外属性值
		end
	end
end

--local function initGlobalData()
--[[
	-- 判断是否开启该功能,这里只看开服天数,不主动判断,一直开启
	local openServerDay = System.getOpenServerDay() + 1 -- 开服天数
	if(openServerDay < DemonCirConfig.openserverday) then
		return
	end
]]

-- 初始化角色属性
local function InitDemonCircle(actor)
	local roleCount = LActor.getRoleCount(actor)
	for roleId=0,roleCount-1 do
		updateDemonAttr(actor,roleId)
	end
end

-- 获取经验 金币相关的加成
function updateAttributes(actor, sysType)
	-- 获取3角色阵眼对经验,金币的加成数值
	--specialattribute.goldEx = 1 -- 金币
	--specialattribute.expEx  = 2 -- 经验
	local goldadd,expadd = GetGoldExpJiaCheng(actor)
	specialattribute.add(actor,specialattribute.goldEx,goldadd,sysType) -- 金币加成
	specialattribute.add(actor,specialattribute.expEx,expadd,sysType) -- 经验加成
end

actorevent.reg(aeInit,InitDemonCircle)
netmsgdispatcher.reg(Protocol.CMD_DemonCircle, Protocol.cDemonCircleCmd_ArrayeyeLvUp, ArrayeyeLvUp) -- 阵眼升级 79-1
netmsgdispatcher.reg(Protocol.CMD_DemonCircle, Protocol.cDemonCircleCmd_NutritionExpAdd, NutritionExpAdd) -- 蕴养增加经验(会触发蕴养升级和特质升级) 79-2
netmsgdispatcher.reg(Protocol.CMD_DemonCircle, Protocol.cDemonCircleCmd_PotentialpointStudy, QiannengStudy) -- 潜能点领悟(达到次数激活,然后随机) 79-3
-- 79-4特质信息
netmsgdispatcher.reg(Protocol.CMD_DemonCircle, Protocol.cDemonCircleCmd_Huanhua, Huanhua) -- 潜能点领悟(达到次数激活,然后随机) 79-3
_G.packDemonCircleData = packDemonCircleData -- 法阵信息给c++


local gmsystem    = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers

gmHandlers.demonitem = function(actor, args)
	local actorid = LActor.getActorId(actor) 
	for i,v in ipairs(DemonCirTalentConfig) do
		local itemid = v[1].costCount.id
		actorawards.giveAwardBase(actor, AwardType_Item, itemid, 1000, "gm:" .. actorid)
	end
	local itemid2 = DemonCirLevelConfig[1][1].cost.id
	actorawards.giveAwardBase(actor, AwardType_Item, itemid2, 1000, "gm:" .. actorid)
	for i,v in pairs(DemonCirQianNengConfig) do
		local itemid3 = v.costandcount.id
		actorawards.giveAwardBase(actor, AwardType_Item, itemid3, 1000, "gm:" .. actorid)
	end
	actorawards.giveAwardBase(actor, AwardType_Item, 200012, 1000, "gm:" .. actorid)
end

-- 子阵信息
local function GetSubInfo(actor,roleId,subId,strlog)
	strlog.log = strlog.log .. "		角色编号:" .. roleId .. " 法阵编号:" .. subId .. " 阵眼等级:" .. GetArrayEyeLevel(actor,roleId,subId) .. "\n"
	strlog.log = strlog.log .. "		蕴养等级:" .. GetNutritionLevel(actor,roleId,subId) .. " 蕴养经验:" .. GetNutritionExp(actor,roleId,subId) .. "\n"
	strlog.log = strlog.log .. "		领悟次数:" .. GetQiannengStudycount(actor,roleId,subId) .. "\n"
	for tezhiId,v in ipairs(DemonCirSkillConfig) do
		strlog.log = strlog.log .. "		特质编号:" .. tezhiId .. " 特质等级:" .. GetSubTezhiLevel(actor,roleId,subId,tezhiId) .. "\n"
	end
	for _,qiannengId in ipairs(DemonCirBaseConfig[subId].qianneng) do
		local strflag = "未激活"
		if(1==GetQiannengActiveFlag(actor,roleId,subId,qiannengId)) then
			strflag = "已激活"
		end
		strlog.log = strlog.log .. "		潜能编号:" .. qiannengId .. " 激活状态:" .. strflag .. " 额外属性:" .. GetQiannengExtravalue(actor,roleId,subId,qiannengId) .. "\n"
	end
end
-- 获取角色信息
local function GetRoleInfo(actor,roleId,strlog)
	for subId,v in ipairs(DemonCirBaseConfig) do
		strlog.log = strlog.log .. "	子阵编号:" .. subId .. "\n"
		for subId,v in ipairs(DemonCirBaseConfig) do
			GetSubInfo(actor,roleId,subId,strlog)
		end
	end
end

-- 玩家信息
local function GetActorInfo(actor,strlog)
	local roleCount = LActor.getRoleCount(actor)
	for roleId=0,roleCount-1 do
		strlog.log = strlog.log .. "角色编号:" .. roleId .. "\n"
		GetRoleInfo(actor,roleId,strlog)
	end

end
-- @getdemoninfo 0 1 角色id,子阵id
gmHandlers.info = function(actor, args)
	local strlog = {}
	strlog.log = ""
	local roleId = tonumber(args[1]) -- 角色索引
	local subId = tonumber(args[2]) -- 子阵编号
	local roleCount = LActor.getRoleCount(actor)
	if(roleId) then
		if(tonumber(roleId) >= tonumber(roleCount) or tonumber(roleId)<0) then
			sendTip(actor,"角色id 0-2")
			return false
		end
	end
	if(subId) then
		if(tonumber(subId)>#DemonCirBaseConfig or tonumber(subId) < 1) then
			sendTip(actor," 子阵id 1-6")
			return
		end
	end
	if(roleId and subId) then
		GetSubInfo(actor,roleId,subId,strlog)
	elseif(roleId) then
		GetRoleInfo(actor,roleId,strlog)
	else
		GetActorInfo(actor,strlog)
	end
	sendTip(actor,strlog.log)
	DEBUG(actor,strlog.log)
	return true
end

gmHandlers.cleardemon = function(actor, args)
	local var = LActor.getStaticVar(actor)
	var.demoncircledata = nil
end

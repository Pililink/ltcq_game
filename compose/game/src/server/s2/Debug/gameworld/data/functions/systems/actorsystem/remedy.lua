-- 临时事务补救系统
module("remedy", package.seeall)

-- 补救系统
function getRemedyVar(actor)
	local var = LActor.getStaticVar(actor)
	if (var == nil) then return end
	if (var.remedy == nil) then var.remedy = {} end
	return var.remedy
end

-- 补救标志（每次叠加）
local flag = 11

-- 实际补救操作（每次修改实现这个即可）
function doRemedyDetail(actor,actorconf)
--[[
	local actorid = LActor.getActorId(actor)
	print(actorid .. "------------------------------------------------------触发补偿")
	-- 补偿暗殿BOSS次数
	darkhallbosssystem.setBossBelongLeftCount(actor, 3)

	local mail_data = {}
	mail_data.head = "新战区特别活动奖励错误补偿"
	mail_data.context = "新战区特别活动奖励错误补偿"
	mail_data.tAwardList = actorconf.remedyrecharge
	mailsystem.sendMailById(actorid, mail_data)
]]
	print(actorid .. "------------------------------------------------------补偿结束")
end

----------------------------------------------------

-- 是否能补救
function canRemedy(actor)
	local var = getRemedyVar(actor)
	if (var == nil) then return false end

	if var.flag == nil then
		return true
	else
		if var.flag < flag then
			return true
		end
	end

	return false
end

-- 补救操作
function doRemeddy(actor, actorconf)

	local var = getRemedyVar(actor)
	if (var == nil) then return end

	doRemedyDetail(actor,actorconf)
	var.flag = flag
end

-- 登录触发补救
function onLogin(actor)
	local sid = System.getServerId()
	local conf = RemedyAccountConf[sid]
	print("尝试补偿了-----------------------------------")
	if(not conf) then print(sid .. "没有配置") end
	-- 单服
	if conf ~= nil then
		print("--------------------------------------单服补偿")
		local actorid = LActor.getActorId(actor)
		for _,actorconf in pairs(conf) do
			if actorid == actorconf.actorid then
				if canRemedy(actor) then
					print("[Remedy] : Ok (onLogin) actorid "..actorid)
					doRemeddy(actor,actorconf)
				end
				return
			end
		end
	-- 全服
	elseif RemedyAccountConf[0] ~= nil then
		print("--------------------------------------全服补偿")
		local conf = RemedyAccountConf[0]
		if canRemedy(actor) and conf[0] then
			--print("可以补偿")
			doRemeddy(actor,conf[0])
		end
	end
end

actorevent.reg(aeUserLogin, onLogin)

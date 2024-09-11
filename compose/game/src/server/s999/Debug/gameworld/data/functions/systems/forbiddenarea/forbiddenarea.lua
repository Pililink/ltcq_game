-- 神器禁地
module("forbiddenarea", package.seeall)

-- 日志
local function LOG(log, actor)
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[ERROR]:forbiddenarea." .. log .. " actorid:" .. actorid)
end

local function DEBUG(log, actor) -- 上线后把内容注掉
	--[[
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[DEBUG]:forbiddenarea." .. log .. " actorid:" .. actorid)
	]]
end

local function INFO(log, actor) -- 上线后把内容注掉
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[INFO]:forbiddenarea." .. log .. " actorid:" .. actorid)
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
	--角色数据
forbiddenareadata = {
	leftchallengecount, -- 剩余挑战次数(退出副本扣1次且当前神器分数清零)
	todayBuyCount, -- 今日已购买次数
	curshenqiscore, -- 当前神器分数,高于100踢出副本
	resurgencecd,  	复活cd
	rebornEid, 		复活定时器句柄
	exitEid, -- 退出副本定时器
}
]]

--[[
	ins.data = {
		floor, --楼层
		confId, -- 配置表的编号
	}
]]


local baseConfig = ShenQiJinDiBase
local config = ShenQiJinDiConfig
local floorConfig = ShenQiJinDiNumberConfig
local gFuBenData = {
--[[
gFuBenData = {
	[floor] = { -- 楼层
		floorNum, -- 楼层数
		fbHandle, -- 副本句柄
		bossGroup={		
			[config.id] = { -- boss配置的id
				confId, -- conf.id
				fbHandle, -- 副本句柄
				monster, -- 刷新的怪物指针
				bossId, -- monster的id
				bossRefreshTime, -- boss下次刷新时间
				bossBelong  当前boss归属者
				revEid,      boss回血定时器
				shieldIndex, -- 当前护盾编号0开始
			}
		}

	}
	...
}
]]

}


local gEnterLists = {
	-- [fbId] = {
		--[actorId] = 1,
		...
	--} -- 楼层配置id 玩家列表 actorId

}

local gBossIdConfIdMap = { -- bossId 与配置id映射
	--[bossId] = confId, 
}



--[[
    @desc: 获取玩家数据
    author:{author}
    time:2020-05-18 17:15:48
    --@actor: 
    @return:
]]
local function getActorData(actor)
	local var = LActor.getStaticVar(actor)
	if not var then return end
	if(var.forbiddenareadata == nil) then var.forbiddenareadata = {} end
	return var.forbiddenareadata
end

--获取剩余次数
local function getLeftChallengeCount(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.leftchallengecount or baseConfig.shenqizhiliAdd or 1
end

--设置剩余次数
local function setLeftChallengeCount(actor, count)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.leftchallengecount = count
end

--增加或者减少剩余次数
local function addLeftChallengeCount(actor, changeCount)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.leftchallengecount = (actorData.leftchallengecount or 0) + changeCount
	if(actorData.leftchallengecount<0) then 
		actorData.leftchallengecount = 0 
	end
end

--获取今日购买次数
local function getTodayBuyCount(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.todayBuyCount or 0
end

--设置今日购买次数
local function setTodayBuyCount(actor, count)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.todayBuyCount = count
end


--获取神器值
local function getCurShenqiScore(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.curshenqiscore or 0
end

-- 设置神器值
local function setCurShenqiScore(actor, score)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.curshenqiscore = score
end

--增加或减少当前神器值
local function addCurShenqiScore(actor, score)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.curshenqiscore = (actorData.curshenqiscore or 0) + score
	if(actorData.curshenqiscore < 0) then
		actorData.curshenqiscore = 0
	end
end

--获取复活cd
local function getResurgenceCd(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.resurgencecd or 0
end

local function setResurgenceCd(actor, cdTime)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.resurgencecd = cdTime
end

--获取复活定时器id
local function getRebornEid(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.rebornEid
end

local function setRebornEid(actor, rebornEid)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	actorData.rebornEid = rebornEid
end

--[[
    @desc: 设置复活信息
    author:{author}
    time:2020-05-20 14:19:53
    --@actor:
	--@rebornEid:复活定时器id
	--@cdTime: 复活cd(下次复活时间)
	--@flag : 是否取消定时器
    @return:
]]
local function setRebornInfo(actor, rebornEid, cdTime, flag)
	local oldRebornEid = getRebornEid(actor)
	setRebornEid(actor, rebornEid)
	setResurgenceCd(actor, cdTime)
	if(rebornEid and flag) then
		LActor.cancelScriptEvent(actor, oldRebornEid) -- 取消定时器
	end
end


--获取退出副本定时器
local function getExitEid(actor)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	return actorData.exitEid
end

--[[
    @desc: 设置定时器
    author:{author}
    time:2020-05-20 17:57:46
    --@actor:
	--@exitEid:定时器id,可以为nil,此时cancelFlag要为true
	--@cancelFlag: 是否取消定时器
    @return:
]]
local function setExitEid(actor, exitEid, cancelFlag)
	local actorData = getActorData(actor)
	if(not actorData) then return end
	if(nil == exitEid and actorData.exitEid and cancelFlag) then
		LActor.cancelScriptEvent(actor, actorData.exitEid)
		actorData.exitEid = nil
		return
	end
	if(not actorData.exitEid) then
		actorData.exitEid = exitEid -- 直接给赋值
		return
	end
end

local function setExitEidInfo(actor, rebornEid, cdTime)
	--setRebornEid(actor, rebornEid)
	--setResurgenceCd(actor, rebornEidm)
end

--[[
    @desc: 添加到列表
    author:{author}
    time:2020-05-18 15:51:48
	--@actor: 
	--@fbId: 副本id
    @return:
]]
local function add2EnterLists(actor, fbId)
	if(not actor or not gEnterLists[fbId]) then return end
	gEnterLists[fbId] = gEnterLists[fbId] or {} -- 这里用fbId是因为fbId唯一
	local actorId = LActor.getActorId(actor)
	gEnterLists[fbId][actorId] = 1
end

local function removeFromEnterLists(actor, fbId)
	if(not actor or not gEnterLists[fbId]) then return end
	gEnterLists[fbId][actorId] = nil
end



-- 获取楼层信息
local function getFloorInfo(floorNum)
	if(floorNum<1 or floorNum>#floorConfig) then
		LOG("getFloorInfo fail,floorNum overstep the boundary")
		return
	end
	if(not gFuBenData[floorNum]) then
		gFuBenData[floorNum] = {}
	end
	return gFuBenData[floorNum]
end

--副本句柄confId 楼层id
local function getFbHandle(floorNum)
	local floorInfo = getFloorInfo(floorNum)
	if(not floorInfo) then
		LOG("getFbHandle getFbHandle fail")  
		return 
	end
	return floorInfo.fbHandle
end

local function setFbHandle(floorNum, fbHandle)
	local floorInfo = getFloorInfo(floorNum)
	if(not floorInfo) then
		LOG("setFbHandle setFbHandle fail")  
		return 
	end
	floorInfo.fbHandle = fbHandle
end



--获取boss组
local function getBossGroup(floor)
	local floorInfo = getFloorInfo(floor)
	if(not floorInfo) then 
		LOG("getBossGroup floorInfo is nil")
		return 
	end
	if(not floorInfo.bossGroup) then floorInfo.bossGroup = {} end
	return floorInfo.bossGroup
end

--[[
    @desc: 获取boss信息
    time:2020-03-26 09:12:37
    --@id: 配置文件中的id
	@return:
	@note:一个副本不会出现相同的boss,所以可以使用bossId查找归属者
]]
local function getBossInfo(confId)
	if not config[confId] then -- 无配置
		LOG("getBossInfo config not exist,confId:" .. confId)
		return
	end
	local floor = config[confId].number
	local bossGroup = getBossGroup(floor)
	if(not bossGroup) then 
		LOG("getBossInfo fail")
		return 
	end
	if(not bossGroup[confId]) then 
		bossGroup[confId] = {} 
	end
	return bossGroup[confId]
end



--获取boss的归属者
local function getBossBelong(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("getBossBelong getBossBelong fail") 
		return 
	end
	return bossInfo.bossBelong
end

--设置boss的归属者
local function setBossBelong(confId, bossBelong)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then return end
	bossInfo.bossBelong = bossBelong
end

--根据bossId获取配置id
local function getConfIdByBossId(bossId)
	return gBossIdConfIdMap[bossId]
end

--获取monster
local function getMonster(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("getBossBelong getMonster fail")  
		return 
	end
	return bossInfo.monster
end

--设置monster
local function setMonster(confId, monster)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then return end
	bossInfo.monster = monster
end

local function getFbHandleByBossConfId(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("getFbHandleByBossConfId fail") 
		return 
	end
	return bossInfo.fbHandle
end

local function setFbHandleByBossConfId(confId, fbHandle)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("setFbHandleByBossConfId fail") 
		return 
	end
	bossInfo.fbHandle = fbHandle
end


--获取回血定时器
local function getRevEid(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("getBossBelong getRevEid fail")
		return 
	end
	return bossInfo.revEid
end

local function setRevEid(confId, revEid)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then return end
	bossInfo.revEid = revEid
end

--[[
    @desc: 获取boss刷新时间
    author:{author}
    time:2020-05-16 17:39:27
    --@confId: 
    @return:
]]
local function getBossRefreshTime(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then
		LOG("getBossBelong getBossRefreshTime fail")
		return 
	end
	return bossInfo.bossRefreshTime or 0
end

local function setBossRefreshTime(confId, refreshTime)
	local bossInfo = getBossInfo(confId)
	bossInfo.bossRefreshTime = refreshTime
end

local function getBossRefreshLeftTime(confId)
	local leftTime = getBossRefreshTime(confId) - System.getNowTime()
	return leftTime>0 and leftTime or 0
end

--获取随机位置
local function getActorRandomPos(confId)
	local conf = floorConfig[confId]
	if(not conf) then
		DEBUG("getActorRandomPos 找不到随机点配置,confId:" .. confId) 
		return 35,20 
	end
	local randompos = math.random(1,#conf.enterPos)
	local posX = conf.enterPos[randompos].x
	local posY = conf.enterPos[randompos].y
	return posX,posY
end




local function getShiled(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then 
		LOG("getBossBelong getShiled fail")
		return
	end
	return bossInfo.shieldindex or 0
end

local function setShiled(confId, index)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then 
		return
	end
	bossInfo.shieldindex = index
end

-- 刷新护盾状态
local function refreshShiled(confId)
	setShiled(confId, 0)
end

--[[
    @desc: 获取boss下一个护盾编号
    author:{author}
    time:2020-05-26 10:13:43
    --@confId: 
    @return:
]]
local function getNextShiled(confId)
	local bossInfo = getBossInfo(confId)
	if(not bossInfo) then 
		LOG("getBossBelong getNextShiled fail")
		return 0
	end
	local nextIndex = bossInfo.shieldindex + 1
	if(not config[confId].shield) then return 0 end
	return config[confId].shield[nextIndex] and nextIndex or 0
end

--使用道具增加挑战次数
local function useItemAddChallengecount(actor, changeCount)
	local leftCount = getLeftChallengeCount(actor)
	if(leftCount>=baseConfig.shenqijindiBelongMaxCount) then
		return false
	end
	addLeftChallengeCount(actor, changeCount)
	return true
end

-- 获取boss的配置id
local function getBossConfId(floor, monster)
	local bossGroup = getBossGroup(floor)
	for _,v in pairs(bossGroup) do
		if(v.monster == monster) then
			return v.confId
		end
	end
	return nil
end

--[[
    @desc: 发送个人信息 剩余次数 当前神器值
    author:{author}
    time:2020-05-19 15:57:14
    --@actor: 
    @return:
]]
local function sendPersonalData(actor)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_ForbiddenArea, Protocol.sForbiddenAreaCmd_PersonalInfo) -- 82-2
	if(not pack) then return end
	LDataPack.writeShort(pack, getLeftChallengeCount(actor)) -- 剩余次数
	LDataPack.writeShort(pack, getCurShenqiScore(actor)) -- 当前神器值
	LDataPack.writeShort(pack, getTodayBuyCount(actor)) -- 今日购买次数
	LDataPack.flush(pack)
end


--[[
    @desc: 是否可以拿归属
    author:{author}
    time:2020-06-03 15:54:23
    --@actor:
	--@floor: 当前boss楼层
    @return:
]]
local function canGetBelong(actor,floor) -- 能在本里的都能归属 系统强行退出的10s能打死BOSS算玩家本事,这里不再做过多判断
	-- 判断一下其他boss是否归属于该玩家
	local bossGroup = getBossGroup(floor)
	if(not bossGroup) then
		LOG("canGetBelong bossGroup not exist,floor:" .. floor)
		return false
	end
	for confId,v in pairs(bossGroup) do
		if(getBossBelong(confId) == actor) then
			return false
		end
	end
	return true
end

--通知玩家的复活个人信息 82-4
local function notifyRebornTime(actor, killerHdl)
    local rebornCd = getResurgenceCd(actor) - System.getNowTime()
    if rebornCd < 0 then rebornCd = 0 end
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_ForbiddenArea, Protocol.sForbiddenAreaCmd_ResurgenceInfo) -- 82-4
    LDataPack.writeInt(npack, rebornCd) -- 复活剩余时间
    LDataPack.writeDouble(npack, killerHdl or 0) -- 击杀者名单
	LDataPack.flush(npack)
	DEBUG("发送下一次复活时间,剩余复活时间:" .. rebornCd, actor)
end

--复活定时器
local function reborn(actor, floor)
	if not actor then return end
	notifyRebornTime(actor)
	local posX, posY = getActorRandomPos(floor)
	LActor.relive(actor, posX, posY)
	LActor.stopAI(actor)
end


--[[
    @desc: 发送单一BOSS信息 82-6
    author:{author}
    time:2020-05-28 16:09:42
    --@confId:
	--@actor:接收者
	--@oldBelong: 原归属者
    @return:
]]
local function sendSingleBossInfo(confId, actor, oldBelong)
	local npack = nil
	if actor then -- 单发
		--DEBUG("单发BOSS归属者信息")
        npack = LDataPack.allocPacket(actor, Protocol.CMD_ForbiddenArea, Protocol.sForbiddenAreaCmd_SingleBossInfo) -- 82-6
	else -- 副本内群发
		--DEBUG("群发BOSS归属者信息")
        npack = LDataPack.allocPacket()
		LDataPack.writeByte(npack, Protocol.CMD_ForbiddenArea)
        LDataPack.writeByte(npack, Protocol.sForbiddenAreaCmd_SingleBossInfo)
    end
	--local bossInfo = getBossInfo(confId)
	local curBossBelong = getBossBelong(confId)
	LDataPack.writeShort(npack, confId) -- 配置id+
	LDataPack.writeInt(npack, getBossRefreshLeftTime(confId)) -- 配置的id
   	LDataPack.writeDouble(npack, oldBelong and LActor.getHandle(oldBelong) or 0) -- 原归属者
	LDataPack.writeDouble(npack, curBossBelong and LActor.getHandle(curBossBelong) or 0) -- 新归属者
	if actor then
		if(curBossBelong) then
			local actorId = LActor.getActorId(curBossBelong)
			local actorName = LActor.getActorName(actorId)
			local logtmp = "玩家进入副本,boss配置id:" .. confId .. " 归属信息handler:" .. (LActor.getHandle(curBossBelong) or -1) .. " 归属者名称:" .. actorName
			DEBUG(logtmp)
		else
			DEBUG("玩家进本 当前无归属者")
		end
        LDataPack.flush(npack)
	else
        Fuben.sendData(getFbHandleByBossConfId(confId), npack)
    end
end
--[[
    @desc: 创建BOSS
    author:{author}
    time:2020-05-16 14:34:24
    --@confId: config配置的id
    @return:
]]
local function refreshBossTimer(confId)
	refreshShiled(confId) -- 刷新BOSS护盾
	local conf = config[confId]
	if not conf then 
		LOG("refreshBossTimer:conf nil, confId:" .. confId) 
		return 
	end
	local bossInfo = getBossInfo(confId)
	if not bossInfo then 
		LOG("refreshBossTimer:bossInfo nil, confId:".. confId) 
		return 
	end
	--刷怪
	local ins = instancesystem.getInsByHdl(bossInfo.fbHandle)
	if ins then
		local bossId = conf.bossId
		local posX = conf.bossPos and conf.bossPos.x or 0
		local posY = conf.bossPos and conf.bossPos.y or 0
		local monster = Fuben.createMonster(ins.scene_list[1], bossId, posX, posY)
		if not monster then 
			LOG("refreshBossTimer:monster nil, bossId:".. bossId) 
			return 
		end
		bossInfo.monster = monster 
		bossInfo.bossRefreshTime = 0 
		sendSingleBossInfo(confId,nil,nil) -- 通知客户端刷新BOSS信息,只通知副本内的玩家
		if conf.refreshNoticeId then -- boss刷新的广播
			--noticemanager.broadCastNotice(conf.refreshNoticeId, MonstersConfig[bossId].name or "", conf.sceneName)
		end
		INFO("refreshBossTimer: refresh monster success, confId:".. confId)
	end
end

--[[
    @desc: 发送奖励弹框与奖励 82-7
    time:2020-03-26 10:11:21
    --@actor:
	--@reward:奖励列表
	--@confId:配置的编号,看config
    @return:
]]
local function sendReward(actor, reward, confId)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_ForbiddenArea, Protocol.sForbiddenAreaCmd_BossBelongReward) -- 82-7
	LDataPack.writeShort(npack, confId) -- 配置id
	LDataPack.writeShort(npack, #reward) -- 奖励数量
	for k, v in pairs(reward or {}) do
		LDataPack.writeInt(npack, v.type) -- 类型
		LDataPack.writeInt(npack, v.id) -- itemId
		LDataPack.writeInt(npack, v.count) -- 数量
	end
	LDataPack.flush(npack)
	local actorId = LActor.getActorId(actor)
	local mailData = {head=baseConfig.shenqijindiTitle , context=baseConfig.shenqijindiContent, tAwardList=reward} -- boss归属奖励
	mailsystem.sendMailById(actorId, mailData) 
end

--清空boss归属者
local function clearBossBelongInfo(ins, actor, floornum)
	local floor = ins and ins.data.floor or floornum
	local confId = 0
	local bossGroup = getBossGroup(floor)
	if(not bossGroup) then return end
	for confIdTmp,bossInfoTmp in pairs(bossGroup) do
		if(getBossBelong(confIdTmp) == actor) then -- 本人是归属者
			confId = confIdTmp
			break
		end
	end
	if(confId == 0) then return end -- 不是任何BOSS的归属者
    setBossBelong(confId, nil)
	sendSingleBossInfo(confId, nil, actor)
	--计时无归属回血
	if baseConfig.revivalTime and not getRevEid(confId) then -- 有回血时间且当前无定时器
		local revEid = LActor.postScriptEventLite(nil, baseConfig.revivalTime * 1000, function(_, confId)
			setRevEid(confId, nil)
			local monster = getMonster(confId)
			if monster then
				LActor.changeHp(monster, LActor.getHpMax(monster))
				refreshShiled(confId) -- 刷新BOSS护盾
			end
		end, confId)
		setRevEid(confId, revEid) -- 记录当前这个定时器
	end
end

--进入公告
local function sendEnterNoticeId(actor, noticeId, conf)
	local actorId = LActor.getActorId(actor)
	local actorName = LActor.getActorName(actorId)
	--noticemanager.broadCastNotice(noticeId, actorName, conf.sceneName or "")
end

--进入副本的时候
local function onEnterFb(ins, actor)
	local fbId = ins.id
	local floor = ins.data.floor -- 楼层
	local conf = floorConfig[floor]
	LActor.setCamp(actor, LActor.getActorId(actor))
	LActor.stopAI(actor)
	add2EnterLists(actor, fbId)

	for _,confId in ipairs(conf.bossId) do -- bossId列表
		sendSingleBossInfo(confId, actor,nil) -- 逐条发送BOSS信息
	end
	if(conf.enterNoticeId) then
		sendEnterNoticeId(actor, conf.enterNoticeId, conf) -- 进入公告
	end
end

--退出的处理
local function onExitFb(ins, actor)
	DEBUG("onExitFb 玩家退出副本", actor)
	local actorId = LActor.getActorId(actor)
	clearBossBelongInfo(ins, actor) --尝试清理归属者信息,如果是归属者的话

	--删除玩家复活定时器
	if (getRebornEid(actor)) then
		setRebornInfo(actor, nil, nil, true)
	end

 	-- 删除玩家退出定时器
	if (getExitEid(actor)) then
		setExitEid(actor, nil, true)
	end

	-- 神器值高于100 清理
	if(getCurShenqiScore(actor) >= 0) then -- baseConfig.shenqizhiliMax
		--减少一次次数
		addLeftChallengeCount(actor, -1)
		--清理积分
		setCurShenqiScore(actor,0)
	end


	--退出把AI恢复
	local role_count = LActor.getRoleCount(actor)
	for i = 0,role_count - 1 do
		local role = LActor.getRole(actor,i)
		LActor.setAIPassivity(role, false)
	end

	removeFromEnterLists(actor, fbId) -- 清理副本玩家列表
end

--[[
    @desc: 玩家离线
    time:2020-03-26 10:08:37
    --@ins:
	--@actor: 
    @return:
]]
local function onOffline(ins, actor)
	LActor.exitFuben(actor)
end

-- 下发护盾信息 82-8
local function notifyShield(fbHandle, curshield, maxShield, bossId)
    local npack = LDataPack.allocPacket()
    LDataPack.writeByte(npack, Protocol.CMD_ForbiddenArea)
	LDataPack.writeByte(npack, Protocol.sForbiddenAreaCmd_BossShield)
	LDataPack.writeInt(npack, bossId) -- bossId
	LDataPack.writeInt(npack, curshield) -- 当前护盾剩余时间
    LDataPack.writeInt(npack, maxShield) -- 护盾最大持续时间
    Fuben.sendData(fbHandle, npack)
end


--boss收到伤害的时候
local function onBossDamage(ins, monster, value, attacker, res)
	local floor = ins.data.floor
	local confId = getBossConfId(floor, monster) -- 获取boss的confId
	if(not confId) then return end
	--DEBUG("BOSS收到伤害,楼层数:" .. floor .. " 配置id:" .. confId)
	local bossBelong = getBossBelong(confId)
	local fbHandle = getFbHandle(floor)
	--第一下攻击者为boss归属者,且该玩家在本里
	if nil == bossBelong and fbHandle == LActor.getFubenHandle(attacker) then
        local actor = LActor.getActor(attacker)
        if actor and false == LActor.isDeath(actor) and canGetBelong(actor, floor) then
			--改变归属者
			DEBUG("改变归属者")
			setBossBelong(confId, actor)
			DEBUG("onBossDamage bossConfId:" .. confId .. " 设置归属者为:" .. LActor.getActorId(actor))
			sendSingleBossInfo(confId, nil, nil) -- 广播归属者信息

			--怪物攻击新的归属者
            if getMonster(confId) then LActor.setAITarget(getMonster(confId), LActor.getLiveByJob(actor)) end

			--有新归属的时候清定时器
			if getRevEid(confId) then
				LActor.cancelScriptEvent(nil, getRevEid(confId))
				setRevEid(confId, nil)
			end
		end
	end

	-- 护盾
	local hpPer = res.ret / LActor.getHpMax(monster) * 100 -- 当前血量百分比 (实际血量/总血量*100)
	local shieldIndex = getNextShiled(confId)
	if(shieldIndex == 0) then return end
	local conf = config[confId].shield[shieldIndex]

	if(hpPer <= conf.hp) then -- 血量条件
		DEBUG("onBossDamage 设置护盾")
		setShiled(confId, shieldIndex) -- 设置护盾索引
		LActor.SetInvincible(monster, true) -- 设置无敌护盾
		notifyShield(getFbHandleByBossConfId(confId), conf.shield, conf.shield, config[confId].bossId) -- 提醒客户端开盾
		LActor.postScriptEventLite(nil, (conf.shield or 0) * 1000, function() -- 注册定时器取消护盾
			LActor.SetInvincible(monster, false)
			notifyShield(getFbHandleByBossConfId(confId), 0, conf.shield, config[confId].bossId)
		end)
	end
end

--[[
    @desc: 玩家所有角色死亡时
    author:{author}
    time:2020-05-20 14:26:52
    --@ins:指路->instance.lua 的 instance结构
	--@actor:
	--@killerHdl: 击杀者handle
    @return:
]]
local function onActorDie(ins, actor, killerHdl)
	if not actor then 
		DEBUG("onActorDie 未找到角色")
		return 
	end
	DEBUG("角色死亡处理")
	local et = LActor.getEntity(killerHdl)
	if not et then
		DEBUG("onActorDie 找不到击杀者") 
	end
	local confId = 0 -- 当前玩家是某BOSS的归属者
	local floor = ins.data.floor
	local bossGroup = getBossGroup(floor)
	for confIdTmp,v in pairs(bossGroup) do
		if(getBossBelong(confIdTmp) == actor) then -- 本人是归属者
			confId = confIdTmp
			break
		end
	end
    local killerActor = LActor.getActor(et)
    --boss归属处理
    if confId ~= 0 then
		--归属者被玩家打死，该玩家是新归属者
		if killerActor and LActor.getFubenHandle(killerActor) == ins.handle and canGetBelong(killerActor,floor) then
			setBossBelong(confId, killerActor)
			--有新归属的时候清定时器
			if getRevEid(confId) then
				LActor.cancelScriptEvent(nil, getRevEid(confId))
				setRevEid(confId, killerActor)
			end
            --怪物攻击新的归属者
			if getMonster(confId) then LActor.setAITarget(getMonster(confId), et) end
        else
            setBossBelong(confId, nil)
            clearBossBelongInfo(ins, actor)
        end
        --广播归属者信息
		sendSingleBossInfo(confId, nil, actor)
    end

    --目标是玩家才停止ai
    if LActor.getActor(LActor.getAITarget(LActor.getLiveByJob(killerActor))) and
    	LActor.getActor(LActor.getAITarget(LActor.getLiveByJob(killerActor))) == actor then
    	LActor.stopAI(killerActor)
    end

	if(killerActor) then -- 被玩家击杀增加神器分数
		addCurShenqiScore(actor, baseConfig.shenqizhiliDie)
		sendPersonalData(actor)
		if( ( getCurShenqiScore(actor) >= baseConfig.shenqizhiliMax) and (not getExitEid(actor)) ) then -- 分数超过且无定时器
			local exitEid = LActor.postScriptEventLite(actor, baseConfig.returnTime * 1000, function(_, confId)
				setExitEid(actor, nil)
				LActor.exitFuben(actor) -- 退出副本 玩家退出副本时要取消这个定时器
			end, confId)
			setExitEid(actor, exitEid)
		end
	end

    --复活定时器
	local resurgenceCd = System.getNowTime() + baseConfig.rebornCd
	local rebornEid = LActor.postScriptEventLite(actor, baseConfig.rebornCd * 1000, reborn, floor)
	setRebornInfo(actor, rebornEid, resurgenceCd)
    notifyRebornTime(actor, killerHdl)
end

--BOSS死亡时候的处理
local function onMonsterDie(ins, mon, killerHdl)
	--DEBUG("onMonsterDie 怪物死亡触发,bossid:" .. ins.data.bossId)
	--getBossConfId(floor, monster)
	local bossId = 0
	local confId = 0
	local monId = Fuben.getMonsterId(mon) -- 死亡怪物的怪物id
	for confIdTmp,v in ipairs(config) do
		if(v.bossId == monId) then
			bossId = v.bossId
			confId = confIdTmp
			break
		end
	end
	if bossId == 0 then
		DEBUG("onMonsterDie 小怪死亡,monId:" .. monId)
		return
	end
	
	local conf = config[confId]

	--发送奖励
	local belonger = getBossBelong(confId)
	if(belonger) then -- 有归属者才做发放奖励操作 
		local actor = belonger
		addCurShenqiScore(actor, conf.shenqizhili) --增加神器debuff值
		local dropId = conf.belongReward
		local rewards = drop.dropGroup(dropId)
		sendReward(actor, rewards, confId) 
		local shenqiScore = getCurShenqiScore(actor)
		if(not shenqiScore) then 
			LOG("DMWFLAG神器分数找不到")
			return 
		end
		if( ( shenqiScore >= baseConfig.shenqizhiliMax) and (not getExitEid(actor)) ) then -- 分数超过且无定时器
			local exitEid = LActor.postScriptEventLite(actor, baseConfig.returnTime * 1000, function(_, confId)
				setExitEid(actor, nil)
				LActor.exitFuben(actor) -- 退出副本 玩家退出副本时要取消这个定时器
			end, confId)
			setExitEid(actor, exitEid)
		end
		sendPersonalData(belonger)
		clearBossBelongInfo(ins, belonger)
		local fbHandle = getFbHandleByBossConfId(confId)
		local monster = getMonster(confId)
		local actors = Fuben.getAllActor(fbHandle)
		if actors and monster then -- 停止玩家AI
			for i=1, #actors do
				local target = LActor.getAITarget(LActor.getLiveByJob(actors[i]))
				if target == monster then LActor.stopAI(actors[i]) end
			end
		end
	end

	--boss刷新定时器
	LActor.postScriptEventLite(nil, conf.refreshTime * 1000, function() refreshBossTimer(confId) end)
	setBossRefreshTime(confId, System.getNowTime() + conf.refreshTime)
	setMonster(confId, nil)
	sendSingleBossInfo(confId, nil, nil) -- boss信息更新
	
end

-- 请求复活
local function onResurgence(actor, packet)
    --没有死光不能复活
	if false == LActor.isDeath(actor) then
		LOG("onResurgence: roles not all die", actor)
    	return
	end

	--已经可以不花钱就复活了
    if (getResurgenceCd(actor) < System.getNowTime()) then
    	LOG("onResurgence: can reborn without money", actor)
    	return
    end

	--扣钱
    local yb = LActor.getCurrency(actor, NumericType_YuanBao)
    if baseConfig.rebornCost > yb then
    	LOG("onResurgence money not enough", actor)
    	return
    end
	LActor.changeCurrency(actor, NumericType_YuanBao, -baseConfig.rebornCost, "forbiddenarea resurgence")

    --重置复活cd和定时器
	if getRebornEid(actor) then 
		LActor.cancelScriptEvent(actor, getRebornEid(actor)) 
	end
	setRebornInfo(actor)

	notifyRebornTime(actor)

	--原地复活
	local x, y = LActor.getPosition(actor)
	LActor.relive(actor, x, y)

	LActor.setCamp(actor, LActor.getActorId(actor))
	LActor.stopAI(actor)
end

--取消归属者
local function onCancelBelong(actor, packet)
	local bossId = LDataPack.readInt(packet) -- bossId
	if(not bossId) then return end
	local confId = getConfIdByBossId(bossId)
	if(not confId) then return end
	local bossBelong = getBossBelong(confId) -- 获取当前boss的归属者信息
	if(not bossBelong or bossBelong ~= actor) then
		LOG("onCancelBelong  belonger not exist",actor)
		return
	end
	clearBossBelongInfo(nil, actor, config[confId].number)
	LActor.stopAI(actor)
end

--购买挑战次数
local function onBuyChallengeCount(actor)
	if(getLeftChallengeCount(actor) ~= 0) then
		DEBUG("onBuyChallengeCount 剩余次数不为0") 
		return 
	end
	local todayBuyCount = getTodayBuyCount(actor)
	if(todayBuyCount>=baseConfig.shenqijindibuyBelongCount) then 
		DEBUG("今日购买次数达到上限", actor)
		return
	end
	if(LActor.getCurrency(actor, NumericType_YuanBao) < baseConfig.shenqijindibuyBelongCountPrice) then return end
	LActor.changeCurrency(actor, NumericType_YuanBao, -baseConfig.shenqijindibuyBelongCountPrice, "forbiddenarea buyChallengeCount")
	addLeftChallengeCount(actor, 1)
	setTodayBuyCount(actor,todayBuyCount+1)
	sendPersonalData(actor)
end


--[[
    @desc: 创建单个副本
    author:{author}
    time:2020-05-16 14:25:40
    --@conf: floorConfig[i]
    @return:
]]
local function createBossFb(conf)
	local floor = conf.number
	local fbId = conf.fbid
	local fbHandle = Fuben.createFuBen(fbId) -- 创建副本
	local ins = instancesystem.getInsByHdl(fbHandle)
	if not ins then
		LOG("createBossFb:ins nil,confNumber:".. conf.number .. " fbid:" .. fbId)
		DEBUG("创建副本失败,副本层数:" .. conf.number .. " 副本id:" .. fbId)
		return
	end
	ins.data.floor = floor
	ins.multipleFlag = true -- 单副本多BOSS
	local floorInfo  = getFloorInfo(floor)

	floorInfo.floorNum = floor
	floorInfo.fbHandle = fbHandle

	for _,bossConfId in ipairs(conf.bossId) do -- boss组,起名为策划原因
		--DEBUG("尝试获取bossInfo")
		local boss = getBossInfo(bossConfId)
		if(not boss) then 
			LOG("createBossFb fail,bossConfId:" .. bossConfId)
			--return
		end
		local bossInfo = getBossInfo(bossConfId)
		bossInfo.confId = bossConfId
		bossInfo.fbHandle = fbHandle
		refreshBossTimer(bossConfId)
		INFO("createBossFb success, bossConfId:".. bossConfId)
	end
end

--[[
    @desc: 创建副本
    author:{author}
    time:2020-05-16 14:22:56
    @return:
]]
local function createAllFb()
	for i=1, #floorConfig do -- 3个副本
		createBossFb(floorConfig[i])
	end
end

--[[
    @desc: 发送一层BOSS的信息
    author:{author}
    time:2020-05-16 17:57:15
    --@actor:
	--@floor: 
    @return:
]]
local function sendFloorBossInfo(actor, floor)
	local pack = LDataPack.allocPacket(actor, Protocol.CMD_ForbiddenArea, Protocol.sForbiddenAreaCmd_BossInfo) -- 82-1
	if not pack then return end
	local conf = floorConfig[floor] and floorConfig[floor].bossId
	if(not conf) then return end
	LDataPack.writeShort(pack, floor) -- 楼层数
	LDataPack.writeShort(pack, #conf) -- boss数量
	for _,confId in pairs(conf) do
		local bossRefreshTime = getBossRefreshTime(confId)
		local leftTime = getBossRefreshTime(confId) - System.getNowTime()
		leftTime = leftTime>0 and leftTime or 0 -- boss剩余刷新时间
		LDataPack.writeShort(pack, confId) -- 配置id
		LDataPack.writeInt(pack, leftTime) -- 剩余刷新时间
	end
	LDataPack.flush(pack)
end


--[[
    @desc: 请求神器禁地boss信息
    author:{author}
    time:2020-05-16 17:23:33
    --@actor:
	--@cpacket: 
    @return:
]]
local function onReqBossInfo(actor,cpacket)
	local floor = LDataPack.readShort(cpacket)
	if(not floor) then
		DEBUG("onReqBossInfo floor not exist") 
		return 
	end
	if(floor < 1 or floor > #floorConfig) then
		return
	end
	sendFloorBossInfo(actor, floor)
end

--82-2
local function onPersonalInfo(actor,cpacket)
	sendPersonalData(actor)
end


--[[
    @desc: 请求挑战boss
    author:{author}
    time:2020-05-18 11:14:16
    --@actor:
	--@cpacket: 
    @return:
]]
local function onChallenge(actor, cpacket)
	local floorNum = LDataPack.readShort(cpacket)
	if(not floorConfig[floorNum]) then -- 检查条件
		DEBUG("发送的楼层不对",actor)
		return
	end
	local conf = floorConfig[floorNum]
	local fbId = conf.fbid
	local fbHandle = gFuBenData[floorNum].fbHandle
	if(not fbHandle) then 
		LOG("onChallenge handleFuben is nil,floorNum:" .. floorNum)
		return 
	end
	if(LActor.getZhuanShengLevel(actor) < (floorConfig.zhuanshenglv or 0)) then
		DEBUG("转生等级不够",actor) 
		return 
	end -- 转生等级不够
	-- 判断挑战次数和神器值
	local leftCount = getLeftChallengeCount(actor)
	if(leftCount <= 0) then -- 没挑战次数不给进
		DEBUG("挑战次数不够", actor)
		return
	end
	local shenqiScore = getCurShenqiScore(actor)
	if(shenqiScore >= (baseConfig.shenqizhiliMax or 100)) then
		setLeftChallengeCount(actor, leftCount - 1)
		setCurShenqiScore(actor, 0)
		sendPersonalData(actor) -- 发送角色数据
		if(getLeftChallengeCount(actor) < 0) then
			DEBUG("清理后次数不足")
			return
		end
	end

	-- 随机一个点
	local posX,posY = getActorRandomPos(floorNum)
	--进入副本
	local ins = instancesystem.getInsByHdl(fbHandle)
	LActor.enterFuBen(actor, fbHandle, ins.scene_list[1], posX, posY)
	DEBUG("onChallenge 进入副本" .. fbId .. "(".. posX .. "," .. posY .. ")", actor)
end

-- 定时器任务分钟级,给副本里的玩家加禁地值 并且踢符合条件的玩家出本
local function onTimer()
	DEBUG("onTimer 分钟定时器触发")
	for floor,_ in ipairs(floorConfig) do -- 楼层
		local fbHandle = getFbHandle(floor)
		local actors = Fuben.getAllActor(fbHandle)
		if(actors) then
			DEBUG("onTimer 当前副本有玩家,floor:" .. floor .. " fbHandle:" .. fbHandle .. " 玩家数量:" .. #actors)
			for i = 1,#actors do
				local actor = actors[i]
				if(actor) then
					local actorId = LActor.getActorId(actor)
					DEBUG("onTimer 定时更新,actorId:" .. actorId)
					DEBUG("增加神器之力,actorId:" .. actorId .. " 增加点数:" .. baseConfig.shenqizhiliAdd)
					addCurShenqiScore(actor, baseConfig.shenqizhiliAdd) -- 增加神器分数
					sendPersonalData(actor)
					if( (getCurShenqiScore(actor) >= baseConfig.shenqizhiliMax) and (not getExitEid(actor)) ) then -- 分数超过且无定时器
						local exitEid = LActor.postScriptEventLite(actor, baseConfig.returnTime * 1000, function(_, floor)
							setExitEid(actor, nil)
							LActor.exitFuben(actor) -- 退出副本 玩家退出副本时要取消这个定时器
						end, floor)
						setExitEid(actor, exitEid)
					end
				end
			end
		else
			DEBUG("onTimer 当前副本无玩家,floor:" .. floor .. " fbHandle:" .. (fbHandle or 0))
		end
	end
end


--登陆
local function onLogin(actor)
	sendPersonalData(actor)
end

--新一天
local function onNewday(actor)
	addLeftChallengeCount(actor, (baseConfig.shenqijindiBelongCount or 1)) -- 增加一次次数
	setCurShenqiScore(actor, 0) -- 清空神器值
	setTodayBuyCount(actor,0)
end


--启动初始化
local function initData()
	if not System.isCommSrv() then
		return -- 普通服才注册
	end
	if(#config == 0) then
		INFO("initData config is null")
		return
	end

	--注册副本事件
	for _, conf in pairs(floorConfig) do
		DEBUG("神器禁地注册事件,副本id:" .. conf.fbid)
		insevent.registerInstanceEnter(conf.fbid, onEnterFb) -- 进入副本事件
		insevent.registerInstanceMonsterDamage(conf.fbid, onBossDamage) -- 怪物受到攻击
		insevent.registerInstanceExit(conf.fbid, onExitFb) -- 玩家退出副本
		insevent.registerInstanceOffline(conf.fbid, onOffline) -- 玩家下线
		insevent.registerInstanceActorDie(conf.fbid, onActorDie) -- 玩家死亡
		insevent.registerInstanceMonsterDie(conf.fbid, onMonsterDie) -- boss死亡
	end
	actorevent.reg(aeUserLogin, onLogin)
	actorevent.reg(aeNewDayArrive, onNewday)
	netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_BossInfo, onReqBossInfo) -- 82-1 请求一层BOSS信息 1
	netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_PersonalInfo, onPersonalInfo) --82-2 请求个人信息
	netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_Challenge, onChallenge) --82-3 请求挑战神器禁地
    netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_Resurgence, onResurgence) -- 82-4 请求复活
	netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_CancelBelong, onCancelBelong) -- 82-5 取消归属
	netmsgdispatcher.reg(Protocol.CMD_ForbiddenArea, Protocol.cForbiddenAreaCmd_BuyChallengeCount, onBuyChallengeCount) -- 82-9 购买挑战次数
	createAllFb() -- 创建副本 一定要放在注册副本事件之后否则无法触发事件
	engineevent.regGameTimer(onTimer) -- 定时器任务分钟级,给副本里的玩家加禁地值 并且踢符合条件的玩家出本
	for confId,v in ipairs(config) do
		gBossIdConfIdMap[v.bossId] = confId
	end
end


table.insert(InitFnTable, initData)

local gmsystem = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers
gmHandlers.sendFloor = function(actor, args)
        local floor = 1
		local leftTime = 120
		local bossNum = 6
        local pack = LDataPack.allocPacket(actor, 82, 1) -- 82-1
		LDataPack.writeShort(pack, floor) -- 楼层数
		print("楼层数:" .. floor)
		LDataPack.writeShort(pack, bossNum) -- boss数量
		print("boss数量:" .. bossNum)
        for i=1,bossNum do
				LDataPack.writeShort(pack, i) -- 配置id
				print("配置id:" .. i)
				LDataPack.writeInt(pack, leftTime) -- 剩余刷新时间
				print("剩余刷新时间:" .. leftTime)
        end
        LDataPack.flush(pack)
end

gmHandlers.setcamp = function(actor, args)
	local camp = tonumber(args[1])
	if(camp==1) then
		LActor.setCamp(actor, LActor.getActorId(actor))
		sendTip(actor,"个人阵营切换为全体敌对模式", 2)
		return true
	else
		LActor.setCamp(actor, LActor.getGuildId(actor))
		sendTip(actor,"个人阵营切换为非同行会敌对模式", 2)
		return true
	end
	return false
end

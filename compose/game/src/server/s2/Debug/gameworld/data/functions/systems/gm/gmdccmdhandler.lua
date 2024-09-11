
-- 处理后台发出的gm命令
module("systems.gm.gmdccmdhander" , package.seeall)
setfenv(1, systems.gm.gmdccmdhander)

if nil == gmDcCmdHandlers then gmDcCmdHandlers = {} end
local lianfuutils = require("systems.lianfu.lianfuutils")

local gmsystem    = require("systems.gm.gmsystem")

local gmHandlers = gmsystem.gmCmdHandlers
local gmDcCmdHandlers = gmDcCmdHandlers

local luaex = require("utils.luaex")
local lua_string_split = luaex.lua_string_split

local gmdochangeName = guildsystem.gmdochangeName
local gmhandleChangeMemo = guildsystem.gmhandleChangeMemo

local noticeEidList = {}	--公告定时器id，用于删除公告

gmDcCmdHandlers.rsf = function(dp)
	System.reloadGlobalNpc(nil, 0)
	return true
end

gmDcCmdHandlers.gc = function(dp)
	System.engineGc()
	return true
end

gmDcCmdHandlers.resettianti = function(dp)
	tiantirank.resetRankingList()
	System.getStaticVar().tianti_gm = System.getStaticVar().tianti_gm or {}
	local sysvar = System.getStaticVar().tianti_gm
	sysvar.gm_reset_time = os.time()
	local actors = System.getOnlineActorList()
	if actors == nil then
		return
	end
	for i=1,#actors do
		tianti.gmResetTianti(actors[i])
	end
end


local function asyncAddTrainExp(actor,exp)
	print(LActor.getActorId(actor) .. " addTrainExp " .. exp)
	trainsystem.addTrainExp(actor,exp)
	LActor.saveDb(actor)
end

gmDcCmdHandlers.addtrainexp = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
	if actor_id then print("addtrainexp "..actor_id) end
	local exp      = tonumber(LDataPack.readString(dp))
	asynevent.reg(actor_id,asyncAddTrainExp,exp)
	return true
end

local function asyncDeleteBagItem(actor,itemid,num)
	print(LActor.getActorId(actor) .. " asyncDeleteItem " .. itemid)
	local conf = ItemConfig[itemid]
	if conf == nil then return end

	if conf.id then
		if LActor.getItemCount(actor, conf.id) < num then
			num = LActor.getItemCount(actor, conf.id)
		end
		LActor.costItem(actor, conf.id, num, "gmcmd deleteItem "..itemid)
	end
	LActor.saveDb(actor)
end

gmDcCmdHandlers.deleteBagItem = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
	local itemid   = tonumber(LDataPack.readString(dp))
	local num   = tonumber(LDataPack.readString(dp))
	asynevent.reg(actor_id,asyncDeleteBagItem,itemid,num)
	return true
end

gmDcCmdHandlers.restRechargeRecord = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
	local actor = LActor.getActorById(actor_id)
	if not actor then return false end
	rechargeitem.resetRecord(actor)
end

gmDcCmdHandlers.restAllRechargeRecord = function(dp)
	local resetFlag = tonumber(LDataPack.readString(dp)) -- 0:立即重置 1:延时重置
	local strTime = LDataPack.readString(dp)
	if resetFlag == 0 then
		local nextResetTime = System.getNowTime()
		rechargeitem.resetAllRecord(resetFlag,nextResetTime)
	else
		local Year,Month,Day,Hour,Minute = string.match(strTime,"(%d+)-(%d+)-(%d+) (%d+):(%d+)")
		print("重置双倍时间:" .. Year.. "-" .. Month .. "-" .. Day .. " " .. Hour.. ":" ..Minute)
		local nextResetTime = System.timeEncode(Year,Month,Day,Hour,Minute, 0)
		rechargeitem.resetAllRecord(resetFlag,nextResetTime)
	end
		return true
end

gmDcCmdHandlers.addstoreintegral = function ( dp )
	local  actor_id = tonumber(LDataPack.readString(dp))
	local count = tonumber(LDataPack.readString(dp))
	local var = System.getStaticVar()
	if var.store == nil then
		var.store = {}
	end
	if var.store[actor_id] == nil then
		var.store[actor_id] = count
	else
		var.store[actor_id] = var.store[actor_id] + count
	end
end


gmDcCmdHandlers.exportranking = function(db)
	LActor.updateRanking()
	local i = RankingType_Power
	local f = io.open("./ranking_"..System.getServerId()..".log","w")
	f:write("serverid,排行类型,排名,用户名,用户id,等级,转生等级,总战力,翅膀总战力,战士战力,法师战力,历练等级,宝石总等级\n")
	while (i < RankingType_Count) do
		local var = LActor.getRankDataByType(i)
		if var ~= nil then
			local str = ""
			local j = 1
			while (j <= 3) do
				if var[j] ~= nil then
					local basic_data = toActorBasicData(var[j])
					str = str   .. System.getServerId()
					str = str .. "," .. i
					str = str .. "," .. j
					str = str .. "," .. basic_data.actor_name
					str = str .. "," .. basic_data.actor_id
					str = str .. "," .. basic_data.level
					str = str .. "," .. basic_data.zhuansheng_lv
					str = str .. "," .. basic_data.total_power

					str = str .. "," .. basic_data.total_wing_power
					str = str .. "," .. basic_data.warrior_power
					str = str .. "," .. basic_data.mage_power
					str = str .. "," .. basic_data.train_level
					str = str .. "," .. basic_data.total_stone_level
					str = str .. "\n"
				end
				j = j + 1
			end
			f:write(str)
		end
		i = i + 1
	end
	f:close()
end

--修复因为缓存而不能登陆的玩家
gmDcCmdHandlers.setActorDataValid = function(dp)
	local acotr_id = tonumber(LDataPack.readString(dp))
	System.setActorDataValid(System.getServerId(), acotr_id, true)
end

--设置禁言
gmDcCmdHandlers.shutup = function(dp)

	local acotr_id = tonumber(LDataPack.readString(dp))
	local time     = tonumber(LDataPack.readString(dp))
	System.shutup(acotr_id,time)
end

--解封禁言
gmDcCmdHandlers.releaseshutup = function(dp)
	local acotr_id = tonumber(LDataPack.readString(dp))
	System.releaseShutup(acotr_id)

end


gmDcCmdHandlers.buymonthcard = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
    if actor_id == nil then
        print("acotrid is nil")
        return
    end
	monthcard.buyMonth(actor_id)
end

gmDcCmdHandlers.buyprivilegemonthcard = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
    if actor_id == nil then
        print("acotrid is nil")
        return
    end
    privilegemonthcard.buyPrivilegeMonth(actor_id)
end

gmDcCmdHandlers.buyprivilege = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
    if actor_id == nil then
        print("acotrid is nil")
        return
    end
	monthcard.buyPrivilegeCard(actor_id)
end

gmDcCmdHandlers.peakdost = function(dp)
	local st = tonumber(LDataPack.readString(dp))
	peakracesystem.gmDoSt(st)
end

gmDcCmdHandlers.addChapterRecord = function(dp)
    local actor_id = tonumber(LDataPack.readString(dp))
    if actor_id == nil then
        print("actorid is nil")
        return
    end
    achievetask.gmAddRecord(actor_id)
end

gmDcCmdHandlers.sendGlobalMail = function(dp)
	local head = LDataPack.readString(dp)
	local context = LDataPack.readString(dp)
	local item_str = LDataPack.readString(dp)
	-- item_str = item_str .. LDataPack.readString(dp)
	 --item_str = item_str .. LDataPack.readString(dp)
	System.addGlobalMail(head,context,item_str)
end

gmDcCmdHandlers.sendMail = function( dp )
	local head = LDataPack.readString(dp)
	local context = LDataPack.readString(dp)
	local actorid = tonumber(LDataPack.readString(dp))
	local item_str = LDataPack.readString(dp)
	if not actorid then return end
	local function split(str, delimiter)
		if str==nil or str=='' or delimiter==nil then
			return nil
		end

		local result = {}
		for match in (str..delimiter):gmatch("(.-)"..delimiter) do
			table.insert(result, match)
		end
		return result
	end
	local mail_data = {}
	mail_data.head = head
	mail_data.context = context
	mail_data.tAwardList = {}
	local tmp = split(item_str,";")
	if tmp ~= nil then
		for i = 1,#tmp do
			local tbl = split(tmp[i],",")
			if #tbl == 3 then
				local award = {}
				award.type = tonumber(tbl[1])
				award.id = tonumber(tbl[2])
				award.count = tonumber(tbl[3])
				table.insert(mail_data.tAwardList,award)
			end
		end
	end
	mailsystem.sendMailById(actorid,mail_data)
	--print(utils.t2s(mail_data))
end

gmDcCmdHandlers.addnotice = function(dp)
    local content = LDataPack.readString(dp)
    local type = LDataPack.readString(dp)
    local startTime = LDataPack.readString(dp)
    local endTime = LDataPack.readString(dp)
    --单位分钟
    local interval = LDataPack.readString(dp)

    --2016-06-30 13:19:18
    local Y,M,D,d,h,m = string.match(startTime, "(%d+)-(%d+)-(%d+)%s(%d+):(%d+):(%d+)")
    print("on addnotice."..Y.." "..M.." "..D.." "..d.." "..h.." "..m)
    local st = System.timeEncode(Y,M,D,d,h,m)

    Y,M,D,d,h,m = string.match(endTime, "(%d+)-(%d+)-(%d+)%s(%d+):(%d+):(%d+)")
    print("on addnotice."..Y.." "..M.." "..D.." "..d.." "..h.." "..m)
    local et = System.timeEncode(Y,M,D,d,h,m)

    local now = System.getNowTime()
    local delay = st - now
    if delay < 0 then delay = 0 end
    local times = math.floor((et - st)/  (interval * 60))
    if times <= 0 then times = 1 end

    local eid = LActor.postScriptEventEx(nil, delay * 1000, function(actor, type, content)
        broadcastNotice(type, content)
    end,
        interval * 60 * 1000,
        times,
        type, content
    )

	print(eid)

    if eid then
    	noticeEidList[#noticeEidList+1] = {eid,content}
    end
end


gmDcCmdHandlers.delnotice = function(dp)
    local msg = LDataPack.readString(dp)
	for i, k in ipairs(noticeEidList) do
		if k[2] == msg then
			LActor.cancelScriptEvent(nil, k[1])
			break
		end
	end
end



--删除所有公告
gmDcCmdHandlers.delAllNotice = function(dp)
	for i, k in ipairs(noticeEidList) do
		 LActor.cancelScriptEvent(nil, k)
	end
end

gmDcCmdHandlers.kick = function(packet)
    local actorid = tonumber(LDataPack.readString(packet))
    if not actorid then return end
    local actor = LActor.getActorById(actorid, true, true)
    if not actor then return end

    System.closeActor(actor)
    return true
end

gmDcCmdHandlers.repairKnighthood=function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
	local actor = LActor.getActorById(actor_id)
	if not actor then return false end
	local basic_data = LActor.getActorData(actor)
	if basic_data.knighthood_lv > 0 then
		local achievementIds = KnighthoodConfig[basic_data.knighthood_lv-1].achievementIds
		for i,v in pairs(achievementIds or {}) do
			if not v.re or v.re ~= 1 then
				achievetask.finishAchieveTask(actor,v.achieveId,v.taskId)
			end
		end
	end
	return true
end

gmDcCmdHandlers.monupdate = function ()
	System.monUpdate()
	System.reloadGlobalNpc(nil, 0)
	return true
end

gmDcCmdHandlers.resetfame = function (packet)
	local actorid = tonumber(LDataPack.readString(packet))
	if not actorid then return end

	asynevent.reg(actorid, skirmish.gmResetFame)
	return true
end

gmDcCmdHandlers.setGuildUpgradeTime = function(dp)
	local guildid = tonumber(LDataPack.readString(dp))
	local time     = tonumber(LDataPack.readString(dp))
	local guild = LGuild.getGuildById(guildid)
	if guild == nil then
		print("can't find guild:".. tostring(guildid))
		return true
	end

	guildcommon.gmRefreshGuildLevelUpTime(guild, time)
	return true
end

gmDcCmdHandlers.setLoginactivate = function(dp)
	local flag = tonumber(LDataPack.readInt(dp))
	loginactivate.setFlag(flag)
end

gmDcCmdHandlers.itemupdate = function()
	System.itemUpdate()
	System.reloadGlobalNpc(nil, 0)
	return true
end

--合服清数据
gmDcCmdHandlers.hfClearData = function(dp)
	--清除决战沙城霸主信息
	guildbattlefb.rsfOccupyData()
	--检测合服充值档次是否需要重置
	rechargeitem.hefuCheckRestMark()
end

--切换战区清数据
gmDcCmdHandlers.changeWZClearData = function(dp)

    --清除跨服boss数据
	crossbossfb.clearSystemData()
end

gmDcCmdHandlers.hfClearBelongData = function(dp)
	--清除决战沙城归属信息
	guildbattle.rsfBelongData()
end

--开帮派战
gmDcCmdHandlers.ogb = function(dp)
	local isCal = tonumber(LDataPack.readInt(dp))
	guildbattlefb.open()

	if isCal and 1 == isCal then guildbattle.setGlobalTimer() end
end

--开魔界入侵
gmDcCmdHandlers.devilbossopen = function(dp)
	devilbossfb.devilBossOpen()
end

gmDcCmdHandlers.giveCscomsumeRankAward = function(dp)
	CSCumsumeRankNewday()
end

gmDcCmdHandlers.chatMonitoring = function(dp)
	local type = tonumber(LDataPack.readString(dp))
	local msgid = tonumber(LDataPack.readString(dp))
    print("-----------"..msgid.."--"..type)
    if type ~= nil then
    	if type == 1 then
    		chat.delchat(msgid)
    	end
    	if type == 2 then
    		guildchat.clearChatLog(msgid)
    	end
    end
end


local function asyncBuyFund(actor,actorid,activid)
	print("gmbuyFund srcActorId: "..actorid.." activid: "..activid)
    if not pactivitysystem.isPActivityOpened(actor, activid) then
    	return false
    end
	psubactivitytype23.setBuy(actor, activid)
	LActor.saveDb(actor)
end

gmDcCmdHandlers.buyFund = function(dp)
	local actorid = tonumber(LDataPack.readString(dp))
	local activid = tonumber(LDataPack.readString(dp))
    if actorid == nil then
        return false
    end
    if activid == nil then
    	return false
    end

	asynevent.reg(actorid, asyncBuyFund, actorid, activid)
	return true
end

gmDcCmdHandlers.deletechat = function(dp)
	local actor_id = tonumber(LDataPack.readString(dp))
	chat.delActorChat(actor_id)
	return true
end

-- 购买珍宝阁礼包 begin
local function asyncBuyTreasureGift(actor,actorid,itemid) -- 购买珍宝阁礼包
	print("gmBuyTreasureGift srcActorId: "..actorid.." itemid: "..itemid)
	--[[ 判断是否开启
    if not pactivitysystem.isPActivityOpened(actor, activid) then
    	return false
	end
	]]--
	rechargelimitbuy.sendTimePacket(actor,itemid)
	LActor.saveDb(actor)
end

gmDcCmdHandlers.buyTreasureGift = function(dp) -- 购买珍宝阁礼包
	local actorid = tonumber(LDataPack.readString(dp)) -- 指定的角色id
	local itemid = tonumber(LDataPack.readString(dp)) -- 珍宝阁礼包id，详见珍宝阁配置
    if actorid == nil then
        return false
    end
    if itemid == nil then
    	return false
    end

	asynevent.reg(actorid, asyncBuyTreasureGift, actorid, itemid)
	return true
end

-- 删除公会
gmDcCmdHandlers.delguild = function(dp)
	local guild = tonumber(LDataPack.readString(dp)) -- 指定的公会id
	if guild == nil then
		return false
	end

	local guildid = LGuild.getGuildById(guild)
	LGuild.deleteGuild(guildid, "gm")
	return true
end

-- 公会改名
gmDcCmdHandlers.changeguildname = function(dp)
	local guild = tonumber(LDataPack.readString(dp)) -- 指定的公会id
	local name = LDataPack.readString(dp)
	if guild == nil then
		return false
	end

	if name == nil then
		return false
	end
	
	gmdochangeName(guild, name)
	return true
end

-- 修改公会公告
gmDcCmdHandlers.changeguildmemo = function(dp)
	local guild = tonumber(LDataPack.readString(dp)) -- 指定的公会id
	local memo = LDataPack.readString(dp)
	if guild == nil then
		return false
	end

	if memo == nil then
		return false
	end

	gmhandleChangeMemo(guild, memo)
	return true
end

--购买珍宝阁礼包 end

local function SendGmResultToSys(cmdid, result)
	-- 发送结果给后台，说明gameworld执行了gm命令
	if cmdid ~= 0 then
--		SendUrl("/gmcallback.jsp", string.format("&cmdid=%d&serverid=%d&ret=%s", cmdid, System.getServerId(), result))
	end
	return true
end

_G.CmdGM = function(cmd, cmdid, dp)
	if nil == gmDcCmdHandlers then gmDcCmdHandlers = {} end

	print("on gmcmd: "..tostring(cmd))
	local handle = gmDcCmdHandlers[cmd]
	if nil == handle then return end
	if not System.isServerStarted() then
		print("server not started. discarded.")
		SendGmResultToSys(cmdid, "false")
	else
		local result = handle(dp)
		if not result then result = false end
		local result = tostring(result)
		SendGmResultToSys(cmdid, result)
	end
end

local dbretdispatcher = require("utils.net.dbretdispatcher")

function onDbGmCmd(reader)
	local cmd = LDataPack.readString(reader)
	local cmdid = LDataPack.readInt(reader)

	CmdGM(cmd, cmdid, reader)
end
--todo 整理数据库消息时再改
dbretdispatcher.reg(dbGlobal, 5, onDbGmCmd)


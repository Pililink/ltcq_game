module("chat", package.seeall)


global_chat_cd         = ChatConstConfig.chatCd
global_chat_list_max   = ChatConstConfig.saveChatListSize
global_chat_char_len   = ChatConstConfig.chatLen
global_chat_send_level = ChatConstConfig.openLevel
global_chat_vip_level  = ChatConstConfig.vipLevel

chatMonitor_world = 1 		-- 世界
chatMonitor_guild = 2 		-- 工会
chatMonitor_friend = 3 		-- 私聊

--[[ 聊天监控的个人数据
	chatmonitor
	{
		[chatMonitor_world],--类型,存储次数
		counter[类型] = 1 	记录的最大msgid
	}
--]]
local function getChatMonitorData(actor)

	local var = LActor.getStaticVar(actor) 
	if var == nil then
		print("ERROR getChatMonitorData")
		return nil
	end
	if var.chatmonitor == nil then var.chatmonitor = {} end
	local monitor = var.chatmonitor
	if monitor[chatMonitor_world] == nil then monitor[chatMonitor_world] = 1 end
	if monitor[chatMonitor_guild] == nil then monitor[chatMonitor_guild] = 1 end
	if monitor[chatMonitor_friend] == nil then monitor[chatMonitor_friend] = 1 end
	return var.chatmonitor
end

local function addChatMonitor(actor,msgtype,guildid,msg)

	if msgtype < chatMonitor_world or msgtype > chatMonitor_friend then
		print("ERROR addChatMonitor1")
		return nil
	end

	local monitor = getChatMonitorData(actor)
	if monitor == nil then
		print("ERROR addChatMonitor2")
		return
	end

	if monitor and monitor[msgtype] == nil then
		print("ERROR addChatMonitor3")
		return
	end

	local actorData = LActor.getActorData(actor)
	if not actorData then
		print("ERROR addChatMonitor4")
		return 
	end

	local msgid = monitor[msgtype]
	local actorid = actorData.actor_id
	local actorname = actorData.actor_name;
	local accountname = actorData.account_name;
	System.saveChatMonitoring(actorid, msgtype, msgid, guildid, actorname, accountname, msg)
	monitor[msgtype] = monitor[msgtype] + 1
end

--存储世界聊天记录
function addChatMonitorWorld(actor,msg,globalid)
	addChatMonitor(actor,chatMonitor_world,globalid,msg)
end

--存储公会聊天记录
function addChatMonitorGuild(actor,guildid,msg)
	addChatMonitor(actor,chatMonitor_guild,guildid,msg)
end

--存储私人聊天记录
function addChatMonitorFriend(actor,friendid,msg)
	addChatMonitor(actor,chatMonitor_friend,friendid,msg)
end

local function chsize(char)
	if not char then
		print("not char")
		return 0
	elseif char > 240 then
		return 4
	elseif char > 225 then
		return 3
	elseif char > 192 then
		return 2
	else
		return 1
	end
end

-- 计算utf8字符串字符数, 各种字符都按一个字符计算
-- 例如utf8len("1你好") => 3
function utf8len(str)
	local len = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local char = string.byte(str, currentIndex)
		currentIndex = currentIndex + chsize(char)
		len = len +1
	end
	return len
end


local function getData(actor)
	local var = LActor.getStaticVar(actor) 

	if var == nil then 
		return nil
	end
	if var.chat == nil then
		var.chat = {}
	end
	if var.chat.cd == nil then 
		var.chat.global_chat_cd = os.time()
	end
	if var.chat.shutup == nil then 
		var.chat.shutup = 0
	end
	if var.chat.chat_size == nil then 
		var.chat.chat_size = 0
	end
	return var.chat
end

function isShutUp(actor)
	local var = getData(actor) 
	if var.shutup > os.time() then 
		print("shutup  " .. (var.shutup - os.time()))
		return true
	end
	return false
end

local function rsfData(actor)
	local var = getData(actor)
	var.chat_size = 0
end

local function getConfig(actor)
	local power = LActor.getActorData(actor).total_power
	local id = 0
	for i = 1,#(ChatLevelConfig) do 
		local conf = ChatLevelConfig[i]
		if power >= conf.power then 
			id = i
		else 
			break
		end
	end
	return ChatLevelConfig[id]
end

local function getGlobalData()
	local var = System.getStaticChatVar() -- staticDataConfig[CHAT_VAR].data 函数
	if var == nil then 
		return nil
	end
	if var.chat == nil then 
		var.chat = {}
	end
	if var.chat.chat_list_begin == nil then 
		var.chat.chat_list_begin = 0
	end
	if var.chat.chat_list_end == nil then
		var.chat.chat_list_end = 0;
	end
	if var.chat.chat_list == nil then
		var.chat.chat_list = {}
	end
	return var.chat;
end

local function addGlobalList(tbl) -- 加入会话
	if tbl ~= nil then 

		local var = getGlobalData()
		var.chat_list[var.chat_list_end] = tbl
		var.chat_list_end = var.chat_list_end + 1
		while (var.chat_list_end - var.chat_list_begin) > global_chat_list_max do 
			var.chat_list[var.chat_list_begin] = nil
			var.chat_list_begin = var.chat_list_begin + 1
		end
		return var.chat_list_end - 1
	end
	return -1
end

local function sendGlobalList(actor)

	local var = getGlobalData()

	local b = var.chat_list_begin 
	local e = var.chat_list_end

	while (b ~= e) do 
		local tbl = var.chat_list[b]
		if tbl ~= nil and tbl.status == nil then  -- 查看是否被禁言
			local npack = LDataPack.allocPacket(actor, Protocol.CMD_Chat, Protocol.sChatCmd_ChatMsg) -- 30-1 发送消息
			if npack == nil then 
				break
			end
			LDataPack.writeByte(npack,tbl.channe)
			LDataPack.writeUInt(npack,tbl.actor_id)
			LDataPack.writeInt(npack,tbl.sid or 0)
			LDataPack.writeString(npack,tbl.actor_name)
			LDataPack.writeByte(npack,tbl.job)
			LDataPack.writeByte(npack,tbl.sex)
			LDataPack.writeByte(npack,tbl.vip_level)
			LDataPack.writeByte(npack,tbl.monthcard)
			LDataPack.writeByte(npack,tbl.last_tianti_level and tbl.last_tianti_level or 0)
			LDataPack.writeByte(npack,tbl.is_last_tianti_first and tbl.is_last_tianti_first or 0)
			LDataPack.writeByte(npack,tbl.zhuansheng_lv or 0)
			LDataPack.writeShort(npack,tbl.level or 0)
			LDataPack.writeString(npack,tbl.guildName or "")
			LDataPack.writeUInt(npack,tbl.target_actor_id)
			LDataPack.writeString(npack,tbl.msg)
			LDataPack.writeInt(npack,b) --消息编号
			LDataPack.flush(npack)
		end
		b = b + 1
	end

end

local function addBasicData(actor,npack,tbl)
	local data = LActor.getActorData(actor)
	local guild = LActor.getGuildPtr(actor)
	LDataPack.writeUInt(npack,data.actor_id)
	LDataPack.writeInt(npack, LActor.getServerId(actor))
	LDataPack.writeString(npack,data.actor_name)
	LDataPack.writeByte(npack,data.job)
	LDataPack.writeByte(npack,data.sex)
	LDataPack.writeByte(npack,data.vip_level)
	LDataPack.writeByte(npack,data.monthcard)
	LDataPack.writeByte(npack,tianti.getLastTiantiLevel(actor))
	LDataPack.writeByte(npack,tiantirank.isLastWeekFirst(actor) and 1 or 0)
	LDataPack.writeByte(npack,data.zhuansheng_lv)
	LDataPack.writeShort(npack,data.level)
	local guildName = ""
	if guild then guildName = LGuild.getGuildName(guild) end
	LDataPack.writeString(npack,guildName)
	
	if tbl ~= nil then 
		tbl.actor_id = data.actor_id
		tbl.sid = LActor.getServerId(actor)
		tbl.actor_name = data.actor_name
		tbl.job = data.job
		tbl.sex = data.sex
		tbl.vip_level = data.vip_level
		tbl.monthcard = data.monthcard
		tbl.last_tianti_level = tianti.getLastTiantiLevel(actor)
		tbl.is_last_tianti_first = tiantirank.isLastWeekFirst(actor) and 1 or 0
		tbl.zhuansheng_lv = data.zhuansheng_lv
		tbl.level = data.level
		tbl.guildName = guildName
	end


end

function sendSystemTips(actor,level,pos,tips)
	local l = LActor.getZhuanShengLevel(actor) * 1000
	l = l + LActor.getLevel(actor)
	if l < level then 
		return
	end
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Chat, Protocol.sChatCmd_Tipmsg)
	if npack == nil then 
		return
	end
	LDataPack.writeInt(npack,level)
	LDataPack.writeInt(npack,pos)
	LDataPack.writeString(npack,tips)
	LDataPack.flush(npack)
end


local rands = {"游戏耐玩", "五星推荐良心制作!","攻城搞起","仰望高端玩家","传奇之路带我飞","矮油，不错不错","厉害了，大佬",
			"好游戏，慢慢玩","最良心的游戏了","加油，战力搞起来","五转美滋滋","下一个梦想是霸服做大哥","诸君猪年大吉","我是一个好人",
			"好好玩游戏，热爱生活","摸了一下铁血魔王","多想，少说，马上执行","花会再开","自强自信","特喜欢这游戏","笑一笑，十年少",
			"恭喜","感恩","祝福","希望","轻轻松松","简简单单","普普通通","平平常常","和和气气","哈哈哈","朋友","兄弟","情怀","好","嗯","***","*",
			"**","****","哈哈哈哈","活动给力","策划很强","运营有思想","自言自语自闭","哇","精品"," ","推荐","服不服","不服","服了服了"};

function filter_spec_chars(s)
    local ss = {}
    local k = 1
    while true do
        if k > #s then break end
        local c = string.byte(s,k)
        if not c then break end
        if c<192 then
            if (c>=48 and c<=57) or (c>= 65 and c<=90) or (c>=97 and c<=122) then
                table.insert(ss, string.char(c))
            end
            k = k + 1
        elseif c<224 then
            k = k + 2
        elseif c<240 then
            if c>=228 and c<=233 then
                local c1 = string.byte(s,k+1)
                local c2 = string.byte(s,k+2)
                if c1 and c2 then
                    local a1,a2,a3,a4 = 128,191,128,191
                    if c == 228 then a1 = 184
                    elseif c == 233 then a2,a4 = 190,c1 ~= 190 and 191 or 165
                    end
                    if c1>=a1 and c1<=a2 and c2>=a3 and c2<=a4 then
                        table.insert(ss, string.char(c,c1,c2))
                    end
                end
            end
            k = k + 3
        elseif c<248 then
            
			k = k + 4
        elseif c<252 then
            k = k + 5
        elseif c<254 then
            k = k + 6
        end
    end
	if _G.next(ss) == nil then
		table.insert(ss, rands[math.random(1, #rands)])
	end
    return table.concat(ss)
end


function sendGlobalMsg(actor,channe,msg)
	if msg == nil then 
		print("not msg")
		return false
	end
	msg = System.filterText(msg)
	if utf8len(msg) > global_chat_char_len then 
		print("char len error ")
		return false
	end
	if channe == nil or (channe ~= ciChannelAll) then 
		return false
	end
	local var = getData(actor) 
	if channe == ciChannelAll and var.global_chat_cd > os.time() then 
		print("global chat cd " .. (os.time() - var.global_chat_cd))
		return false
	end
	if var.shutup > os.time() then 
		print("shutup  " .. (var.shutup - os.time()))
		return false
	end

	local level = LActor.getZhuanShengLevel(actor) * 1000
	level = level + LActor.getLevel(actor)
	if level < global_chat_send_level then 
		print("global chat level")
		return false
	end
	
	local vip_level = LActor.getVipLevel(actor)
	
	if vip_level < global_chat_vip_level then 
		print("global chat vip_level")
		return false
	end
	
	local conf = getConfig(actor) 
	if conf == nil then 
		print(LActor.getActorId(actor) .. "  chat not has conf ")
		return false
	end
	local var = getData(actor)
	if var.chat_size >= conf.chatSize then 
		sendSystemTips(actor,1,2,"没有发言次数")
		return false
	end
	local npack = LDataPack.allocPacket()
	if npack == nil then return end



	LDataPack.writeByte(npack,Protocol.CMD_Chat)
	LDataPack.writeByte(npack,Protocol.sChatCmd_ChatMsg)

	LDataPack.writeByte(npack,channe)
	if channe == ciChannelAll then 
		local tbl = {}
		addBasicData(actor,npack,tbl)
		LDataPack.writeUInt(npack,0)
		LDataPack.writeString(npack,msg)
		tbl.channe = channe
		tbl.target_actor_id = 0
		tbl.msg = msg
		local msgid = addGlobalList(tbl)
		LDataPack.writeInt(npack,msgid)
		-- 记录世界聊天监控
		addChatMonitorWorld(actor,msg,msgid)
	else
		addBasicData(actor,npack)
		LDataPack.writeUInt(npack,0)
		LDataPack.writeString(npack,msg)


	end
	System.broadcastData(npack)
	if channe == ciChannelAll then 
		var.global_chat_cd = os.time() + global_chat_cd
	end
	var.chat_size = var.chat_size + 1
	return true
end


--net
local function onChatMsg(actor,packet)
	-- 充值金额限制
	print("onChatMsg")
	local aData = LActor.getActorData(actor)
	if ChatConstConfig.paygoldnum then
		print("onChatMsg "..ChatConstConfig.paygoldnum)
		if aData.recharge < ChatConstConfig.paygoldnum then
			print("onChatMsg "..aData.recharge)
			local tips = string.format( Lang.ScriptTips.chat001, ChatConstConfig.paygoldnum )
			LActor.sendTipmsg( actor, tips )
			return
		end
	end

	local channe = LDataPack.readByte(packet)
	local target_actor_id = LDataPack.readUInt(packet)
	local msg = LDataPack.readString(packet)
	if channe == ciChannelAll then 
		local ret = sendGlobalMsg(actor,channe,msg)
		local npack = LDataPack.allocPacket(actor, Protocol.CMD_Chat, Protocol.sChatCmd_ChatMsgResult)
		if npack == nil then 
			return
		end
		LDataPack.writeByte(npack,ret and 1 or 0)
		LDataPack.flush(npack)
	end
end

local function sendShutUpTime(actor)
	local npack = LDataPack.allocPacket(actor, Protocol.CMD_Chat, Protocol.sChatCmd_ShutUpTime)
	if npack == nil then return end
	local var  = getData(actor)
	LDataPack.writeInt(npack, var.shutup or 0)
	LDataPack.flush(npack)
end

local function onLogin(actor) 
	LActor.postScriptEventLite(actor,6000,sendGlobalList,actor)
	sendShutUpTime(actor)
end

local function onNewDay(actor)
	rsfData(actor)
end

-- extern 
function shutup(actor,time)
	local var  = getData(actor)
	var.shutup = os.time() + (time * 60)
	sendShutUpTime(actor)
	print(LActor.getActorId(actor).." chat.shutup:"..var.shutup)
end

function releaseShutup(actor)
	local var  = getData(actor)
	var.shutup = 0
	sendShutUpTime(actor)
	print(LActor.getActorId(actor).." chat.releaseShutup:"..var.shutup)
end

function chatlog()
	local var = getGlobalData()

	local b = var.chat_list_begin 
	local e = var.chat_list_end
	local ret = {}
	while (b ~= e) do 
		local tbl = var.chat_list[b]
		if tbl ~= nil and tbl.status == nil then 
			local unit = {
				actorid    = tbl.actor_id,
				actorname   = tbl.actor_name,
				msg   = tbl.msg,
				type    = 1,
				id = b,
			}

			table.insert(ret, unit)
		end
		b = b + 1
	end
	return ret
end

-- gm删除世界频道消息
local function sendDelInfoToAll(msgid) -- 30-6
	local npack = LDataPack.allocPacket()
	if npack == nil then return end
	LDataPack.writeByte(npack,Protocol.CMD_Chat)
	LDataPack.writeByte(npack,Protocol.sChatCmd_ChatMsgDelGM)

	--LDataPack.writeByte(npack,ciChannelAll)
	LDataPack.writeInt(npack,tonumber(msgid))
	System.broadcastData(npack)
	print("deletemsg,协议:" .. Protocol.CMD_Chat .. " " .. Protocol.sChatCmd_ChatMsgDelGM .. " msgid:" .. msgid)
	return true

end

function delchat(msgid)
	local var = getGlobalData()
	local b = var.chat_list_begin 
	local e = var.chat_list_end
	if msgid < b or msgid > e then
		return
	end
	local tbl = var.chat_list[msgid]
	if tbl ~= nil then
		tbl.msg = '精品游戏，五星推荐'
		tbl.status = 1
	end
	sendDelInfoToAll(msgid) -- 通知客户端删除
end

function delActorChat(aid)
	local var = getGlobalData()
	if var.chat_list then
		for i,tbl in pairs(var.chat_list) do
			if tbl.actor_id == aid then
				--var.chat_list[i] = nil
				tbl.msg = '精品游戏，五星推荐'
				tbl.status = 1
				local msgid = i
				sendDelInfoToAll(msgid) -- 通知所有客户端删除
			end
		end
	end
end

_G.shutup        = shutup
_G.releaseShutup = releaseShutup
actorevent.reg(aeNewDayArrive, onNewDay)
actorevent.reg(aeUserLogin, onLogin)
netmsgdispatcher.reg(Protocol.CMD_Chat, Protocol.cChatCmd_ChatMsg,onChatMsg) -- 30-1

local gmsystem    = require("systems.gm.gmsystem")
local gmHandlers = gmsystem.gmCmdHandlers

gmHandlers.delchat = function(actor, args)
	local msgid = tonumber(args[1]) -- 消息id
	print("删除会话id:" .. msgid)
	delchat(msgid)
	return true
end

gmHandlers.delactorchat = function(actor, args)
	local actorid = tonumber(args[1]) -- 角色id
	delActorChat(actorid)
	return true
end

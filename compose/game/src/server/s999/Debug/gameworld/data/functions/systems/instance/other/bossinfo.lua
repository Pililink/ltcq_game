--副本内boss信息
module("bossinfo", package.seeall)

--[[
boss_info = {
    damagelist = {
        [actorid] = {name, damage}
     },
     damagerank = {
        {id, name,damage}[]
     }
     id,
     hp,
     src_hdl,
     tar_hdl,
     need_update,
 }
--]]
-- 日志
local function LOG(log, actor)
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[ERROR]:bossinfo." .. log .. " actorid:" .. actorid)
end

local function DEBUG(log, actor) -- 上线后把内容注掉
--[[
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[DEBUG]:bossinfo." .. log .. " actorid:" .. actorid)
]]
end

local function INFO(log, actor)
	local actorid = actor and LActor.getActorId(actor) or 0
	print("[INFO]:bossinfo." .. log .. " actorid:" .. actorid)
end

local p = Protocol

function getDdamageRank(ins)
	onTimer(ins,System.getNowTime(), true)
	return ins.boss_info.damagerank
end

local function onDamage(ins, selfid, curhp, damage, attacker)
    if ins.boss_info == nil then ins.boss_info = {} end
    if ins.boss_info.damagelist == nil then ins.boss_info.damagelist = {} end
    if(not ins.multipleFlag) then -- 这个标志位true表示这是单副本多BOSS的副本
        local actor = LActor.getActor(attacker)
        if actor and damage > 0 then
	    	local info = ins.boss_info.damagelist[LActor.getActorId(actor)]
	    	if info == nil then
	    		ins.boss_info.damagelist[LActor.getActorId(actor)] = {name = LActor.getName(actor), damage = damage}
	    	else
	    		info.damage = info.damage + damage
	    	end
	    end
        ins.boss_info.hp = curhp
        ins.boss_info.id = selfid
        ins.boss_info.need_update = true
    else
        if(not ins.multipleBossInfo) then ins.multipleBossInfo = {} end
        local bossId = selfid
        ins.multipleBossInfo[bossId] = ins.multipleBossInfo[bossId] or {}
        ins.multipleBossInfo[bossId].hp = curhp
        ins.multipleBossInfo[bossId].bossId = bossId
        ins.multipleBossInfo[bossId].needUpdate = true
    end

    if curhp <= 0 or damage < 0 then
        onTimer(ins, System.getNowTime(), true, ins.multipleFlag, selfid)
    end
end

local function sortDamage(boss_info)
    if boss_info == nil then return end
    if boss_info.damagelist == nil then return end
    boss_info.damagerank = {}
    for aid, v in pairs(boss_info.damagelist) do
        table.insert(boss_info.damagerank, {id=aid,name=v.name,damage=v.damage})
    end
    table.sort(boss_info.damagerank, function(a,b)
        return a.damage > b.damage
    end)

end

local function onChangeTarget(ins, src_hdl, tarHdl, bossId)
    if(not multipleFlag) then -- 单Boss
        if ins.boss_info == nil then ins.boss_info = {} end
        ins.boss_info.src_hdl = src_hdl
        ins.boss_info.tar_hdl = tarHdl
        ins.boss_info.need_update = true
    else
        if ins.multipleBossInfo == nil then ins.multipleBossInfo = {} end
        if(not ins.multipleBossInfo[bossId]) then ins.multipleBossInfo[bossId] = {} end
        local bossInfo = ins.multipleBossInfo[bossId]
        bossInfo.bossHdl = src_hdl
        bossInfo.tarHdl = tarHdl
        bossInfo.needUpdate = true
    end
    onTimer(ins,System.getNowTime(),true)

end

--c++回调接口
-- selfid: bossId
_G.onBossDamage = function(fbhdl, selfid, curhp, damage, attacker)
	-- print("--- on boss damage ---")
    local ins = instancesystem.getInsByHdl(fbhdl)
    if ins then
        onDamage(ins, selfid, curhp, damage, attacker)
    end
end

_G.onBossRecover = function(fbhdl, mon, maxhp)
	local ins = instancesystem.getInsByHdl(fbhdl)
    if not ins then return end
    if ins.boss_info == nil then return end
    if ins.boss_info.id == nil then return end
    ins.boss_info.hp = maxhp
end

_G.onBossChangeTarget = function(fbhdl, src_hdl, tarHdl, bossId)
    local ins = instancesystem.getInsByHdl(fbhdl)
    if ins then
        onChangeTarget(ins, src_hdl, tarHdl, bossId)
    end
end

function onMonsterCreate(ins, monster)
    if LActor.isBoss(monster) then
        if(not ins.multipleFlag) then
		    if ins.boss_info == nil then ins.boss_info = {} end
		    if ins.boss_info.damagelist == nil then ins.boss_info.damagelist = {} end
		    ins.boss_info.hp = tonumber(LActor.getHp(monster))
		    ins.boss_info.id = LActor.getId(monster)
            ins.boss_info.need_update = true
            --print("DMWFLAG bosscreate,srchdl:" .. ins.boss_info.src_hdl)
        else
            if (ins.multipleBossInfo == nil) then ins.multipleBossInfo = {} end
            local bossId = LActor.getId(monster)
            if(ins.multipleBossInfo[bossId] == nil) then ins.multipleBossInfo[bossId] = {} end
            local bossInfo = ins.multipleBossInfo[bossId]
            bossInfo.bossId = bossId
            bossInfo.bossHp = tonumber(LActor.getHp(monster))
            bossInfo.bossHdl = tonumber(LActor.getHandle(monster))
            bossInfo.needUpdate = true
        end
	end
end

--instance回调接口
local function notify(ins, actor)
    if(ins.multipleFlag) then return end
    local npack = LDataPack.allocPacket(actor, p.CMD_Boss, p.sBossCmd_BossInfo) -- 10-20
    if npack == nil then return end

    local info = ins.boss_info
    LDataPack.writeInt(npack, info.id) -- bossId
    LDataPack.writeDouble(npack, info.hp) -- 血量
    LDataPack.writeInt64(npack, info.src_hdl or 0) -- boss标识
    print("info.src_hdl:".. info.src_hdl)
    LDataPack.writeInt64(npack, info.tar_hdl or 0) -- 归属者
    if info.damagerank == nil then
        LDataPack.writeShort(npack, 0)
    else
        LDataPack.writeShort(npack, #info.damagerank) -- 伤害排行数量
        for i=1,#info.damagerank do
            LDataPack.writeInt(npack, info.damagerank[i].id)
            LDataPack.writeString(npack, info.damagerank[i].name)
            LDataPack.writeDouble(npack, info.damagerank[i].damage)
        end
    end
    LDataPack.flush(npack)
end

--[[
    @desc: 发送单副本多BOSS信息
    author:{author}
    time:2020-05-25 09:39:46
    --@ins:
    --@actor:
    --@forceFlag:是否强制
	--@bossId: 必填
    @return:
]]
local function sendMultipleBossInfo(ins, actor)
    if(not ins.multipleFlag) then return end -- 不是单本多BOSS的不发
    local nowTime = System.getNowTime()
    local actorId = LActor.getActorId(actor)

    --DEBUG("10-39 boss群发")
    local updataBossIdList = {} -- 要更新的BOSS列表
    if(not ins.multipleBossInfo) then
        DEBUG("ins.multipleBossInfo is nil")
    end
    for bossIdTmp, bossInfo in pairs(ins.multipleBossInfo or {}) do
        --DEBUG("DMWFLAG bossIdTmp:" .. bossIdTmp)
        if(bossInfo.needUpdate or forceFlag or bossInfo.timer<=nowTime) then
            table.insert(updataBossIdList, bossIdTmp)
            --DEBUG("DMWFLAG 更新bossInfo bossIdTmp:" .. bossIdTmp .. " 当前总数量:" .. #updataBossIdList)
        end
    end
    local bossCount = #updataBossIdList
    if(bossCount == 0) then  -- 要更新的BOSS
        --DEBUG("DMWFLAG boss数量是0",actor)
        return 
    else
        --DEBUG("DMWFLAG BOSS数量不是0", actor)
    end
    local npack = LDataPack.allocPacket(actor, Protocol.CMD_Boss, Protocol.sMultipleBoss_Info) -- 10-39
    if(not npack) then return end
    LDataPack.writeShort(npack, bossCount) -- bossCount
    for _,bossIdTmp in ipairs(updataBossIdList) do
        local bossInfo = ins.multipleBossInfo[bossIdTmp]
        LDataPack.writeInt(npack, bossInfo.bossId) -- bossId
        LDataPack.writeDouble(npack, bossInfo.bossHp) -- 血量
        LDataPack.writeInt64(npack, bossInfo.bossHdl or 0) -- boss标识
        LDataPack.writeInt64(npack, bossInfo.tarHdl or 0) -- 归属者
    end
    LDataPack.flush(npack)
    return
end

function onEnter(ins, actor)
    if ins.boss_info == nil then return end
    if ins.boss_info.id == nil then return end
	
    notify(ins, actor)
    sendMultipleBossInfo(ins, actor)
end



--[[
    @desc: 定时3秒发送boss信息
    edit:dmw
    time:2020-05-22 16:20:15
    --@ins:instance
	--@now_t:当前时间
    --@force: 是否强制发送
    --@multipleFlag:是否为多BOSS副本(可删)
    --@bossId:有表示单发一个BOSS 没有全发
    @return:
]]
function onTimer(ins, now_t, force, multipleFlag, bossId)
    --print("DMWFLAG 定时发送")
    local actors = ins:getActorList()
    if(not ins.multipleFlag) then
	    if ins.boss_info == nil then return end
	    if ins.boss_info.id == nil then return end
	    if not ins.boss_info.need_update then return end
	    if not force and ((ins.boss_info.timer or 0) > now_t) then return end
	    ins.boss_info.timer = now_t + 3 --3秒执行一次
	    sortDamage(ins.boss_info)
	    for _, actor in ipairs(actors) do
	       notify(ins, actor)
	    end
        ins.boss_info.need_update = false
    else -- 多BOSS
        --if not force and ((ins.boss_info.timer or 0) > now_t) then return end
        if not force and ((ins.multipleTimer or 0) > now_t) then return end
        for _, actor in ipairs(actors) do
            sendMultipleBossInfo(ins, actor)
        end
        ins.multipleTimer = now_t + 3
    end
end

--发送攻击列表给归属者
local function sendAttackedListToBelong(actor)
	if not actor then return end
	--通知归属者,当前攻击归属者的玩家列表
	local actors = Fuben.getAllActor(LActor.getFubenHandle(actor))
	if actors ~= nil then
		local handles = {}
		local count = 0
		for i = 1,#actors do 
			if LActor.getCamp(actors[i]) == WorldBossCampType_Attack then
				handles[LActor.getHandle(LActor.getActor(actors[i]))] = 1
				count = count + 1
			end
		end
		local npack = LDataPack.allocPacket(actor, p.CMD_Boss, p.sWorldBoss_UpdateAttackedListInfo) -- 10-23 威胁列表
		if nil == npack then return end
		LDataPack.writeUInt(npack, count)
		for k,v in pairs(handles) do
			LDataPack.writeDouble(npack, k)
		end
		LDataPack.flush(npack)
	end
end
_G.sendAttackedListToBelong = sendAttackedListToBelong

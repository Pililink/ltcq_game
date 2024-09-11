--[[
    24类型的活动服务器并不参与,只是通知客户端需要开启这个活动
]]
module("subactivitytype24", package.seeall)
local subType = 24
subactivities.regConf(subType, ActivityType24Config)

local addonName = ...
local guildLevels = {}
local lastUpdate = 0

local frame = CreateFrame("Frame")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")

frame:SetScript("OnEvent", function(self, event)
    if event == "GUILD_ROSTER_UPDATE" then
        if not IsInGuild() then return end
        
        for i = 1, GetNumGuildMembers() do
            local name, _, _, level, _, _, _, _, online = GetGuildRosterInfo(i)
            if name and level and online then
                name = name:match("^[^-]+")
                guildLevels[name] = level
            end
        end
    end
end)

local function RequestGuildUpdate()
    local now = GetTime()
    if now - lastUpdate > 300 then
        lastUpdate = now
        GuildRoster()
    end
end

local function LookupSingleMember(memberName)
    if not IsInGuild() or not memberName then return nil end
    
    for i = 1, GetNumGuildMembers() do
        local name, _, _, level = GetGuildRosterInfo(i)
        if name then
            local shortName = name:match("^[^-]+")
            if shortName == memberName then
                guildLevels[shortName] = level
                return level
            end
        end
    end
    
    return nil
end

local function GetGuildMemberLevel(memberName)
    if not memberName then return nil end
    
    if guildLevels[memberName] then
        return guildLevels[memberName]
    end
    
    local level = LookupSingleMember(memberName)
    if level then
        return level
    end
    
    RequestGuildUpdate()
    
    return nil
end

local function GuildChatFilter(self, event, msg, author, ...)
    local name = author and author:match("^[^-]+")
    if not name then
        return false, msg, author, ...
    end

    local level = GetGuildMemberLevel(name)
    if not level then
        return false, msg, author, ...
    end

    return false, "|cff9d9d9d[" .. level .. "]|r " .. msg, author, ...
end

local function GuildWhisperFilter(self, event, msg, author, ...)
    local name = author and author:match("^[^-]+")
    if not name then
        return false, msg, author, ...
    end
    
    local level = GetGuildMemberLevel(name)
    if not level then
        return false, msg, author, ...
    end

    return false, "|cff9d9d9d[" .. level .. "]|r " .. msg, author, ...
end

ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", GuildChatFilter)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", GuildWhisperFilter)

C_Timer.After(2, function()
    GuildRoster()
end)
local addonName, ns = ...

ns = ns or {}
_G.WPA_NS = ns

ns.addonName = addonName
ns.events = CreateFrame("Frame")
ns.playerName = UnitName("player")
ns.playerRealm = GetRealmName()

local function deepcopy(tbl)
    if type(tbl) ~= "table" then
        return tbl
    end

    local out = {}
    for k, v in pairs(tbl) do
        out[k] = deepcopy(v)
    end
    return out
end
ns.deepcopy = deepcopy

local defaults = {
    minimap = false,
    debug = false,
    showDone = false,
    window = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        width = 860,
        height = 560,
    },
    profiles = {},
    characters = {},
    customGoals = {},
    playerPreferences = {
    scores = {
        random_dungeon = 0,
        weekly_delves = 0,
        weekly_world_activities = 0,
    },
    lastDecayAt = 0,
    behaviour = {
    dungeons = 0,
    delves = 0,
    world = 0,
},
},
}
ns.defaults = defaults

function ns.RefreshAll(reason, ...)
    if ns.Engine and ns.Engine.Refresh then
        ns.Engine.Refresh(reason, ...)
    end

    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end
end

local function getCharKey()
    local name = UnitName("player") or "Unknown"
    local realm = GetRealmName() or "UnknownRealm"
    return name .. "-" .. realm
end
ns.getCharKey = getCharKey

local function mergeDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then
                dst[k] = {}
            end
            mergeDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

local function trim(s)
    s = tostring(s or "")
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function initDB()
    WPA_DB = WPA_DB or ns.deepcopy(defaults)
    mergeDefaults(WPA_DB, defaults)

    local charKey = getCharKey()
    WPA_DB.characters[charKey] = WPA_DB.characters[charKey] or {
        role = "unknown",
        trackLeveling = true,
        trackWeekly = true,
        manualNotes = "",
    }

    ns.db = WPA_DB
    ns.char = WPA_DB.characters[charKey]
end

local function printHelp()
    print("|cff33ff99WPA|r commands:")
    print("/wpa - show/hide")
    print("/wpa config - load example goals")
    print("/wpa debug - toggle debug")
    print("/wpa done - toggle show done goals")
    print("/wpa refresh - recompute")
    print("/wpa prefs - show learned preferences")
    print("/wpa behaviour - show learned behaviour counters")
end

local function onLogin()
    initDB()

    if ns.Data and ns.Data.Initialize then
        ns.Data.Initialize()
    end

    if ns.Engine and ns.Engine.Refresh then
        ns.Engine.Refresh("PLAYER_LOGIN")
    end

    if ns.UI and ns.UI.Create then
        ns.UI.Create()
    end

    SLASH_WPA1 = "/wpa"
SlashCmdList["WPA"] = function(msg)
    msg = trim(string.lower(msg or ""))

    if msg == "prefs" then
        if ns.db and ns.db.playerPreferences and ns.db.playerPreferences.scores then
            print("|cff33ff99WPA|r preferences:")
            for k, v in pairs(ns.db.playerPreferences.scores) do
                print(" - " .. tostring(k) .. " = " .. tostring(v))
            end
            print(" - lastDecayAt = " .. tostring(ns.db.playerPreferences.lastDecayAt or 0))
        else
            print("|cff33ff99WPA|r preferences: none yet")
        end
        return
    end

    if msg == "behaviour" then
        ns.db.behaviour = ns.db.behaviour or {
            dungeons = 0,
            delves = 0,
            world = 0,
        }

        print("|cff33ff99WPA|r behaviour:")
        print(" - dungeons = " .. tostring(ns.db.behaviour.dungeons or 0))
        print(" - delves = " .. tostring(ns.db.behaviour.delves or 0))
        print(" - world = " .. tostring(ns.db.behaviour.world or 0))
        return
    end

    if msg == "config" then
        if ns.Config and ns.Config.Open then
            ns.Config.Open()
        end
        return
    end

    if msg == "debug" then
        ns.db.debug = not ns.db.debug
        print("|cff33ff99WPA|r debug = " .. tostring(ns.db.debug))
        if ns.RefreshAll then
            ns.RefreshAll("DEBUG_TOGGLE")
        end
        return
    end

    if msg == "done" then
        ns.db.showDone = not ns.db.showDone
        print("|cff33ff99WPA|r showDone = " .. tostring(ns.db.showDone))
        if ns.RefreshAll then
            ns.RefreshAll("DONE_TOGGLE")
        end
        return
    end

    if msg == "refresh" then
        if ns.RefreshAll then
            ns.RefreshAll("MANUAL_REFRESH")
        end
        return
    end

    if msg == "help" then
        printHelp()
        return
    end

    if ns.UI and ns.UI.Toggle then
        ns.UI.Toggle()
    end
end

ns.events:RegisterEvent("PLAYER_LOGIN")
ns.events:RegisterEvent("PLAYER_ENTERING_WORLD")
ns.events:RegisterEvent("QUEST_TURNED_IN")
ns.events:RegisterEvent("QUEST_ACCEPTED")
ns.events:RegisterEvent("PLAYER_LEVEL_UP")
ns.events:RegisterEvent("ACHIEVEMENT_EARNED")
ns.events:RegisterEvent("CRITERIA_EARNED")
ns.events:RegisterEvent("WEEKLY_REWARDS_UPDATE")
ns.events:RegisterEvent("BAG_UPDATE_DELAYED")
ns.events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
ns.events:RegisterEvent("ZONE_CHANGED")
ns.events:RegisterEvent("ZONE_CHANGED_INDOORS")
ns.events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
ns.events:RegisterEvent("QUEST_LOG_UPDATE")
ns.events:RegisterEvent("LFG_COMPLETION_REWARD")
ns.events:RegisterEvent("CHALLENGE_MODE_COMPLETED")
ns.events:RegisterEvent("ACHIEVEMENT_EARNED")
ns.events:RegisterEvent("QUEST_TURNED_IN")
ns.events:RegisterEvent("WEEKLY_REWARDS_UPDATE")
ns.events:RegisterEvent("CRITERIA_EARNED")

ns.events:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        onLogin()
        return
    end
    if event == "LFG_COMPLETION_REWARD" then
    print("|cff33ff99WPA|r Dungeon completed")
    if ns.Engine and ns.Engine.RecordActivity then
        ns.Engine.RecordActivity("dungeon")
    end
end

if event == "CHALLENGE_MODE_COMPLETED" then
    print("|cff33ff99WPA|r Mythic+ completed")
end



if event == "ACHIEVEMENT_EARNED" then
    print("|cff33ff99WPA|r Achievement earned")
end
if event == "CRITERIA_EARNED" then
    print("|cff33ff99WPA|r Criteria progress")
    if ns.Engine and ns.Engine.RecordActivity then
        ns.Engine.RecordActivity("delve")
    end
end

if event == "WEEKLY_REWARDS_UPDATE" then
    print("|cff33ff99WPA|r Weekly rewards updated")
    if ns.Engine and ns.Engine.RegisterWeeklySignal then
        ns.Engine.RegisterWeeklySignal("weekly_rewards")
    end
end

if event == "QUEST_TURNED_IN" then
    print("|cff33ff99WPA|r Quest completed")
    if ns.Engine and ns.Engine.RecordActivity then
        ns.Engine.RecordActivity("world")
    end
end

    ns.RefreshAll(event, ...)
end)

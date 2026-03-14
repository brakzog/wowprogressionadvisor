local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.Config = {}

local Config = ns.Config

local function hasGoal(key)
    for _, goal in ipairs(ns.db.customGoals or {}) do
        if goal.key == key then
            return true
        end
    end
    return false
end

local function addManualExampleGoals()
    if not hasGoal("suramar_campaign") then
        ns.Data.UpsertCustomGoal({
            key = "suramar_campaign",
            title = "Finir Suramar",
            checkType = "achievement",
            sourceID = 11124,
            priority = 70,
            bucket = "custom",
            notes = "Objectif perso de progression / completion.",
        })
    end

    if not hasGoal("weekly_open_world_focus") then
        ns.Data.UpsertCustomGoal({
            key = "weekly_open_world_focus",
            title = "Faire un objectif monde prioritaire",
            checkType = "manual",
            priority = 65,
            bucket = "custom",
            notes = "A cocher quand vous avez termine votre activite monde la plus rentable.",
            completed = false,
        })
    end

    if not hasGoal("weekly_gearing_focus") then
        ns.Data.UpsertCustomGoal({
            key = "weekly_gearing_focus",
            title = "Faire une activite de gearing utile",
            checkType = "manual",
            priority = 75,
            bucket = "custom",
            notes = "A cocher apres un donjon, gouffre ou autre activite de progression.",
            completed = false,
        })
    end
end

function Config.Open()
    addManualExampleGoals()

    if ns.Engine and ns.Engine.Refresh then
        ns.Engine.Refresh("CONFIG_OPEN")
    end

    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end

   print("|cff33ff99WPA|r custom goals charges.")
print("|cff33ff99WPA|r /wpa debug - toggle debug")
print("|cff33ff99WPA|r /wpa done - show/hide done goals")
end

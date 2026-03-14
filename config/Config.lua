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
        ns.Data.AddCustomGoal({
            key = "suramar_campaign",
            title = "Finir Suramar",
            checkType = "achievement",
            sourceID = 11124,
            priority = 95,
            bucket = "custom",
            notes = "Tres bon objectif account-wide / cosmetique / progression Legion.",
        })
    end

    if not hasGoal("dream_explorer") then
        ns.Data.AddCustomGoal({
            key = "dream_explorer",
            title = "Explorer la zone cible",
            checkType = "manual",
            priority = 60,
            bucket = "custom",
            notes = "Click dessus pour toggle done / todo.",
            completed = false,
        })
    end

    if not hasGoal("example_weekly_quest") then
        ns.Data.AddCustomGoal({
            key = "example_weekly_quest",
            title = "Exemple de quete hebdo a remplacer",
            checkType = "quest",
            sourceID = 999999,
            priority = 85,
            bucket = "custom",
            notes = "Remplace l ID par une vraie quete hebdo pour tester le check auto.",
        })
    end

    if not hasGoal("test_ach") then
        ns.Data.AddCustomGoal({
            key = "test_ach",
            title = "Test achievement",
            checkType = "achievement",
            sourceID = 12,
            priority = 90,
            bucket = "custom",
            notes = "Objectif de test achievement.",
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

    print("|cff33ff99WPA|r exemples d objectifs charges.")
    print("|cff33ff99WPA|r /wpa debug - toggle debug")
    print("|cff33ff99WPA|r /wpa done - show/hide done goals")
end

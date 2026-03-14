local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.Data = {}

local Data = ns.Data

Data.catalog = {
    leveling = {
        {
            key = "campaign_main",
            title = "Continuer la campagne principale",
            checkType = "rule",
            ruleKey = "campaign_main",
            priority = 100,
            bucket = "leveling",
            notes = "Campagne / leveling encore pertinent",
        },
        {
            key = "random_dungeon",
            title = "Faire un donjon aleatoire",
            checkType = "rule",
            ruleKey = "random_dungeon",
            priority = 80,
            bucket = "leveling",
            notes = "Suggestion leveling active",
        },
        {
            key = "zone_side_quests",
            title = "Completer les quetes de zone efficaces",
            checkType = "rule",
            ruleKey = "zone_side_quests",
            priority = 60,
            bucket = "leveling",
            notes = "Suggestion leveling active",
        },
    },

    weekly = {
    {
        key = "weekly_cache",
        title = "Securiser le coffre hebdomadaire",
        checkType = "weeklyRewards",
        priority = 100,
        bucket = "weekly",
        notes = "Progression coffre suivie automatiquement quand l API est dispo.",
    },
    {
        key = "weekly_meta",
        title = "Faire les activites hebdo majeures",
        checkType = "rule",
        ruleKey = "weekly_meta",
        priority = 90,
        bucket = "weekly",
        notes = "Regle generique a specialiser avec de vraies quetes hebdo.",
    },
    {
        key = "weekly_delves",
        title = "Faire des gouffres",
        checkType = "rule",
        ruleKey = "weekly_delves",
        priority = 80,
        bucket = "weekly",
        notes = "Bon moyen de progresser en gear.",
    },
    {
        key = "weekly_world_activities",
        title = "Faire des activites monde / expes",
        checkType = "rule",
        ruleKey = "weekly_world_activities",
        priority = 70,
        bucket = "weekly",
        notes = "Utile pour le rattrapage et les recompenses annexes.",
    },
},
}

function Data.Initialize()
    ns.db.customGoals = ns.db.customGoals or {}
end

function Data.GetAllGoals()
    local goals = {}

    for _, entry in ipairs(Data.catalog.leveling) do
        goals[#goals + 1] = entry
    end

    for _, entry in ipairs(Data.catalog.weekly) do
        goals[#goals + 1] = entry
    end

    for _, entry in ipairs(ns.db.customGoals) do
        goals[#goals + 1] = entry
    end

    return goals
end

function Data.AddCustomGoal(goal)
    ns.db.customGoals[#ns.db.customGoals + 1] = goal
end

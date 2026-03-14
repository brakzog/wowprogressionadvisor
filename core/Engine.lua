local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.Engine = {}

local Engine = ns.Engine

Engine.state = {
    suggestions = {},
    grouped = {
        leveling = {},
        custom = {},
        weekly = {},
    },
    best = nil,
    lastEvent = nil,
    snapshot = nil,

    recentSuggestions = {},
}

local STATUS = {
    AUTO_DONE = "AUTO_DONE",
    AUTO_TODO = "AUTO_TODO",
    AUTO_PARTIAL = "AUTO_PARTIAL",
    MANUAL = "MANUAL",
    UNKNOWN = "UNKNOWN",
}
Engine.STATUS = STATUS



local function registerSuggestion(goalKey)
    if not goalKey then
        return
    end

    local list = Engine.state.recentSuggestions or {}
    list[#list + 1] = goalKey

    -- on garde seulement les 3 dernieres
    if #list > 3 then
        table.remove(list, 1)
    end

    Engine.state.recentSuggestions = list
end


local function diversityPenalty(goalKey)
    local list = Engine.state.recentSuggestions or {}

    for _, key in ipairs(list) do
        if key == goalKey then
            return -40
        end
    end

    return 0
end

local function isQuestDone(questID)
    if not questID then
        return false
    end

    if C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted then
        return C_QuestLog.IsQuestFlaggedCompleted(questID) or false
    end

    return false
end

local function getAchievementDone(achievementID)
    if not achievementID then
        return false, nil
    end

    local id, name, _, completed = GetAchievementInfo(achievementID)
    if type(id) == "number" and type(name) == "string" then
        return completed == true or completed == 1, name
    end

    return false, nil
end

local function getVaultProgressText()
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then
        return nil, 0, 0
    end

    local activities = C_WeeklyRewards.GetActivities() or {}
    local maxProgress = 0
    local bestProgress = 0

    for _, activity in ipairs(activities) do
        local threshold = activity.threshold or 0
        local progress = activity.progress or 0

        if threshold > maxProgress then
            maxProgress = threshold
        end

        if progress > bestProgress then
            bestProgress = progress
        end
    end

    if maxProgress > 0 then
        return string.format("Coffre: %d/%d", bestProgress, maxProgress), bestProgress, maxProgress
    end

    return "Coffre indisponible", 0, 0
end

local function checkWeeklyRewards()
    if not C_WeeklyRewards or not C_WeeklyRewards.GetActivities then
        return STATUS.UNKNOWN, "API weekly rewards indisponible"
    end

    local text, progress, threshold = getVaultProgressText()

    if threshold <= 0 then
        return STATUS.UNKNOWN, text or "Progression coffre inconnue"
    end

    if progress >= threshold then
        return STATUS.AUTO_DONE, text
    elseif progress > 0 then
        return STATUS.AUTO_PARTIAL, text
    else
        return STATUS.AUTO_TODO, text
    end
end


function Engine.RegisterWeeklySignal(signalType)
    if not Engine.state.weeklySignals then
        Engine.state.weeklySignals = {
            lastWeeklyRewardsUpdate = 0,
            lastQuestTurnIn = 0,
        }
    end

    if signalType == "weekly_rewards" then
        Engine.state.weeklySignals.lastWeeklyRewardsUpdate = GetTime()
    elseif signalType == "quest_turnin" then
        Engine.state.weeklySignals.lastQuestTurnIn = GetTime()
    end

    if ns.RefreshAll then
        ns.RefreshAll("WEEKLY_SIGNAL_UPDATE")
    end
end


function Engine.RegisterActivity(activityType)
    if not Engine.state.weeklyState then
        Engine.state.weeklyState = {
            delveCount = 0,
            dungeonCount = 0,
        }
    end

    if activityType == "delve" then
        Engine.state.weeklyState.delveCount = (Engine.state.weeklyState.delveCount or 0) + 1
    elseif activityType == "dungeon" then
        Engine.state.weeklyState.dungeonCount = (Engine.state.weeklyState.dungeonCount or 0) + 1
    end

    if ns.RefreshAll then
        ns.RefreshAll("ACTIVITY_DONE")
    end
end

function Engine.CheckGoalStatus(goal)
    if not goal then
        return STATUS.UNKNOWN, "Objectif invalide"
    end

    if goal.checkType == "quest" then
        if isQuestDone(goal.sourceID) then
            return STATUS.AUTO_DONE, "Quete validee"
        end
        return STATUS.AUTO_TODO, "Quete non validee"
    end

    if goal.checkType == "achievement" then
        local done, achName = getAchievementDone(goal.sourceID)

        if ns.db and ns.db.debug and goal.key == "test_ach" then
            print("WPA DEBUG achievement:", tostring(goal.sourceID), tostring(achName), tostring(done))
        end

        if done then
            return STATUS.AUTO_DONE, "Haut fait termine"
        end

        return STATUS.AUTO_TODO, "Haut fait non termine"
    end

    if goal.checkType == "manual" then
        if goal.completed == true then
            return STATUS.AUTO_DONE, "Objectif manuel coche"
        end
        return STATUS.MANUAL, "A verifier manuellement"
    end

    if goal.checkType == "weeklyRewards" then
        return checkWeeklyRewards()
    end

    if goal.checkType == "rule" then
        if goal.ruleKey == "campaign_main" then
            if ns.Rules.ShouldLeveling() then
                return STATUS.AUTO_TODO, "Campagne / leveling encore pertinent"
            else
                return STATUS.AUTO_DONE, "Niveau max atteint"
            end
        end

        if goal.ruleKey == "random_dungeon" then
            if ns.Rules.ShouldLeveling() then
                return STATUS.AUTO_TODO, "Donjons utiles pour xp"
            elseif ns.Rules.ShouldGearUp() then
                return STATUS.AUTO_TODO, "Donjons utiles pour gear"
            else
                return STATUS.UNKNOWN, "Donjons moins prioritaires"
            end
        end

        if goal.ruleKey == "zone_side_quests" then
            if ns.Rules.ShouldLeveling() then
                return STATUS.AUTO_TODO, "Bon complement xp"
            else
                return STATUS.UNKNOWN, "Moins utile au niveau max"
            end
        end

        if goal.ruleKey == "weekly_meta" then
            if ns.Rules.ShouldWeekly() then
                return STATUS.MANUAL, "Activites hebdo a faire"
            else
                return STATUS.UNKNOWN, "Hebdo pas pertinente avant max"
            end
        end

        if goal.ruleKey == "weekly_delves" then
    if ns.Rules.ShouldGearUp() then
        return STATUS.MANUAL, "Gouffres utiles pour progresser en gear"
    elseif ns.Rules.ShouldWeekly() then
        return STATUS.UNKNOWN, "Option weekly secondaire"
    else
        return STATUS.UNKNOWN, "Pas prioritaire"
    end
end

if goal.ruleKey == "weekly_world_activities" then
    if ns.Rules.ShouldGearUp() then
        return STATUS.MANUAL, "Activites monde utiles pour le rattrapage"
    elseif ns.Rules.ShouldWeekly() then
        return STATUS.UNKNOWN, "Option weekly secondaire"
    else
        return STATUS.UNKNOWN, "Pas prioritaire"
    end
end

        return STATUS.UNKNOWN, "Regle non implementee"
    end

    return STATUS.UNKNOWN, "Type de verification inconnu"
end

local function statusWeight(status)
    if status == STATUS.AUTO_TODO then return 4 end
    if status == STATUS.AUTO_PARTIAL then return 3 end
    if status == STATUS.MANUAL then return 2 end
    if status == STATUS.UNKNOWN then return 1 end
    return 0
end

local function bucketWeight(bucket)
    if bucket == "leveling" then return 30 end
    if bucket == "weekly" then return 20 end
    if bucket == "custom" then return 25 end
    return 0
end


local function phaseWeight(goal, phase)
    if not phase then
        return 0
    end

    if phase == "leveling" then
        if goal.bucket == "leveling" then return 40 end
    end

    if phase == "gearing" then
        if goal.ruleKey == "random_dungeon" then return 60 end
        if goal.ruleKey == "weekly_delves" then return 50 end
        if goal.ruleKey == "weekly_world_activities" then return 40 end
    end

    if phase == "weekly" then
        if goal.bucket == "weekly" then return 60 end
    end

    return 0
end

local function zoneWeight(goal, zone)
    if not zone then
        return 0
    end

    -- Zone tres specifique : Suramar
    if zone == "Suramar" then
        if goal.key == "suramar_campaign" then
            return 80
        end
    end

    -- Capitales / hubs : favoriser preparation et activites instanciees
    if zone == "Lune-d’Argent"
        or zone == "Lune-d'Argent"
        or zone == "Orgrimmar"
        or zone == "Hurlevent"
        or zone == "Dalaran"
        or zone == "Valdrakken"
        or zone == "Dornogal" then

        if goal.ruleKey == "random_dungeon" then
            return 35
        end

        if goal.ruleKey == "weekly_delves" then
            return 20
        end
    end

    -- Zones d activites monde / endgame : favoriser weekly et open world
    if zone == "Tempete du Vide"
        or zone == "Tempête du Vide"
        or zone == "Azj-Kahet"
        or zone == "L ile de Dorn"
        or zone == "L'île de Dorn"
        or zone == "Les abimes Retentissants"
        or zone == "Les abîmes Retentissants"
        or zone == "Sainte-Chute"
        or zone == "Anneaux de l'eveil"
        or zone == "Anneaux de l'éveil" then

        if goal.ruleKey == "weekly_world_activities" then
            return 35
        end

        if goal.ruleKey == "weekly_delves" then
            return 25
        end

        if goal.bucket == "weekly" then
            return 15
        end
    end

    return 0
end

local function buildDetailedReason(goal, detail, phase, gearBand)
    local baseReason = detail or goal.notes or ""

    if phase == "gearing" then
        if goal.ruleKey == "random_dungeon" then
            if gearBand == "low" then
                return "Donjons utiles pour gear rapidement"
            elseif gearBand == "mid" then
                return "Donjons encore utiles, mais d autres activites deviennent competitives"
            else
                return "Donjons utiles surtout en complement"
            end
        end

        if goal.ruleKey == "weekly_delves" then
            if gearBand == "low" then
                return "Gouffres utiles pour progresser en gear"
            elseif gearBand == "mid" then
                return "Gouffres tres interessants pour continuer le rattrapage"
            else
                return "Gouffres utiles en activite secondaire"
            end
        end

        if goal.ruleKey == "weekly_world_activities" then
            if gearBand == "low" then
                return "Activites monde utiles pour le rattrapage"
            elseif gearBand == "mid" then
                return "Activites monde utiles en complement de progression"
            else
                return "Activites monde surtout utiles pour du bonus"
            end
        end
    end

    return baseReason
end


local function buildReasonTags(goal, status, phase, zone)
    local tags = {}

    if phase == "leveling" and goal.bucket == "leveling" then
        tags[#tags + 1] = "leveling phase"
    end

    if phase == "gearing" then
        if goal.ruleKey == "random_dungeon" then
            tags[#tags + 1] = "gearing phase"
        end
        if goal.ruleKey == "weekly_delves" then
            tags[#tags + 1] = "gear progression"
        end
        if goal.ruleKey == "weekly_world_activities" then
            tags[#tags + 1] = "catch-up activity"
        end
    end

    if phase == "weekly" and goal.bucket == "weekly" then
        tags[#tags + 1] = "weekly phase"
    end

    if zone == "Suramar" and goal.key == "suramar_campaign" then
        tags[#tags + 1] = "zone bonus"
    end

    if status == STATUS.MANUAL then
        tags[#tags + 1] = "manual tracking"
    elseif status == STATUS.AUTO_TODO then
        tags[#tags + 1] = "ready now"
    elseif status == STATUS.AUTO_PARTIAL then
        tags[#tags + 1] = "in progress"
    end

    return tags
end


local function addSuggestion(tbl, goal, status, detail)
    local zone = Engine.state.snapshot and Engine.state.snapshot.zone
    local phase = Engine.state.snapshot and Engine.state.snapshot.phase
    local gearBand = ns.Rules and ns.Rules.GetGearBand and ns.Rules.GetGearBand() or "unknown"
local finalReason = buildDetailedReason(goal, detail, phase, gearBand)

    local score = (goal.priority or 0)
        + statusWeight(status) * 100
        + bucketWeight(goal.bucket)
        + phaseWeight(goal, phase)
+ zoneWeight(goal, zone)



local weeklySignals = Engine.state.weeklySignals or {}

if goal.bucket == "weekly" then
    local lastWeeklyRewardsUpdate = weeklySignals.lastWeeklyRewardsUpdate or 0
    local lastQuestTurnIn = weeklySignals.lastQuestTurnIn or 0
    local now = GetTime()

    if lastWeeklyRewardsUpdate > 0 and (now - lastWeeklyRewardsUpdate) < 30 then
        score = score + 20
    end

    if lastQuestTurnIn > 0 and (now - lastQuestTurnIn) < 30 then
        score = score + 10
    end
end


        local weeklyState = Engine.state.weeklyState or {}

if goal.ruleKey == "weekly_delves" then
    local delveCount = weeklyState.delveCount or 0

    if phase == "gearing" then
        if delveCount >= 2 then
            score = score - 40
        end
    elseif phase == "weekly" then
        if delveCount >= 1 then
            score = score - 20
        end
    end
end

score = score + diversityPenalty(goal.key)

    local priorityLabel = "LOW"

    if score >= 500 then
        priorityLabel = "HIGH"
    elseif score >= 300 then
        priorityLabel = "MED"
    end
    
    local tags = buildReasonTags(goal, status, phase, zone)

tbl[#tbl + 1] = {
    key = goal.key,
    title = goal.title or "Objectif",
    reason = finalReason,
    score = score,
    bucket = goal.bucket or "misc",
    status = status,
    priorityLabel = priorityLabel,
    reasonTags = tags,
    goal = goal,
}
end

local function sortSuggestions(tbl)
    table.sort(tbl, function(a, b)
        if a.score == b.score then
            return a.title < b.title
        end
        return a.score > b.score
    end)
end





local function groupSuggestions(suggestions)
    local grouped = {
        leveling = {},
        custom = {},
        weekly = {},
    }

    for _, item in ipairs(suggestions) do
        local bucket = item.bucket or "custom"
        if not grouped[bucket] then
            grouped[bucket] = {}
        end
        grouped[bucket][#grouped[bucket] + 1] = item
    end

    return grouped
end

function Engine.Refresh(event)
    Engine.state.lastEvent = event
    Engine.state.snapshot = ns.Rules and ns.Rules.GetPlayerSnapshot and ns.Rules.GetPlayerSnapshot() or nil

    if Engine.state.snapshot and ns.Rules and ns.Rules.GetProgressionPhase then
    Engine.state.snapshot.phase = ns.Rules.GetProgressionPhase()
end

    local suggestions = {}

    if not ns.Data or not ns.Data.GetAllGoals then
        Engine.state.suggestions = suggestions
        Engine.state.grouped = groupSuggestions(suggestions)
        Engine.state.best = nil
        return
    end

    for _, goal in ipairs(ns.Data.GetAllGoals()) do
        local status, detail = Engine.CheckGoalStatus(goal)

        if ns.db and ns.db.showDone then
            addSuggestion(suggestions, goal, status, detail)
        else
            if status ~= STATUS.AUTO_DONE and status ~= STATUS.UNKNOWN then
				addSuggestion(suggestions, goal, status, detail)
			end
        end
    end

    sortSuggestions(suggestions)

    Engine.state.suggestions = suggestions
    Engine.state.grouped = groupSuggestions(suggestions)
    Engine.state.best = suggestions[1]
    if Engine.state.best then
    registerSuggestion(Engine.state.best.key)
end
end

function Engine.GetSuggestions()
    return Engine.state.suggestions or {}
end

function Engine.GetGroupedSuggestions()
    return Engine.state.grouped or { leveling = {}, custom = {}, weekly = {} }
end

function Engine.GetBestSuggestion()
    return Engine.state.best
end

function Engine.GetSnapshot()
    return Engine.state.snapshot
end

function Engine.OnSuggestionClick(item)
    if not item or not item.goal then
        return
    end

    local goal = item.goal

    -- Quest goals
    if goal.checkType == "quest" and goal.sourceID then
        print("|cff33ff99WPA|r quest goal:", goal.sourceID)
        return
    end

    -- Achievement goals
    if goal.checkType == "achievement" and goal.sourceID then
        if AchievementFrame_LoadUI then
            AchievementFrame_LoadUI()
        end
        if ToggleAchievementFrame then
            ToggleAchievementFrame()
        end
        print("|cff33ff99WPA|r achievement goal:", goal.sourceID)
        return
    end

    -- Manual goals
    if goal.checkType == "manual" then
        goal.completed = not goal.completed
        print("|cff33ff99WPA|r manual goal toggled:", goal.title, tostring(goal.completed))
        if ns.RefreshAll then
    ns.RefreshAll("MANUAL_GOAL_TOGGLE")
else
    Engine.Refresh("MANUAL_GOAL_TOGGLE")
    if ns.UI and ns.UI.Refresh then
        ns.UI.Refresh()
    end
end
        if ns.UI and ns.UI.Refresh then
            ns.UI.Refresh()
        end
        return
    end

    -- Rule-based goals
    if goal.checkType == "rule" then

    -- Random dungeon
    if goal.ruleKey == "random_dungeon" then
        if PVEFrame_ToggleFrame then
            PVEFrame_ToggleFrame()
        end
        if LFDParentFrame then
            LFDParentFrame:Show()
        end
        print("|cff33ff99WPA|r ouverture de l outil Donjon")
        return
    end

    -- Weekly world activities
    if goal.ruleKey == "weekly_world_activities" then
        if ToggleWorldMap then
            ToggleWorldMap()
        end
        print("|cff33ff99WPA|r ouverture de la carte du monde")
        return
    end

    -- Weekly delves
    if goal.ruleKey == "weekly_delves" then
        if ToggleWorldMap then
            ToggleWorldMap()
        end
        print("|cff33ff99WPA|r cherchez un gouffre proche sur la carte")
        return
    end

    -- Weekly meta
    if goal.ruleKey == "weekly_meta" then
        if ToggleWorldMap then
            ToggleWorldMap()
        end
        print("|cff33ff99WPA|r regardez les activites hebdomadaires")
        return
    end
end

    print("|cff33ff99WPA|r clicked:", goal.title or "goal")
end

local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.Rules = ns.Rules or {}

local Rules = ns.Rules

local function getAverageItemLevel()
    if GetAverageItemLevel then
        local overall, equipped = GetAverageItemLevel()
        return equipped or overall or 0
    end
    return 0
end

function Rules.GetLevel()
    return UnitLevel("player") or 1
end

function Rules.GetMaxLevel()
    return GetMaxLevelForPlayerExpansion and GetMaxLevelForPlayerExpansion()
        or GetMaxPlayerLevel and GetMaxPlayerLevel()
        or 80
end

function Rules.IsMaxLevel()
    return Rules.GetLevel() >= Rules.GetMaxLevel()
end

function Rules.GetItemLevel()
    return getAverageItemLevel()
end

function Rules.GetZoneName()
    return GetRealZoneText() or GetZoneText() or "Unknown"
end

function Rules.GetPlayerSnapshot()
    return {
        level = Rules.GetLevel(),
        maxLevel = Rules.GetMaxLevel(),
        isMax = Rules.IsMaxLevel(),
        ilvl = Rules.GetItemLevel(),
        zone = Rules.GetZoneName(),
    }
end

function Rules.ShouldLeveling()
    local snap = Rules.GetPlayerSnapshot()
    return snap.level < snap.maxLevel
end

function Rules.ShouldGearUp()
    local snap = Rules.GetPlayerSnapshot()

    if snap.level < snap.maxLevel then
        return false
    end

    return snap.ilvl > 0 and snap.ilvl < 300
end

function Rules.ShouldWeekly()
    local snap = Rules.GetPlayerSnapshot()

    if snap.level < snap.maxLevel then
        return false
    end

    return snap.ilvl >= 300
end

function Rules.GetProgressionPhase()
    local snap = Rules.GetPlayerSnapshot()

    if snap.level < snap.maxLevel then
        return "leveling"
    end

    if snap.ilvl > 0 and snap.ilvl < 300 then
        return "gearing"
    end

    return "weekly"
end

function Rules.GetGearBand()
    local snap = Rules.GetPlayerSnapshot()

    if not snap or not snap.ilvl then
        return "unknown"
    end

    if snap.ilvl < 220 then
        return "low"
    elseif snap.ilvl < 260 then
        return "mid"
    end

    return "high"
end
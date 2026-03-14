local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.Rules = {}

local Rules = ns.Rules

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
    local _, equipped = GetAverageItemLevel()
    return equipped or 0
end

function Rules.GetZoneName()
    return GetZoneText() or "Unknown"
end

function Rules.ShouldLeveling()
    return not Rules.IsMaxLevel()
end

function Rules.ShouldWeekly()
    return Rules.IsMaxLevel()
end

function Rules.ShouldGearUp()
    if not Rules.IsMaxLevel() then
        return false
    end

    local ilvl = Rules.GetItemLevel()
    return ilvl > 0 and ilvl < 580
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

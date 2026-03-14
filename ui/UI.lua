local addonName, ns = ...

ns = ns or _G.WPA_NS or {}
ns.UI = {}

local UI = ns.UI
local frame
local sections = {}

local statusText = {
    AUTO_DONE = "DONE",
    AUTO_TODO = "TODO",
    AUTO_PARTIAL = "PART",
    MANUAL = "MAN",
    UNKNOWN = "?",
}


local OUTER_MARGIN = 14
local COLUMN_GAP = 14
local ROW_GAP = 8
local SECTION_TOP = -152
local SECTION_HEIGHT = 360
local ROW_HEIGHT = 56
local MAX_ROWS = 5

local function createBackdrop(target)
    target:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    target:SetBackdropColor(0, 0, 0, 0.9)
end

local function getColumnWidth()
    local totalWidth = frame:GetWidth() - (OUTER_MARGIN * 2) - (COLUMN_GAP * 2)
    return math.floor(totalWidth / 3)
end

local function createRow(parent, width, index)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetSize(width, ROW_HEIGHT)
    createBackdrop(row)
    row:SetBackdropColor(0.08, 0.08, 0.08, 0.45)

    if index == 1 then
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    else
        row:SetPoint("TOPLEFT", parent.rows[index - 1], "BOTTOMLEFT", 0, -ROW_GAP)
    end

    row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
    row.title:SetJustifyH("LEFT")
    row.title:SetWidth(width - 20)

    row.reason = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.reason:SetPoint("TOPLEFT", row.title, "BOTTOMLEFT", 0, -4)
    row.reason:SetJustifyH("LEFT")
    row.reason:SetWidth(width - 20)

    row:SetScript("OnEnter", function(self)
    if not self.item or not GameTooltip then
        return
    end

    local item = self.item
    local score = item.score or 0
    local priorityLabel = item.priorityLabel or "LOW"

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(item.title or "Objectif")
    GameTooltip:AddLine(item.reason or "", 1, 1, 1, true)
    GameTooltip:AddLine("Status: " .. tostring(item.status or "UNKNOWN"), 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Priority: " .. tostring(priorityLabel), 1, 0.82, 0)
    GameTooltip:AddLine("Score: " .. tostring(score), 0.6, 1, 0.6)

    if item.goal and item.goal.sourceID then
        GameTooltip:AddLine("SourceID: " .. tostring(item.goal.sourceID), 0.6, 0.8, 1)
    end

    GameTooltip:AddLine("Click: action rapide", 1, 0.82, 0)
    GameTooltip:Show()
end)

    row:SetScript("OnLeave", function()
        if GameTooltip then
            GameTooltip:Hide()
        end
    end)

    row:SetScript("OnClick", function(self)
        if ns.Engine and ns.Engine.OnSuggestionClick then
            ns.Engine.OnSuggestionClick(self.item)
        end
    end)

    return row
end

local function createSection(parent, title, columnIndex)
    local section = CreateFrame("Frame", nil, parent)
    section.titleText = title
    section.columnIndex = columnIndex
    section.rows = {}

    section.header = section:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    section.header:SetJustifyH("LEFT")
    section.header:SetText(title)

    for i = 1, MAX_ROWS do
        section.rows[i] = createRow(section, 200, i)
    end

    return section
end

local function layoutSection(section)
    local colWidth = getColumnWidth()
    local x = OUTER_MARGIN + ((section.columnIndex - 1) * (colWidth + COLUMN_GAP))

    section:ClearAllPoints()
    section:SetPoint("TOPLEFT", frame, "TOPLEFT", x, SECTION_TOP)
    section:SetSize(colWidth, SECTION_HEIGHT)

    section.header:ClearAllPoints()
    section.header:SetPoint("BOTTOMLEFT", section, "TOPLEFT", 0, 10)
    section.header:SetWidth(colWidth)

    for _, row in ipairs(section.rows) do
        row:SetWidth(colWidth)
        row.title:SetWidth(colWidth - 20)
        row.reason:SetWidth(colWidth - 20)
    end
end

local function fillSection(section, items)
    for i, row in ipairs(section.rows) do
        local item = items[i]
        if item then
            local status = statusText[item.status] or "?"
            row.item = item
            local priorityLabel = item.priorityLabel or "LOW"
row.title:SetText(string.format("[%s] %s %s", priorityLabel, status, item.title or "Objectif"))
            row.reason:SetText(item.reason or "")
            row:Show()
        else
            row.item = nil
            row:Hide()
        end
    end
end

function UI.Create()
    if frame then
        return
    end

    frame = CreateFrame("Frame", "WPA_MainFrame", UIParent, "BackdropTemplate")
    frame:SetSize(ns.db.window.width, ns.db.window.height)
    frame:SetPoint(ns.db.window.point, UIParent, ns.db.window.relativePoint, ns.db.window.x, ns.db.window.y)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        ns.db.window.point = point
        ns.db.window.relativePoint = relativePoint
        ns.db.window.x = x
        ns.db.window.y = y
    end)

    createBackdrop(frame)

    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", OUTER_MARGIN, -12)
    frame.title:SetText("WoW Progression Advisor")

    frame.subTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.subTitle:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subTitle:SetText("Smart suggestions based on your character progression")

    frame.modeLine = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.modeLine:SetPoint("TOPLEFT", frame.subTitle, "BOTTOMLEFT", 0, -8)
frame.modeLine:SetText("Advisor mode: UNKNOWN")

frame.focusLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
frame.focusLine:SetPoint("TOPLEFT", frame.modeLine, "BOTTOMLEFT", 0, -4)
frame.focusLine:SetText("Focus: ...")


    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

    frame.bestBox = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.bestBox:SetPoint("TOPLEFT", frame, "TOPLEFT", OUTER_MARGIN, -82)
frame.bestBox:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -OUTER_MARGIN, -82)
    frame.bestBox:SetHeight(54)
    createBackdrop(frame.bestBox)
    frame.bestBox:SetBackdropColor(0.05, 0.12, 0.05, 0.8)

    frame.bestTitle = frame.bestBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.bestTitle:SetPoint("TOPLEFT", frame.bestBox, "TOPLEFT", 10, -7)
    frame.bestTitle:SetWidth(frame:GetWidth() - 40)
    frame.bestTitle:SetJustifyH("LEFT")

    frame.bestReason = frame.bestBox:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.bestReason:SetPoint("TOPLEFT", frame.bestTitle, "BOTTOMLEFT", 0, -4)
    frame.bestReason:SetWidth(frame:GetWidth() - 40)
    frame.bestReason:SetJustifyH("LEFT")

    frame.snapshot = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.snapshot:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", OUTER_MARGIN, 14)
    frame.snapshot:SetText("")

    sections.leveling = createSection(frame, "LEVELING", 1)
    sections.custom = createSection(frame, "CUSTOM GOALS", 2)
    sections.weekly = createSection(frame, "WEEKLY", 3)

    layoutSection(sections.leveling)
    layoutSection(sections.custom)
    layoutSection(sections.weekly)

    frame:Hide()
    UI.Refresh()
end

function UI.Refresh()
    if not frame then
        return
    end

    layoutSection(sections.leveling)
    layoutSection(sections.custom)
    layoutSection(sections.weekly)

    local grouped = ns.Engine and ns.Engine.GetGroupedSuggestions and ns.Engine.GetGroupedSuggestions() or {
        leveling = {},
        custom = {},
        weekly = {},
    }

    local best = ns.Engine and ns.Engine.GetBestSuggestion and ns.Engine.GetBestSuggestion() or nil
    local snap = ns.Engine and ns.Engine.GetSnapshot and ns.Engine.GetSnapshot() or nil

    local phase = snap and snap.phase or "unknown"
local modeText = "Advisor mode: UNKNOWN"
local focusText = "Focus: analyse indisponible"

if phase == "leveling" then
    modeText = "Advisor mode: LEVELING"
    focusText = "Focus: monter en niveau efficacement"
elseif phase == "gearing" then
    modeText = "Advisor mode: GEARING"
    focusText = "Focus: ameliorer votre equipement"
elseif phase == "weekly" then
    modeText = "Advisor mode: WEEKLY"
    focusText = "Focus: optimiser vos activites hebdomadaires"
end

frame.modeLine:SetText(modeText)
frame.focusLine:SetText(focusText)

    if best then
        frame.bestTitle:SetText("Best next action: " .. (best.title or "Objectif"))
        frame.bestReason:SetText(best.reason or "")
    else
        frame.bestTitle:SetText("Best next action: none")
        frame.bestReason:SetText("")
    end

    if snap then
        frame.snapshot:SetText(
    string.format(
        "Level %d/%d | ilvl %.1f | phase: %s | zone: %s",
        snap.level or 0,
        snap.maxLevel or 0,
        snap.ilvl or 0,
        snap.phase or "unknown",
        snap.zone or "Unknown"
    )
)
    else
        frame.snapshot:SetText("")
    end

    fillSection(sections.leveling, grouped.leveling or {})
    fillSection(sections.custom, grouped.custom or {})
    fillSection(sections.weekly, grouped.weekly or {})
end

function UI.Toggle()
    if not frame then
        return
    end

    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        UI.Refresh()
    end
end

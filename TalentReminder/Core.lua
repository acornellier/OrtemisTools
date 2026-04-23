local addonName, ns = ...
local TR = ns.TalentReminder

local ICON_SIZE = 80
local ICON_SPACING = 8

local GREEN = {0, 0.8, 0}
local RED = {0.8, 0, 0}

-- Main frame
local frame = CreateFrame("Frame", "OrtemisToolsTalentReminderFrame", UIParent)
frame:SetSize(1, 1)
frame:SetPoint("TOP", UIParent, "TOP", 0, -140)
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint()
    OrtemisToolsDB.position = { point = point, x = x, y = y }
end)
frame:SetClampedToScreen(true)
frame:Hide()

TR.frame = frame

local icons = {}

local function GetOrCreateIcon(index)
    if icons[index] then return icons[index] end

    local btn = CreateFrame("Frame", nil, frame)
    btn:SetSize(ICON_SIZE, ICON_SIZE)

    if index == 1 then
        btn:SetPoint("LEFT", frame, "LEFT", 0, 0)
    else
        btn:SetPoint("LEFT", icons[index - 1], "RIGHT", ICON_SPACING, 0)
    end

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()

    btn:EnableMouse(true)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetSpellByID(self.spellID)
        if self.action then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(self.action, unpack(self.glowColor))
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    icons[index] = btn
    return btn
end

local function CreateProcGlow(btn)
    if btn.procGlow then return end

    local glow = CreateFrame("Frame", nil, btn)
    glow:SetAllPoints()
    glow:SetFrameLevel(btn:GetFrameLevel() + 1)

    glow.loop = glow:CreateTexture(nil, "OVERLAY")
    glow.loop:SetAtlas("UI-HUD-ActionBar-Proc-Loop-Flipbook")
    glow.loop:SetDesaturated(true)
    glow.loop:SetPoint("CENTER")
    glow.loop:SetSize(ICON_SIZE * 1.4, ICON_SIZE * 1.4)
    glow.loop:SetAlpha(0)

    glow.loopAnim = glow:CreateAnimationGroup()
    glow.loopAnim:SetLooping("REPEAT")

    local fadeIn = glow.loopAnim:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.001)
    fadeIn:SetOrder(0)

    local flipbook = glow.loopAnim:CreateAnimation("FlipBook")
    flipbook:SetTarget(glow.loop)
    flipbook:SetFlipBookRows(6)
    flipbook:SetFlipBookColumns(5)
    flipbook:SetFlipBookFrames(30)
    flipbook:SetDuration(1.0)
    flipbook:SetOrder(0)

    glow.loopAnim:SetScript("OnPlay", function()
        glow.loop:SetAlpha(1)
    end)
    glow.loopAnim:SetScript("OnStop", function()
        glow.loop:SetAlpha(0)
    end)

    btn.procGlow = glow
end

local function StartGlow(btn, color)
    CreateProcGlow(btn)
    btn.procGlow.loop:SetVertexColor(color[1], color[2], color[3])
    btn.procGlow.loopAnim:Play()
end

local function StopGlow(btn)
    if btn.procGlow then
        btn.procGlow.loopAnim:Stop()
    end
end

local function IsMistweaver()
    local _, _, classID = UnitClass("player")
    if classID ~= 10 then return false end
    local specIndex = GetSpecialization()
    return specIndex == 2
end

local function IsTalentKnown(spellID)
    return IsPlayerSpell(spellID)
end

local function GetCurrentDungeon()
    local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
    if difficultyID == TR.MYTHIC_DIFFICULTY_ID and TR.dungeonByID[instanceID] then
        return instanceID
    end
    return nil
end

function TR:UpdateDisplay()
    -- Stop glows and hide all existing icons
    for _, icon in ipairs(icons) do
        StopGlow(icon)
        icon:Hide()
    end

    if OrtemisToolsDB.enabled == false or not IsMistweaver() then
        frame:Hide()
        return
    end

    local dungeonID = GetCurrentDungeon()
    if not dungeonID then
        frame:Hide()
        return
    end

    local db = OrtemisToolsDB.talentConfig
    local showCount = 0

    for _, talent in ipairs(TR.talents) do
        local configEnabled = db[talent.spellID] and db[talent.spellID][dungeonID]
        local isKnown = IsTalentKnown(talent.spellID)

        local color, action
        if configEnabled and not isKnown then
            color = GREEN
            action = "Take this talent"
        elseif not configEnabled and isKnown then
            color = RED
            action = "Drop this talent"
        end

        if color then
            showCount = showCount + 1
            local btn = GetOrCreateIcon(showCount)
            btn.spellID = talent.spellID
            btn.glowColor = color
            btn.action = action
            btn.icon:SetTexture(C_Spell.GetSpellTexture(talent.spellID))
            btn:Show()
            StartGlow(btn, color)
        end
    end

    if showCount > 0 then
        frame:SetSize(
            showCount * ICON_SIZE + (showCount - 1) * ICON_SPACING,
            ICON_SIZE
        )
        frame:Show()
    else
        frame:Hide()
    end
end

-- Initialize saved variables
local function InitDB()
    OrtemisToolsDB = OrtemisToolsDB or {}
    if OrtemisToolsDB.enabled == nil then OrtemisToolsDB.enabled = false end
    OrtemisToolsDB.talentConfig = OrtemisToolsDB.talentConfig or {}

    -- Merge defaults for any missing entries
    for spellID, dungeonDefaults in pairs(TR.defaults) do
        OrtemisToolsDB.talentConfig[spellID] = OrtemisToolsDB.talentConfig[spellID] or {}
        for dungeonID, default in pairs(dungeonDefaults) do
            if OrtemisToolsDB.talentConfig[spellID][dungeonID] == nil then
                OrtemisToolsDB.talentConfig[spellID][dungeonID] = default
            end
        end
    end

    -- Restore position
    if OrtemisToolsDB.position then
        local pos = OrtemisToolsDB.position
        frame:ClearAllPoints()
        frame:SetPoint(pos.point, UIParent, pos.point, pos.x, pos.y)
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            InitDB()
            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUi = ...
        if not (isInitialLogin or isReloadingUi) then
            C_Timer.NewTimer(0.5, function()
                TR:UpdateDisplay()
            end)
        else
            C_Timer.NewTimer(1, function()
                TR:UpdateDisplay()
            end)
        end

    elseif event == "TRAIT_CONFIG_UPDATED" or event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        if frame:IsVisible() or GetCurrentDungeon() then
            C_Timer.NewTimer(0.2, function()
                TR:UpdateDisplay()
            end)
        end

    elseif event == "CHALLENGE_MODE_START" then
        frame:Hide()
    end
end)

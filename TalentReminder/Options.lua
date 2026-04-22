local addonName, ns = ...
local TR = ns.TalentReminder

local COL_WIDTH = 60
local ROW_HEIGHT = 30
local HEADER_HEIGHT = 24
local TALENT_LABEL_WIDTH = 140

-- Create the options panel
local optionsFrame = CreateFrame("Frame", "OrtemisToolsOptionsFrame", UIParent)
optionsFrame:Hide()

-- Chi Balls section
local cbTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cbTitle:SetPoint("TOPLEFT", 16, -16)
cbTitle:SetText("Chi Balls")

local chiballsEnabledCB = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
chiballsEnabledCB:SetSize(24, 24)
chiballsEnabledCB:SetPoint("LEFT", cbTitle, "RIGHT", 8, 0)
chiballsEnabledCB.text = chiballsEnabledCB:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
chiballsEnabledCB.text:SetPoint("LEFT", chiballsEnabledCB, "RIGHT", 2, 0)
chiballsEnabledCB.text:SetText("Enabled")
chiballsEnabledCB:SetScript("OnShow", function(self)
    self:SetChecked(OrtemisToolsDB.chiBalls and OrtemisToolsDB.chiBalls.enabled ~= false)
end)
chiballsEnabledCB:SetScript("OnClick", function(self)
    OrtemisToolsDB.chiBalls = OrtemisToolsDB.chiBalls or {}
    OrtemisToolsDB.chiBalls.enabled = self:GetChecked()
    if ns.ChiBalls then ns.ChiBalls.refresh() end
end)

local cbDesc = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
cbDesc:SetPoint("TOPLEFT", cbTitle, "BOTTOMLEFT", 0, -6)
cbDesc:SetText("Displays Teachings of the Monastery stacks. Requires buff to be enabled in CDM as a Tracked Buff. Configure in Edit Mode.\n\nThanks to sfmict for developing this module!")
cbDesc:SetTextColor(0.7, 0.7, 0.7)
cbDesc:SetWidth(500)
cbDesc:SetJustifyH("LEFT")

-- Talent Reminders section
local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", cbDesc, "BOTTOMLEFT", 0, -24)
title:SetText("Talent Reminders")

local enableCB = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
enableCB:SetSize(24, 24)
enableCB:SetPoint("LEFT", title, "RIGHT", 8, 0)
enableCB.text = enableCB:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
enableCB.text:SetPoint("LEFT", enableCB, "RIGHT", 2, 0)
enableCB.text:SetText("Enabled")
enableCB:SetScript("OnShow", function(self)
    self:SetChecked(OrtemisToolsDB.enabled ~= false)
end)
enableCB:SetScript("OnClick", function(self)
    OrtemisToolsDB.enabled = self:GetChecked()
    TR:UpdateDisplay()
end)

-- Grid container
local grid = CreateFrame("Frame", nil, optionsFrame)
grid:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
grid:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -16, 16)

local checkboxes = {}

local function CreateGrid()
    -- Clear existing checkboxes
    for _, cb in ipairs(checkboxes) do
        cb:Hide()
    end
    checkboxes = {}

    local dungeons = TR.dungeons
    local talents = TR.talents

    -- Column headers (dungeon names)
    for col, dungeon in ipairs(dungeons) do
        local header = grid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOP", grid, "TOPLEFT",
            TALENT_LABEL_WIDTH + (col - 1) * COL_WIDTH + COL_WIDTH / 2,
            0)
        header:SetWidth(COL_WIDTH - 4)
        header:SetJustifyH("CENTER")
        header:SetText(dungeon.short)
        header:SetTextColor(1, 0.82, 0)

        -- Tooltip for full name
        local headerBtn = CreateFrame("Frame", nil, grid)
        headerBtn:SetSize(COL_WIDTH, HEADER_HEIGHT)
        headerBtn:SetPoint("TOP", header, "TOP", 0, 4)
        headerBtn:EnableMouse(true)
        headerBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
            GameTooltip:AddLine(dungeon.name)
            GameTooltip:Show()
        end)
        headerBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- Rows (talents)
    for row, talent in ipairs(talents) do
        local yOffset = -(HEADER_HEIGHT + (row - 1) * ROW_HEIGHT)

        -- Talent icon
        local icon = grid:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, yOffset - 4)
        icon:SetTexture(C_Spell.GetSpellTexture(talent.spellID))

        -- Talent name
        local label = grid:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(talent.name)

        -- Checkboxes for each dungeon
        for col, dungeon in ipairs(dungeons) do
            local cb = CreateFrame("CheckButton", nil, grid, "UICheckButtonTemplate")
            cb:SetSize(24, 24)
            cb:SetPoint("TOP", grid, "TOPLEFT",
                TALENT_LABEL_WIDTH + (col - 1) * COL_WIDTH + COL_WIDTH / 2,
                yOffset - 2)

            cb:SetChecked(
                OrtemisToolsDB.talentConfig[talent.spellID]
                and OrtemisToolsDB.talentConfig[talent.spellID][dungeon.id]
                or false
            )

            cb:SetScript("OnClick", function(self)
                OrtemisToolsDB.talentConfig[talent.spellID] = OrtemisToolsDB.talentConfig[talent.spellID] or {}
                OrtemisToolsDB.talentConfig[talent.spellID][dungeon.id] = self:GetChecked()
                TR:UpdateDisplay()
            end)

            checkboxes[#checkboxes + 1] = cb
        end
    end
end

-- Defaults button
local defaultsBtn = CreateFrame("Button", nil, optionsFrame, "UIPanelButtonTemplate")
defaultsBtn:SetSize(100, 22)
defaultsBtn:SetText("Defaults")
defaultsBtn:SetPoint("BOTTOMLEFT", optionsFrame, "BOTTOMLEFT", 16, 16)
defaultsBtn:SetScript("OnClick", function()
    OrtemisToolsDB.talentConfig = {}
    for spellID, dungeonDefaults in pairs(TR.defaults) do
        OrtemisToolsDB.talentConfig[spellID] = {}
        for dungeonID, default in pairs(dungeonDefaults) do
            OrtemisToolsDB.talentConfig[spellID][dungeonID] = default
        end
    end
    CreateGrid()
    TR:UpdateDisplay()
end)

optionsFrame:SetScript("OnShow", function()
    CreateGrid()
end)

-- Register with the Settings API
local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, "OrtemisTools")
Settings.RegisterAddOnCategory(category)

-- Slash command
SLASH_ORTEMISTOOLS1 = "/ort"
SlashCmdList["ORTEMISTOOLS"] = function()
    Settings.OpenToCategory(category:GetID())
end

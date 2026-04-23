local addonName, ns = ...
local TR = ns.TalentReminder

local COL_WIDTH = 60
local ROW_HEIGHT = 30
local HEADER_HEIGHT = 24
local TALENT_LABEL_WIDTH = 140

local optionsFrame = CreateFrame("Frame", "OrtemisToolsOptionsFrame", UIParent)
optionsFrame:Hide()

-- Chi Balls section
local cbTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
cbTitle:SetPoint("TOPLEFT", 16, -16)
cbTitle:SetText("Teachings of the Monastery Balls")

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
cbDesc:SetWidth(600)
cbDesc:SetJustifyH("LEFT")

-- Spiritfont section
local sfTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
sfTitle:SetPoint("TOPLEFT", cbDesc, "BOTTOMLEFT", 0, -24)
sfTitle:SetText("Spiritfont Balls")

local spiritfontEnabledCB = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
spiritfontEnabledCB:SetSize(24, 24)
spiritfontEnabledCB:SetPoint("LEFT", sfTitle, "RIGHT", 8, 0)
spiritfontEnabledCB.text = spiritfontEnabledCB:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
spiritfontEnabledCB.text:SetPoint("LEFT", spiritfontEnabledCB, "RIGHT", 2, 0)
spiritfontEnabledCB.text:SetText("Enabled")
spiritfontEnabledCB:SetScript("OnShow", function(self)
    self:SetChecked(not OrtemisToolsDB.spiritFont or OrtemisToolsDB.spiritFont.enabled ~= false)
end)
spiritfontEnabledCB:SetScript("OnClick", function(self)
    OrtemisToolsDB.spiritFont = OrtemisToolsDB.spiritFont or {}
    OrtemisToolsDB.spiritFont.enabled = self:GetChecked()
    if ns.Spiritfont then ns.Spiritfont.refresh() end
end)

local sfDesc = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
sfDesc:SetPoint("TOPLEFT", sfTitle, "BOTTOMLEFT", 0, -6)
sfDesc:SetText("Displays Spirit Font stacks. Requires buff to be enabled in CDM as a Tracked Buff. Configure in Edit Mode.")
sfDesc:SetTextColor(0.7, 0.7, 0.7)
sfDesc:SetWidth(600)
sfDesc:SetJustifyH("LEFT")

-- Dance of Chi Ji section
local dTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
dTitle:SetPoint("TOPLEFT", sfDesc, "BOTTOMLEFT", 0, -24)
dTitle:SetText("Dance of Chi-Ji Balls")

local danceEnabledCB = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
danceEnabledCB:SetSize(24, 24)
danceEnabledCB:SetPoint("LEFT", dTitle, "RIGHT", 8, 0)
danceEnabledCB.text = danceEnabledCB:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
danceEnabledCB.text:SetPoint("LEFT", danceEnabledCB, "RIGHT", 2, 0)
danceEnabledCB.text:SetText("Enabled")
danceEnabledCB:SetScript("OnShow", function(self)
    self:SetChecked(not OrtemisToolsDB.danceOfChiJi or OrtemisToolsDB.danceOfChiJi.enabled ~= false)
end)
danceEnabledCB:SetScript("OnClick", function(self)
    OrtemisToolsDB.danceOfChiJi = OrtemisToolsDB.danceOfChiJi or {}
    OrtemisToolsDB.danceOfChiJi.enabled = self:GetChecked()
    if ns.DanceOfChiJi then ns.DanceOfChiJi.refresh() end
end)

local dDesc = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
dDesc:SetPoint("TOPLEFT", dTitle, "BOTTOMLEFT", 0, -6)
dDesc:SetText("Displays Dance of Chi Ji proc. Requires buff to be enabled in CDM as a Tracked Buff. Configure in Edit Mode.")
dDesc:SetTextColor(0.7, 0.7, 0.7)
dDesc:SetWidth(600)
dDesc:SetJustifyH("LEFT")

-- Renewing Mist section
local remTitle = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
remTitle:SetPoint("TOPLEFT", dDesc, "BOTTOMLEFT", 0, -24)
remTitle:SetText("Renewing Mist")

local remEnabledCB = CreateFrame("CheckButton", nil, optionsFrame, "UICheckButtonTemplate")
remEnabledCB:SetSize(24, 24)
remEnabledCB:SetPoint("LEFT", remTitle, "RIGHT", 8, 0)
remEnabledCB.text = remEnabledCB:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
remEnabledCB.text:SetPoint("LEFT", remEnabledCB, "RIGHT", 2, 0)
remEnabledCB.text:SetText("Enabled")
remEnabledCB:SetScript("OnShow", function(self)
    self:SetChecked(OrtemisToolsDB.renewingMist and OrtemisToolsDB.renewingMist.enabled ~= false)
end)
remEnabledCB:SetScript("OnClick", function(self)
    OrtemisToolsDB.renewingMist = OrtemisToolsDB.renewingMist or {}
    OrtemisToolsDB.renewingMist.enabled = self:GetChecked()
    if ns.RenewingMist then ns.RenewingMist.refresh() end
end)

local remDesc = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
remDesc:SetPoint("TOPLEFT", remTitle, "BOTTOMLEFT", 0, -6)
remDesc:SetText("Displays Renewing Mist charges as horizontal progress bars. Configure in Edit Mode.")
remDesc:SetTextColor(0.7, 0.7, 0.7)
remDesc:SetWidth(600)
remDesc:SetJustifyH("LEFT")

-- Talent Reminders section
local title = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", remDesc, "BOTTOMLEFT", 0, -24)
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

local grid = CreateFrame("Frame", nil, optionsFrame)
grid:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
grid:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -16, 16)

local checkboxes = {}

local function CreateGrid()
    for _, cb in ipairs(checkboxes) do
        cb:Hide()
    end
    checkboxes = {}

    local dungeons = TR.dungeons
    local talents = TR.talents

    for col, dungeon in ipairs(dungeons) do
        local header = grid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("TOP", grid, "TOPLEFT",
            TALENT_LABEL_WIDTH + (col - 1) * COL_WIDTH + COL_WIDTH / 2,
            0)
        header:SetWidth(COL_WIDTH - 4)
        header:SetJustifyH("CENTER")
        header:SetText(dungeon.short)
        header:SetTextColor(1, 0.82, 0)

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

    for row, talent in ipairs(talents) do
        local yOffset = -(HEADER_HEIGHT + (row - 1) * ROW_HEIGHT)

        local icon = grid:CreateTexture(nil, "ARTWORK")
        icon:SetSize(20, 20)
        icon:SetPoint("TOPLEFT", grid, "TOPLEFT", 0, yOffset - 4)
        icon:SetTexture(C_Spell.GetSpellTexture(talent.spellID))

        local label = grid:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        label:SetPoint("LEFT", icon, "RIGHT", 6, 0)
        label:SetText(talent.name)

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

local category = Settings.RegisterCanvasLayoutCategory(optionsFrame, "OrtemisTools")
Settings.RegisterAddOnCategory(category)

SLASH_ORTEMISTOOLS1 = "/ort"
SlashCmdList["ORTEMISTOOLS"] = function()
    Settings.OpenToCategory(category:GetID())
end

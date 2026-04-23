local addonName, ns = ...

if select(2, UnitClass("player")) ~= "MONK" then return end

local ReM = {}
ns.RenewingMist = ReM

local anchorFrame = CreateFrame("FRAME", nil, UIParent)
anchorFrame.editModeName = "Renewing Mist"
anchorFrame:SetClampedToScreen(true)

local spellID = 115151
local maxStacks = 3
local bars = {}
local barFrame = nil
local isEditing = false
local eventFrame = nil

-- currentCharges is always a secret value from addon code (Blizzard's design).
-- Arithmetic or comparison on it throws. Track the count locally via events instead.
local localCharges = maxStacks
local pendingConsumed = false  -- true between UNIT_SPELLCAST_SUCCEEDED and its SPELL_UPDATE_CHARGES

for i = 1, maxStacks do
	local f = CreateFrame("Frame", nil, anchorFrame)

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	local bar = CreateFrame("StatusBar", nil, f)
	bar:SetAllPoints()
	bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
	f.bar = bar

	local border = CreateFrame("Frame", nil, f, "BackdropTemplate")
	border:SetAllPoints()
	border:SetFrameLevel(bar:GetFrameLevel() + 1)
	border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	border:SetBackdropBorderColor(0, 0, 0, 1)

	bars[i] = f
end


-- Sync localCharges from the API when the value is readable (out of combat).
local function syncCharges(chargeInfo)
	if not chargeInfo then return end
	if issecretvalue and issecretvalue(chargeInfo.currentCharges) then return end
	localCharges = chargeInfo.currentCharges + 0
end


local function shouldHideBars()
	if not anchorFrame.db or not anchorFrame.db.hideWhenSolo then return false end
	return not UnitExists("target")
		and not UnitAffectingCombat("player")
		and GetNumGroupMembers() == 0
end

local function updateVisibility()
	local show = not shouldHideBars()
	for i = 1, maxStacks do
		bars[i]:SetShown(show)
	end
end


local function updateBars()
	local chargeInfo = C_Spell.GetSpellCharges(spellID)
	if not chargeInfo then
		for i = 1, maxStacks do
			bars[i].bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
			bars[i].bar:SetValue(0)
		end
		return
	end

	syncCharges(chargeInfo)

	local charges = localCharges
	local isRecharging = chargeInfo.isActive == true  -- non-secret bool per 12.0.1

	for i = 1, maxStacks do
		local b = bars[i].bar
		if i <= charges then
			b:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
			b:SetValue(1)
		elseif i == charges + 1 and isRecharging then
			local durObj = C_Spell.GetSpellChargeDuration(spellID)
			if durObj then
				-- SetMinMaxValues and SetTimerDuration accept secret values
				b:SetMinMaxValues(0, chargeInfo.cooldownDuration)
				b:SetTimerDuration(durObj, Enum.StatusBarInterpolation.None, Enum.StatusBarTimerDirection.ElapsedTime)
				b:SetToTargetValue()
			else
				b:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
				b:SetValue(0)
			end
		else
			b:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
			b:SetValue(0)
		end
	end
end


local function findCDMBar()
	for f in BuffBarCooldownViewer.itemFramePool:EnumerateActive() do
		if f.cooldownID then
			local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, f.cooldownID)
			if ok and info and info.spellID == spellID then
				return f
			end
		end
	end
	for f in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
		if f.cooldownID then
			local ok, info = pcall(C_CooldownViewer.GetCooldownViewerCooldownInfo, f.cooldownID)
			if ok and info and info.spellID == spellID then
				return f
			end
		end
	end
end


local function refreshHooks()
	if barFrame and barFrame._ReM then
		barFrame.SetAlpha = nil
		barFrame._ReM = nil
		barFrame:SetAlpha(1)
	end
	barFrame = nil

	if OrtemisToolsDB.renewingMist.enabled == false then
		for i = 1, maxStacks do bars[i]:Hide() end
		if eventFrame then eventFrame:UnregisterAllEvents() end
		return
	end

	if isEditing then
		for i = 1, maxStacks do
			bars[i]:Show()
			bars[i].bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
			bars[i].bar:SetValue(1)
		end
		return
	end

	local isMistweaver = C_SpecializationInfo.GetSpecialization() == 2

	if isMistweaver then
		if eventFrame then
			eventFrame:RegisterEvent("SPELL_UPDATE_CHARGES")
			eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
			eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
			eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
			eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
			eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
			eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
		end

		barFrame = findCDMBar()
		if barFrame and anchorFrame.db.hideDefault then
			barFrame._ReM = true
			barFrame:SetAlpha(0)
			local setAlpha = getmetatable(barFrame).__index.SetAlpha
			hooksecurefunc(barFrame, "SetAlpha", function(self)
				setAlpha(self, 0)
			end)
		end

		updateBars()
		updateVisibility()
	else
		for i = 1, maxStacks do bars[i]:Hide() end
		if eventFrame then eventFrame:UnregisterAllEvents() end
	end
end

ReM.refresh = refreshHooks


local function updateLayout(self)
	local db = self.db
	local totalWidth = db.width
	local height = db.height
	local spacing = db.spacing
	local barWidth = math.floor((totalWidth - spacing * (maxStacks - 1)) / maxStacks)

	for i = 1, maxStacks do
		bars[i]:SetSize(barWidth, height)
		bars[i]:ClearAllPoints()
		if i == 1 then
			bars[i]:SetPoint("TOPLEFT", 0, 0)
		else
			bars[i]:SetPoint("TOPLEFT", bars[i - 1], "TOPRIGHT", spacing, 0)
		end
	end

	self:SetSize(totalWidth, height)
	self:ClearAllPoints()
	self:SetPoint(self.db.point, self.db.x, self.db.y)
end


local function init(self)
	OrtemisToolsDB.renewingMist = OrtemisToolsDB.renewingMist or {}
	if OrtemisToolsDB.renewingMist.enabled == nil then OrtemisToolsDB.renewingMist.enabled = true end
	self.db = OrtemisToolsDB.renewingMist
	local db = self.db
	if db.hideDefault == nil then db.hideDefault = true end
	if db.hideWhenSolo == nil then db.hideWhenSolo = true end
	db.width = db.width or 230
	db.height = db.height or 16
	db.spacing = db.spacing or 2
	db.point = db.point or "BOTTOM"
	db.x = db.x or 0
	db.y = db.y or UIParent:GetHeight() / 5 * 2

	local tex = LibStub("LibSharedMedia-3.0"):Fetch("statusbar", "Steel")
	for i = 1, maxStacks do
		bars[i].bar:SetStatusBarTexture(tex)
		bars[i].bar:SetStatusBarColor(0, 1, 188 / 255)
	end
end


local function onPositionChanged(self, layoutName, point, x, y)
	self.db.point = point
	self.db.x = x
	self.db.y = y
end


C_Timer.After(0, function()
	init(anchorFrame)

	local specFrame = CreateFrame("Frame")
	specFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	specFrame:SetScript("OnEvent", function()
		refreshHooks()
	end)

	eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", function(self, event, a1, a2, a3)
		if event == "UNIT_SPELLCAST_SUCCEEDED" then
			if a3 ~= spellID then return end
			-- Charge consumed: decrement before SPELL_UPDATE_CHARGES fires
			pendingConsumed = true
			localCharges = math.max(0, localCharges - 1)

		elseif event == "SPELL_UPDATE_CHARGES" then
			local chargeInfo = C_Spell.GetSpellCharges(spellID)
			if chargeInfo then
				if chargeInfo.isActive ~= true then
					-- No recharge in progress = all charges full
					localCharges = maxStacks
				elseif not pendingConsumed then
					-- isActive==true and not from our own cast: a charge was gained
					localCharges = math.min(maxStacks - 1, localCharges + 1)
				end
				pendingConsumed = false
			end

		elseif event == "PLAYER_REGEN_ENABLED" then
			-- Out of combat: sync from API now that values are readable
			local chargeInfo = C_Spell.GetSpellCharges(spellID)
			syncCharges(chargeInfo)
		end

		updateBars()
		updateVisibility()
	end)

	refreshHooks()

	local defaultData = {
		point = "BOTTOM",
		x = 0,
		y = UIParent:GetHeight() / 5 * 2,
	}

	local lem = LibStub("LibEditMode")
	lem:AddFrame(anchorFrame, onPositionChanged, defaultData)
	lem:AddFrameSettings(anchorFrame, {
		{
			name = "Hide from CDM",
			kind = lem.SettingType.Checkbox,
			default = true,
			get = function()
				return anchorFrame.db.hideDefault
			end,
			set = function(_, value)
				anchorFrame.db.hideDefault = value
				refreshHooks()
			end,
		},
		{
			name = "Hide if solo, out of combat, and no target",
			kind = lem.SettingType.Checkbox,
			default = true,
			get = function()
				return anchorFrame.db.hideWhenSolo
			end,
			set = function(_, value)
				anchorFrame.db.hideWhenSolo = value
				updateVisibility()
			end,
		},
		{
			name = "Width",
			kind = lem.SettingType.Slider,
			default = 230,
			minValue = 30,
			maxValue = 600,
			valueStep = 1,
			get = function()
				return anchorFrame.db.width
			end,
			set = function(_, value)
				anchorFrame.db.width = value
				updateLayout(anchorFrame)
			end,
		},
		{
			name = "Height",
			kind = lem.SettingType.Slider,
			default = 16,
			minValue = 4,
			maxValue = 60,
			valueStep = 1,
			get = function()
				return anchorFrame.db.height
			end,
			set = function(_, value)
				anchorFrame.db.height = value
				updateLayout(anchorFrame)
			end,
		},
		{
			name = "Spacing",
			kind = lem.SettingType.Slider,
			default = 2,
			minValue = 0,
			maxValue = 20,
			valueStep = 1,
			get = function()
				return anchorFrame.db.spacing
			end,
			set = function(_, value)
				anchorFrame.db.spacing = value
				updateLayout(anchorFrame)
			end,
		},
	})

	lem:RegisterCallback("layout", function(layoutName)
		updateLayout(anchorFrame)
	end)

	lem:RegisterCallback("enter", function()
		isEditing = true
		if eventFrame then eventFrame:UnregisterAllEvents() end
		for i = 1, maxStacks do
			bars[i]:Show()
			bars[i].bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
			bars[i].bar:SetValue(1)
		end
	end)

	lem:RegisterCallback("exit", function()
		isEditing = false
		refreshHooks()
	end)
end)

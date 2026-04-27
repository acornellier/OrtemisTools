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

-- Per-slot structure (ArcUI pattern):
--   slot.fullBar:  SetMinMaxValues(i-0.5, i) + SetValue(secretCurrentCharges)
--                  → full when charges >= i, empty otherwise; sits above rechargeBar
--   slot.detector: offscreen 1px bar, same min/max. detectorTex:GetWidth() gives a
--                  non-secret float (~1 when full, ~0 when empty) for alpha control.
--   slot.rechargeBar: SetTimerDuration applied to all slots; alpha driven by
--                     previous slot's detector width so only the right slot is visible.
for i = 1, maxStacks do
	local f = CreateFrame("Frame", nil, anchorFrame)
	local baseLevel = anchorFrame:GetFrameLevel()

	local bg = f:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.5)

	local rechargeBar = CreateFrame("StatusBar", nil, f)
	rechargeBar:SetAllPoints()
	rechargeBar:SetFrameLevel(baseLevel + 1)
	rechargeBar:SetValue(0)

	local fullBar = CreateFrame("StatusBar", nil, f)
	fullBar:SetAllPoints()
	fullBar:SetFrameLevel(baseLevel + 2)
	fullBar:SetMinMaxValues(i - 0.5, i)
	fullBar:SetValue(0)

	local border = CreateFrame("Frame", nil, f, "BackdropTemplate")
	border:SetAllPoints()
	border:SetFrameLevel(baseLevel + 3)
	border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
	border:SetBackdropBorderColor(0, 0, 0, 1)

	-- Offscreen 1px detector: same min/max as fullBar.
	-- GetWidth() on its texture is non-secret and near-zero when empty (off-screen skips
	-- minimum pixel rendering), used to drive next slot's alpha without secret arithmetic.
	local detector = CreateFrame("StatusBar", nil, UIParent)
	detector:SetSize(1, 10)
	detector:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -500, 500)
	detector:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	detector:SetAlpha(0)
	detector:SetMinMaxValues(i - 0.5, i)
	detector:SetValue(0)
	detector:Show()

	f.rechargeBar = rechargeBar
	f.fullBar = fullBar
	f.detector = detector
	f.detectorTex = detector:GetStatusBarTexture()
	bars[i] = f
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
	if not chargeInfo then return end

	local secretCurrentCharges = chargeInfo.currentCharges
	local isRecharging = chargeInfo.isActive == true

	-- Feed fullBar and detector with the secret charge value.
	-- fullBar renders solid for slots <= currentCharges, transparent otherwise.
	-- detector width is used below to drive the next slot's alpha.
	for i = 1, maxStacks do
		bars[i].fullBar:SetValue(secretCurrentCharges)
		bars[i].detector:SetValue(secretCurrentCharges)
	end

	-- Apply recharge timer to all slots; only the correct slot will be visible
	-- because its alpha is gated by the previous slot's detector width (below).
	if isRecharging then
		local durObj = C_Spell.GetSpellChargeDuration(spellID)
		if durObj then
			for i = 1, maxStacks do
				bars[i].rechargeBar:SetMinMaxValues(0, chargeInfo.cooldownDuration)
				bars[i].rechargeBar:SetTimerDuration(durObj, Enum.StatusBarInterpolation.None, Enum.StatusBarTimerDirection.ElapsedTime)
				bars[i].rechargeBar:SetToTargetValue()
			end
		end
	else
		for i = 1, maxStacks do
			bars[i].rechargeBar:SetValue(0)
		end
	end

	-- Drive slot visibility: slot 1 always fully visible; slot i > 1 gets its alpha
	-- set to prevSlot.detectorTex:GetWidth(), which is non-secret (~1 when full, ~0 when empty).
	for i = 1, maxStacks do
		if i == 1 then
			bars[i].rechargeBar:SetAlpha(1)
			bars[i].fullBar:SetAlpha(1)
		else
			local w = bars[i - 1].detectorTex:GetWidth()
			bars[i].rechargeBar:SetAlpha(w)
			bars[i].fullBar:SetAlpha(w)
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
			bars[i].fullBar:SetValue(i)
			bars[i].fullBar:SetAlpha(1)
			bars[i].rechargeBar:SetValue(0)
			bars[i].rechargeBar:SetAlpha(1)
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
		bars[i].rechargeBar:SetAllPoints(bars[i])
		bars[i].fullBar:SetAllPoints(bars[i])
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
		bars[i].fullBar:SetStatusBarTexture(tex)
		bars[i].fullBar:SetStatusBarColor(0, 1, 188 / 255)
		bars[i].rechargeBar:SetStatusBarTexture(tex)
		bars[i].rechargeBar:SetStatusBarColor(0, 1, 188 / 255)
	end
end


local function onPositionChanged(self, layoutName, point, x, y)
	self.db.point = point
	self.db.x = x
	self.db.y = y
end


C_Timer.After(0, function()
	init(anchorFrame)
	updateLayout(anchorFrame)

	local specFrame = CreateFrame("Frame")
	specFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	specFrame:SetScript("OnEvent", function()
		refreshHooks()
	end)

	eventFrame = CreateFrame("Frame")
	eventFrame:SetScript("OnEvent", function(self, event, a1, a2, a3)
		if event == "UNIT_SPELLCAST_SUCCEEDED" and a3 ~= spellID then return end
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
			bars[i].fullBar:SetValue(i)
			bars[i].fullBar:SetAlpha(1)
			bars[i].rechargeBar:SetValue(0)
			bars[i].rechargeBar:SetAlpha(1)
		end
	end)

	lem:RegisterCallback("exit", function()
		isEditing = false
		refreshHooks()
	end)
end)

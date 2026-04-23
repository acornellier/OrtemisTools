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


local updater = CreateFrame("Frame")
updater:Hide()


local function applyChargeInfo()
	local info = C_Spell.GetSpellCharges(spellID)
	local charges = info and info.currentCharges or 0
	local maxCharges = info and info.maxCharges or maxStacks
	local duration = info and info.cooldownDuration or 0
	local recharging = info and charges < maxCharges and duration > 0

	local progress = 0
	if recharging then
		progress = math.max(0, math.min(1, (GetTime() - (info.cooldownStartTime or 0)) / duration))
	end

	for i = 1, maxStacks do
		if i <= charges then
			bars[i].bar:SetValue(1)
		elseif i == charges + 1 and recharging then
			bars[i].bar:SetValue(progress)
		else
			bars[i].bar:SetValue(0)
		end
	end

	return recharging
end


updater:SetScript("OnUpdate", function()
	if not isEditing then
		applyChargeInfo()
	end
end)


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
		updater:Hide()
		return
	end

	if isEditing then
		updater:Hide()
		for i = 1, maxStacks do
			bars[i]:Show()
			bars[i].bar:SetValue(1)
		end
		return
	end

	local show = C_SpecializationInfo.GetSpecialization() == 2
	for i = 1, maxStacks do
		bars[i]:SetShown(show)
	end
	updater:SetShown(show)
	if not show then return end

	barFrame = findCDMBar()
	if barFrame and anchorFrame.db.hideDefault then
		barFrame._ReM = true
		barFrame:SetAlpha(0)
		local setAlpha = getmetatable(barFrame).__index.SetAlpha
		hooksecurefunc(barFrame, "SetAlpha", function(self)
			setAlpha(self, 0)
		end)
	end

	applyChargeInfo()
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
	self.db = OrtemisToolsDB.renewingMist
	local db = self.db
	if db.hideDefault == nil then db.hideDefault = true end
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

	local eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
	eventFrame:SetScript("OnEvent", function(self, event)
		refreshHooks()
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
		updater:Hide()
		for i = 1, maxStacks do
			bars[i]:Show()
			bars[i].bar:SetValue(1)
		end
	end)

	lem:RegisterCallback("exit", function()
		isEditing = false
		refreshHooks()
	end)
end)

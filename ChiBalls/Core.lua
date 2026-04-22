local addonName, ns = ...

if select(2, UnitClass("player")) ~= "MONK" then return end

local CB = {}
ns.ChiBalls = CB

local anchorFrame = CreateFrame("FRAME", nil, UIParent)
anchorFrame.editModeName = "Chi Balls"
anchorFrame:SetClampedToScreen(true)

local spellID = 116645
local bgAtlas = "uf-chi-bg"
local iconTexture = "Interface\\AddOns\\OrtemisTools\\ChiBalls\\chi_texture"
local iconX = 0
local iconY = 5

local dSize = 50
local iconSize = 32
local maxStacks = 4
local bars, barFrame = {}
local isEditing = false

for i = 1, maxStacks do
	local bar = CreateFrame("StatusBar", nil, anchorFrame)
	bar:SetSize(dSize, dSize)
	bar:SetMinMaxValues(i - 1, i, Enum.StatusBarInterpolation.Immediate)
	bar:SetStatusBarTexture("")
	local barTex = bar:GetStatusBarTexture()
	barTex:SetAtlas(bgAtlas)
	bar.icon = CreateFrame("StatusBar", nil, bar)
	bar.icon:SetSize(iconSize, iconSize)
	bar.icon:SetPoint("CENTER", iconX, iconY)
	bar.icon:SetMinMaxValues(i - 1, i, Enum.StatusBarInterpolation.Immediate)
	bar.icon:SetStatusBarTexture("")
	local iconTex = bar.icon:GetStatusBarTexture()
	iconTex:SetTexture(iconTexture)
	bars[i] = bar
end


local function updateBars(stacks)
	for i = 1, maxStacks do
		bars[i]:SetValue(stacks)
		bars[i].icon:SetValue(stacks)
	end
end


local function getBar(category)
	local cooldownIDs = C_CooldownViewer.GetCooldownViewerCategorySet(category, false)
	for i, cooldownID in ipairs(cooldownIDs) do
		local cooldownInfo = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
		if cooldownInfo.spellID == spellID then
			return cooldownID
		end
	end
end


local function refreshHooks()
	if OrtemisToolsDB.chiBalls.enabled == false then
		for i = 1, maxStacks do bars[i]:Hide() end
		return
	end

	if isEditing then
		for i = 1, maxStacks do bars[i]:Show() end
		updateBars(maxStacks)
		return
	end

	barFrame = nil
	local cdID, applications = getBar(Enum.CooldownViewerCategory.TrackedBuff) or getBar(Enum.CooldownViewerCategory.TrackedBar)

	for f in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
		if f._ChiBalls then
			f.SetAlpha = nil
			f.Applications.Applications.SetText = nil
			f._ChiBalls = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applications = f.Applications.Applications
		end
	end

	for f in BuffBarCooldownViewer.itemFramePool:EnumerateActive() do
		if f._ChiBalls then
			f.SetAlpha = nil
			f.Icon.Applications.SetText = nil
			f._ChiBalls = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applications = f.Icon.Applications
		end
	end

	local show = barFrame and C_SpecializationInfo.GetSpecialization() == 2
	for i, bar in ipairs(bars) do
		bar:SetShown(show)
	end
	if not show then return end

	local alpha = anchorFrame.db.hideDefault and 0 or 1
	barFrame._ChiBalls = true
	barFrame:SetAlpha(alpha)

	local setAlpha = getmetatable(barFrame).__index.SetAlpha
	hooksecurefunc(barFrame, "SetAlpha", function(self)
		setAlpha(self, alpha)
	end)
	hooksecurefunc(applications, "SetText", function(self, count)
		if isEditing then return end
		updateBars(tonumber(count) or barFrame:GetAuraSpellInstanceID() and 1 or 0)
	end)

	local stacks = 0
	local auraInstanceID = barFrame:GetAuraSpellInstanceID()
	if auraInstanceID then
		local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
		stacks = auraData and auraData.applications or 0
	end

	updateBars(stacks)
end

CB.refresh = refreshHooks


local function updateLayout(self)
	local size = self.db.size
	local gap = self.db.gap
	local yOffset14 = self.db.yOffset14
	local ballPos = self.db.ballPos
	local scale = size / dSize
	local x = (size + gap) / scale
	local y = yOffset14 / scale
	local x1 = x * .5
	local x2 = (x > math.abs(y) and math.sqrt(x*x - y*y) or x) + x1
	local y1 = 15
	local y2 = y + y1

	for i = 1, maxStacks do
		bars[i]:SetScale(scale)
		bars[i].icon:SetSize(self.db.iconSize, self.db.iconSize)
	end
	bars[ballPos[1]]:SetPoint("BOTTOM", -x2, y2)
	bars[ballPos[2]]:SetPoint("BOTTOM", -x1, y1)
	bars[ballPos[3]]:SetPoint("BOTTOM", x1, y1)
	bars[ballPos[4]]:SetPoint("BOTTOM", x2, y2)

	self:SetSize((size + gap) * 4 - gap + 10, size + 30)
	self:ClearAllPoints()
	self:SetPoint(self.db.point, self.db.x, self.db.y)
end


local function init(self)
	self.db = OrtemisToolsDB.chiBalls
	local db = self.db
	if db.hideDefault == nil then db.hideDefault = true end
	db.size = db.size or 28
	db.gap = db.gap or -2
	db.iconSize = db.iconSize or 32
	db.yOffset14 = db.yOffset14 or 10
	db.ballPos = db.ballPos or {}
	db.ballPos[1] = db.ballPos[1] or 3
	db.ballPos[2] = db.ballPos[2] or 1
	db.ballPos[3] = db.ballPos[3] or 2
	db.ballPos[4] = db.ballPos[4] or 4
	db.point = db.point or "BOTTOM"
	db.x = db.x or 0
	db.y = db.y or UIParent:GetHeight() / 5 * 2
end


local function setBallPos(self, chi, pos)
	local ballPos = self.db.ballPos
	if ballPos[chi] == pos then return end

	for i = 1, maxStacks do
		if ballPos[i] == pos then
			ballPos[i] = ballPos[chi]
			ballPos[chi] = pos
			break
		end
	end

	updateLayout(anchorFrame)
end


local function onPositionChanged(self, layoutName, point, x, y)
	self.db.point = point
	self.db.x = x
	self.db.y = y
end


C_Timer.After(0, function()
	init(anchorFrame)

	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", refreshHooks)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", refreshHooks)
	refreshHooks()

	local defaultData = {
		point = "BOTTOM",
		x = 0,
		y = UIParent:GetHeight() / 5 * 2,
	}
	local chiOptions = {}
	for i = 1, maxStacks do
		chiOptions[i] = {text = i}
	end

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
			end
		},
		{
			name = "Size",
			kind = lem.SettingType.Slider,
			default = 32,
			minValue = 4,
			maxValue = 100,
			valueStep = 1,
			get = function()
				return anchorFrame.db.size
			end,
			set = function(_, value)
				anchorFrame.db.size = value
				updateLayout(anchorFrame)
			end,
		},
		{
			name = "Icon Size",
			kind = lem.SettingType.Slider,
			default = 38,
			minValue = 4,
			maxValue = 50,
			valueStep = 1,
			get = function()
				return anchorFrame.db.iconSize
			end,
			set = function(_, value)
				anchorFrame.db.iconSize = value
				updateLayout(anchorFrame)
			end
		},
		{
			name = "Gap",
			kind = lem.SettingType.Slider,
			default = -2,
			minValue = -10,
			maxValue = 10,
			valueStep = 1,
			get = function()
				return anchorFrame.db.gap
			end,
			set = function(_, value)
				anchorFrame.db.gap = value
				updateLayout(anchorFrame)
			end
		},
		{
			name = "1&4 offset",
			kind = lem.SettingType.Slider,
			default = 10,
			minValue = -50,
			maxValue = 50,
			valueStep = 1,
			get = function()
				return anchorFrame.db.yOffset14
			end,
			set = function(_, value)
				anchorFrame.db.yOffset14 = value
				updateLayout(anchorFrame)
			end
		},
		{
			name = "Chi 1 is",
			kind = lem.SettingType.Dropdown,
			default = 3,
			get = function()
				return anchorFrame.db.ballPos[1]
			end,
			set = function(_, value)
				setBallPos(anchorFrame, 1, value)
				lem:RefreshFrameSettings(anchorFrame)
			end,
			values = chiOptions,
		},
		{
			name = "Chi 2 is",
			kind = lem.SettingType.Dropdown,
			default = 1,
			get = function()
				return anchorFrame.db.ballPos[2]
			end,
			set = function(_, value)
				setBallPos(anchorFrame, 2, value)
				lem:RefreshFrameSettings(anchorFrame)
			end,
			values = chiOptions,
		},
		{
			name = "Chi 3 is",
			kind = lem.SettingType.Dropdown,
			default = 2,
			get = function()
				return anchorFrame.db.ballPos[3]
			end,
			set = function(_, value)
				setBallPos(anchorFrame, 3, value)
				lem:RefreshFrameSettings(anchorFrame)
			end,
			values = chiOptions,
		},
		{
			name = "Chi 4 is",
			kind = lem.SettingType.Dropdown,
			default = 4,
			get = function()
				return anchorFrame.db.ballPos[4]
			end,
			set = function(_, value)
				setBallPos(anchorFrame, 4, value)
				lem:RefreshFrameSettings(anchorFrame)
			end,
			values = chiOptions,
		},
	})

	lem:RegisterCallback("layout", function(layoutName)
		updateLayout(anchorFrame)
	end)

	lem:RegisterCallback("enter", function()
		isEditing = true
		for i = 1, maxStacks do bars[i]:Show() end
		updateBars(maxStacks)
	end)

	lem:RegisterCallback("exit", function()
		isEditing = false
		refreshHooks()
	end)
end)

local addonName, ns = ...

if select(2, UnitClass("player")) ~= "MONK" then return end

local CB = {}
ns.DanceOfChiJi = CB

local anchorFrame = CreateFrame("FRAME", nil, ns.ballsAnchor)
anchorFrame:SetClampedToScreen(true)

local spellID = 438439
local bgAtlas = "uf-chi-bg"
local iconTexture = "Interface\\AddOns\\OrtemisTools\\DanceOfChiJi\\spinny_texture"
local iconX = 0
local iconY = 5

local dSize = 50
local iconSize = 32
local bar, barFrame, applicationsText
local isEditing = false

bar = CreateFrame("StatusBar", nil, anchorFrame)
bar:SetSize(dSize, dSize)
bar:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
bar:SetStatusBarTexture("")
local barTex = bar:GetStatusBarTexture()
barTex:SetAtlas(bgAtlas)
bar.icon = CreateFrame("StatusBar", nil, bar)
bar.icon:SetSize(iconSize, iconSize)
bar.icon:SetPoint("CENTER", iconX, iconY)
bar.icon:SetMinMaxValues(0, 1, Enum.StatusBarInterpolation.Immediate)
bar.icon:SetStatusBarTexture("")
local iconTex = bar.icon:GetStatusBarTexture()
iconTex:SetTexture(iconTexture)


local function updateBars(stacks)
	bar:SetValue(stacks)
	bar.icon:SetValue(stacks)
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
	if OrtemisToolsDB.danceOfChiJi.enabled == false then
		bar:Hide()
		return
	end

	if isEditing then
		bar:Show()
		updateBars(1)
		return
	end

	barFrame = nil
	applicationsText = nil
	local cdID = getBar(Enum.CooldownViewerCategory.TrackedBuff) or getBar(Enum.CooldownViewerCategory.TrackedBar)

	for f in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
		if f._DanceOfChiJi then
			f.SetAlpha = nil
			f.Applications.Applications.SetText = nil
			f._DanceOfChiJi = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applicationsText = f.Applications.Applications
		end
	end

	for f in BuffBarCooldownViewer.itemFramePool:EnumerateActive() do
		if f._DanceOfChiJi then
			f.SetAlpha = nil
			f.Icon.Applications.SetText = nil
			f._DanceOfChiJi = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applicationsText = f.Icon.Applications
		end
	end

	local show = barFrame and C_SpecializationInfo.GetSpecialization() == 2
	bar:SetShown(show)
	if not show then return end

	local alpha = anchorFrame.db.hideDefault and 0 or 1
	barFrame._DanceOfChiJi = true
	barFrame:SetAlpha(alpha)

	local setAlpha = getmetatable(barFrame).__index.SetAlpha
	hooksecurefunc(barFrame, "SetAlpha", function(self)
		setAlpha(self, alpha)
	end)
	hooksecurefunc(applicationsText, "SetText", function(self, count)
		if isEditing then return end
		updateBars(tonumber(count) or barFrame:GetAuraSpellInstanceID() and 1 or 0)
	end)

	updateBars(barFrame:GetAuraSpellInstanceID() and 1 or 0)
end

CB.refresh = refreshHooks


local function updateLayout(self)
	local size = self.db.size
	local scale = size / dSize

	bar:SetScale(scale)
	bar.icon:SetSize(self.db.iconSize, self.db.iconSize)
	bar:ClearAllPoints()
	bar:SetPoint("BOTTOM", 0, 15)

	self:SetSize(size + 10, size + 30)
	self:ClearAllPoints()
	self:SetPoint("CENTER", self.db.xOffset, self.db.yOffset)
end

CB.updateLayout = function() updateLayout(anchorFrame) end


local function init(self)
	OrtemisToolsDB.danceOfChiJi = OrtemisToolsDB.danceOfChiJi or {}
	self.db = OrtemisToolsDB.danceOfChiJi
	local db = self.db
	if db.hideDefault == nil then db.hideDefault = true end
	db.size = db.size or 30
	db.iconSize = db.iconSize or 32
	db.xOffset = db.xOffset or 0
	db.yOffset = db.yOffset or 24
end


C_Timer.After(0, function()
	init(anchorFrame)

	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", refreshHooks)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", refreshHooks)
	refreshHooks()

	local lem = LibStub("LibEditMode")
	lem:RegisterCallback("layout", function()
		updateLayout(anchorFrame)
	end)

	lem:RegisterCallback("enter", function()
		isEditing = true
		bar:Show()
		updateBars(1)
	end)

	lem:RegisterCallback("exit", function()
		isEditing = false
		refreshHooks()
	end)
end)

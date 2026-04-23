local addonName, ns = ...

if select(2, UnitClass("player")) ~= "MONK" then return end

local CB = {}
ns.Spiritfont = CB

local anchorFrame = CreateFrame("FRAME", nil, ns.ballsAnchor)
anchorFrame:SetClampedToScreen(true)

local spellID = 1260511
local bgAtlas = "uf-chi-bg"
local iconTexture = "Interface\\AddOns\\OrtemisTools\\Spiritfont\\spirit_texture"
local iconX = 0
local iconY = 5

local dSize = 50
local iconSize = 32
local maxStacks = 2
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
	if OrtemisToolsDB.spiritFont.enabled == false then
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
		if f._Spiritfont then
			f.SetAlpha = nil
			f.Applications.Applications.SetText = nil
			f._Spiritfont = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applications = f.Applications.Applications
		end
	end

	for f in BuffBarCooldownViewer.itemFramePool:EnumerateActive() do
		if f._Spiritfont then
			f.SetAlpha = nil
			f.Icon.Applications.SetText = nil
			f._Spiritfont = nil
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
	barFrame._Spiritfont = true
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
	local ballPos = self.db.ballPos
	local scale = size / dSize
	local x1 = (size + gap) / scale / 2
	local y1 = 15

	for i = 1, maxStacks do
		bars[i]:SetScale(scale)
		bars[i].icon:SetSize(self.db.iconSize, self.db.iconSize)
	end
	bars[ballPos[1]]:SetPoint("BOTTOM", -x1, y1)
	bars[ballPos[2]]:SetPoint("BOTTOM", x1, y1)

	self:SetSize((size + gap) * 2 - gap + 10, size + 30)
	self:ClearAllPoints()
	self:SetPoint("CENTER", self.db.xOffset, self.db.yOffset)
end


local function init(self)
	OrtemisToolsDB.spiritFont = OrtemisToolsDB.spiritFont or {}
	self.db = OrtemisToolsDB.spiritFont
	local db = self.db
	if db.hideDefault == nil then db.hideDefault = true end
	db.size = db.size or 28
	db.gap = db.gap or 20
	db.iconSize = db.iconSize or 32
	db.ballPos = db.ballPos or {}
	if not db.ballPos[1] or db.ballPos[1] > maxStacks or
	   not db.ballPos[2] or db.ballPos[2] > maxStacks or
	   db.ballPos[1] == db.ballPos[2] then
		db.ballPos[1] = 1
		db.ballPos[2] = 2
	end
	db.ballPos[3] = nil
	db.ballPos[4] = nil
	db.xOffset = db.xOffset or 0
	db.yOffset = db.yOffset or 27
end


local function setBallPos(self, spirit, pos)
	local ballPos = self.db.ballPos
	if ballPos[spirit] == pos then return end

	for i = 1, maxStacks do
		if ballPos[i] == pos then
			ballPos[i] = ballPos[spirit]
			ballPos[spirit] = pos
			break
		end
	end

	updateLayout(anchorFrame)
end

CB.updateLayout = function() updateLayout(anchorFrame) end
CB.setBallPos = function(spirit, pos) setBallPos(anchorFrame, spirit, pos) end


C_Timer.After(0, function()
	init(anchorFrame)

	hooksecurefunc(BuffIconCooldownViewer, "RefreshLayout", refreshHooks)
	hooksecurefunc(BuffBarCooldownViewer, "RefreshLayout", refreshHooks)
	refreshHooks()

	local unitAuraFrame = CreateFrame("Frame")
	unitAuraFrame:RegisterUnitEvent("UNIT_AURA", "player")
	unitAuraFrame:SetScript("OnEvent", function()
		if isEditing or not barFrame then return end
		local stacks = 0
		local auraInstanceID = barFrame:GetAuraSpellInstanceID()
		if auraInstanceID then
			local auraData = C_UnitAuras.GetAuraDataByAuraInstanceID("player", auraInstanceID)
			if auraData and auraData.spellId == spellID then
				stacks = auraData.applications or 0
			end
		end
		updateBars(stacks)
	end)

	local lem = LibStub("LibEditMode")
	lem:RegisterCallback("layout", function()
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

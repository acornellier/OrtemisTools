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
local bars, barFrame, applicationsText = {}
local lastCount
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


-- Stack count, read without ever touching aura data directly. Since 12.1 the aura
-- instance ID handed out by the cooldown viewer is a secret value while combat
-- restrictions are in effect, and C_UnitAuras.GetAuraDataByAuraInstanceID rejects secret
-- arguments coming from addon code, so the old lookup threw in combat and left the orbs
-- showing whatever they were last set to. Everything used here is untainted data the
-- viewer already computed: its applications text (printed only at 2 stacks and up, and
-- accepted by SetValue even when it is itself a secret value) and isActive, its own
-- aura-present-and-unexpired flag, which covers no aura versus a single stack.
-- isActive is read as a plain field on purpose. Its setter is a mixin method, and mixin
-- methods live on the frame itself rather than on a metatable, so hooking one and later
-- clearing that hook the way SetAlpha is cleared would delete the method outright.
local function updateFromViewer()
	if isEditing or not barFrame then return end

	if not barFrame.isActive then
		updateBars(0)
	elseif lastCount then
		updateBars(lastCount)
	else
		updateBars(1)
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
	applicationsText = nil
	local cdID = getBar(Enum.CooldownViewerCategory.TrackedBuff) or getBar(Enum.CooldownViewerCategory.TrackedBar)

	for f in BuffIconCooldownViewer.itemFramePool:EnumerateActive() do
		if f._Spiritfont then
			f.SetAlpha = nil
			f.Applications.Applications.SetText = nil
			f._Spiritfont = nil
			f:SetAlpha(1)
		end
		if f.cooldownID == cdID then
			barFrame = f
			applicationsText = f.Applications.Applications
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
			applicationsText = f.Icon.Applications
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
	-- RefreshData writes the applications text before it refreshes the active state, so
	-- the text hook can only set the count; the UNIT_AURA handler below runs after the
	-- viewer has finished with the event and settles the 0/1 case from isActive.
	lastCount = nil
	hooksecurefunc(applicationsText, "SetText", function(self, count)
		lastCount = tonumber(count)
		updateFromViewer()
	end)

	updateFromViewer()
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
	unitAuraFrame:SetScript("OnEvent", updateFromViewer)

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

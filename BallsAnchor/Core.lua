local addonName, ns = ...

if select(2, UnitClass("player")) ~= "MONK" then return end

local anchor = CreateFrame("FRAME", nil, UIParent)
anchor.editModeName = "Chi Balls"
anchor:SetClampedToScreen(true)
anchor:SetSize(1, 1)
ns.ballsAnchor = anchor


local function onPositionChanged(self, layoutName, point, x, y)
	self.db.point = point
	self.db.x = x
	self.db.y = y
end


local function updateLayout(self)
	self:ClearAllPoints()
	self:SetPoint(self.db.point, self.db.x, self.db.y)
end


C_Timer.After(0, function()
	OrtemisToolsDB.ballsAnchor = OrtemisToolsDB.ballsAnchor or {}
	anchor.db = OrtemisToolsDB.ballsAnchor
	local db = anchor.db
	db.point = db.point or "BOTTOM"
	db.x = db.x or 0
	db.y = db.y or UIParent:GetHeight() / 5 * 2

	updateLayout(anchor)

	local defaultData = {
		point = "BOTTOM",
		x = 0,
		y = UIParent:GetHeight() / 5 * 2,
	}

	local chiOptions = {}
	for i = 1, 4 do chiOptions[i] = {text = i} end

local lem = LibStub("LibEditMode")
	lem:AddFrame(anchor, onPositionChanged, defaultData)
	lem:AddFrameSettings(anchor, {
		-- Chi Balls
		{
			name = "Teachings: Hide from CDM",
			kind = lem.SettingType.Checkbox,
			default = true,
			get = function() return OrtemisToolsDB.chiBalls.hideDefault end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.hideDefault = value
				ns.ChiBalls.refresh()
			end,
		},
		{
			name = "Size",
			kind = lem.SettingType.Slider,
			default = 32,
			minValue = 4,
			maxValue = 100,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.size end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.size = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "Icon Size",
			kind = lem.SettingType.Slider,
			default = 36,
			minValue = 4,
			maxValue = 50,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.iconSize end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.iconSize = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "Gap",
			kind = lem.SettingType.Slider,
			default = -2,
			minValue = -10,
			maxValue = 10,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.gap end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.gap = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "1&4 Offset",
			kind = lem.SettingType.Slider,
			default = 10,
			minValue = -50,
			maxValue = 50,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.yOffset14 end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.yOffset14 = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "X Offset",
			kind = lem.SettingType.Slider,
			default = 0,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.xOffset end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.xOffset = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "Y Offset",
			kind = lem.SettingType.Slider,
			default = 0,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.chiBalls.yOffset end,
			set = function(_, value)
				OrtemisToolsDB.chiBalls.yOffset = value
				ns.ChiBalls.updateLayout()
			end,
		},
		{
			name = "1 is",
			kind = lem.SettingType.Dropdown,
			default = 3,
			get = function() return OrtemisToolsDB.chiBalls.ballPos[1] end,
			set = function(_, value)
				ns.ChiBalls.setBallPos(1, value)
				lem:RefreshFrameSettings(anchor)
			end,
			values = chiOptions,
		},
		{
			name = "2 is",
			kind = lem.SettingType.Dropdown,
			default = 1,
			get = function() return OrtemisToolsDB.chiBalls.ballPos[2] end,
			set = function(_, value)
				ns.ChiBalls.setBallPos(2, value)
				lem:RefreshFrameSettings(anchor)
			end,
			values = chiOptions,
		},
		{
			name = "3 is",
			kind = lem.SettingType.Dropdown,
			default = 2,
			get = function() return OrtemisToolsDB.chiBalls.ballPos[3] end,
			set = function(_, value)
				ns.ChiBalls.setBallPos(3, value)
				lem:RefreshFrameSettings(anchor)
			end,
			values = chiOptions,
		},
		{
			name = "4 is",
			kind = lem.SettingType.Dropdown,
			default = 4,
			get = function() return OrtemisToolsDB.chiBalls.ballPos[4] end,
			set = function(_, value)
				ns.ChiBalls.setBallPos(4, value)
				lem:RefreshFrameSettings(anchor)
			end,
			values = chiOptions,
		},
		{ kind = lem.SettingType.Divider },
		-- Spiritfont
		{
			name = "Spiritfont: Hide from CDM",
			kind = lem.SettingType.Checkbox,
			default = true,
			get = function() return OrtemisToolsDB.spiritFont.hideDefault end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.hideDefault = value
				ns.Spiritfont.refresh()
			end,
		},
		{
			name = "Size",
			kind = lem.SettingType.Slider,
			default = 28,
			minValue = 4,
			maxValue = 100,
			valueStep = 1,
			get = function() return OrtemisToolsDB.spiritFont.size end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.size = value
				ns.Spiritfont.updateLayout()
			end,
		},
		{
			name = "Icon Size",
			kind = lem.SettingType.Slider,
			default = 32,
			minValue = 4,
			maxValue = 50,
			valueStep = 1,
			get = function() return OrtemisToolsDB.spiritFont.iconSize end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.iconSize = value
				ns.Spiritfont.updateLayout()
			end,
		},
		{
			name = "Gap",
			kind = lem.SettingType.Slider,
			default = 20,
			minValue = -10,
			maxValue = 50,
			valueStep = 1,
			get = function() return OrtemisToolsDB.spiritFont.gap end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.gap = value
				ns.Spiritfont.updateLayout()
			end,
		},
		{
			name = "X Offset",
			kind = lem.SettingType.Slider,
			default = 0,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.spiritFont.xOffset end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.xOffset = value
				ns.Spiritfont.updateLayout()
			end,
		},
		{
			name = "Y Offset",
			kind = lem.SettingType.Slider,
			default = 27,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.spiritFont.yOffset end,
			set = function(_, value)
				OrtemisToolsDB.spiritFont.yOffset = value
				ns.Spiritfont.updateLayout()
			end,
		},
{ kind = lem.SettingType.Divider },
		-- Dance of Chi Ji
		{
			name = "Dance of Chi-Ji: Hide from CDM",
			kind = lem.SettingType.Checkbox,
			default = true,
			get = function() return OrtemisToolsDB.danceOfChiJi.hideDefault end,
			set = function(_, value)
				OrtemisToolsDB.danceOfChiJi.hideDefault = value
				ns.DanceOfChiJi.refresh()
			end,
		},
		{
			name = "Size",
			kind = lem.SettingType.Slider,
			default = 30,
			minValue = 4,
			maxValue = 100,
			valueStep = 1,
			get = function() return OrtemisToolsDB.danceOfChiJi.size end,
			set = function(_, value)
				OrtemisToolsDB.danceOfChiJi.size = value
				ns.DanceOfChiJi.updateLayout()
			end,
		},
		{
			name = "Icon Size",
			kind = lem.SettingType.Slider,
			default = 32,
			minValue = 4,
			maxValue = 50,
			valueStep = 1,
			get = function() return OrtemisToolsDB.danceOfChiJi.iconSize end,
			set = function(_, value)
				OrtemisToolsDB.danceOfChiJi.iconSize = value
				ns.DanceOfChiJi.updateLayout()
			end,
		},
		{
			name = "X Offset",
			kind = lem.SettingType.Slider,
			default = 0,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.danceOfChiJi.xOffset end,
			set = function(_, value)
				OrtemisToolsDB.danceOfChiJi.xOffset = value
				ns.DanceOfChiJi.updateLayout()
			end,
		},
		{
			name = "Y Offset",
			kind = lem.SettingType.Slider,
			default = 24,
			minValue = -1000,
			maxValue = 1000,
			valueStep = 1,
			get = function() return OrtemisToolsDB.danceOfChiJi.yOffset end,
			set = function(_, value)
				OrtemisToolsDB.danceOfChiJi.yOffset = value
				ns.DanceOfChiJi.updateLayout()
			end,
		},
	})

	lem:RegisterCallback("layout", function()
		updateLayout(anchor)
	end)
end)

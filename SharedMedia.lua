local LSM = LibStub("LibSharedMedia-3.0")
local MediaType_BORDER = LSM.MediaType.BORDER or "border"
local MediaType_STATUSBAR = LSM.MediaType.STATUSBAR or "statusbar"

-- statusbars:
LSM:Register(MediaType_STATUSBAR, "Circle", [[Interface\AddOns\OrtemisTools\statusbar\Circle.tga]])

-- borders
LSM:Register(MediaType_BORDER, "Ferous 13", [[Interface\AddOns\OrtemisTools\border\Ferous13.tga]])

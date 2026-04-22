local addonName, ns = ...

ns.TalentReminder = ns.TalentReminder or {}
local TR = ns.TalentReminder

TR.MYTHIC_DIFFICULTY_ID = 23

TR.dungeons = {
    { id = 2526, name = "Algeth'ar Academy",       short = "AA" },
    { id = 2811, name = "Magisters' Terrace",       short = "MAGI" },
    { id = 2874, name = "Maisara Caverns",          short = "CAVNS" },
    { id = 2915, name = "Nexus-Point Xenas",        short = "XENAS" },
    { id = 658,  name = "Pit of Saron",             short = "PIT" },
    { id = 1753, name = "Seat of the Triumvirate",  short = "SEAT" },
    { id = 1209, name = "Skyreach",                 short = "SKY" },
    { id = 2805, name = "Windrunner Spire",         short = "WIND" },
}

-- Lookup table: instanceID → dungeon info
TR.dungeonByID = {}
for _, d in ipairs(TR.dungeons) do
    TR.dungeonByID[d.id] = d
end

TR.talents = {
    { spellID = 388874, name = "Improved Detox" },
    { spellID = 450432, name = "Pressure Points" },
    { spellID = 1243287, name = "Diffuse Magic" },
    { spellID = 328670, name = "Hasty Provocation" },
    { spellID = 450622, name = "Swift Art" },
    { spellID = 434774, name = "Linked Spirits" },
}

-- Default config for each talent/dungeon combo
TR.defaults = {
    [388874]  = { [2526] = true, [2874] = true, [658] = true, [2805] = true },
    [450432]  = { [2526] = true, [2915] = true, [658] = true, [1753] = true, [1209] = true, [2805] = true },
    [1243287] = { [2811] = true, [2874] = true, [2915] = true, [658] = true, [1753] = true, [2805] = true },
    [328670]  = { },
    [450622]  = { [658] = true },
    [434774]  = { [1209] = true, [2805] = true },
}
-- Fill in missing dungeon entries with false
for _, talent in ipairs(TR.talents) do
    TR.defaults[talent.spellID] = TR.defaults[talent.spellID] or {}
    for _, dungeon in ipairs(TR.dungeons) do
        if TR.defaults[talent.spellID][dungeon.id] == nil then
            TR.defaults[talent.spellID][dungeon.id] = false
        end
    end
end

local addonName, ns = ...

ns.TalentReminder = ns.TalentReminder or {}
local TR = ns.TalentReminder

TR.MYTHIC_DIFFICULTY_ID = 23

-- Season 2 pool, sorted by short name.
-- ids are instanceIDs as returned by GetInstanceInfo().
TR.dungeons = {
    { id = 2993, name = "Altar of Fangs",           short = "FANG" },
    { id = 1762, name = "Kings' Rest",              short = "KR" },
    { id = 2813, name = "Murder Row",               short = "MURD" },
    { id = 2825, name = "Den of Nalorakk",          short = "NALO" },
    { id = 2521, name = "Ruby Life Pools",          short = "RLP" },
    { id = 1877, name = "Temple of Sethraliss",     short = "TOS" },
    { id = 2859, name = "The Blinding Vale",        short = "VALE" },
    { id = 2923, name = "Voidscar Arena",           short = "VOID" },
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
    { spellID = 450622, name = "Swift Art" },
    { spellID = 328670, name = "Hasty Provocation" },
    { spellID = 434774, name = "Linked Spirits" },
}

-- Default config for each talent/dungeon combo.
--          FANG   KR   MURD  NALO   RLP   TOS   VALE  VOID
-- Detox     x     x     x     x           x     x     x
-- Pressure  x     x     x     x           x           x
-- Diffuse   x     x     x     x     x     x     x     x
-- Swift     x     x           x           x           x
TR.defaults = {
    -- Improved Detox
    [388874]  = { [2993] = true, [2859] = true, [2825] = true, [1762] = true, [2813] = true, [1877] = true, [2923] = true },
    -- Pressure Points
    [450432]  = { [2993] = true, [2825] = true, [1762] = true, [2813] = true, [1877] = true, [2923] = true },
    -- Diffuse Magic
    [1243287] = { [2993] = true, [2859] = true, [2825] = true, [1762] = true, [2813] = true, [2521] = true, [1877] = true, [2923] = true },
    -- Swift Art
    [450622]  = { [2993] = true, [2825] = true, [1762] = true, [1877] = true, [2923] = true },
    -- Hasty Provocation
    [328670]  = { },
    -- Linked Spirits
    [434774]  = { },
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

Ext.Require("Shade.lua")

StatPaths={
    "Public/Shade/Stats/Generated/Data/Shade_Interrupt.txt",
    "Public/Shade/Stats/Generated/Data/Shade_PASSIVES.txt",
    "Public/Shade/Stats/Generated/Data/Shade_Shout_Spell.txt",
    "Public/Shade/Stats/Generated/Data/Shade_Status_BOOSTS.txt",
    "Public/Shade/Stats/Generated/Data/Shade_Status_INVISIBLE.txt",
    "Public/Shade/Stats/Generated/Data/Shade_Target_Spell.txt",
}

local function on_reset_completed()
    for _, statPath in ipairs(StatPaths) do
        Ext.Stats.LoadStatsFile(statPath,1)
    end
    _P('Reloading stats!')
end
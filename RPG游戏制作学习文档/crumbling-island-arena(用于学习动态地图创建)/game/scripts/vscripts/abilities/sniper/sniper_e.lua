sniper_e = class({})
LinkLuaModifier("modifier_sniper_e", "abilities/sniper/modifier_sniper_e", LUA_MODIFIER_MOTION_NONE)

function sniper_e:OnSpellStart()
    local hero = self:GetCaster().hero
    hero:AddNewModifier(hero, self, "modifier_sniper_e", { duration = 3 })
    hero:EmitSound("Arena.Sniper.CastE")
end

function sniper_e:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(sniper_e)
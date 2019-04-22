lc_e = class({})

LinkLuaModifier("modifier_lc_e_animation", "abilities/lc/modifier_lc_e_animation", LUA_MODIFIER_MOTION_NONE)

function lc_e:OnSpellStart()
	Wrappers.DirectionalAbility(self)

    local hero = self:GetCaster().hero
    local target = hero:GetPos() + self:GetDirection() * hero.unit:GetIdealSpeed()

    Dash(hero, target, 1200, {
        modifier = { name = "modifier_lc_e_animation", ability = self },
        hitParams = {
            ability = self,
            modifier = { name = "modifier_stunned_lua", ability = self, duration = 0.7 }
        },
        forceFacing = true
    })

    hero:EmitSound("Arena.LC.CastE")
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(lc_e)
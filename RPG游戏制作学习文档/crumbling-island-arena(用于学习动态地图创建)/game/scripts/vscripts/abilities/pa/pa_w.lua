pa_w = class({})

function pa_w:OnSpellStart()
    local hero = self:GetCaster().hero
    hero:EmitSound("Arena.PA.CastW")

    local particle = "particles/econ/items/axe/axe_weapon_bloodchaser/axe_attack_blur_counterhelix_bloodchaser_b.vpcf"
    ImmediateEffect(particle, PATTACH_ABSORIGIN_FOLLOW, hero)

    hero:AreaEffect({
        ability = self,
        filter = Filters.Area(hero:GetPos(), 300),
        action = function(victim)
            local direction = (victim:GetPos() - hero:GetPos()):Normalized()
            local blood = ImmediateEffect("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
            ParticleManager:SetParticleControlEnt(blood, 0, victim:GetUnit(), PATTACH_POINT_FOLLOW, "attach_hitloc", victim:GetPos(), true)
            ParticleManager:SetParticleControlForward(blood, 0, direction)
            ParticleManager:SetParticleControl(blood, 2, direction * 1000)

            local effect = ImmediateEffectPoint("particles/econ/items/earthshaker/earthshaker_gravelmaw/earthshaker_fissure_dust_gravelmaw.vpcf", PATTACH_ABSORIGIN, hero, victim:GetPos())
            ParticleManager:SetParticleControl(effect, 1, victim:GetPos() + direction * 120)
        end,
        knockback = { force = 80, decrease = 9 },
        damage = self:GetDamage(),
        sound = "Arena.PA.HitQ"
    })

    GridNav:DestroyTreesAroundPoint(hero:GetPos(), 256, true)
end

function pa_w:GetCastAnimation()
    return ACT_DOTA_ATTACK_EVENT
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(pa_w)
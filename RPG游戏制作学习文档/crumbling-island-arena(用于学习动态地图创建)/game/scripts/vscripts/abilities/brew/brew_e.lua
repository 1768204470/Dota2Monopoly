brew_e = class({})

function brew_e:OnSpellStart()
    local hero = self:GetCaster():GetParentEntity()

    hero:Heal(hero:FindAbility("brew_q"):CountBeer(hero))
    hero:GetUnit():Purge(false, true, false, false, false)

    FX("particles/items3_fx/mango_active.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, { release = true })

    hero:EmitSound("Arena.Brew.CastE")
    hero:EmitSound("Arena.Brew.CastE2")
end

function brew_e:GetCastAnimation()
    return ACT_DOTA_SPAWN
end

function brew_e:GetPlaybackRateOverride()
    return 2
end
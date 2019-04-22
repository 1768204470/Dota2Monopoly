storm_spirit_r = class({})

function HasDeadRemnants(unit)
    return #unit.hero.lastRemnants > 0
end

function storm_spirit_r:OnSpellStart()
    local hero = self:GetCaster().hero

    hero:EmitSound("Arena.Storm.CastR.Voice")
    hero:AddNewModifier(hero, hero:FindAbility("storm_spirit_a"), "modifier_storm_spirit_a", { duration = 5 })

    for _, data in pairs(hero.lastRemnants) do
        hero:AddRemnant(EntityStormQ(hero.round, hero, data.position, data.facing, hero:FindAbility("storm_spirit_q")):Activate())
    end

    hero.lastRemnants = {}
end

function storm_spirit_r:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function storm_spirit_r:CastFilterResult()
    -- Remnant data can't be accessed on the client
    if not IsServer() then return UF_SUCCESS end

    if not HasDeadRemnants(self:GetCaster()) then
        return UF_FAIL_CUSTOM
    end

    return UF_SUCCESS
end

function storm_spirit_r:GetCustomCastError()
    if not IsServer() then return "" end

    if not HasDeadRemnants(self:GetCaster()) then
        return "#dota_hud_error_cant_cast_no_dead_remnants"
    end

    return ""
end

function storm_spirit_r:GetPlaybackRateOverride()
    return 2.0
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(storm_spirit_r)

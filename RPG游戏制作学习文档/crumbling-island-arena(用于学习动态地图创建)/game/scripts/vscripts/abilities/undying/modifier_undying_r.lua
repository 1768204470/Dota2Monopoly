modifier_undying_r = class({})
self = modifier_undying_r

if IsServer() then
    function self:OnCreated()
        local hero = self:GetParent():GetParentEntity()

        hero:SwapAbilities("undying_w", "undying_w_sub")
        hero:FindAbility("undying_e"):SetActivated(false)
        hero:FindAbility("undying_r"):SetActivated(false)
        hero:Animate(ACT_DOTA_SPAWN)

        FX("particles/units/heroes/hero_undying/undying_fg_transform.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, { release = true})
        ScreenShake(hero:GetPos(), 5, 150, 0.45, 3000, 0, true)
    end

    function self:OnDestroy()
        local hero = self:GetParent():GetParentEntity()

        hero:SwapAbilities("undying_w_sub", "undying_w")
        hero:FindAbility("undying_e"):SetActivated(true)
        hero:FindAbility("undying_r"):SetActivated(true)

        FX("particles/units/heroes/hero_undying/undying_fg_transform_reverse.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, { release = true})
        ScreenShake(hero:GetPos(), 5, 150, 0.45, 3000, 0, true)

        local shield = hero:FindModifier("modifier_undying_q_health")

        if shield then
            shield:SetDuration(5, true)
        end
    end
end

function self:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
        MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
        MODIFIER_PROPERTY_MODEL_CHANGE
    }

    return funcs
end

function self:GetModifierMoveSpeedOverride(params)
    return 450 + self:GetCaster():GetModifierStackCount("modifier_undying_q_health", self:GetCaster()) * 20
end

function self:GetModifierModelChange()
    if self:GetParent():GetParentEntity():IsAwardEnabled() then
        return "models/undying_reward/golem.vmdl"
    else
        return "models/heroes/undying/undying_flesh_golem.vmdl"
    end
end

function self:GetActivityTranslationModifiers()
    return "haste"
end

function self:RemoveOnDeath()
    return false
end
modifier_qop_q = class({})

if IsServer() then
    function modifier_qop_q:OnCreated(kv)
        self:StartIntervalThink(self:GetDuration() / 3)

        local effect = ParticleManager:CreateParticle("particles/units/heroes/hero_queenofpain/queen_shadow_strike_debuff.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())

        for _, cp in pairs({ 0, 2, 3 }) do
            ParticleManager:SetParticleControlEnt(effect, cp, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
        end

        self:AddParticle(effect, false, false, 0, true, false)

        self.heals = kv.heals ~= 0
    end

    function modifier_qop_q:OnIntervalThink()
        self:GetParent():GetParentEntity():Damage(self:GetCaster().hero, self:GetAbility():GetDamage() / 3)

        if self.heals and self:GetCaster():GetParentEntity():Alive() then
            self:GetCaster():GetParentEntity():Heal(self:GetAbility():GetDamage() / 3)
            FX("particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetCaster(), { release = true })

            if RandomInt(0, 1) == 0 then
                self:GetCaster():EmitSound("Arena.QOP.CastR.Heal")
            end
        end
    end
end

function modifier_qop_q:DeclareFunctions()
    local funcs = {
        MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
    }

    return funcs
end

function modifier_qop_q:IsDebuff()
    return true
end

function modifier_qop_q:GetModifierMoveSpeedBonus_Percentage(params)
    return -20
end

function modifier_qop_q:GetAttributes()
    return MODIFIER_ATTRIBUTE_MULTIPLE
end

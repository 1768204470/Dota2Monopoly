pudge_e = class({})

LinkLuaModifier("modifier_pudge_e_animation", "abilities/pudge/modifier_pudge_e_animation", LUA_MODIFIER_MOTION_NONE)

function pudge_e:OnSpellStart()
    Wrappers.DirectionalAbility(self, 1000)

    local hero = self:GetCaster().hero
    local target = self:GetCursorPosition()
    local direction = self:GetDirection()

    local dash = Dash(hero, target, 800, {
        modifier = { name = "modifier_pudge_e_animation", ability = self },
        forceFacing = true,
        gesture = ACT_DOTA_RUN,
        gestureRate = 2.5
    })

    dash.hitParams = {
        ability = self,
        modifier = { name = "modifier_stunned_lua", ability = self, duration = 0.7 },
        knockback = {
            force = 90,
            direction = function(target)
                local towardsTarget = (target:GetPos() - hero:GetPos()):Normalized()

                return direction * 0.65 + towardsTarget * 0.35
            end
        },
        damage = self:GetDamage(),
        notBlockedAction = function(target)
            ScreenShake(target:GetPos(), 5, 150, 0.45, 3000, 0, true)
            hero:EmitSound("Arena.Pudge.HitE")
            dash:Interrupt()
        end,
        filter = function(target)
            return not instanceof(target, PudgeMeat)
        end
    }
end

function pudge_e:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_2
end

function pudge_e:GetPlaybackRateOverride()
    return 2
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(pudge_e)
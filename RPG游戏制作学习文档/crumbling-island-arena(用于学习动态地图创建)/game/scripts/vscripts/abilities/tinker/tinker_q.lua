tinker_q = class({})

LinkLuaModifier("modifier_tinker_q", "abilities/tinker/modifier_tinker_q", LUA_MODIFIER_MOTION_NONE)

function tinker_q:OnSpellStart()
    Wrappers.DirectionalAbility(self, 850, 850)

    local hero = self:GetCaster().hero
    local facing = hero:GetFacing()
    local from = hero:GetPos() + Vector(facing.y, -facing.x, 0) * 96
    local target = self:GetCursorPosition()
    local height = Vector(0, 0, 96)

    local function PortalFilter(ent)
        return instanceof(ent, EntityTinkerE) and ent:Alive() and ent.link and ent.link:Alive()
    end

    local portals = hero.round.spells:FilterEntities(PortalFilter)

    local min = math.huge
    local closest = nil
    local closestPoint = nil

    for _, portal in pairs(portals) do
        local closestPointFound = ClosestPointToSegment(from, target, portal:GetPos())
        local dist = portal:GetPos() - closestPointFound

        if dist:Length2D() <= portal.size + 96 and dist:Length2D() < min then
            min = dist:Length2D()
            closest = portal
            closestPoint = closestPointFound
        end
    end

    if closest then
        local effect = ImmediateEffect("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN, hero)
        ParticleManager:SetParticleControlEnt(effect, 9, hero:GetUnit(), PATTACH_POINT_FOLLOW, "ArbitraryChain8_plc8", hero:GetPos(), true)
        --ParticleManager:SetParticleControl(effect, 9, from + height)
        ParticleManager:SetParticleControl(effect, 1, closestPoint + height)

        local diff = closestPoint - closest:GetPos()
        local portalStart = closest.link:GetPos() + diff
        local remaining = 700 - (closestPoint - from):Length2D()
        local dir = (closestPoint - from):Normalized()
        local portalEnd = portalStart + remaining * dir

        effect = ImmediateEffect("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN, hero)
        ParticleManager:SetParticleControl(effect, 9, portalStart + height / 2)
        ParticleManager:SetParticleControl(effect, 1, portalEnd + height / 2)

        hero:AreaEffect({
            ability = self,
            filter = Filters.Line(from, closestPoint, 64)..Filters.Line(portalStart, portalEnd, 64),
            modifier = { name = "modifier_tinker_q", duration = 1.5, ability = self },
            damage = self:GetDamage(),
            sound = "Arena.Tinker.HitQ",
            isPhysical = true
        })
    else
        local effect = ImmediateEffect("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN, hero)
        ParticleManager:SetParticleControlEnt(effect, 9, hero:GetUnit(), PATTACH_POINT_FOLLOW, "ArbitraryChain8_plc8", hero:GetPos(), true)
        ParticleManager:SetParticleControl(effect, 1, target)

        hero:AreaEffect({
            ability = self,
            filter = Filters.Line(from, target, 64),
            modifier = { name = "modifier_tinker_q", duration = 1.5, ability = self },
            damage = self:GetDamage(),
            sound = "Arena.Tinker.HitQ"
        })
    end

    ScreenShake(hero:GetPos(), 5, 150, 0.25, 3000, 0, true)

    hero:EmitSound("Arena.Tinker.CastQ")
end

function tinker_q:GetCastAnimation()
    return ACT_DOTA_CAST_ABILITY_1
end

function tinker_q:GetPlaybackRateOverride()
    return 2.0
end

if IsClient() then
    require("wrappers")
end

Wrappers.NormalAbility(tinker_q)
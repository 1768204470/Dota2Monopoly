WKSkeleton = WKSkeleton or class({}, nil, UnitEntity)

function WKSkeleton:constructor(round, owner, ability, position, direction)
    getbase(WKSkeleton).constructor(self, round, "wk_skeleton", position, owner.unit:GetTeamNumber(), true)

    self.ability = ability
    self.owner = owner.owner
    self.hero = owner
    self.size = 32
    self.start = position
    self.direction = direction
    self.removeOnDeath = false
    self.attacking = nil
    self.collisionType = COLLISION_TYPE_INFLICTOR

    self:SetFacing(direction)
    self:AddNewModifier(self.hero, nil, "modifier_wk_skeleton", { duration = 3 })

    if owner.owner then
        self:GetUnit():SetControllableByPlayer(owner.owner.id, true)
    end
end

function WKSkeleton:GetPos()
    return self:GetUnit():GetAbsOrigin()
end

function WKSkeleton:CollidesWith(target)
    return self.owner.team ~= target.owner.team
end

function WKSkeleton:CollideWith(target)
    local unit = self:GetUnit()

    if not instanceof(target, Projectile) and not instanceof(target, Obstacle) and not unit:IsStunned() and not unit:IsRooted() and not self.attacking and not target:IsAirborne() then
        local direction = (target:GetPos() - self:GetPos())

        ExecuteOrderFromTable({ UnitIndex = unit:GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_STOP })

        self:FindModifier("modifier_wk_skeleton"):SetDuration(0.25, false)
        self:SetFacing(direction:Normalized())
        self.attacking = target
        self.collisionType = COLLISION_TYPE_RECEIVER
        self:EmitSound("Arena.WK.HitQ")

        StartAnimation(unit, { duration = 0.25, activity = ACT_DOTA_ATTACK, rate = 1.5 })
    end
end

function WKSkeleton:Update()
    getbase(WKSkeleton).Update(self)

    if self.falling then
        return
    end

    if self:FindModifier("modifier_wk_skeleton"):GetRemainingTime() <= 0 then
        local blocked = self.attacking and self.attacking:AllowAbilityEffect(self, self.ability) == false

        if self.attacking and self.attacking:Alive() and not blocked then
            local distance = (self.attacking:GetPos() - self:GetPos()):Length2D()

            if distance <= 250 then
                local modifier = self.attacking:FindModifier("modifier_wk_q")

                if not modifier then
                    modifier = self.attacking:AddNewModifier(self.hero, self.ability, "modifier_wk_q", { duration = 3 })
                end

                if modifier then
                    modifier:IncrementStackCount()

                    if modifier:GetStackCount() <= 3 then
                        self.attacking:Damage(self, self.ability:GetDamage() / 3)
                    end
                end

                self:EmitSound("Arena.WK.HitQ2")
            end
        end

        self:Destroy()
        return
    end

    if self.attacking then
        if self:GetUnit():IsStunned() or self:GetUnit():IsRooted() then
            self.collisionType = COLLISION_TYPE_INFLICTOR
            self.attacking = false
        end

        return
    end

    local d = (self:GetPos() - self.start):Length2D() * self.direction;
    local result = ClampToMap(self.start + d + self.direction * 200)

    self.i = (self.i or 20) + 1

    if self.i % 10 == 0 then
        ExecuteOrderFromTable({ UnitIndex = self:GetUnit():GetEntityIndex(), OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION, Position = result })
    end
end

function WKSkeleton:Damage()
    self:Destroy()
end
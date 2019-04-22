DeathMatch = DeathMatch or class({})

function DeathMatch:constructor(players, availableHeroes) 
    self.respawnListener = CustomGameEventManager:RegisterListener("dm_respawn", function(id, ...) self["OnRespawn"](self, ...) end)
    self.randomListener = CustomGameEventManager:RegisterListener("dm_random", function(id, ...) self["OnRandom"](self, ...) end)

    self.players = players
    self.availableHeroes = availableHeroes
    self.removalQueue = {}
end

function DeathMatch:Update()
    local time = GameRules:GetGameTime()

    for hero, timeQueued in pairs(self.removalQueue) do
        if time - timeQueued >= 10 then
            hero.removeOnDeath = true
            hero:Destroy()
            self.removalQueue[hero] = nil
        end
    end
end

function DeathMatch:IsHeroAvailable(hero)
    local heroData = self.availableHeroes[hero]

    return not heroData.disabled
end

function DeathMatch:OnRespawn(args)
    local player = self.players[args.PlayerID]
    local hero = args.hero

    if self:IsPlayerDead(player) then
        if not self:IsHeroAvailable(hero) then
            return
        end

        self:CreateHeroForPlayer(player, hero)
    end
end

function DeathMatch:EnqueueRemove(hero)
    self.removalQueue[hero] = GameRules:GetGameTime()
end


function DeathMatch:FindPlaceToRespawn()
    local maxDistance = -1
    local farthestPart = nil

    GameRules.GameMode.level:GroundAction(
        function(part)
            local pos = Vector(part.x, part.y, 0)
            if pos:Length2D() < GameRules.GameMode.level.distance - 300 then
                local distance = 0
                for _, player in pairs(self.players) do
                    if player.hero and player.hero:Alive() then
                        distance = distance + (player.hero:GetPos() - pos):Length2D()
                    end
                end

                if distance > maxDistance then
                    maxDistance = distance
                    farthestPart = part
                end
            end
        end
    )

    if farthestPart then
        return Vector(farthestPart.x + farthestPart.offsetX, farthestPart.y + farthestPart.offsetY)
    end
end

function DeathMatch:CreateHeroForPlayer(player, heroName)
    local position = self:FindPlaceToRespawn()

    if not position then
        return
    end

    local hero = GameRules.GameMode.round:LoadHeroClass(heroName)
    local unit = CreateUnitByName(heroName, position, true, nil, nil, player.team)
    hero:SetUnit(unit)
    hero:Setup()
    hero:SetOwner(player)
    GameRules.GameMode.round:LoadHeroMixins(heroName, hero)

    local count = unit:GetAbilityCount() - 1
    for i = 0, count do
        local ability = unit:GetAbilityByIndex(i)

        if ability ~= nil and string.ends(ability:GetName(), "_r") then
            local initialCooldown = self.availableHeroes[heroName].initialCD
            local actualCooldown = ability:GetCooldown(1) * 1.5

            if actualCooldown < 10 then
                actualCooldown = ULTS_TIME / 2
            end

            ability:StartCooldown(initialCooldown or actualCooldown)
        end
    end

    hero:Activate()
    player.hero = hero
    player.selectedHero = heroName

    FX("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero, { release = true })

    GameRules.GameMode:UpdatePlayerTable()
    GameRules.GameMode.round.statistics:AddPlayedHero(player, player.selectedHero)

    CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player.id), "dm_respawn_event", { x = position.x, y = position.y })
end

function DeathMatch:OnRandom(args)
    local player = self.players[args.PlayerID]

    if self:IsPlayerDead(player) then
        local allHeroes = {}

        for hero, _ in pairs(self.availableHeroes) do
            if self:IsHeroAvailable(hero) then
                table.insert(allHeroes, hero)
            end
        end

        self:CreateHeroForPlayer(player, allHeroes[RandomInt(1, #allHeroes)])
    end
end

function DeathMatch:CleanupPlayer(round, player)
    self:EnqueueRemove(player.hero)

    if player.hero then
        round.spells:InterruptDashes(player.hero)
    end

    for _, entity in pairs(round.spells.entities) do
        if entity.owner == player then
            if not instanceof(entity, Projectile) and
               not instanceof(entity, ArcProjectile) and
               not instanceof(entity, Hero) and
               not entity.dontCleanup then
                entity:Destroy()
            end
        end
    end
end

function DeathMatch:OnRoundEnd(round)
    local winner = GameRules.GameMode.winner

    GameRules.GameMode:SubmitRoundInfo(round, winner, winner ~= nil)
    Stats.SubmitRoundInfo(self.players, winner, round.statistics)

    GameRules.GameMode.generalStatistics:Add(round.statistics)
    GameRules.GameMode:SetState(STATE_GAME_OVER_DM)

    CustomGameEventManager:UnregisterListener(self.respawnListener)
    CustomGameEventManager:UnregisterListener(self.randomListener)

    Timers:CreateTimer(10, function ()
        GameRules.GameMode:EndGame()
    end)
end

function DeathMatch:IsPlayerDead(player)
    return (not player.hero) or (not player.hero:Alive())
end

function DeathMatch:Activate(GameMode, inst)
    function GameMode:RecordKill(victim, source, fell)
        if victim.owner.team ~= source.owner.team then
            self.round.statistics:IncreaseKills(source.owner)

            if not self.firstBloodBy then
                self.firstBloodBy = source
                self.round.statistics:IncreaseFBs(source.owner)
                self:SendFirstBloodMessage(victim:GetName())
            else
                self:SendKillMessageToTeam(source.owner.team, victim:GetName(), fell)
            end

            source.owner.score = source.owner.score + 1

            if source.owner.score == self.gameGoal then
                self.winner = source.owner.team
                self.round:EndRound()
            end
        end

        if not fell then
            FX("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_ABSORIGIN, source, {
                cp4 = victim:GetPos(),
                release = true
            })
        end

        self.deathmatch:CleanupPlayer(self.round, victim.owner)

        CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(victim.owner.id), "dm_death_event", {})

        self:UpdatePlayerTable()

        CustomGameEventManager:Send_ServerToAllClients("kill_log_entry", {
            killer = source.owner.hero:GetName(),
            victim = victim:GetName(),
            color = self.TeamColors[source.owner.team],
            fell = fell
        })
    end

    function GameMode:UpdatePlayerTable()
        local players = {}

        for i, player in pairs(self.Players) do
            local playerData = {}
            playerData.id = i
            playerData.hero = player.selectedHero
            playerData.team = player.team
            playerData.color = self.TeamColors[player.team]
            playerData.score = player.score
            playerData.isDead = self.deathmatch:IsPlayerDead(player)

            table.insert(players, playerData)
        end

        CustomNetTables:SetTableValue("main", "players", {
            players = players,
            goal = self.gameGoal,
            isDeathMatch = self:IsDeathMatch()
        })
    end
end
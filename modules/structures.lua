local Projectile = require("modules.projectile")

local Structure = {}
Structure.__index = Structure

function Structure.new(x, y, structureType)
    local self = setmetatable({}, Structure)

    self.x = x
    self.y = y
    self.structureType = structureType or "Turret"

    self.projectiles = {}
    self.currentTarget = nil

    -- Target priority controls for Turrets and Missile Towers.
    self.targetingModes = {
        "Nearest",
        "Strongest",
        "Weakest",
        "Siege First",
        "Scout First"
    }

    self.targetingModeIndex = 1

    self.dead = false
    self.exploded = false

    if self.structureType == "Mine" then
        self.width = 22
        self.height = 22
        self.radius = 11

        self.capacityCost = 0
        self.targetable = false

        self.triggerRadius = 34
        self.blastRadius = 85
        self.damage = 120

        self.armed = true
    elseif self.structureType == "CommandPost" then
        self.width = 54
        self.height = 54
        self.radius = 27

        self.capacityCost = 0
        self.capacityBonus = 4
        self.targetable = true

        self.maxHealth = 600
        self.health = self.maxHealth
    elseif self.structureType == "MissileTurret" then
        self.width = 38
        self.height = 38
        self.radius = 19

        self.capacityCost = 3
        self.targetable = true

        self.maxHealth = 320
        self.health = self.maxHealth

        self.range = 600
        self.fireRate = 0.45
        self.cooldown = 0

        self.directDamage = 35
        self.splashDamage = 90
        self.splashRadius = 70

        self.explosions = {}
    else
        self.structureType = "Turret"

        self.width = 30
        self.height = 30
        self.radius = 15

        self.capacityCost = 2
        self.targetable = true

        self.maxHealth = 220
        self.health = self.maxHealth

        self.range = 500
        self.fireRate = 1
        self.cooldown = 0
    end

    return self
end

function Structure:canChangeTargetingMode()
    return not self.dead
        and (
            self.structureType == "Turret"
            or self.structureType == "MissileTurret"
        )
end

function Structure:getTargetingMode()
    return self.targetingModes[self.targetingModeIndex]
        or "Nearest"
end

function Structure:cycleTargetingMode()
    if not self:canChangeTargetingMode() then
        return
    end

    self.targetingModeIndex =
        self.targetingModeIndex + 1

    if self.targetingModeIndex > #self.targetingModes then
        self.targetingModeIndex = 1
    end
end

function Structure:containsPoint(px, py)
    return px >= self.x - self.width / 2
        and px <= self.x + self.width / 2
        and py >= self.y - self.height / 2
        and py <= self.y + self.height / 2
end

function Structure:takeDamage(amount)
    if self.dead or self.targetable == false then
        return
    end

    self.health = self.health - amount

    if self.health <= 0 then
        self.health = 0
        self.dead = true
    end
end

function Structure:findClosestEnemy(enemies)
    local closestEnemy = nil
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.range
                and distance < closestDistance then
                closestEnemy = enemy
                closestDistance = distance
            end
        end
    end

    return closestEnemy
end

function Structure:findStrongestEnemy(enemies)
    local strongestEnemy = nil
    local strongestHealth = -math.huge
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.range then
                local betterHealth =
                    enemy.health > strongestHealth

                local sameHealthButCloser =
                    enemy.health == strongestHealth
                    and distance < closestDistance

                if betterHealth or sameHealthButCloser then
                    strongestEnemy = enemy
                    strongestHealth = enemy.health
                    closestDistance = distance
                end
            end
        end
    end

    return strongestEnemy
end

function Structure:findWeakestEnemy(enemies)
    local weakestEnemy = nil
    local weakestHealth = math.huge
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.range then
                local lowerHealth =
                    enemy.health < weakestHealth

                local sameHealthButCloser =
                    enemy.health == weakestHealth
                    and distance < closestDistance

                if lowerHealth or sameHealthButCloser then
                    weakestEnemy = enemy
                    weakestHealth = enemy.health
                    closestDistance = distance
                end
            end
        end
    end

    return weakestEnemy
end

function Structure:findClosestEnemyOfType(
    enemies,
    enemyType
)
    local closestEnemy = nil
    local closestDistance = math.huge

    for _, enemy in ipairs(enemies) do
        if not enemy.dead
            and enemy.enemyType == enemyType then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.range
                and distance < closestDistance then
                closestEnemy = enemy
                closestDistance = distance
            end
        end
    end

    return closestEnemy
end

function Structure:findTargetEnemy(enemies)
    local mode = self:getTargetingMode()

    if mode == "Strongest" then
        return self:findStrongestEnemy(enemies)
    end

    if mode == "Weakest" then
        return self:findWeakestEnemy(enemies)
    end

    if mode == "Siege First" then
        local siegeTarget =
            self:findClosestEnemyOfType(
                enemies,
                "siege"
            )

        if siegeTarget ~= nil then
            return siegeTarget
        end

        return self:findClosestEnemy(enemies)
    end

    if mode == "Scout First" then
        local scoutTarget =
            self:findClosestEnemyOfType(
                enemies,
                "scout"
            )

        if scoutTarget ~= nil then
            return scoutTarget
        end

        return self:findClosestEnemy(enemies)
    end

    return self:findClosestEnemy(enemies)
end

function Structure:updateTurret(dt, enemies, terrain, combatText)
    -- Let already-fired projectiles keep traveling.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    if self.dead then
        self.currentTarget = nil
        return
    end

    self.cooldown = self.cooldown - dt

    local target = self:findTargetEnemy(enemies)
    self.currentTarget = target

    if target ~= nil
        and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(
                self.x,
                self.y,
                target,
                nil,
                nil,
                nil,
                nil,
                terrain,
                combatText
            )
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Structure:updateMissileTurret(
    dt,
    enemies,
    terrain,
    combatText
)
    -- Fade temporary blast visuals.
    for i = #self.explosions, 1, -1 do
        local explosion = self.explosions[i]

        explosion.timer = explosion.timer - dt

        if explosion.timer <= 0 then
            table.remove(self.explosions, i)
        end
    end

    -- Update active missiles.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    if self.dead then
        self.currentTarget = nil
        return
    end

    self.cooldown = self.cooldown - dt

    local target = self:findTargetEnemy(enemies)
    self.currentTarget = target

    if target ~= nil
        and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(
                self.x,
                self.y,
                target,
                self.directDamage,

                -- Deal direct and splash damage at impact.
                function(hitTarget, impactX, impactY)
                    if not hitTarget.dead then
                        local directDamage = self.directDamage
                        local coverReduced = false

                        if terrain ~= nil then
                            directDamage, coverReduced =
                                terrain:modifyDamage(
                                    hitTarget,
                                    self.directDamage
                                )
                        end

                        if combatText ~= nil then
                            combatText:applyDamage(
                                hitTarget,
                                directDamage,
                                {
                                    damageType = "explosion",
                                    coverReduced = coverReduced
                                }
                            )
                        else
                            hitTarget:takeDamage(directDamage)
                        end
                    end

                    for _, enemy in ipairs(enemies) do
                        if not enemy.dead then
                            local dx = enemy.x - impactX
                            local dy = enemy.y - impactY

                            local distance = math.sqrt(
                                dx * dx + dy * dy
                            )

                            if distance <= self.splashRadius then
                                local splashDamage = self.splashDamage
                                local coverReduced = false

                                if terrain ~= nil then
                                    splashDamage, coverReduced =
                                        terrain:modifyDamage(
                                            enemy,
                                            self.splashDamage
                                        )
                                end

                                if combatText ~= nil then
                                    combatText:applyDamage(
                                        enemy,
                                        splashDamage,
                                        {
                                            damageType = "explosion",
                                            coverReduced = coverReduced
                                        }
                                    )
                                else
                                    enemy:takeDamage(splashDamage)
                                end
                            end
                        end
                    end

                    table.insert(
                        self.explosions,
                        {
                            x = impactX,
                            y = impactY,
                            timer = 0.22,
                            maxTimer = 0.22,
                            radius = self.splashRadius
                        }
                    )
                end,

                -- Orange missile projectile.
                { 1, 0.35, 0.1 },
                7
            )
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Structure:updateMine(enemies, terrain, combatText)
    if self.dead or not self.armed then
        return
    end

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.triggerRadius then
                self:explode(enemies, terrain, combatText)
                return
            end
        end
    end
end

function Structure:explode(enemies, terrain, combatText)
    if self.dead then
        return
    end

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.blastRadius then
                local finalDamage = self.damage
                local coverReduced = false

                if terrain ~= nil then
                    finalDamage, coverReduced =
                        terrain:modifyDamage(
                            enemy,
                            self.damage
                        )
                end

                if combatText ~= nil then
                    combatText:applyDamage(
                        enemy,
                        finalDamage,
                        {
                            damageType = "explosion",
                            coverReduced = coverReduced
                        }
                    )
                else
                    enemy:takeDamage(finalDamage)
                end
            end
        end
    end

    self.exploded = true
    self.dead = true
end

function Structure:update(
    dt,
    enemies,
    terrain,
    combatText
)
    if self.structureType == "Mine" then
        self:updateMine(
            enemies,
            terrain,
            combatText
        )
    elseif self.structureType == "MissileTurret" then
        self:updateMissileTurret(
            dt,
            enemies,
            terrain,
            combatText
        )
    elseif self.structureType == "Turret" then
        self:updateTurret(
            dt,
            enemies,
            terrain,
            combatText
        )
    end
end

function Structure:drawHealthBar()
    if self.dead
        or self.maxHealth == nil then
        return
    end

    local barWidth = math.max(36, self.width + 10)
    local barHeight = 4

    local barX = self.x - barWidth / 2
    local barY = self.y - self.height / 2 - 10

    local healthPercent = self.health / self.maxHealth

    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth,
        barHeight
    )

    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth * healthPercent,
        barHeight
    )

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle(
        "line",
        barX,
        barY,
        barWidth,
        barHeight
    )
end

function Structure:drawTargetIndicator()
    if self.dead
        or self.currentTarget == nil
        or self.currentTarget.dead then
        return
    end

    if self.structureType ~= "Turret"
        and self.structureType ~= "MissileTurret" then
        return
    end

    if self.structureType == "MissileTurret" then
        love.graphics.setColor(1, 0.45, 0.1, 0.55)
    else
        love.graphics.setColor(0.25, 0.65, 1, 0.45)
    end

    love.graphics.setLineWidth(1)

    love.graphics.line(
        self.x,
        self.y,
        self.currentTarget.x,
        self.currentTarget.y
    )

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

function Structure:drawSelectionIndicator()
    if not self:canChangeTargetingMode() then
        return
    end

    local mode = self:getTargetingMode()

    if self.structureType == "MissileTurret" then
        love.graphics.setColor(1, 0.45, 0.1, 0.9)
    else
        love.graphics.setColor(0.25, 0.65, 1, 0.9)
    end

    love.graphics.setLineWidth(2)

    love.graphics.rectangle(
        "line",
        self.x - self.width / 2 - 5,
        self.y - self.height / 2 - 5,
        self.width + 10,
        self.height + 10
    )

    love.graphics.setLineWidth(1)

    local label = "Target: " .. mode
    local font = love.graphics.getFont()
    local textWidth = font:getWidth(label)

    love.graphics.setColor(0, 0, 0, 0.75)

    love.graphics.rectangle(
        "fill",
        self.x - textWidth / 2 - 5,
        self.y - self.height / 2 - 28,
        textWidth + 10,
        18
    )

    love.graphics.setColor(1, 1, 1)

    love.graphics.print(
        label,
        self.x - textWidth / 2,
        self.y - self.height / 2 - 26
    )

    love.graphics.setColor(1, 1, 1)
end

function Structure:drawTurret()
    if self.dead then
        -- Destroyed turret wreck.
        love.graphics.setColor(0.12, 0.12, 0.12)

        love.graphics.rectangle(
            "fill",
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.width,
            self.height
        )

        love.graphics.setColor(0.35, 0.08, 0.08)

        love.graphics.line(
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.x + self.width / 2,
            self.y + self.height / 2
        )

        love.graphics.line(
            self.x + self.width / 2,
            self.y - self.height / 2,
            self.x - self.width / 2,
            self.y + self.height / 2
        )
    else
        -- Active turret.
        love.graphics.setColor(0.2, 0.5, 1)

        love.graphics.rectangle(
            "fill",
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.width,
            self.height
        )

        -- Debug range.
        love.graphics.setColor(0.2, 0.5, 1, 0.25)

        love.graphics.circle(
            "line",
            self.x,
            self.y,
            self.range
        )

        self:drawHealthBar()
    end

    love.graphics.setColor(1, 1, 1)

    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
end

function Structure:drawMine()
    if self.exploded then
        -- Temporary scorch mark.
        love.graphics.setColor(0.08, 0.08, 0.08)

        love.graphics.circle(
            "fill",
            self.x,
            self.y,
            16
        )

        love.graphics.setColor(0.45, 0.18, 0.05)

        love.graphics.circle(
            "line",
            self.x,
            self.y,
            22
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    if self.dead then
        return
    end

    -- Armed mine.
    love.graphics.setColor(0.95, 0.8, 0.15)

    love.graphics.circle(
        "fill",
        self.x,
        self.y,
        self.radius
    )

    love.graphics.setColor(0.15, 0.15, 0.15)

    love.graphics.circle(
        "line",
        self.x,
        self.y,
        self.radius
    )

    love.graphics.setColor(1, 1, 1)
end

function Structure:drawCommandPost()
    if self.dead then
        -- Destroyed command post wreck.
        love.graphics.setColor(0.12, 0.12, 0.12)

        love.graphics.rectangle(
            "fill",
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.width,
            self.height
        )

        love.graphics.setColor(0.45, 0.08, 0.08)

        love.graphics.line(
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.x + self.width / 2,
            self.y + self.height / 2
        )

        love.graphics.line(
            self.x + self.width / 2,
            self.y - self.height / 2,
            self.x - self.width / 2,
            self.y + self.height / 2
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Active command post.
    love.graphics.setColor(0.7, 0.3, 1)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    love.graphics.setColor(0.9, 0.85, 1)

    love.graphics.rectangle(
        "fill",
        self.x - 8,
        self.y - 8,
        16,
        16
    )

    self:drawHealthBar()

    love.graphics.setColor(1, 1, 1)
end

function Structure:drawMissileTurret()
    if self.dead then
        -- Destroyed missile-turret wreck.
        love.graphics.setColor(0.12, 0.12, 0.12)

        love.graphics.rectangle(
            "fill",
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.width,
            self.height
        )

        love.graphics.setColor(0.5, 0.1, 0.05)

        love.graphics.line(
            self.x - self.width / 2,
            self.y - self.height / 2,
            self.x + self.width / 2,
            self.y + self.height / 2
        )

        love.graphics.line(
            self.x + self.width / 2,
            self.y - self.height / 2,
            self.x - self.width / 2,
            self.y + self.height / 2
        )

        love.graphics.setColor(1, 1, 1)
        return
    end

    -- Active missile turret.
    love.graphics.setColor(0.9, 0.3, 0.1)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    -- Temporary missile-launcher detail.
    love.graphics.setColor(0.25, 0.25, 0.28)

    love.graphics.rectangle(
        "fill",
        self.x - 12,
        self.y - 8,
        24,
        10
    )

    -- Debug attack range.
    love.graphics.setColor(1, 0.35, 0.1, 0.22)

    love.graphics.circle(
        "line",
        self.x,
        self.y,
        self.range
    )

    self:drawHealthBar()

    -- Draw active missiles.
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end

    -- Draw short-lived impact explosions.
    for _, explosion in ipairs(self.explosions) do
        local percent =
            explosion.timer / explosion.maxTimer

        love.graphics.setColor(
            1,
            0.35,
            0.08,
            0.55 * percent
        )

        love.graphics.circle(
            "fill",
            explosion.x,
            explosion.y,
            explosion.radius
            * (1 - percent * 0.25)
        )

        love.graphics.setColor(
            1,
            0.85,
            0.25,
            0.9 * percent
        )

        love.graphics.circle(
            "line",
            explosion.x,
            explosion.y,
            explosion.radius
            * (1 - percent * 0.25)
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function Structure:draw()
    if self.structureType == "Mine" then
        self:drawMine()
    elseif self.structureType == "CommandPost" then
        self:drawCommandPost()
    elseif self.structureType == "MissileTurret" then
        self:drawMissileTurret()
    else
        self:drawTurret()
    end
end

return Structure

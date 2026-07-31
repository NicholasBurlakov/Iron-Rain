local Projectile = require("modules.projectile")

local Unit = {}
Unit.__index = Unit

function Unit.new(x, y, unitType)
    local self = setmetatable({}, Unit)

    self.x = x
    self.y = y
    self.unitType = unitType

    -- Unit stats.
    if unitType == "Rifle" then
        self.color = { 0.2, 0.6, 1 }

        self.width = 18
        self.height = 26
        self.maxHealth = 100
        self.speed = 120
        self.capacityCost = 1
        self.supplyCost = 50
        self.range = 145
        self.damage = 10
        self.fireRate = 1.4
    elseif unitType == "Heavy" then
        self.color = { 0.3, 1, 0.3 }

        self.width = 24
        self.height = 32
        self.maxHealth = 180
        self.speed = 85
        self.capacityCost = 2
        self.supplyCost = 100
        self.range = 115
        self.damage = 25
        self.fireRate = 0.7
    end

    self.radius = math.max(self.width, self.height) / 2

    self.health = self.maxHealth
    self.dead = false
    self.isExtracting = false
    self.extracted = false
    self.extractionProgress = 0
    self.extractionStatus = nil
    self.extractionComplete = false
    self.rotation = 0

    -- Corpse timing.
    self.corpseAge = 0
    self.corpseFadeDelay = 10
    self.corpseFadeDuration = 2
    self.removeCorpse = false

    -- Basic combat state.
    self.cooldown = 0
    self.projectiles = {}
    self.currentTarget = nil

    -- Player-controlled target priority.
    self.targetingModes = {
        "Nearest",
        "Strongest",
        "Weakest",
        "Siege First",
        "Scout First"
    }

    self.targetingModeIndex = 1

    return self
end

function Unit:canChangeTargetingMode()
    return not self.dead
        and not self.isExtracting
        and not self.extracted
end

function Unit:getTargetingMode()
    return self.targetingModes[self.targetingModeIndex]
        or "Nearest"
end

function Unit:cycleTargetingMode()
    if not self:canChangeTargetingMode() then
        return
    end

    self.targetingModeIndex = self.targetingModeIndex + 1

    if self.targetingModeIndex > #self.targetingModes then
        self.targetingModeIndex = 1
    end
end

function Unit:takeDamage(amount)
    if self.dead
        or self.extracted then
        return
    end

    self.health = self.health - amount

    if self.health <= 0 then
        self.health = 0
        self.dead = true
        self.currentTarget = nil

        if love.math.random() < 0.5 then
            self.rotation = math.rad(90)
        else
            self.rotation = math.rad(-90)
        end
    end
end

function Unit:findClosestEnemy(enemies)
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

function Unit:findStrongestEnemy(enemies)
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

function Unit:findWeakestEnemy(enemies)
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

function Unit:findClosestEnemyOfType(enemies, enemyType)
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

function Unit:findTargetEnemy(enemies)
    local mode = self:getTargetingMode()

    if mode == "Strongest" then
        return self:findStrongestEnemy(enemies)
    end

    if mode == "Weakest" then
        return self:findWeakestEnemy(enemies)
    end

    if mode == "Siege First" then
        local siegeTarget =
            self:findClosestEnemyOfType(enemies, "siege")

        if siegeTarget ~= nil then
            return siegeTarget
        end

        return self:findClosestEnemy(enemies)
    end

    if mode == "Scout First" then
        local scoutTarget =
            self:findClosestEnemyOfType(enemies, "scout")

        if scoutTarget ~= nil then
            return scoutTarget
        end

        return self:findClosestEnemy(enemies)
    end

    return self:findClosestEnemy(enemies)
end

function Unit:update(
    dt,
    enemies,
    terrain,
    combatText
)
    -- Update active projectiles even if the unit later dies.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    if self.dead then
        self.currentTarget = nil
        self.corpseAge = self.corpseAge + dt

        if self.corpseAge >=
            self.corpseFadeDelay + self.corpseFadeDuration then
            self.removeCorpse = true
        end

        return
    end

    if self.isExtracting
        or self.extracted then
        self.currentTarget = nil
        return
    end

    -- Apply terrain movement effects.
    local movementSpeed = self.speed

    if terrain ~= nil then
        movementSpeed =
            movementSpeed
            * terrain:getSpeedMultiplier(self.x, self.y)
    end

    -- Move toward the current order.
    if self.targetX ~= nil
        and self.targetY ~= nil then
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance <= movementSpeed * dt then
            self.x = self.targetX
            self.y = self.targetY

            self.targetX = nil
            self.targetY = nil
        else
            local dirX = dx / distance
            local dirY = dy / distance

            self.x = self.x + dirX * movementSpeed * dt
            self.y = self.y + dirY * movementSpeed * dt
        end
    end

    -- Find a target using the unit's selected target priority.
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
                self.damage,
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

function Unit:moveTo(x, y)
    if self.dead
        or self.isExtracting
        or self.extracted then
        return
    end

    self.targetX = x
    self.targetY = y
end

function Unit:beginExtraction()
    if self.dead
        or self.isExtracting
        or self.extracted then
        return false
    end

    -- Stop the unit from moving or firing while extraction begins.
    self.isExtracting = true
    self.extractionProgress = 0.05
    self.extractionStatus = "Dropship inbound"
    self.extractionComplete = false

    self.currentTarget = nil
    self.targetX = nil
    self.targetY = nil
    self.projectiles = {}

    return true
end

function Unit:containsPoint(x, y)
    if self.dead
        or self.extractionComplete then
        return false
    end

    return x >= self.x - self.width / 2
        and x <= self.x + self.width / 2
        and y >= self.y - self.height / 2
        and y <= self.y + self.height / 2
end

function Unit:getCorpseAlpha()
    if not self.dead then
        return 1
    end

    if self.corpseAge <= self.corpseFadeDelay then
        return 1
    end

    local fadeProgress =
        (self.corpseAge - self.corpseFadeDelay)
        / self.corpseFadeDuration

    return math.max(0, 1 - fadeProgress)
end

function Unit:drawDottedLine(startX, startY, endX, endY)
    local dx = endX - startX
    local dy = endY - startY
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 8 then
        return
    end

    local dirX = dx / distance
    local dirY = dy / distance

    local dotSpacing = 12
    local dotRadius = 2

    -- Start a little away from the unit so the dots do not cover the unit body.
    local currentDistance = 12

    while currentDistance < distance - 12 do
        local dotX = startX + dirX * currentDistance
        local dotY = startY + dirY * currentDistance

        love.graphics.circle("fill", dotX, dotY, dotRadius)

        currentDistance = currentDistance + dotSpacing
    end
end

function Unit:drawMoveDestinationMarker(x, y)
    -- Small persistent destination marker.
    -- This stays visible until the unit reaches the position or loses the order.
    love.graphics.setLineWidth(2)

    love.graphics.circle("line", x, y, 8)

    love.graphics.line(x - 5, y, x + 5, y)
    love.graphics.line(x, y - 5, x, y + 5)

    love.graphics.setLineWidth(1)
end

function Unit:drawMoveOrder()
    if self.dead
        or self.isExtracting
        or self.extracted
        or self.targetX == nil
        or self.targetY == nil then
        return
    end

    -- The line is drawn from the unit's CURRENT position to its destination.
    -- Because self.x/self.y update every frame, the dotted line naturally
    -- gets shorter as the unit travels.
    love.graphics.setColor(0.25, 0.65, 1, 0.32)
    self:drawDottedLine(
        self.x,
        self.y,
        self.targetX,
        self.targetY
    )

    love.graphics.setColor(0.25, 0.65, 1, 0.75)
    self:drawMoveDestinationMarker(
        self.targetX,
        self.targetY
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(1)
end

function Unit:drawTargetIndicator()
    if self.dead
        or self.isExtracting
        or self.extracted
        or self.currentTarget == nil
        or self.currentTarget.dead then
        return
    end

    love.graphics.setColor(0.25, 0.65, 1, 0.5)
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

function Unit:draw()
    -- Hide only after extraction is fully complete.
    if self.extracted and self.extractionComplete then
        return
    end

    -- Draw the unit body.
    -- After boarding, keep a faint ground marker so the player can reselect it.
    local alpha = self:getCorpseAlpha()

    if self.extracted and not self.extractionComplete then
        alpha = 0.35
    end

    love.graphics.setColor(
        self.color[1],
        self.color[2],
        self.color[3],
        alpha
    )

    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.rotation)
    love.graphics.rectangle(
        "fill",
        -self.width / 2,
        -self.height / 2,
        self.width,
        self.height
    )
    love.graphics.pop()

    -- Draw health while alive.
    if not self.dead then
        local barWidth = math.max(32, self.width + 8)
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

    love.graphics.setColor(1, 1, 1)

    -- Draw active projectiles.
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
end

return Unit

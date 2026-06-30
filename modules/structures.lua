local Projectile = require("modules.projectile")

local Structure = {}
Structure.__index = Structure

function Structure.new(x, y, structureType)
    local self = setmetatable({}, Structure)

    self.x = x
    self.y = y
    self.structureType = structureType or "Turret"

    self.projectiles = {}
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

function Structure:updateTurret(dt, enemies)
    -- Let already-fired projectiles keep traveling.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    if self.dead then
        return
    end

    self.cooldown = self.cooldown - dt

    local target = self:findClosestEnemy(enemies)

    if target ~= nil
        and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(self.x, self.y, target)
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Structure:updateMine(enemies)
    if self.dead or not self.armed then
        return
    end

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.triggerRadius then
                self:explode(enemies)
                return
            end
        end
    end
end

function Structure:explode(enemies)
    if self.dead then
        return
    end

    for _, enemy in ipairs(enemies) do
        if not enemy.dead then
            local dx = enemy.x - self.x
            local dy = enemy.y - self.y
            local distance = math.sqrt(dx * dx + dy * dy)

            if distance <= self.blastRadius then
                enemy:takeDamage(self.damage)
            end
        end
    end

    self.exploded = true
    self.dead = true
end

function Structure:update(dt, enemies)
    if self.structureType == "Mine" then
        self:updateMine(enemies)
    else
        self:updateTurret(dt, enemies)
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

function Structure:draw()
    if self.structureType == "Mine" then
        self:drawMine()
    else
        self:drawTurret()
    end
end

return Structure

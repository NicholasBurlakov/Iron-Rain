local Projectile = require("modules.projectile")

local Tower = {}
Tower.__index = Tower

function Tower.new(x, y, towerType)
    local self = setmetatable({}, Tower)

    self.x = x
    self.y = y

    self.towerType = towerType or "Turret"
    self.capacityCost = 2

    self.width = 30
    self.height = 30
    self.radius = math.max(self.width, self.height) / 2

    -- Structure health.
    self.maxHealth = 220
    self.health = self.maxHealth
    self.dead = false

    self.range = 500
    self.fireRate = 1
    self.cooldown = 0

    self.projectiles = {}

    return self
end

function Tower:takeDamage(amount)
    if self.dead then
        return
    end

    self.health = self.health - amount

    if self.health <= 0 then
        self.health = 0
        self.dead = true
    end
end

function Tower:findClosestEnemy(enemies)
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

function Tower:update(dt, enemies)
    -- Let projectiles already fired continue traveling.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    -- Destroyed turrets cannot fire.
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

function Tower:drawHealthBar()
    if self.dead then
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

function Tower:draw()
    if self.dead then
        -- Temporary destroyed-turret wreck.
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

return Tower
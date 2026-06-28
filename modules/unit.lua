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
        self.range = 115
        self.damage = 25
        self.fireRate = 0.7
    end

    self.radius = math.max(self.width, self.height) / 2

    self.health = self.maxHealth
    self.dead = false
    self.rotation = 0

    -- Basic combat state.
    self.cooldown = 0
    self.projectiles = {}

    return self
end

function Unit:takeDamage(amount)
    if self.dead then
        return
    end

    self.health = self.health - amount

    if self.health <= 0 then
        self.health = 0
        self.dead = true

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

            if distance <= self.range and distance < closestDistance then
                closestEnemy = enemy
                closestDistance = distance
            end
        end
    end

    return closestEnemy
end

function Unit:update(dt, enemies)
    -- Update active projectiles.
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

    -- Move toward the current order.
    if self.targetX ~= nil and self.targetY ~= nil then
        local dx = self.targetX - self.x
        local dy = self.targetY - self.y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance <= self.speed * dt then
            self.x = self.targetX
            self.y = self.targetY

            self.targetX = nil
            self.targetY = nil
        else
            local dirX = dx / distance
            local dirY = dy / distance

            self.x = self.x + dirX * self.speed * dt
            self.y = self.y + dirY * self.speed * dt
        end
    end

    -- Find a target and fire.
    self.cooldown = self.cooldown - dt

    local target = self:findClosestEnemy(enemies)

    if target ~= nil and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(self.x, self.y, target, self.damage)
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Unit:moveTo(x, y)
    if self.dead then
        return
    end

    self.targetX = x
    self.targetY = y
end

function Unit:containsPoint(x, y)
    if self.dead then
        return false
    end
    return x >= self.x - self.width / 2
        and x <= self.x + self.width / 2
        and y >= self.y - self.height / 2
        and y <= self.y + self.height / 2
end

function Unit:draw()
    -- Draw the unit body.
    love.graphics.setColor(self.color)

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
        love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

        love.graphics.setColor(0, 1, 0)
        love.graphics.rectangle(
            "fill",
            barX,
            barY,
            barWidth * healthPercent,
            barHeight
        )

        love.graphics.setColor(0, 0, 0)
        love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
    end

    love.graphics.setColor(1, 1, 1)

    -- Draw active projectiles.
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
end

return Unit

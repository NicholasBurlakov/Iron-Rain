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

    self.range = 500
    self.fireRate = 1
    self.cooldown = 0

    self.projectiles = {}

    return self
end

function Tower:findClosestEnemy(enemies)
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

function Tower:update(dt, enemies)
    self.cooldown = self.cooldown - dt

    -- Update active projectiles.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    -- Find a target and fire.
    local target = self:findClosestEnemy(enemies)

    if target ~= nil and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(self.x, self.y, target)
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Tower:draw()
    -- Tower
    love.graphics.setColor(0.2, 0.5, 1)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    -- Debug range
    love.graphics.setColor(0.2, 0.5, 1, 0.25)

    love.graphics.circle(
        "line",
        self.x,
        self.y,
        self.range
    )

    love.graphics.setColor(1, 1, 1)

    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
end

return Tower

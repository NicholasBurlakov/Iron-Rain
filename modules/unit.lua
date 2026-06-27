local Projectile = require("modules.projectile")

local Unit = {}
Unit.__index = Unit

function Unit.new(x, y, unitType)
    local self = setmetatable({}, Unit)

    self.x = x
    self.y = y
    self.unitType = unitType

    self.width = 22
    self.height = 22

    self.speed = 120
    self.targetX = nil
    self.targetY = nil

    if unitType == "Rifle" then
        self.color = {0.2, 0.6, 1}
        self.range = 145
        self.damage = 10
        self.fireRate = 1.4

    elseif unitType == "Heavy" then
        self.color = {0.3, 1, 0.3}
        self.range = 115
        self.damage = 25
        self.fireRate = 0.7
    end

    -- Basic combat state.
    self.cooldown = 0
    self.projectiles = {}

    return self
end

function Unit:update(dt, enemy)
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

    -- Update active projectiles.
    for i = #self.projectiles, 1, -1 do
        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end
    end

    -- Attack the current enemy when in range.
    if enemy == nil or enemy.dead then
        return
    end

    self.cooldown = self.cooldown - dt

    local dx = enemy.x - self.x
    local dy = enemy.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= self.range and self.cooldown <= 0 then
        table.insert(
            self.projectiles,
            Projectile.new(self.x, self.y, enemy, self.damage)
        )

        self.cooldown = 1 / self.fireRate
    end
end

function Unit:moveTo(x, y)
    self.targetX = x
    self.targetY = y
end

function Unit:containsPoint(x, y)
    return x >= self.x - self.width / 2
        and x <= self.x + self.width / 2
        and y >= self.y - self.height / 2
        and y <= self.y + self.height / 2
end

function Unit:draw()
    love.graphics.setColor(self.color)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    love.graphics.setColor(1, 1, 1)

    -- Draw active projectiles.
    for _, projectile in ipairs(self.projectiles) do
        projectile:draw()
    end
end

return Unit
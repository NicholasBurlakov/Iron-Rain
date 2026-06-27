local Projectile = require("modules.projectile")
local Tower = {}
Tower.__index = Tower

function Tower.new(x, y)
    local self = setmetatable({}, Tower)

    self.x = x
    self.y = y

    self.width = 30
    self.height = 30

    self.range = 500
    self.fireRate = 1
    self.cooldown = 0

    self.projectiles = {}

    return self
end

function Tower:update(dt, enemy)

    self.cooldown = self.cooldown - dt

    local dx = enemy.x - self.x
    local dy = enemy.y - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= self.range then

        if self.cooldown <= 0 then

            table.insert(
                self.projectiles,
                Projectile.new(self.x, self.y, enemy)
            )

            self.cooldown = 1 / self.fireRate

        end

    end

    for i = #self.projectiles, 1, -1 do

        local projectile = self.projectiles[i]

        projectile:update(dt)

        if projectile.dead then
            table.remove(self.projectiles, i)
        end

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
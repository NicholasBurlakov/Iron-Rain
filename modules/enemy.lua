local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y)
    local self = setmetatable({}, Enemy)

    -- Position
    self.x = x
    self.y = y

    -- Movement
    self.speed = 100
    self.radius = 12
    self.waypointIndex = 2

    -- Health
    self.maxHealth = 100
    self.health = self.maxHealth

    -- Sprite
    self.sprite = love.graphics.newImage("assets/enemy.png")

    return self
end

function Enemy:update(dt, waypoints)

    if self.waypointIndex > #waypoints then
        return
    end

    local target = waypoints[self.waypointIndex]

    local dx = target.x - self.x
    local dy = target.y - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 5 then
        self.waypointIndex = self.waypointIndex + 1
        return
    end

    local dirX = dx / distance
    local dirY = dy / distance

    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt

end

function Enemy:takeDamage(amount)

    self.health = self.health - amount

    if self.health < 0 then
        self.health = 0
    end

end

function Enemy:draw()

    -- Draw enemy sprite
    love.graphics.setColor(1, 1, 1)

    love.graphics.draw(
        self.sprite,
        self.x - self.radius,
        self.y - self.radius
    )

    -- Health Bar

    local barWidth = 32
    local barHeight = 4

    local barX = self.x - barWidth / 2
    local barY = self.y - 24

    local healthPercent = self.health / self.maxHealth

    -- Lost health (red)
    love.graphics.setColor(1, 0, 0)

    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth,
        barHeight
    )

    -- Remaining health (green)
    love.graphics.setColor(0, 1, 0)

    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth * healthPercent,
        barHeight
    )

    -- Outline
    love.graphics.setColor(0, 0, 0)

    love.graphics.rectangle(
        "line",
        barX,
        barY,
        barWidth,
        barHeight
    )

    love.graphics.setColor(1, 1, 1)

end

return Enemy
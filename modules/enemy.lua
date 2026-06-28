local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y, enemyType)
    local self = setmetatable({}, Enemy)

    -- Position
    self.x = x
    self.y = y

    self.enemyType = enemyType or "grunt"
    self.waypointIndex = 2

    -- Set stats based on enemy type.
    if self.enemyType == "scout" then
        self.maxHealth = 55
        self.speed = 155
        self.radius = 9
        self.width = 14
        self.height = 24
        self.color = { 1, 0.8, 0.1 }
        self.usesSprite = false
    elseif self.enemyType == "heavy" then
        self.maxHealth = 250
        self.speed = 65
        self.radius = 16
        self.width = 26
        self.height = 38
        self.color = { 1, 0.2, 0.2 }
        self.usesSprite = false
    else
        self.enemyType = "grunt"
        self.maxHealth = 100
        self.speed = 100
        self.radius = 12
        self.width = 24
        self.height = 24
        self.usesSprite = true
    end

    self.health = self.maxHealth

    if self.usesSprite then
        self.sprite = love.graphics.newImage("assets/enemy.png")
    end

    self.dead = false
    self.rotation = 0 -- Body falls on death via sprite rotation
    self.reachedEnd = false

    return self
end

function Enemy:update(dt, waypoints)
    if self.dead then
        return
    end

    if self.waypointIndex > #waypoints then
        self.reachedEnd = true
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

function Enemy:drawBody()
    if self.usesSprite then
        love.graphics.setColor(1, 1, 1)

        love.graphics.draw(
            self.sprite,
            self.x,
            self.y,
            self.rotation,
            1,
            1,
            self.sprite:getWidth() / 2,
            self.sprite:getHeight() / 2
        )
    else
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
    end
end

function Enemy:draw()
    -- Draw the enemy body.
    self:drawBody()

    -- Health Bar
    local barWidth = math.max(32, self.width + 6)
    local barHeight = 4

    local barX = self.x - barWidth / 2
    local barY = self.y - self.radius - 12

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

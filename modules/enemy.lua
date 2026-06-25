local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(x, y)
    local self = setmetatable({}, Enemy)

    self.x = x
    self.y = y
    self.speed = 100
    self.radius = 12
    self.waypointIndex = 2

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

function Enemy:draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.circle("fill", self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 1)
end

return Enemy
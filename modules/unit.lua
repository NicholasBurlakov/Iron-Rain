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
    elseif unitType == "Heavy" then
        self.color = {0.3, 1, 0.3}
    end

    return self
end

function Unit:update(dt)
    if self.targetX == nil or self.targetY == nil then
        return
    end

    local dx = self.targetX - self.x
    local dy = self.targetY - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    -- The unit has reached its destination.
    if distance <= self.speed * dt then
        self.x = self.targetX
        self.y = self.targetY

        self.targetX = nil
        self.targetY = nil

        return
    end

    local dirX = dx / distance
    local dirY = dy / distance

    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt
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
end

return Unit
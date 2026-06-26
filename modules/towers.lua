local Tower = {}
Tower.__index = Tower

function Tower.new(x, y)
    local self = setmetatable({}, Tower)

    self.x = x
    self.y = y

    self.width = 30
    self.height = 30

    self.range = 125

    return self
end

function Tower:update(dt)

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

end

return Tower
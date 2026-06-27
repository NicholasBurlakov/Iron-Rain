local Unit = {}
Unit.__index = Unit

function Unit.new(x, y, unitType)
    local self = setmetatable({}, Unit)

    self.x = x
    self.y = y
    self.unitType = unitType

    self.width = 22
    self.height = 22

    if unitType == "Rifle" then
        self.color = {0.2, 0.6, 1}
    elseif unitType == "Heavy" then
        self.color = {0.3, 1, 0.3}
    end

    return self
end

function Unit:update(dt)
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
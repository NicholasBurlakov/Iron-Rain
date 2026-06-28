local Dropship = {}
Dropship.__index = Dropship

function Dropship.new(
    payloadX,
    payloadY,
    unitType,
    payloadWidth,
    payloadHeight,
    capacityCost,
    onDeploy
)
    local self = setmetatable({}, Dropship)

    self.x = -140
    self.y = -80

    self.payloadX = payloadX
    self.payloadY = payloadY

    self.unitType = unitType
    self.payloadWidth = payloadWidth
    self.payloadHeight = payloadHeight
    self.capacityCost = capacityCost

    self.onDeploy = onDeploy

    self.width = 70
    self.height = 32
    self.speed = 500

    self.landingX = payloadX
    self.landingY = payloadY - 30

    self.state = "approaching"
    self.deployTimer = 0.75

    self.deployed = false
    self.dead = false

    return self
end

function Dropship:moveToward(targetX, targetY, dt)
    local dx = targetX - self.x
    local dy = targetY - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= self.speed * dt then
        self.x = targetX
        self.y = targetY
        return true
    end

    local dirX = dx / distance
    local dirY = dy / distance

    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt

    return false
end

function Dropship:update(dt)
    -- Fly toward the landing zone.
    if self.state == "approaching" then
        if self:moveToward(self.landingX, self.landingY, dt) then
            self.state = "deploying"
        end

        return
    end

    -- Deploy the unit after a short pause.
    if self.state == "deploying" then
        self.deployTimer = self.deployTimer - dt

        if self.deployTimer <= 0 then
            self.onDeploy(
                self.payloadX,
                self.payloadY,
                self.unitType
            )

            self.deployed = true
            self.capacityCost = 0

            self.exitX = love.graphics.getWidth() + 140
            self.exitY = -80
            self.state = "departing"
        end

        return
    end

    -- Return to orbit.
    if self.state == "departing" then
        if self:moveToward(self.exitX, self.exitY, dt) then
            self.dead = true
        end
    end
end

function Dropship:draw()
    love.graphics.setColor(0.35, 0.4, 0.48)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    love.graphics.setColor(0.2, 0.7, 1)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2 - 12,
        self.y - 5,
        12,
        10
    )

    love.graphics.setColor(1, 1, 1)
end

return Dropship

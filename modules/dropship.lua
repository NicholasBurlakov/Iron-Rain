local Dropship = {}
Dropship.__index = Dropship

function Dropship.createBase()
    local self = setmetatable({}, Dropship)

    self.width = 70
    self.height = 32
    self.speed = 500

    self.dead = false

    return self
end

-- Used for Rifle and Heavy reinforcements.
function Dropship.new(
    payloadX,
    payloadY,
    unitType,
    payloadWidth,
    payloadHeight,
    capacityCost,
    onDeploy
)
    local self = Dropship.createBase()

    self.kind = "reinforcement"

    self.x = -140
    self.y = -80

    self.payloadX = payloadX
    self.payloadY = payloadY

    self.unitType = unitType
    self.payloadWidth = payloadWidth
    self.payloadHeight = payloadHeight
    self.capacityCost = capacityCost

    self.onDeploy = onDeploy

    self.landingX = payloadX
    self.landingY = payloadY - 30

    self.state = "approaching"
    self.deployTimer = 0.75

    self.deployed = false

    return self
end

-- Used to extract one selected player unit.
function Dropship.newExtraction(unit, onPickup, onSafeReturn)
    local self = Dropship.createBase()

    self.kind = "extraction"

    self.x = love.graphics.getWidth() + 140
    self.y = -80

    self.targetUnit = unit
    self.onPickup = onPickup
    self.onSafeReturn = onSafeReturn
    self.safeReturnHandled = false

    self.state = "approaching"
    self.pickupTimer = 0.5

    self.hasCargo = false
    self.capacityCost = 0

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

function Dropship:beginReturn()
    self.exitX = love.graphics.getWidth() + 140
    self.exitY = -80
    self.state = "departing"
end

function Dropship:updateReinforcement(dt)
    if self.state == "approaching" then
        if self:moveToward(
                self.landingX,
                self.landingY,
                dt
            ) then
            self.state = "deploying"
        end

        return
    end

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
            self:beginReturn()
        end

        return
    end

    if self.state == "departing" then
        if self:moveToward(self.exitX, self.exitY, dt) then
            self.dead = true
        end
    end
end

function Dropship:updateExtraction(dt)
    if self.state == "approaching" then
        if self.targetUnit == nil
            or self.targetUnit.dead
            or self.targetUnit.extracted then
            self:beginReturn()
            return
        end

        local pickupX = self.targetUnit.x
        local pickupY = self.targetUnit.y - 30

        if self:moveToward(pickupX, pickupY, dt) then
            self.state = "pickingUp"
        end

        return
    end

    if self.state == "pickingUp" then
        if self.targetUnit.dead
            or self.targetUnit.extracted then
            self:beginReturn()
            return
        end

        self.pickupTimer = self.pickupTimer - dt

        if self.pickupTimer <= 0 then
            self.onPickup(self.targetUnit)

            self.hasCargo = true
            self:beginReturn()
        end

        return
    end

    if self.state == "departing" then
        if self:moveToward(self.exitX, self.exitY, dt) then
            -- The refund is earned only after the ship is safe.
            if self.hasCargo
                and self.onSafeReturn ~= nil
                and not self.safeReturnHandled then
                self.onSafeReturn(self.targetUnit)
                self.safeReturnHandled = true
            end

            self.dead = true
        end
    end
end

function Dropship:update(dt)
    if self.kind == "reinforcement" then
        self:updateReinforcement(dt)
    elseif self.kind == "extraction" then
        self:updateExtraction(dt)
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

    -- Cockpit / front section.
    love.graphics.setColor(0.2, 0.7, 1)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2 - 12,
        self.y - 5,
        12,
        10
    )

    -- Yellow marker while collecting a unit.
    if self.kind == "extraction"
        and self.state == "pickingUp" then
        love.graphics.setColor(1, 0.85, 0.15)

        love.graphics.rectangle(
            "fill",
            self.x - 6,
            self.y + self.height / 2,
            12,
            14
        )
    end

    -- Cargo marker after the unit has boarded.
    if self.kind == "extraction"
        and self.hasCargo then
        love.graphics.setColor(0.3, 1, 0.3)

        love.graphics.rectangle(
            "fill",
            self.x - 8,
            self.y - 5,
            16,
            10
        )
    end

    love.graphics.setColor(1, 1, 1)
end

return Dropship

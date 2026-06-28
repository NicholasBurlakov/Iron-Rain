local OrbitalPod = {}
OrbitalPod.__index = OrbitalPod

function OrbitalPod.new(
    payloadX,
    payloadY,
    structureType,
    payloadWidth,
    payloadHeight,
    capacityCost,
    onDeploy
)
    local self = setmetatable({}, OrbitalPod)

    self.x = payloadX
    self.y = -60

    self.payloadX = payloadX
    self.payloadY = payloadY

    self.structureType = structureType
    self.payloadWidth = payloadWidth
    self.payloadHeight = payloadHeight
    self.capacityCost = capacityCost

    self.onDeploy = onDeploy

    self.width = 20
    self.height = 38
    self.speed = 520

    self.state = "falling"
    self.deployTimer = 0.25

    self.deployed = false
    self.dead = false

    return self
end

function OrbitalPod:update(dt)
    -- Fall from orbit.
    if self.state == "falling" then
        self.y = self.y + self.speed * dt

        if self.y >= self.payloadY then
            self.y = self.payloadY
            self.state = "deploying"
        end

        return
    end

    -- Deploy the structure.
    if self.state == "deploying" then
        self.deployTimer = self.deployTimer - dt

        if self.deployTimer <= 0 then
            self.onDeploy(
                self.payloadX,
                self.payloadY,
                self.structureType
            )

            self.deployed = true
            self.capacityCost = 0
            self.dead = true
        end
    end
end

function OrbitalPod:draw()
    love.graphics.setColor(0.6, 0.6, 0.65)

    love.graphics.rectangle(
        "fill",
        self.x - self.width / 2,
        self.y - self.height / 2,
        self.width,
        self.height
    )

    if self.state == "falling" then
        love.graphics.setColor(1, 0.45, 0.1)

        love.graphics.rectangle(
            "fill",
            self.x - 5,
            self.y + self.height / 2,
            10,
            14
        )
    end

    love.graphics.setColor(1, 1, 1)
end

return OrbitalPod

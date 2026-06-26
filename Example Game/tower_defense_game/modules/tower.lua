-- modules/tower.lua

local Tower = {}
local Projectile = require("modules.projectile")
local Map = require("modules.map")

function Tower:new(tileX, tileY)
    local tower = {
        tileX = tileX,
        tileY = tileY,
        x = (tileX - 0.5) * Map.TILE_SIZE,
        y = (tileY - 0.5) * Map.TILE_SIZE,
        image = love.graphics.newImage("assets/tower.png"),
        range = 150, -- Pixels
        attackSpeed = 1, -- Attacks per second
        damage = 20,
        timeSinceLastAttack = 0,
        target = nil
    }
    setmetatable(tower, { __index = self })
    return tower
end

function Tower:update(dt, enemies, projectiles)
    self.timeSinceLastAttack = self.timeSinceLastAttack + dt

    -- Clear target if it's dead or out of range
    if self.target and (self.target.isDead or self:distanceTo(self.target) > self.range) then
        self.target = nil
    end

    -- Find a new target if none exists
    if not self.target then
        for i, enemy in ipairs(enemies) do
            if not enemy.isDead and self:distanceTo(enemy) <= self.range then
                self.target = enemy
                break
            end
        end
    end

    -- Attack if target exists and attack cooldown is ready
    if self.target and self.timeSinceLastAttack >= (1 / self.attackSpeed) then
        table.insert(projectiles, Projectile:new(self.x, self.y, self.target, self.damage))
        self.timeSinceLastAttack = 0
    end
end

function Tower:draw()
    local imgWidth = self.image:getWidth()
    local imgHeight = self.image:getHeight()
    love.graphics.draw(self.image, self.x - imgWidth/2, self.y - imgHeight/2, 0, Map.TILE_SIZE / imgWidth, Map.TILE_SIZE / imgHeight)

    -- Draw range circle (for debugging/visual aid)
    love.graphics.setColor(1, 1, 1, 0.2) -- White, semi-transparent
    love.graphics.circle("line", self.x, self.y, self.range)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function Tower:distanceTo(object)
    return math.sqrt((self.x - object.x)^2 + (self.y - object.y)^2)
end

return Tower

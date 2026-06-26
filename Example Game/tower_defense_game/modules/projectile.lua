-- modules/projectile.lua

local Projectile = {}
local Map = require("modules.map")

function Projectile:new(x, y, target, damage)
    local projectile = {
        x = x,
        y = y,
        speed = 300,
        target = target,
        damage = damage,
        image = love.graphics.newImage("assets/projectile.png"),
        isDead = false
    }
    setmetatable(projectile, { __index = self })
    return projectile
end

function Projectile:update(dt)
    if self.isDead or not self.target or self.target.isDead then
        self.isDead = true
        return
    end

    local dx = self.target.x - self.x
    local dy = self.target.y - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < self.speed * dt then
        -- Hit target
        self.target:takeDamage(self.damage)
        self.isDead = true
    else
        -- Move towards target
        self.x = self.x + dx / dist * self.speed * dt
        self.y = self.y + dy / dist * self.speed * dt
    end
end

function Projectile:draw()
    if self.isDead then return end
    local imgWidth = self.image:getWidth()
    local imgHeight = self.image:getHeight()
    love.graphics.draw(self.image, self.x - imgWidth/2, self.y - imgHeight/2, 0, Map.TILE_SIZE / imgWidth, Map.TILE_SIZE / imgHeight)
end

return Projectile

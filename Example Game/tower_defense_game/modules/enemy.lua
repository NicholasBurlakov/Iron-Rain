-- modules/enemy.lua

local Enemy = {}
local Map = require("modules.map")

function Enemy:new(x, y, speed, health)
    local enemy = {
        x = x,
        y = y,
        speed = speed,
        health = health,
        image = love.graphics.newImage("assets/enemy.png"),
        currentWaypoint = 1,
        isDead = false
    }
    setmetatable(enemy, { __index = self })
    return enemy
end

function Enemy:update(dt)
    if self.isDead then return end

    local targetWaypoint = Map.waypoints[self.currentWaypoint]
    if not targetWaypoint then
        -- Enemy reached the end of the path
        self.isDead = true -- Mark for removal
        return "reached_end"
    end

    local targetX, targetY = Map:getPixelCoords(targetWaypoint.x, targetWaypoint.y)

    local dx = targetX - self.x
    local dy = targetY - self.y
    local dist = math.sqrt(dx*dx + dy*dy)

    if dist < self.speed * dt then
        -- Reached waypoint, move to next
        self.x = targetX
        self.y = targetY
        self.currentWaypoint = self.currentWaypoint + 1
    else
        -- Move towards waypoint
        self.x = self.x + dx / dist * self.speed * dt
        self.y = self.y + dy / dist * self.speed * dt
    end
end

function Enemy:draw()
    if self.isDead then return end
    local imgWidth = self.image:getWidth()
    local imgHeight = self.image:getHeight()
    love.graphics.draw(self.image, self.x - imgWidth/2, self.y - imgHeight/2, 0, Map.TILE_SIZE / imgWidth, Map.TILE_SIZE / imgHeight)
    
    -- Draw health bar (simple red rectangle)
    love.graphics.setColor(1, 0, 0, 1) -- Red
    love.graphics.rectangle("fill", self.x - Map.TILE_SIZE/4, self.y - Map.TILE_SIZE/2 - 5, Map.TILE_SIZE/2 * (self.health / 100), 3)
    love.graphics.setColor(1, 1, 1, 1) -- Reset color
end

function Enemy:takeDamage(damage)
    self.health = self.health - damage
    if self.health <= 0 then
        self.isDead = true
        return true -- Enemy defeated
    end
    return false
end

return Enemy

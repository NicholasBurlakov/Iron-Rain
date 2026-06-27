local Map = {}
local Enemy = require("modules.enemy")
local Tower = require("modules.towers")
local BuildMenu = require("modules.buildMenu")

function Map:load()
    self.background = love.graphics.newImage(
        "assets/map.png"
    )

    self.mapWidth = self.background:getWidth()
    self.mapHeight = self.background:getHeight()

    --#build menu
    self.buildMenu = BuildMenu.new()


    --#map path for enemy
    self.waypoints = {
    {x = 90,  y = 220},
    {x = 200, y = 220},
    {x = 200, y = 150},
    {x = 310, y = 150},
    {x = 310, y = 230},
    {x = 470, y = 230},
    {x = 470, y = 330},
    {x = 600, y = 330},
    {x = 600, y = 430},
    {x = 730, y = 430},
}

self.enemy = Enemy.new(
    self.waypoints[1].x,
    self.waypoints[1].y
)

self.towers = {}

table.insert(
    self.towers,
    Tower.new(345, 90)
)


end

function Map:update(dt)

    self.enemy:update(dt, self.waypoints)

    for _, tower in ipairs(self.towers) do
        tower:update(dt, self.enemy)
    end

    --#testing enemy damage
    if love.keyboard.isDown("space") then
    self.enemy:takeDamage(20 * dt)
end

end

function Map:draw()

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local scaleX = screenWidth / self.mapWidth
    local scaleY = screenHeight / self.mapHeight

    love.graphics.draw(
        self.background,
        0,
        0,
        0,
        scaleX,
        scaleY
    )

    self.enemy:draw()

    --#debug path
    love.graphics.setColor(0, 1, 0)

    for i = 1, #self.waypoints - 1 do
        local a = self.waypoints[i]
        local b = self.waypoints[i + 1]

        love.graphics.line(
            a.x,
            a.y,
            b.x,
            b.y
        )
    end

    love.graphics.setColor(1, 1, 1)

    for _, tower in ipairs(self.towers) do
        tower:draw()
    end

    self.buildMenu:draw()
end

function Map:mousepressed(x, y, button)

    if button == 1 then
        self.buildMenu:mousepressed(x, y)
    end

end



return Map
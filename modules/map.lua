local Map = {}
local Enemy = require("modules.enemy")
local Tower = require("modules.towers")
local BuildMenu = require("modules.buildMenu")
local Unit = require("modules.unit")

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

self.units = {}
self.selectedUnit = nil


end

function Map:update(dt)

    self.enemy:update(dt, self.waypoints)

    for _, tower in ipairs(self.towers) do
        tower:update(dt, self.enemy)
    end

    for _, unit in ipairs(self.units) do
        unit:update(dt)
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


    for _, unit in ipairs(self.units) do
        unit:draw()
    end

    if self.selectedUnit ~= nil then
    local unit = self.selectedUnit

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)

    love.graphics.rectangle(
        "line",
        unit.x - unit.width / 2 - 3,
        unit.y - unit.height / 2 - 3,
        unit.width + 6,
        unit.height + 6
    )

    love.graphics.setLineWidth(1)
end
    
    self.buildMenu:draw()

end


function Map:mousepressed(x, y, button)
    local screenHeight = love.graphics.getHeight()

    -- Left-click: menu selection, deployment, or unit selection.
    if button == 1 then
        local clickedMenu = self.buildMenu:mousepressed(x, y)

        if clickedMenu then
            self.selectedUnit = nil
            return
        end

        -- Do not interact with the battlefield inside the menu area.
        if y >= screenHeight - self.buildMenu.height then
            return
        end

        local selectedDeployable = self.buildMenu.selected

        -- If a menu item is selected, deploy it first.
        if selectedDeployable ~= nil then
            if selectedDeployable == "Rifle"
            or selectedDeployable == "Heavy" then

                table.insert(
                    self.units,
                    Unit.new(x, y, selectedDeployable)
                )

            elseif selectedDeployable == "Turret" then
                table.insert(
                    self.towers,
                    Tower.new(x, y)
                )
            end

            self.buildMenu.selected = nil
            return
        end

        -- No deployable selected: try to select a unit.
        for i = #self.units, 1, -1 do
            local unit = self.units[i]

            if unit:containsPoint(x, y) then
                self.selectedUnit = unit
                return
            end
        end

        -- Clicking empty ground removes the current selection.
        self.selectedUnit = nil
    end

    -- Right-click: order the selected unit to move.
    if button == 2 then
        if self.selectedUnit ~= nil
        and y < screenHeight - self.buildMenu.height then

            self.selectedUnit:moveTo(x, y)
        end
    end
end



return Map
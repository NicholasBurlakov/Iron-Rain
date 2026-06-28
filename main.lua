local Map = require("modules.map")
local Enemy = require("modules.enemy")



function love.load()
    Map:load()
end

function love.draw()
    Map:draw()
end

function love.update(dt)
    Map:update(dt)
end

function love.mousepressed(x, y, button)
    Map:mousepressed(x, y, button)
end

function love.keypressed(key)
    Map:keypressed(key)
end

function love.mousereleased(x, y, button)
    Map:mousereleased(x, y, button)
end

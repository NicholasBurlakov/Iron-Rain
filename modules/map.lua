local Map = {}

function Map:load()
    self.background = love.graphics.newImage(
        "assets/map.png"
    )

    self.mapWidth = self.background:getWidth()
    self.mapHeight = self.background:getHeight()
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

end

return Map
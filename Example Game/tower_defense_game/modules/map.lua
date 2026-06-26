-- modules/map.lua

local Map = {}

Map.TILE_SIZE = 64

-- Define the level layout
-- 0: Buildable/Empty (grass)
-- 1: Path (dirt)
-- 2: Tower placement spot (buildable on path)
Map.layout = {
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
    {0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0},
    {0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 0},
    {0, 1, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0},
    {0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0},
    {0, 1, 0, 1, 0, 1, 0, 0, 0, 0, 1, 0},
    {0, 1, 0, 1, 0, 1, 1, 1, 1, 0, 1, 0},
    {0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0},
    {0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0},
    {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
}

-- Define the enemy path as a sequence of waypoints (tile coordinates)
Map.waypoints = {
    {x = 1, y = 1}, -- Start at (1,1)
    {x = 1, y = 9},
    {x = 3, y = 9},
    {x = 3, y = 3},
    {x = 5, y = 3},
    {x = 5, y = 7},
    {x = 7, y = 7},
    {x = 7, y = 1},
    {x = 9, y = 1},
    {x = 9, y = 9},
    {x = 10, y = 9} -- End at (10,9)
}

-- Convert tile coordinates to pixel coordinates
function Map:getPixelCoords(tileX, tileY)
    return (tileX - 0.5) * self.TILE_SIZE, (tileY - 0.5) * self.TILE_SIZE
end

function Map:load()
    self.grassImage = love.graphics.newImage("assets/grass.png")
    self.pathImage = love.graphics.newImage("assets/path.png")
end

function Map:draw()
    for y = 1, #self.layout do
        for x = 1, #self.layout[y] do
            local tileType = self.layout[y][x]
            local drawX = (x - 1) * self.TILE_SIZE
            local drawY = (y - 1) * self.TILE_SIZE

            if tileType == 0 then
                love.graphics.draw(self.grassImage, drawX, drawY, 0, self.TILE_SIZE / self.grassImage:getWidth(), self.TILE_SIZE / self.grassImage:getHeight())
            elseif tileType == 1 then
                love.graphics.draw(self.pathImage, drawX, drawY, 0, self.TILE_SIZE / self.pathImage:getWidth(), self.TILE_SIZE / self.pathImage:getHeight())
            end
        end
    end
end

return Map

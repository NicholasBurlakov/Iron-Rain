-- main.lua

local Map = require("modules.map")
local Enemy = require("modules.enemy")
local Tower = require("modules.tower")

-- Game state variables
local enemies = {}
local towers = {}
local projectiles = {}
local lives = 5
local gameOver = false

-- Spawning variables
local spawnTimer = 0
local spawnInterval = 2 -- seconds
local enemiesToSpawn = 10
local enemiesSpawned = 0

function love.load()
    Map:load()
    love.window.setMode(Map.TILE_SIZE * #Map.layout[1], Map.TILE_SIZE * #Map.layout, {resizable=false, vsync=true})
    love.window.setTitle("Simple Tower Defense")

    -- Initial tower placement for testing (at tile 2,2)
    local towerX, towerY = Map:getPixelCoords(2, 2)
    table.insert(towers, Tower:new(2, 2))
end

function love.update(dt)
    if gameOver then return end

    -- Spawn enemies
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval and enemiesSpawned < enemiesToSpawn then
        local startWaypoint = Map.waypoints[1]
        local startX, startY = Map:getPixelCoords(startWaypoint.x, startWaypoint.y)
        table.insert(enemies, Enemy:new(startX, startY, 50, 100)) -- x, y, speed, health
        enemiesSpawned = enemiesSpawned + 1
        spawnTimer = 0
    end

    -- Update enemies
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]
        local status = enemy:update(dt)
        if status == "reached_end" then
            lives = lives - 1
            table.remove(enemies, i)
            if lives <= 0 then
                gameOver = true
            end
        elseif enemy.isDead then
            table.remove(enemies, i)
        end
    end

    -- Update towers
    for i, tower in ipairs(towers) do
        tower:update(dt, enemies, projectiles)
    end

    -- Update projectiles
    for i = #projectiles, 1, -1 do
        local projectile = projectiles[i]
        projectile:update(dt)
        if projectile.isDead then
            table.remove(projectiles, i)
        end
    end
end

function love.draw()
    Map:draw()

    for i, enemy in ipairs(enemies) do
        enemy:draw()
    end

    for i, tower in ipairs(towers) do
        tower:draw()
    end

    for i, projectile in ipairs(projectiles) do
        projectile:draw()
    end

    -- Draw UI
    love.graphics.print("Lives: " .. lives, 10, 10)
    if gameOver then
        love.graphics.print("GAME OVER!", love.graphics.getWidth()/2 - 50, love.graphics.getHeight()/2 - 10)
    end
end

function love.mousepressed(x, y, button)
    if button == 1 and not gameOver then -- Left click
        local tileX = math.floor(x / Map.TILE_SIZE) + 1
        local tileY = math.floor(y / Map.TILE_SIZE) + 1

        -- Check if tile is within bounds and is a buildable path tile (type 1)
        if tileY >= 1 and tileY <= #Map.layout and
           tileX >= 1 and tileX <= #Map.layout[tileY] and
           Map.layout[tileY][tileX] == 1 then -- Allow building on path for simplicity

            -- Check if a tower already exists at this tile
            local towerExists = false
            for i, tower in ipairs(towers) do
                if tower.tileX == tileX and tower.tileY == tileY then
                    towerExists = true
                    break
                end
            end

            if not towerExists then
                table.insert(towers, Tower:new(tileX, tileY))
            end
        end
    end
end

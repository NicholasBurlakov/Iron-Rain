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

    --#map path for enemy
    self.waypoints = {
        { x = 90,   y = 220 },
        { x = 200,  y = 220 },
        { x = 200,  y = 150 },
        { x = 310,  y = 150 },
        { x = 310,  y = 230 },
        { x = 470,  y = 230 },
        { x = 470,  y = 330 },
        { x = 600,  y = 330 },
        { x = 600,  y = 430 },
        { x = 730,  y = 430 },
        { x = 1500, y = 600 },
    }

    -- Mission settings.
    self.totalWaves = 3
    self.baseEnemiesPerWave = 4
    self.enemiesPerWaveIncrease = 2

    self.spawnDelay = 3
    self.waveBreakDuration = 8

    self.startingSupply = 300
    self.startingCommandCapacity = 12
    self.supplyIncome = 10

    self.buildMenu = BuildMenu.new()

    self:resetMission()
end

function Map:resetMission()
    -- Reset battlefield state.
    self.enemies = {}
    self.units = {}
    self.towers = {}

    self.selectedUnits = {}
    self.isSelecting = false
    self.selectionStartX = 0
    self.selectionStartY = 0

    self.buildMenu.selected = nil

    self.supply = self.startingSupply
    self.commandCapacity = self.startingCommandCapacity
    self.missionState = "playing"

    -- Reset wave state.
    self.currentWave = 0
    self.waveState = "active"
    self.waveTimer = 0

    self.spawnedEnemies = 0
    self.spawnTimer = 0
    self.totalEnemies = 0

    -- Temporary starting defense.
    table.insert(
        self.towers,
        Tower.new(375, 190, "Turret")
    )

    self:startNextWave()
end

function Map:getUsedCapacity()
    local totalCapacity = 0

    -- Count living player units.
    for _, unit in ipairs(self.units) do
        if not unit.dead then
            totalCapacity =
                totalCapacity + unit.capacityCost
        end
    end

    -- Count active structures.
    for _, tower in ipairs(self.towers) do
        if not tower.dead then
            totalCapacity =
                totalCapacity + tower.capacityCost
        end
    end

    return totalCapacity
end

function Map:clearSelectedUnits()
    self.selectedUnits = {}
end

function Map:selectSingleUnit(unit)
    self.selectedUnits = { unit }
end

function Map:removeDeadSelectedUnits()
    for i = #self.selectedUnits, 1, -1 do
        if self.selectedUnits[i].dead then
            table.remove(self.selectedUnits, i)
        end
    end
end

function Map:getPlacementInfo(deployableType)
    if deployableType == "Rifle" then
        return {
            width = 18,
            height = 26
        }
    elseif deployableType == "Heavy" then
        return {
            width = 24,
            height = 32
        }
    elseif deployableType == "Turret" then
        return {
            width = 30,
            height = 30
        }
    end

    return nil
end

function Map:rectanglesOverlap(
    x1,
    y1,
    width1,
    height1,
    x2,
    y2,
    width2,
    height2,
    padding
)
    padding = padding or 0

    return x1 - width1 / 2 - padding
        < x2 + width2 / 2
        and x1 + width1 / 2 + padding
        > x2 - width2 / 2
        and y1 - height1 / 2 - padding
        < y2 + height2 / 2
        and y1 + height1 / 2 + padding
        > y2 - height2 / 2
end

function Map:isPlacementValid(x, y, deployableType)
    local info = self:getPlacementInfo(deployableType)

    if info == nil then
        return false
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local battlefieldBottom =
        screenHeight - self.buildMenu.height

    -- Keep deployments inside the playable area.
    if x - info.width / 2 < 0
        or x + info.width / 2 > screenWidth
        or y - info.height / 2 < 0
        or y + info.height / 2 > battlefieldBottom then
        return false
    end

    -- Do not overlap living player units.
    for _, unit in ipairs(self.units) do
        if not unit.dead then
            local overlapsUnit = self:rectanglesOverlap(
                x,
                y,
                info.width,
                info.height,
                unit.x,
                unit.y,
                unit.width,
                unit.height,
                8
            )

            if overlapsUnit then
                return false
            end
        end
    end

    -- Do not overlap existing structures.
    for _, tower in ipairs(self.towers) do
        local overlapsTower = self:rectanglesOverlap(
            x,
            y,
            info.width,
            info.height,
            tower.x,
            tower.y,
            tower.width,
            tower.height,
            8
        )

        if overlapsTower then
            return false
        end
    end

    return true
end

function Map:drawPlacementPreview()
    local selectedDeployable = self.buildMenu.selected

    if selectedDeployable == nil then
        return
    end

    local info = self:getPlacementInfo(selectedDeployable)

    if info == nil then
        return
    end

    local mouseX, mouseY = love.mouse.getPosition()

    local valid = self:isPlacementValid(
        mouseX,
        mouseY,
        selectedDeployable
    )

    -- Green means valid. Red means invalid.
    if valid then
        love.graphics.setColor(0.2, 1, 0.3, 0.45)
    else
        love.graphics.setColor(1, 0.2, 0.2, 0.45)
    end

    love.graphics.rectangle(
        "fill",
        mouseX - info.width / 2,
        mouseY - info.height / 2,
        info.width,
        info.height
    )

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.setLineWidth(2)

    love.graphics.rectangle(
        "line",
        mouseX - info.width / 2,
        mouseY - info.height / 2,
        info.width,
        info.height
    )

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

function Map:startNextWave()
    self.currentWave = self.currentWave + 1

    self.totalEnemies =
        self.baseEnemiesPerWave
        + (self.currentWave - 1) * self.enemiesPerWaveIncrease

    self.spawnedEnemies = 0
    self.spawnTimer = 0
    self.waveState = "active"
end

function Map:getEnemyTypeForWave()
    local enemyNumber = self.spawnedEnemies + 1

    if self.currentWave == 1 then
        return "grunt"
    end

    if self.currentWave == 2 then
        if enemyNumber % 3 == 0 then
            return "scout"
        end

        return "grunt"
    end

    -- Wave 3 and later.
    if enemyNumber % 4 == 0 then
        return "heavy"
    end

    if enemyNumber % 2 == 0 then
        return "scout"
    end

    return "grunt"
end

function Map:spawnEnemy()
    local start = self.waypoints[1]

    local enemyType = self:getEnemyTypeForWave()

    local enemy = Enemy.new(
        start.x,
        start.y,
        enemyType
    )

    -- Scale enemy strength by wave.
    enemy.wave = self.currentWave

    local healthMultiplier = 1 + (self.currentWave - 1) * 0.35

    enemy.maxHealth = math.floor(
        enemy.maxHealth * healthMultiplier
    )

    enemy.health = enemy.maxHealth

    enemy.speed = enemy.speed + (self.currentWave - 1) * 10

    table.insert(self.enemies, enemy)

    self.spawnedEnemies = self.spawnedEnemies + 1
end

function Map:currentWaveDefeated()
    if self.spawnedEnemies < self.totalEnemies then
        return false
    end

    for _, enemy in ipairs(self.enemies) do
        if enemy.wave == self.currentWave
            and not enemy.dead then
            return false
        end
    end

    return true
end

function Map:getLivingEnemiesInCurrentWave()
    local livingEnemies = 0

    for _, enemy in ipairs(self.enemies) do
        if enemy.wave == self.currentWave
            and not enemy.dead then
            livingEnemies = livingEnemies + 1
        end
    end

    return livingEnemies
end

function Map:update(dt)
    if self.missionState ~= "playing" then
        return
    end

    -- Generate Supply over time.
    self.supply = self.supply + self.supplyIncome * dt

    -- Count down between waves.
    if self.waveState == "preparing" then
        self.waveTimer = self.waveTimer - dt

        if self.waveTimer <= 0 then
            self:startNextWave()
        end
    end

    -- Spawn enemies during an active wave.
    if self.waveState == "active"
        and self.spawnedEnemies < self.totalEnemies then
        self.spawnTimer = self.spawnTimer - dt

        if self.spawnTimer <= 0 then
            self:spawnEnemy()
            self.spawnTimer = self.spawnDelay
        end
    end

    -- Update enemies and check the endpoint.
    for _, enemy in ipairs(self.enemies) do
        enemy:update(
            dt,
            self.waypoints,
            self.units
        )

        if enemy.reachedEnd then
            self.missionState = "lost"
            return
        end
    end

    -- Update player defenses.
    for _, tower in ipairs(self.towers) do
        tower:update(dt, self.enemies)
    end

    for _, unit in ipairs(self.units) do
        unit:update(dt, self.enemies)
    end
    self:removeDeadSelectedUnits()

    -- Advance to the next wave or finish the mission.
    if self.waveState == "active"
        and self:currentWaveDefeated() then
        if self.currentWave >= self.totalWaves then
            self.missionState = "won"
        else
            self.waveState = "preparing"
            self.waveTimer = self.waveBreakDuration
        end
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

    -- Draw every enemy, including corpses.
    for _, enemy in ipairs(self.enemies) do
        enemy:draw()
    end

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

    -- Draw selected unit outlines.
    for _, unit in ipairs(self.selectedUnits) do
        if not unit.dead then
            love.graphics.setColor(1, 1, 1)
            love.graphics.setLineWidth(2)

            love.graphics.rectangle(
                "line",
                unit.x - unit.width / 2 - 3,
                unit.y - unit.height / 2 - 3,
                unit.width + 6,
                unit.height + 6
            )
        end
    end

    -- Draw the current drag-selection box.
    if self.isSelecting then
        local mouseX, mouseY = love.mouse.getPosition()

        local boxX = math.min(self.selectionStartX, mouseX)
        local boxY = math.min(self.selectionStartY, mouseY)

        local boxWidth = math.abs(mouseX - self.selectionStartX)
        local boxHeight = math.abs(mouseY - self.selectionStartY)

        love.graphics.setColor(0.3, 0.8, 1, 0.8)
        love.graphics.setLineWidth(2)

        love.graphics.rectangle(
            "line",
            boxX,
            boxY,
            boxWidth,
            boxHeight
        )

        love.graphics.setLineWidth(1)
        love.graphics.setColor(1, 1, 1)
    end

    love.graphics.setLineWidth(1)

    self:drawPlacementPreview()

    self.buildMenu:draw(self.supply, self:getUsedCapacity(), self.commandCapacity)

    -- Draw wave status.
    love.graphics.setColor(1, 1, 1)

    local waveText

    if self.waveState == "preparing" then
        waveText =
            "Next Wave: "
            .. (self.currentWave + 1)
            .. " / "
            .. self.totalWaves
            .. " in "
            .. math.ceil(self.waveTimer)
            .. " seconds"
    else
        waveText =
            "Wave "
            .. self.currentWave
            .. " / "
            .. self.totalWaves
            .. " - "
            .. self:getLivingEnemiesInCurrentWave()
            .. " enemies remaining"
    end

    love.graphics.print(waveText, 20, 20)

    if self.missionState ~= "playing" then
        -- Draw the mission result screen.
        love.graphics.setColor(0, 0, 0, 0.7)

        love.graphics.rectangle(
            "fill",
            0,
            0,
            screenWidth,
            screenHeight
        )

        local message = "MISSION FAILED"

        if self.missionState == "won" then
            message = "MISSION COMPLETE"
        end

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            message,
            0,
            screenHeight / 2 - 30,
            screenWidth,
            "center"
        )

        love.graphics.printf(
            "Press R to restart",
            0,
            screenHeight / 2 + 15,
            screenWidth,
            "center"
        )
    end
end

function Map:mousepressed(x, y, button)
    if self.missionState ~= "playing" then
        return
    end

    local screenHeight = love.graphics.getHeight()

    -- Handle left-clicks.
    if button == 1 then
        local clickedMenu = self.buildMenu:mousepressed(
            x,
            y,
            self.supply,
            self:getUsedCapacity(),
            self.commandCapacity
        )

        if clickedMenu then
            self:clearSelectedUnits()
            return
        end

        -- Ignore clicks inside the menu area.
        if y >= screenHeight - self.buildMenu.height then
            return
        end

        local selectedDeployable = self.buildMenu.selected

        -- Deploy the selected item.
        if selectedDeployable ~= nil then
            local cost = self.buildMenu:getSelectedCost()
            local capacityCost = self.buildMenu:getSelectedCapacity()

            if cost == nil
                or capacityCost == nil
                or self.supply < cost
                or self:getUsedCapacity() + capacityCost
                > self.commandCapacity then
                self.buildMenu.selected = nil
                return
            end

            -- Keep the item selected when placement is invalid.
            if not self:isPlacementValid(
                    x,
                    y,
                    selectedDeployable
                ) then
                return
            end

            local deployed = false

            if selectedDeployable == "Rifle"
                or selectedDeployable == "Heavy" then
                table.insert(
                    self.units,
                    Unit.new(x, y, selectedDeployable)
                )

                deployed = true
            elseif selectedDeployable == "Turret" then
                table.insert(
                    self.towers,
                    Tower.new(x, y, "Turret")
                )

                deployed = true
            end

            if deployed then
                self.supply = self.supply - cost
            end

            self.buildMenu.selected = nil
            return
        end

        -- Begin unit selection.
        self.isSelecting = true
        self.selectionStartX = x
        self.selectionStartY = y
    end

    -- Give selected units a movement order.
    if button == 2 then
        if y >= screenHeight - self.buildMenu.height then
            return
        end

        local unitCount = #self.selectedUnits

        if unitCount == 0 then
            return
        end

        local columns = math.ceil(math.sqrt(unitCount))
        local spacing = 32

        for i, unit in ipairs(self.selectedUnits) do
            local column = (i - 1) % columns
            local row = math.floor((i - 1) / columns)

            local offsetX = (column - (columns - 1) / 2) * spacing
            local offsetY = (row - (columns - 1) / 2) * spacing

            unit:moveTo(x + offsetX, y + offsetY)
        end
    end
end

function Map:mousereleased(x, y, button)
    if button ~= 1 or not self.isSelecting then
        return
    end

    self.isSelecting = false

    local dragDistanceX = math.abs(x - self.selectionStartX)
    local dragDistanceY = math.abs(y - self.selectionStartY)

    local wasClick =
        dragDistanceX < 8
        and dragDistanceY < 8

    -- Handle a single click.
    if wasClick then
        for i = #self.units, 1, -1 do
            local unit = self.units[i]

            if unit:containsPoint(x, y) then
                self:selectSingleUnit(unit)
                return
            end
        end

        self:clearSelectedUnits()
        return
    end

    -- Handle drag-box selection.
    local left = math.min(self.selectionStartX, x)
    local right = math.max(self.selectionStartX, x)

    local top = math.min(self.selectionStartY, y)
    local bottom = math.max(self.selectionStartY, y)

    self:clearSelectedUnits()

    for _, unit in ipairs(self.units) do
        local insideBox =
            not unit.dead
            and unit.x >= left
            and unit.x <= right
            and unit.y >= top
            and unit.y <= bottom

        if insideBox then
            table.insert(self.selectedUnits, unit)
        end
    end
end

function Map:keypressed(key)
    if key == "r" and self.missionState ~= "playing" then
        self:resetMission()
        return
    end
end

return Map

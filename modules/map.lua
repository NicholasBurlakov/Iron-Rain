local Enemy = require("modules.enemy")
local Structure = require("modules.structures")
local BuildMenu = require("modules.buildMenu")
local Unit = require("modules.unit")
local Dropship = require("modules.dropship")
local OrbitalPod = require("modules.orbitalPod")
local Tutorial = require("modules.tutorial")
local Terrain = require("modules.terrain")
local CombatText = require("modules.combatText")

local Map = {}

function Map:load()
    self.background = love.graphics.newImage(
        "assets/map.png"
    )

    self.mapWidth = self.background:getWidth()
    self.mapHeight = self.background:getHeight()

    --#map path for enemy
    self.waypoints = {
        { x = 90,   y = 380 },
        { x = 445,  y = 380 },
        { x = 445,  y = 275 },
        { x = 665,  y = 275 },
        { x = 665,  y = 400 },
        { x = 1000, y = 400 },
        { x = 1000, y = 590 },
        { x = 1275, y = 590 },
        { x = 1275, y = 760 },
        { x = 1600, y = 760 }


    }

    -- All enemies stay slower than their normal base speed.
    self.enemySpeedMultiplier = 0.72

    -- Difficulty increases through more enemies and mixed formations.
    -- Enemy stats do not increase between waves.
    self.wavePlans = {
        {
            name = "Probe Force",
            enemies = {
                "grunt",
                "grunt",
                "grunt",
                "grunt",
                "grunt"
            },
            spawnDelay = 0.22
        },
        {
            name = "Scout Screen",
            enemies = {
                "grunt",
                "grunt",
                "scout",
                "grunt",
                "grunt",
                "scout",
                "grunt",
                "grunt"
            },
            spawnDelay = 0.65
        },
        {
            name = "Armored Push",
            enemies = {
                "grunt",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "grunt",
                "scout"
            },
            spawnDelay = 0.60
        },
        {
            name = "Mixed Assault",
            enemies = {
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "grunt"
            },
            spawnDelay = 0.52
        },
        {
            name = "Final Push",
            enemies = {
                "grunt",
                "scout",
                "heavy",
                "grunt",
                "grunt",
                "heavy",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "grunt",
                "heavy",
                "grunt",
                "scout",
                "heavy",
                "grunt",
                "grunt"
            },
            spawnDelay = 0.48
        }
    }

    self.totalWaves = #self.wavePlans
    self.waveBreakDuration = 10

    self.startingSupply = 300
    self.startingCommandCapacity = 12
    self.startingDropshipFleetSize = 1
    self.orbitalPodFabricationDuration = 6
    self.extractionRefundPercent = 0.5
    self.supplyIncome = 10

    self.buildMenu = BuildMenu.new()
    self.tutorial = Tutorial.new()
    self.terrain = Terrain.new()
    self.combatText = CombatText.new()
    self:resetMission()
end

function Map:resetMission()
    -- Reset battlefield state.
    self.combatText:clear()
    self.enemies = {}
    self.units = {}
    self.structures = {}
    self.dropships = {}
    self.orbitalPods = {}

    self.selectedUnits = {}
    self.isSelecting = false
    self.selectionStartX = 0
    self.selectionStartY = 0

    self.buildMenu.selected = nil

    self.supply = self.startingSupply
    self.commandCapacity = self.startingCommandCapacity

    self.dropshipFleetSize = self.startingDropshipFleetSize

    self.orbitalPodReady = true
    self.orbitalPodTimer = 0
    self.missionState = "playing"

    -- Reset wave state.
    self.currentWave = 0
    self.waveState = "active"
    self.waveTimer = 0

    self.spawnedEnemies = 0
    self.spawnTimer = 0
    self.totalEnemies = 0



    self:startNextWave()
end

function Map:getUsedCapacity()
    local totalCapacity = 0

    -- Count living player units.
    for _, unit in ipairs(self.units) do
        if not unit.dead
            and not unit.extracted then
            totalCapacity =
                totalCapacity + unit.capacityCost
        end
    end

    -- Count active structures.
    for _, structure in ipairs(self.structures) do
        if not structure.dead then
            totalCapacity =
                totalCapacity + structure.capacityCost
        end
    end

    -- Reserve capacity for incoming reinforcements.
    for _, dropship in ipairs(self.dropships) do
        totalCapacity =
            totalCapacity + dropship.capacityCost
    end

    for _, pod in ipairs(self.orbitalPods) do
        totalCapacity =
            totalCapacity + pod.capacityCost
    end

    return totalCapacity
end

function Map:getEffectiveCommandCapacity()
    local totalCapacity = self.commandCapacity

    -- Living Command Posts increase the maximum.
    for _, structure in ipairs(self.structures) do
        if not structure.dead
            and structure.capacityBonus ~= nil then
            totalCapacity =
                totalCapacity + structure.capacityBonus
        end
    end

    return totalCapacity
end

function Map:getAvailableDropships()
    local busyDropships = 0

    for _, dropship in ipairs(self.dropships) do
        if not dropship.dead then
            busyDropships = busyDropships + 1
        end
    end

    return math.max(
        0,
        self.dropshipFleetSize - busyDropships
    )
end

function Map:isLogisticsReady(deployableType)
    if deployableType == "Rifle"
        or deployableType == "Heavy" then
        return self:getAvailableDropships() > 0
    end

    if deployableType == "Turret"
        or deployableType == "Mine"
        or deployableType == "CommandPost"
        or deployableType == "MissileTurret" then
        return self.orbitalPodReady
    end

    return true
end

function Map:startOrbitalPodFabrication()
    self.orbitalPodReady = false
    self.orbitalPodTimer =
        self.orbitalPodFabricationDuration
end

function Map:clearSelectedUnits()
    self.selectedUnits = {}
end

function Map:selectSingleUnit(unit)
    self.selectedUnits = { unit }
end

function Map:removeDeadSelectedUnits()
    for i = #self.selectedUnits, 1, -1 do
        if self.selectedUnits[i].dead
            or self.selectedUnits[i].isExtracting
            or self.selectedUnits[i].extracted then
            table.remove(self.selectedUnits, i)
        end
    end
end

function Map:removeExtractedUnits()
    for i = #self.units, 1, -1 do
        if self.units[i].extracted then
            table.remove(self.units, i)
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
    elseif deployableType == "Mine" then
        return {
            width = 22,
            height = 22
        }
    elseif deployableType == "CommandPost" then
        return {
            width = 54,
            height = 54
        }
    elseif deployableType == "MissileTurret" then
        return {
            width = 38,
            height = 38
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

    -- Do not overlap existing active structures.
    for _, structure in ipairs(self.structures) do
        if not structure.dead then
            local overlapsStructure = self:rectanglesOverlap(
                x,
                y,
                info.width,
                info.height,
                structure.x,
                structure.y,
                structure.width,
                structure.height,
                8
            )

            if overlapsStructure then
                return false
            end
        end
    end

    -- Do not overlap incoming deliveries.
    for _, dropship in ipairs(self.dropships) do
        if dropship.kind == "reinforcement"
            and not dropship.deployed then
            local overlapsDropship =
                self:rectanglesOverlap(
                    x,
                    y,
                    info.width,
                    info.height,
                    dropship.payloadX,
                    dropship.payloadY,
                    dropship.payloadWidth,
                    dropship.payloadHeight,
                    8
                )

            if overlapsDropship then
                return false
            end
        end
    end

    for _, pod in ipairs(self.orbitalPods) do
        if not pod.deployed then
            local overlapsPod =
                self:rectanglesOverlap(
                    x,
                    y,
                    info.width,
                    info.height,
                    pod.payloadX,
                    pod.payloadY,
                    pod.payloadWidth,
                    pod.payloadHeight,
                    8
                )

            if overlapsPod then
                return false
            end
        end
    end

    return true
end

function Map:callDropship(
    x,
    y,
    unitType,
    capacityCost
)
    if self:getAvailableDropships() <= 0 then
        return false
    end

    local info = self:getPlacementInfo(unitType)

    if info == nil then
        return false
    end

    table.insert(
        self.dropships,
        Dropship.new(
            x,
            y,
            unitType,
            info.width,
            info.height,
            capacityCost,
            function(deployX, deployY, deployedUnitType)
                table.insert(
                    self.units,
                    Unit.new(
                        deployX,
                        deployY,
                        deployedUnitType
                    )
                )
            end
        )
    )

    return true
end

function Map:requestUnitExtraction(unit)
    if unit == nil
        or unit.dead
        or unit.isExtracting
        or unit.extracted then
        return false
    end

    if self:getAvailableDropships() <= 0 then
        return false
    end

    if not unit:beginExtraction() then
        return false
    end

    local refund = math.floor(
        unit.supplyCost
        * self.extractionRefundPercent
    )

    table.insert(
        self.dropships,
        Dropship.newExtraction(
            unit,

            -- The unit boards the dropship.
            function(extractedUnit)
                if extractedUnit.dead
                    or extractedUnit.extracted then
                    return
                end

                extractedUnit.extracted = true
                extractedUnit.isExtracting = false
            end,

            -- Supply returns only when the dropship safely exits.
            function()
                self.supply = self.supply + refund
            end
        )
    )

    return true
end

function Map:dropStructure(
    x,
    y,
    structureType,
    capacityCost
)
    if not self.orbitalPodReady then
        return false
    end

    local info = self:getPlacementInfo(structureType)

    if info == nil then
        return false
    end

    -- A new cargo pod begins fabrication immediately.
    self:startOrbitalPodFabrication()

    table.insert(
        self.orbitalPods,
        OrbitalPod.new(
            x,
            y,
            structureType,
            info.width,
            info.height,
            capacityCost,
            function(deployX, deployY, deployedStructureType)
                table.insert(
                    self.structures,
                    Structure.new(
                        deployX,
                        deployY,
                        deployedStructureType
                    )
                )
            end
        )
    )

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

    local valid =
        self:isPlacementValid(
            mouseX,
            mouseY,
            selectedDeployable
        )
        and self:isLogisticsReady(
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

    self.currentWavePlan =
        self.wavePlans[self.currentWave]

    self.totalEnemies =
        #self.currentWavePlan.enemies

    self.currentSpawnDelay =
        self.currentWavePlan.spawnDelay

    self.spawnedEnemies = 0
    self.spawnTimer = 0
    self.waveState = "active"
end

function Map:getEnemyTypeForWave()
    local enemyNumber = self.spawnedEnemies + 1

    return self.currentWavePlan.enemies[enemyNumber]
end

function Map:spawnEnemy()
    local start = self.waypoints[1]
    local enemyType = self:getEnemyTypeForWave()

    local spawnOffsetX = 0
    local spawnOffsetY = 0

    -- Wave 1 enters in a tight formation for splash-damage testing.
    if self.currentWave == 1 then
        local formationOffsets = {
            { x = 0,   y = 0 },
            { x = -8,  y = -6 },
            { x = -14, y = 7 },
            { x = -22, y = -7 },
            { x = -30, y = 5 }
        }

        local offset =
            formationOffsets[self.spawnedEnemies + 1]
            or { x = 0, y = 0 }

        spawnOffsetX = offset.x
        spawnOffsetY = offset.y
    end

    local enemy = Enemy.new(
        start.x + spawnOffsetX,
        start.y + spawnOffsetY,
        enemyType
    )

    enemy.wave = self.currentWave

    -- Every wave uses the same reduced speed.
    -- Enemy health, damage, and other stats remain unchanged.
    enemy.speed = math.max(
        20,
        math.floor(
            enemy.speed * self.enemySpeedMultiplier
        )
    )

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
    if self.tutorial:isOpen() then
        return
    end

    if self.missionState ~= "playing" then
        return
    end

    -- Generate Supply over time.
    self.supply = self.supply + self.supplyIncome * dt

    -- Fabricate the next orbital cargo pod.
    if not self.orbitalPodReady then
        self.orbitalPodTimer =
            self.orbitalPodTimer - dt

        if self.orbitalPodTimer <= 0 then
            self.orbitalPodTimer = 0
            self.orbitalPodReady = true
        end
    end

    -- Count down between waves.
    if self.waveState == "preparing" then
        self.waveTimer = self.waveTimer - dt

        if self.waveTimer <= 0 then
            self:startNextWave()
        end

        -- Spawn enemies during an active wave.
    elseif self.waveState == "active"
        and self.spawnedEnemies < self.totalEnemies then
        self.spawnTimer = self.spawnTimer - dt

        if self.spawnTimer <= 0 then
            self:spawnEnemy()
            self.spawnTimer = self.currentSpawnDelay
        end
    end

    -- Update enemies and check the endpoint.
    for _, enemy in ipairs(self.enemies) do
        enemy:update(
            dt,
            self.waypoints,
            self.units,
            self.structures,
            self.terrain,
            self.combatText
        )

        if enemy.reachedEnd then
            self.missionState = "lost"
            return
        end
    end

    -- Remove enemy corpses after their fade finishes.
    for i = #self.enemies, 1, -1 do
        if self.enemies[i].removeCorpse then
            table.remove(self.enemies, i)
        end
    end


    -- Update incoming reinforcements.
    for i = #self.dropships, 1, -1 do
        local dropship = self.dropships[i]

        dropship:update(dt)

        if dropship.dead then
            table.remove(self.dropships, i)
        end
    end

    for i = #self.orbitalPods, 1, -1 do
        local pod = self.orbitalPods[i]

        pod:update(dt)

        if pod.dead then
            table.remove(self.orbitalPods, i)
        end
    end

    self:removeExtractedUnits()

    -- Update player structures.
    for _, structure in ipairs(self.structures) do
        structure:update(
            dt,
            self.enemies,
            self.terrain,
            self.combatText
        )
    end

    for _, unit in ipairs(self.units) do
        unit:update(
            dt,
            self.enemies,
            self.terrain,
            self.combatText
        )
    end

    -- Remove player-unit corpses after their fade finishes.
    for i = #self.units, 1, -1 do
        if self.units[i].removeCorpse then
            table.remove(self.units, i)
        end
    end

    self:removeDeadSelectedUnits()

    -- Update floating combat feedback.
    self.combatText:update(dt)

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

    -- Draw terrain under units and structures.
    self.terrain:draw()

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

    for _, structure in ipairs(self.structures) do
        structure:draw()
    end


    for _, unit in ipairs(self.units) do
        unit:draw()
    end

    -- Draw active deliveries.
    for _, dropship in ipairs(self.dropships) do
        dropship:draw()
    end

    for _, pod in ipairs(self.orbitalPods) do
        pod:draw()
    end

    -- Draw floating combat feedback above battlefield objects.
    self.combatText:draw()

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

    if self.tutorial:isOpen() then
        self.tutorial:draw()
        return
    end

    self:drawPlacementPreview()

    self.buildMenu:draw(
        self.supply,
        self:getUsedCapacity(),
        self:getEffectiveCommandCapacity(),
        self:getAvailableDropships(),
        self.dropshipFleetSize,
        self.orbitalPodReady,
        self.orbitalPodTimer
    )

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
    -- Let the briefing handle input before the mission begins.
    if self.tutorial:isOpen() then
        self.tutorial:mousepressed(x, y, button)
        return
    end

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
            self:getEffectiveCommandCapacity(),
            self:getAvailableDropships(),
            self.orbitalPodReady
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

            local effectiveCapacity =
                self:getEffectiveCommandCapacity()

            local exceedsCapacity =
                capacityCost > 0
                and self:getUsedCapacity() + capacityCost
                > effectiveCapacity

            if cost == nil
                or capacityCost == nil
                or self.supply < cost
                or exceedsCapacity then
                self.buildMenu.selected = nil
                return
            end

            -- Wait until a dropship or orbital pod is available.
            if not self:isLogisticsReady(
                    selectedDeployable
                ) then
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
                deployed = self:callDropship(
                    x,
                    y,
                    selectedDeployable,
                    capacityCost
                )
            elseif selectedDeployable == "Turret"
                or selectedDeployable == "Mine"
                or selectedDeployable == "CommandPost"
                or selectedDeployable == "MissileTurret" then
                deployed = self:dropStructure(
                    x,
                    y,
                    selectedDeployable,
                    capacityCost
                )
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
    if self.tutorial:isOpen() then
        return
    end

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
    -- Let Enter or Space start the mission briefing.
    if self.tutorial:isOpen() then
        self.tutorial:keypressed(key)
        return
    end

    -- Extract selected units with available dropships.
    if key == "e"
        and self.missionState == "playing" then
        local unitsToExtract = {}

        for _, unit in ipairs(self.selectedUnits) do
            table.insert(unitsToExtract, unit)
        end

        self:clearSelectedUnits()

        for _, unit in ipairs(unitsToExtract) do
            if self:getAvailableDropships() <= 0 then
                break
            end

            self:requestUnitExtraction(unit)
        end

        return
    end

    -- Restart after the mission ends.
    if key == "r"
        and self.missionState ~= "playing" then
        self:resetMission()
    end
end

return Map

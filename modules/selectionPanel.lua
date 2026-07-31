local SelectionPanel = {}
SelectionPanel.__index = SelectionPanel

function SelectionPanel.new()
    local self = setmetatable({}, SelectionPanel)

    self.x = 18
    self.y = 18
    self.width = 310
    self.padding = 12
    self.lineHeight = 18

    self.titleFont = love.graphics.newFont(16)
    self.bodyFont = love.graphics.newFont(13)
    self.smallFont = love.graphics.newFont(11)

    return self
end

function SelectionPanel:formatNumber(value)
    if value == nil then
        return "--"
    end

    if math.floor(value) == value then
        return tostring(value)
    end

    return string.format("%.1f", value)
end

function SelectionPanel:getEntityName(entity)
    if entity == nil then
        return ""
    end

    local names = {
        Rifle = "RIFLE",
        Heavy = "HEAVY",
        Turret = "TURRET",
        Mine = "MINE",
        CommandPost = "COMMAND POST",
        MissileTurret = "MISSILE TOWER",
        grunt = "GRUNT",
        scout = "SCOUT",
        heavy = "HEAVY",
        siege = "SIEGE WALKER"
    }

    return names[entity.unitType]
        or names[entity.structureType]
        or names[entity.enemyType]
        or "UNKNOWN"
end

function SelectionPanel:getEntityRole(entity)
    if entity == nil then
        return "Unknown"
    end

    local roles = {
        Rifle = "Infantry",
        Heavy = "Heavy Infantry",
        Turret = "Single-Target Defense",
        Mine = "Hidden Explosive",
        CommandPost = "Command Structure",
        MissileTurret = "Splash Defense",
        grunt = "Standard Enemy",
        scout = "Fast Enemy",
        heavy = "Heavy Enemy",
        siege = "Structure Hunter"
    }

    return roles[entity.unitType]
        or roles[entity.structureType]
        or roles[entity.enemyType]
        or "Unknown"
end

function SelectionPanel:getEntityColor(entity)
    if entity == nil then
        return { 1, 1, 1 }
    end

    if entity.color ~= nil then
        return entity.color
    end

    local colors = {
        Turret = { 0.2, 0.5, 1 },
        Mine = { 0.95, 0.8, 0.15 },
        CommandPost = { 0.7, 0.3, 1 },
        MissileTurret = { 0.9, 0.3, 0.1 }
    }

    return colors[entity.structureType] or { 0.8, 0.8, 0.8 }
end

function SelectionPanel:getHealthText(entity)
    if entity.maxHealth == nil then
        return nil
    end

    return self:formatNumber(entity.health)
        .. " / "
        .. self:formatNumber(entity.maxHealth)
end

function SelectionPanel:getAttackLines(entity)
    local lines = {}

    if entity.structureType == "Mine" then
        table.insert(
            lines,
            {
                label = "Attack",
                value = "Explosion " .. self:formatNumber(entity.damage)
            }
        )

        return lines
    end

    if entity.structureType == "MissileTurret" then
        table.insert(
            lines,
            {
                label = "Attack",
                value = "Direct " .. self:formatNumber(entity.directDamage)
                    .. " / Splash " .. self:formatNumber(entity.splashDamage)
            }
        )
    elseif entity.structureType == "Turret" then
        -- Turrets use the default Projectile damage.
        table.insert(
            lines,
            {
                label = "Attack",
                value = "20"
            }
        )
    elseif entity.damage ~= nil then
        table.insert(
            lines,
            {
                label = "Attack",
                value = self:formatNumber(entity.damage)
            }
        )
    end

    if entity.fireRate ~= nil then
        table.insert(
            lines,
            {
                label = "Fire Rate",
                value = self:formatNumber(entity.fireRate) .. "/sec"
            }
        )
    end

    return lines
end

function SelectionPanel:getProtectionText(entity, terrain)
    if terrain == nil
        or entity == nil
        or entity.x == nil
        or entity.y == nil then
        return "None"
    end

    local zone = terrain:getZoneAt(entity.x, entity.y)

    if zone == nil then
        return "None"
    end

    if zone.minDamageReduction ~= nil then
        return "Cover active"
    end

    if zone.speedMultiplier ~= nil
        and zone.speedMultiplier < 1 then
        return "Rough terrain"
    end

    return "None"
end

function SelectionPanel:getStatusText(entity)
    if entity.dead then
        return "Dead"
    end

    if entity.extracted then
        return "Extracted"
    end

    if entity.isExtracting then
        return "Extracting"
    end

    return nil
end

function SelectionPanel:getExtractionProgress(entity)
    if entity.extractionProgress ~= nil then
        return entity.extractionProgress
    end

    if entity.extracted then
        return 1
    end

    if entity.isExtracting then
        -- Temporary fallback until dropship extraction progress is wired in.
        return 0.15
    end

    return nil
end

function SelectionPanel:addLine(lines, label, value)
    if value == nil then
        return
    end

    table.insert(
        lines,
        {
            label = label,
            value = value
        }
    )
end

function SelectionPanel:getLines(entity, terrain)
    local lines = {}

    self:addLine(lines, "Role", self:getEntityRole(entity))
    self:addLine(lines, "Health", self:getHealthText(entity))

    for _, attackLine in ipairs(self:getAttackLines(entity)) do
        table.insert(lines, attackLine)
    end

    if entity.unitType ~= nil
        or entity.enemyType ~= nil then
        self:addLine(
            lines,
            "Speed",
            self:formatNumber(entity.speed)
        )
    end

    if entity.capacityCost ~= nil
        and entity.enemyType == nil then
        self:addLine(
            lines,
            "Capacity",
            self:formatNumber(entity.capacityCost)
        )
    end

    if entity.getTargetingMode ~= nil then
        self:addLine(
            lines,
            "Target Mode",
            entity:getTargetingMode()
        )
    end

    self:addLine(
        lines,
        "Protection",
        self:getProtectionText(entity, terrain)
    )

    self:addLine(lines, "Status", self:getStatusText(entity))

    return lines
end

function SelectionPanel:drawPortrait(entity, x, y)
    local color = self:getEntityColor(entity)
    local label = string.sub(self:getEntityName(entity), 1, 1)

    love.graphics.setColor(
        color[1],
        color[2],
        color[3],
        1
    )

    love.graphics.rectangle("fill", x, y, 44, 44)

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", x, y, 44, 44)

    love.graphics.setFont(self.titleFont)
    love.graphics.printf(label, x, y + 12, 44, "center")
end

function SelectionPanel:drawLine(line, x, y)
    love.graphics.setFont(self.bodyFont)

    love.graphics.setColor(0.78, 0.82, 0.9)
    love.graphics.print(line.label .. ":", x, y)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(line.value, x + 105, y)
end

function SelectionPanel:drawProgressBar(label, progress, x, y, width)
    progress = math.max(0, math.min(1, progress))

    love.graphics.setFont(self.bodyFont)
    love.graphics.setColor(0.78, 0.82, 0.9)
    love.graphics.print(label .. ":", x, y)

    local barX = x + 105
    local barY = y + 3
    local barWidth = width - 105
    local barHeight = 10

    love.graphics.setColor(0.08, 0.08, 0.1, 0.95)
    love.graphics.rectangle("fill", barX, barY, barWidth, barHeight)

    love.graphics.setColor(0.25, 0.65, 1, 0.95)
    love.graphics.rectangle(
        "fill",
        barX,
        barY,
        barWidth * progress,
        barHeight
    )

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("line", barX, barY, barWidth, barHeight)
end

function SelectionPanel:getUnitGroupComposition(units)
    local rifleCount = 0
    local heavyCount = 0
    local otherCount = 0

    for _, unit in ipairs(units) do
        if unit.unitType == "Rifle" then
            rifleCount = rifleCount + 1
        elseif unit.unitType == "Heavy" then
            heavyCount = heavyCount + 1
        else
            otherCount = otherCount + 1
        end
    end

    local parts = {}

    if rifleCount > 0 then
        table.insert(parts, "Rifle x" .. rifleCount)
    end

    if heavyCount > 0 then
        table.insert(parts, "Heavy x" .. heavyCount)
    end

    if otherCount > 0 then
        table.insert(parts, "Other x" .. otherCount)
    end

    return table.concat(parts, ", ")
end

function SelectionPanel:getUnitGroupHealth(units)
    local health = 0
    local maxHealth = 0

    for _, unit in ipairs(units) do
        if not unit.dead then
            health = health + unit.health
            maxHealth = maxHealth + unit.maxHealth
        end
    end

    if maxHealth <= 0 then
        return nil
    end

    local percent = math.floor((health / maxHealth) * 100)

    return self:formatNumber(health)
        .. " / "
        .. self:formatNumber(maxHealth)
        .. " ("
        .. percent
        .. "%)"
end

function SelectionPanel:getUnitGroupCapacity(units)
    local capacity = 0

    for _, unit in ipairs(units) do
        if not unit.dead
            and not unit.extractionComplete then
            capacity = capacity + unit.capacityCost
        end
    end

    return self:formatNumber(capacity)
end

function SelectionPanel:getUnitGroupTargetMode(units)
    local firstMode = nil

    for _, unit in ipairs(units) do
        if unit.getTargetingMode ~= nil then
            local mode = unit:getTargetingMode()

            if firstMode == nil then
                firstMode = mode
            elseif firstMode ~= mode then
                return "Mixed"
            end
        end
    end

    return firstMode
end

function SelectionPanel:getUnitGroupProtection(units, terrain)
    if terrain == nil then
        return "None"
    end

    local coverCount = 0
    local roughCount = 0

    for _, unit in ipairs(units) do
        local zone = terrain:getZoneAt(unit.x, unit.y)

        if zone ~= nil then
            if zone.minDamageReduction ~= nil then
                coverCount = coverCount + 1
            elseif zone.speedMultiplier ~= nil
                and zone.speedMultiplier < 1 then
                roughCount = roughCount + 1
            end
        end
    end

    local parts = {}

    if coverCount > 0 then
        table.insert(parts, coverCount .. " in cover")
    end

    if roughCount > 0 then
        table.insert(parts, roughCount .. " in rough")
    end

    if #parts == 0 then
        return "None"
    end

    return table.concat(parts, ", ")
end

function SelectionPanel:getUnitGroupExtractionProgress(units)
    local extractingCount = 0
    local totalProgress = 0

    for _, unit in ipairs(units) do
        if unit.isExtracting
            or unit.extracted then
            extractingCount = extractingCount + 1
            totalProgress = totalProgress
                + (unit.extractionProgress or 0)
        end
    end

    if extractingCount == 0 then
        return nil
    end

    return totalProgress / extractingCount
end

function SelectionPanel:drawMiniPortrait(unit, x, y, size)
    local color = self:getEntityColor(unit)
    local label = string.sub(self:getEntityName(unit), 1, 1)

    love.graphics.setColor(
        color[1],
        color[2],
        color[3],
        1
    )

    love.graphics.rectangle("fill", x, y, size, size)

    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.rectangle("line", x, y, size, size)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(
        label,
        x,
        y + 5,
        size,
        "center"
    )
end

function SelectionPanel:drawUnitGroup(units, terrain)
    if units == nil
        or #units == 0 then
        return
    end

    local lines = {}

    self:addLine(lines, "Role", "Selected Squad")
    self:addLine(lines, "Units", tostring(#units) .. " selected")
    self:addLine(lines, "Composition", self:getUnitGroupComposition(units))
    self:addLine(lines, "Health", self:getUnitGroupHealth(units))
    self:addLine(lines, "Capacity", self:getUnitGroupCapacity(units))
    self:addLine(lines, "Target Mode", self:getUnitGroupTargetMode(units))
    self:addLine(
        lines,
        "Protection",
        self:getUnitGroupProtection(units, terrain)
    )

    local extractionProgress =
        self:getUnitGroupExtractionProgress(units)

    local portraitSize = 24
    local portraitGap = 6
    local portraitsPerRow = 8
    local visiblePortraits = math.min(#units, 16)
    local portraitRows = math.ceil(visiblePortraits / portraitsPerRow)

    local portraitAreaHeight =
        portraitRows * portraitSize
        + math.max(0, portraitRows - 1) * portraitGap

    local contentHeight =
        42
        + portraitAreaHeight
        + 14
        + #lines * self.lineHeight

    if extractionProgress ~= nil then
        contentHeight = contentHeight + self.lineHeight
    end

    local panelHeight = contentHeight + self.padding * 2

    -- Panel background.
    love.graphics.setColor(0.02, 0.025, 0.035, 0.9)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        panelHeight
    )

    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.rectangle(
        "line",
        self.x,
        self.y,
        self.width,
        panelHeight
    )

    local contentX = self.x + self.padding
    local contentY = self.y + self.padding

    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("UNIT GROUP", contentX, contentY)

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.78, 0.82, 0.9)
    love.graphics.print(
        "Selected Squad",
        contentX,
        contentY + 21
    )

    local portraitStartY = contentY + 42

    -- Draw one small portrait for each selected unit.
    -- Limit visible portraits so the panel stays compact.
    for i = 1, visiblePortraits do
        local column = (i - 1) % portraitsPerRow
        local row = math.floor((i - 1) / portraitsPerRow)

        local portraitX =
            contentX + column * (portraitSize + portraitGap)

        local portraitY =
            portraitStartY + row * (portraitSize + portraitGap)

        self:drawMiniPortrait(
            units[i],
            portraitX,
            portraitY,
            portraitSize
        )
    end

    if #units > visiblePortraits then
        love.graphics.setFont(self.smallFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(
            "+" .. tostring(#units - visiblePortraits),
            contentX + portraitsPerRow * (portraitSize + portraitGap),
            portraitStartY + portraitAreaHeight - portraitSize
        )
    end

    local lineY =
        portraitStartY
        + portraitAreaHeight
        + 14

    for _, line in ipairs(lines) do
        self:drawLine(line, contentX, lineY)
        lineY = lineY + self.lineHeight
    end

    if extractionProgress ~= nil then
        self:drawProgressBar(
            "Extraction",
            extractionProgress,
            contentX,
            lineY,
            self.width - self.padding * 2
        )
    end

    love.graphics.setColor(1, 1, 1)
end

function SelectionPanel:draw(entity, terrain)
    if entity == nil then
        return
    end

    local lines = self:getLines(entity, terrain)
    local extractionProgress = self:getExtractionProgress(entity)

    local contentHeight = 64 + #lines * self.lineHeight

    if extractionProgress ~= nil then
        contentHeight = contentHeight + self.lineHeight
    end

    local panelHeight = contentHeight + self.padding * 2

    -- Panel background.
    love.graphics.setColor(0.02, 0.025, 0.035, 0.9)
    love.graphics.rectangle(
        "fill",
        self.x,
        self.y,
        self.width,
        panelHeight
    )

    love.graphics.setColor(1, 1, 1, 0.18)
    love.graphics.rectangle(
        "line",
        self.x,
        self.y,
        self.width,
        panelHeight
    )

    local portraitX = self.x + self.padding
    local portraitY = self.y + self.padding

    self:drawPortrait(entity, portraitX, portraitY)

    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(
        self:getEntityName(entity),
        portraitX + 56,
        portraitY + 4
    )

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(0.78, 0.82, 0.9)
    love.graphics.print(
        "Selected Entity",
        portraitX + 56,
        portraitY + 26
    )

    local lineX = self.x + self.padding
    local lineY = self.y + self.padding + 62

    for _, line in ipairs(lines) do
        self:drawLine(line, lineX, lineY)
        lineY = lineY + self.lineHeight
    end

    if extractionProgress ~= nil then
        self:drawProgressBar(
            "Extraction",
            extractionProgress,
            lineX,
            lineY,
            self.width - self.padding * 2
        )
    end

    love.graphics.setColor(1, 1, 1)
end

return SelectionPanel

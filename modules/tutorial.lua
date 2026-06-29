local Tutorial = {}
Tutorial.__index = Tutorial

function Tutorial.new()
    local self = setmetatable({}, Tutorial)

    self.open = true

    self.titleFont = love.graphics.newFont(34)
    self.bodyFont = love.graphics.newFont(16)
    self.buttonFont = love.graphics.newFont(20)

    return self
end

function Tutorial:isOpen()
    return self.open
end

function Tutorial:startMission()
    self.open = false
end

function Tutorial:getStartButtonBounds()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    local buttonWidth = 250
    local buttonHeight = 55

    return {
        x = screenWidth / 2 - buttonWidth / 2,
        y = screenHeight - 105,
        width = buttonWidth,
        height = buttonHeight
    }
end

function Tutorial:isStartButtonClicked(x, y)
    local button = self:getStartButtonBounds()

    return x >= button.x
        and x <= button.x + button.width
        and y >= button.y
        and y <= button.y + button.height
end

function Tutorial:mousepressed(x, y, button)
    if not self.open then
        return
    end

    if button == 1
    and self:isStartButtonClicked(x, y) then
        self:startMission()
    end
end

function Tutorial:keypressed(key)
    if not self.open then
        return
    end

    if key == "return"
    or key == "space" then
        self:startMission()
    end
end

function Tutorial:draw()
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local previousFont = love.graphics.getFont()

    local panelWidth = math.min(780, screenWidth - 80)
    local panelHeight = math.min(590, screenHeight - 60)

    local panelX = screenWidth / 2 - panelWidth / 2
    local panelY = screenHeight / 2 - panelHeight / 2

    -- Darken the battlefield behind the briefing.
    love.graphics.setColor(0, 0, 0, 0.78)
    love.graphics.rectangle(
        "fill",
        0,
        0,
        screenWidth,
        screenHeight
    )

    -- Draw the briefing panel.
    love.graphics.setColor(0.07, 0.1, 0.15, 0.96)
    love.graphics.rectangle(
        "fill",
        panelX,
        panelY,
        panelWidth,
        panelHeight
    )

    love.graphics.setColor(0.25, 0.75, 1, 1)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle(
        "line",
        panelX,
        panelY,
        panelWidth,
        panelHeight
    )

    -- Draw the title.
    love.graphics.setFont(self.titleFont)
    love.graphics.setColor(1, 1, 1)

    love.graphics.printf(
        "IRON RAIN",
        panelX,
        panelY + 25,
        panelWidth,
        "center"
    )

    love.graphics.setFont(self.bodyFont)

    local tutorialText = [[
MISSION BRIEFING

OBJECTIVE
Defend the route and destroy every enemy wave before they reach the end.

DEPLOYMENT
- Click a unit or structure card, then click a green placement area.
- Green means valid placement. Red means the location is blocked.
- Rifle and Heavy units arrive by dropship.
- Turrets arrive by orbital cargo pod.

COMMAND
- Left-click a unit to select it.
- Drag a box around multiple units to select a group.
- Right-click to order selected units to move.
- Press E to extract selected units when a dropship is available.

LOGISTICS
- Supply pays for reinforcements and structures.
- Command Capacity limits your active force.
- Dropships must return to orbit before they can deploy more troops.
- Orbital pods must be fabricated before another structure can deploy.
- Extraction refunds Supply only after the dropship escapes safely.

DEV NOTES
- This is a work-in-progress. The game is not yet complete.
- Please report any bugs or issues to the developer.
- Enter full screen mode for correct enemy pathing.
]]

    love.graphics.setColor(0.9, 0.94, 1, 1)

    love.graphics.printf(
        tutorialText,
        panelX + 42,
        panelY + 90,
        panelWidth - 84,
        "left"
    )

    -- Draw the start button.
    local button = self:getStartButtonBounds()
    local mouseX, mouseY = love.mouse.getPosition()

    if self:isStartButtonClicked(mouseX, mouseY) then
        love.graphics.setColor(0.2, 0.75, 1, 1)
    else
        love.graphics.setColor(0.12, 0.45, 0.72, 1)
    end

    love.graphics.rectangle(
        "fill",
        button.x,
        button.y,
        button.width,
        button.height
    )

    love.graphics.setColor(1, 1, 1)
    love.graphics.setLineWidth(2)

    love.graphics.rectangle(
        "line",
        button.x,
        button.y,
        button.width,
        button.height
    )

    love.graphics.setFont(self.buttonFont)

    love.graphics.printf(
        "START MISSION",
        button.x,
        button.y + 15,
        button.width,
        "center"
    )

    love.graphics.setLineWidth(1)
    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1)
end

return Tutorial
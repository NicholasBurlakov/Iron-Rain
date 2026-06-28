local BuildMenu = {}
BuildMenu.__index = BuildMenu

function BuildMenu.new()
    local self = setmetatable({}, BuildMenu)

    self.height = 110

    self.buttonWidth = 100
    self.buttonHeight = 50
    self.buttonTopPadding = 15

    self.selected = nil

    self.buttons = {
        {
            name = "Rifle",
            color = { 0.2, 0.6, 1 },
            cost = 50,
            capacity = 1,
            x = 20
        },
        {
            name = "Heavy",
            color = { 0.3, 1, 0.3 },
            cost = 100,
            capacity = 2,
            x = 135
        },
        {
            name = "Turret",
            color = { 1, 0.3, 0.3 },
            cost = 150,
            capacity = 2,
            x = 250
        },
        {
            name = "Mine",
            color = { 1, 1, 0.3 },
            cost = 75,
            capacity = 1,
            available = false,
            x = 365
        }
    }

    return self
end

function BuildMenu:draw(supply, usedCapacity, commandCapacity, availableDropships, dropshipFleetSize, orbitalPodReady,
                        orbitalPodTimer)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Draw the menu background.
    love.graphics.setColor(0.15, 0.15, 0.15)

    love.graphics.rectangle(
        "fill",
        0,
        screenHeight - self.height,
        screenWidth,
        self.height
    )

    -- Draw each deployable button.
    for _, button in ipairs(self.buttons) do
        local available = button.available ~= false
        local alpha = 1

        local hasCapacity = usedCapacity + button.capacity <= commandCapacity

        local logisticsReady =
            self:isLogisticsReady(
                button,
                availableDropships,
                orbitalPodReady
            )

        if not available
            or supply < button.cost
            or not hasCapacity
            or not logisticsReady then
            alpha = 0.35
        end

        if self.selected == button.name then
            love.graphics.setColor(1, 1, 1)

            love.graphics.rectangle(
                "line",
                button.x - 3,
                screenHeight - self.height + self.buttonTopPadding - 3,
                self.buttonWidth + 6,
                self.buttonHeight + 6
            )
        end

        love.graphics.setColor(
            button.color[1],
            button.color[2],
            button.color[3],
            alpha
        )

        love.graphics.rectangle(
            "fill",
            button.x,
            screenHeight - self.height + self.buttonTopPadding,
            self.buttonWidth,
            self.buttonHeight
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.printf(
            button.name,
            button.x,
            screenHeight - 40,
            self.buttonWidth,
            "center"
        )

        love.graphics.printf(
            button.cost
            .. "S / "
            .. button.capacity
            .. "C",
            button.x,
            screenHeight - 22,
            self.buttonWidth,
            "center"
        )
    end

    local statusX = screenWidth - 240
    local menuTop = screenHeight - self.height

    local podStatus = "Pod: READY"

    if not orbitalPodReady then
        podStatus =
            "Pod: FAB "
            .. string.format(
                "%.1fs",
                math.max(0, orbitalPodTimer)
            )
    end

    love.graphics.setColor(1, 1, 1)

    love.graphics.print(
        "Supply: " .. math.floor(supply),
        statusX,
        menuTop + 10
    )

    love.graphics.print(
        "Capacity: "
        .. usedCapacity
        .. " / "
        .. commandCapacity,
        statusX,
        menuTop + 31
    )

    love.graphics.print(
        "Dropships: "
        .. availableDropships
        .. " / "
        .. dropshipFleetSize,
        statusX,
        menuTop + 52
    )

    love.graphics.print(
        podStatus,
        statusX,
        menuTop + 73
    )
end

function BuildMenu:getSelectedCost()
    for _, button in ipairs(self.buttons) do
        if button.name == self.selected then
            return button.cost
        end
    end

    return nil
end

function BuildMenu:getSelectedCapacity()
    for _, button in ipairs(self.buttons) do
        if button.name == self.selected then
            return button.capacity
        end
    end

    return nil
end

function BuildMenu:isLogisticsReady(
    button,
    availableDropships,
    orbitalPodReady
)
    if button.name == "Rifle"
        or button.name == "Heavy" then
        return availableDropships > 0
    end

    if button.name == "Turret"
        or button.name == "Mine" then
        return orbitalPodReady
    end

    return true
end

function BuildMenu:mousepressed(x, y, supply, usedCapacity, commandCapacity, availableDropships, orbitalPodReady)
    local screenHeight = love.graphics.getHeight()

    for _, button in ipairs(self.buttons) do
        local insideButton =
            x >= button.x
            and x <= button.x + self.buttonWidth
            and y >= screenHeight - self.height + self.buttonTopPadding
            and y <= screenHeight - self.height
            + self.buttonTopPadding
            + self.buttonHeight

        if insideButton then
            local available = button.available ~= false

            local hasCapacity = usedCapacity + button.capacity <= commandCapacity

            local logisticsReady =
                self:isLogisticsReady(
                    button,
                    availableDropships,
                    orbitalPodReady
                )

            if available
                and supply >= button.cost
                and hasCapacity
                and logisticsReady then
                self.selected = button.name
            end

            return true
        end
    end

    return false
end

return BuildMenu

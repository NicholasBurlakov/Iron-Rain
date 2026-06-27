local BuildMenu = {}
BuildMenu.__index = BuildMenu

function BuildMenu.new()

    local self = setmetatable({}, BuildMenu)

    self.height = 90

    self.selected = nil

    self.buttons = {
        {
            name = "Rifle",
            color = {0.2, 0.6, 1},
            cost = 50,
            x = 20
        },
        {
            name = "Heavy",
            color = {0.3, 1, 0.3},
            cost = 100,
            x = 110
        },
        {
            name = "Turret",
            color = {1, 0.3, 0.3},
            cost = 150,
            x = 200
        },
        {
            name = "Mine",
            color = {1, 1, 0.3},
            cost = 75,
            available = false,
            x = 290
        }
    }

    return self
end

function BuildMenu:draw(supply)
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

        if not available or supply < button.cost then
            alpha = 0.35
        end

        if self.selected == button.name then
            love.graphics.setColor(1, 1, 1)

            love.graphics.rectangle(
                "line",
                button.x - 3,
                screenHeight - 73,
                56,
                56
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
            screenHeight - 70,
            50,
            50
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.print(
            button.name .. " - " .. button.cost,
            button.x,
            screenHeight - 15
        )
    end

    -- Draw current Supply.
    love.graphics.print(
        "Supply: " .. math.floor(supply),
        screenWidth - 150,
        screenHeight - 55
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

function BuildMenu:mousepressed(x, y, supply)
    local screenHeight = love.graphics.getHeight()

    for _, button in ipairs(self.buttons) do
        local insideButton =
            x >= button.x
            and x <= button.x + 50
            and y >= screenHeight - 70
            and y <= screenHeight - 20

        if insideButton then
            local available = button.available ~= false

            if available and supply >= button.cost then
                self.selected = button.name
            end

            return true
        end
    end

    return false
end

return BuildMenu
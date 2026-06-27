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
            x = 20
        },
        {
            name = "Heavy",
            color = {0.3, 1, 0.3},
            x = 110
        },
        {
            name = "Turret",
            color = {1, 0.3, 0.3},
            x = 200
        },
        {
            name = "Mine",
            color = {1, 1, 0.3},
            x = 290
        }
    }

    return self
end

function BuildMenu:draw()

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Background
    love.graphics.setColor(0.15, 0.15, 0.15)
    love.graphics.rectangle(
        "fill",
        0,
        screenHeight - self.height,
        screenWidth,
        self.height
    )

    -- Buttons
    for _, button in ipairs(self.buttons) do

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

        love.graphics.setColor(button.color)

        love.graphics.rectangle(
            "fill",
            button.x,
            screenHeight - 70,
            50,
            50
        )

        love.graphics.setColor(1, 1, 1)

        love.graphics.print(
            button.name,
            button.x,
            screenHeight - 15
        )

    end

end

function BuildMenu:mousepressed(x, y)
    local screenHeight = love.graphics.getHeight()

    for _, button in ipairs(self.buttons) do
        if x >= button.x
        and x <= button.x + 50
        and y >= screenHeight - 70
        and y <= screenHeight - 20 then

            self.selected = button.name
            return true
        end
    end

    return false
end

return BuildMenu
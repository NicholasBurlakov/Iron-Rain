local CombatText = {}
CombatText.__index = CombatText

function CombatText.new()
    local self = setmetatable({}, CombatText)

    self.entries = {}
    self.font = love.graphics.newFont(14)

    return self
end

function CombatText:clear()
    self.entries = {}
end

function CombatText:addEntry(text, x, y, color)
    table.insert(
        self.entries,
        {
            text = text,
            x = x + love.math.random(-10, 10),
            y = y - 22 + love.math.random(-4, 4),
            color = color,
            timer = 1.3,
            maxTimer = 1.3,
            riseSpeed = 28
        }
    )
end

function CombatText:addDamage(target, damage, options)
    options = options or {}

    local text = "-" .. tostring(damage)
    local color = { 1, 1, 1 }

    -- Cover feedback takes priority over damage source color.
    if options.coverReduced then
        text = text .. " COVER"
        color = { 0.3, 0.75, 1 }
    elseif options.damageType == "explosion" then
        color = { 1, 0.45, 0.1 }
    end

    self:addEntry(
        text,
        target.x,
        target.y,
        color
    )
end

function CombatText:addDestroyed(target)
    local text = "KIA"

    if target.structureType ~= nil then
        text = "DESTROYED"
    end

    self:addEntry(
        text,
        target.x,
        target.y,
        { 1, 0.2, 0.2 }
    )
end

function CombatText:applyDamage(target, damage, options)
    if target == nil or target.dead then
        return
    end

    local wasAlive = not target.dead

    target:takeDamage(damage)

    self:addDamage(
        target,
        damage,
        options
    )

    if wasAlive and target.dead then
        self:addDestroyed(target)
    end
end

function CombatText:update(dt)
    for i = #self.entries, 1, -1 do
        local entry = self.entries[i]

        entry.timer = entry.timer - dt
        entry.y = entry.y - entry.riseSpeed * dt

        if entry.timer <= 0 then
            table.remove(self.entries, i)
        end
    end
end

function CombatText:draw()
    local previousFont = love.graphics.getFont()

    love.graphics.setFont(self.font)

    for _, entry in ipairs(self.entries) do
        local alpha =
            math.max(0, entry.timer / entry.maxTimer)

        local textWidth =
            self.font:getWidth(entry.text)

        -- Dark shadow improves readability over the map.
        love.graphics.setColor(0, 0, 0, alpha)

        love.graphics.print(
            entry.text,
            entry.x - textWidth / 2 + 1,
            entry.y + 1
        )

        love.graphics.setColor(
            entry.color[1],
            entry.color[2],
            entry.color[3],
            alpha
        )

        love.graphics.print(
            entry.text,
            entry.x - textWidth / 2,
            entry.y
        )
    end

    love.graphics.setFont(previousFont)
    love.graphics.setColor(1, 1, 1)
end

return CombatText

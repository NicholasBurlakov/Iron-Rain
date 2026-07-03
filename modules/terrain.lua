local Terrain = {}
Terrain.__index = Terrain

function Terrain.new()
    local self = setmetatable({}, Terrain)

    -- Temporary visible testing zones.
    self.zones = {
        {
            kind = "cover",
            label = "COVER",
            x = 500,
            y = 205,
            width = 185,
            height = 130,
            minDamageReduction = 0.15,
            maxDamageReduction = 0.30
        },
        {
            kind = "rough",
            label = "MUD",
            x = 820,
            y = 335,
            width = 220,
            height = 150,
            speedMultiplier = 0.65
        }
    }

    return self
end

function Terrain:contains(zone, x, y)
    return x >= zone.x
        and x <= zone.x + zone.width
        and y >= zone.y
        and y <= zone.y + zone.height
end

function Terrain:getZoneAt(x, y)
    for i = #self.zones, 1, -1 do
        local zone = self.zones[i]

        if self:contains(zone, x, y) then
            return zone
        end
    end

    return nil
end

function Terrain:getSpeedMultiplier(x, y)
    local zone = self:getZoneAt(x, y)

    if zone ~= nil
        and zone.speedMultiplier ~= nil then
        return zone.speedMultiplier
    end

    return 1
end

function Terrain:modifyDamage(target, damage)
    local zone = self:getZoneAt(target.x, target.y)

    if zone == nil
        or zone.minDamageReduction == nil then
        return damage
    end

    local minimumPercent = math.floor(
        zone.minDamageReduction * 100
    )

    local maximumPercent = math.floor(
        zone.maxDamageReduction * 100
    )

    -- Roll a new cover reduction for every direct hit.
    local reduction =
        love.math.random(
            minimumPercent,
            maximumPercent
        ) / 100

    return math.max(
        1,
        math.floor(damage * (1 - reduction) + 0.5)
    )
end

function Terrain:draw()
    for _, zone in ipairs(self.zones) do
        if zone.kind == "cover" then
            love.graphics.setColor(0.2, 0.55, 0.9, 0.2)
        else
            love.graphics.setColor(0.45, 0.28, 0.1, 0.25)
        end

        love.graphics.rectangle(
            "fill",
            zone.x,
            zone.y,
            zone.width,
            zone.height
        )

        if zone.kind == "cover" then
            love.graphics.setColor(0.35, 0.75, 1, 0.9)
        else
            love.graphics.setColor(0.7, 0.45, 0.18, 0.9)
        end

        love.graphics.setLineWidth(2)

        love.graphics.rectangle(
            "line",
            zone.x,
            zone.y,
            zone.width,
            zone.height
        )

        love.graphics.print(
            zone.label,
            zone.x + 8,
            zone.y + 8
        )
    end

    love.graphics.setLineWidth(1)
    love.graphics.setColor(1, 1, 1)
end

return Terrain

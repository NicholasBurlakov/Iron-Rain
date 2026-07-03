local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(
    x,
    y,
    target,
    damage,
    onImpact,
    color,
    radius,
    terrain
)
    local self = setmetatable({}, Projectile)

    self.x = x
    self.y = y

    self.target = target
    self.damage = damage or 20
    self.onImpact = onImpact
    self.terrain = terrain

    self.speed = 350
    self.radius = radius or 5
    self.color = color or { 1, 1, 0 }

    self.dead = false

    return self
end

function Projectile:update(dt)
    if self.dead then
        return
    end

    if self.target == nil
        or self.target.dead
        or self.target.health <= 0 then
        self.dead = true
        return
    end

    local dx = self.target.x - self.x
    local dy = self.target.y - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    if distance <= self.radius + self.target.radius then
        if self.onImpact ~= nil then
            self.onImpact(
                self.target,
                self.x,
                self.y
            )
        else
            local finalDamage = self.damage

            -- Cover affects direct projectile hits only.
            if self.terrain ~= nil then
                finalDamage = self.terrain:modifyDamage(
                    self.target,
                    self.damage
                )
            end

            self.target:takeDamage(finalDamage)
        end

        self.dead = true
        return
    end

    local dirX = dx / distance
    local dirY = dy / distance

    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt
end

function Projectile:draw()
    love.graphics.setColor(
        self.color[1],
        self.color[2],
        self.color[3]
    )

    love.graphics.circle(
        "fill",
        self.x,
        self.y,
        self.radius
    )

    love.graphics.setColor(1, 1, 1)
end

return Projectile

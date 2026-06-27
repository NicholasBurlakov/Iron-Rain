local Projectile = {}
Projectile.__index = Projectile

function Projectile.new(x, y, target, damage)

    local self = setmetatable({}, Projectile)

    self.x = x
    self.y = y

    self.target = target

    self.speed = 350
    self.damage = damage or 20

    self.radius = 5

    self.dead = false

    return self
end

function Projectile:update(dt)

    if self.dead then
        return
    end

    if self.target.health <= 0 then
        self.dead = true
        return
    end

    local dx = self.target.x - self.x
    local dy = self.target.y - self.y

    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < self.radius + self.target.radius then

        self.target:takeDamage(self.damage)
        self.dead = true

        return
    end

    local dirX = dx / distance
    local dirY = dy / distance

    self.x = self.x + dirX * self.speed * dt
    self.y = self.y + dirY * self.speed * dt

end

function Projectile:draw()

    love.graphics.setColor(1, 1, 0)

    love.graphics.circle(
        "fill",
        self.x,
        self.y,
        self.radius
    )

    love.graphics.setColor(1, 1, 1)

end

return Projectile

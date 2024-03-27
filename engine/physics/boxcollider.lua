BoxCollider = Collider:extend()

---@param gameobject Gameobject The gameobject this collider is attached to.
---@param width number The width of the collider.
---@param height number The height of the collider.
function BoxCollider:new(gameobject, width, height)
    BoxCollider.super.new(self, gameobject)
    self.width = width or self.gameobject.transform.scale.w
    self.height = height or self.gameobject.transform.scale.h
end

function BoxCollider:check_collision(other)
    -- Implement rectangle collision detection logic here.
    -- This is a simplified example.
    local ax1, ay1 = self.gameobject.transform.position.x, self.gameobject.transform.position.y
    local ax2, ay2 = ax1 + self.width, ay1 + self.height
    local bx1, by1 = other.gameobject.transform.position.x, other.gameobject.transform.position.y
    local bx2, by2 = bx1 + other.width, by1 + other.height

    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

function BoxCollider:draw()
    local colour = love.graphics.getColor()
    love.graphics.setColor(0, 1, 0)
    local x, y = self.gameobject.transform.position.x, self.gameobject.transform.position.y
    love.graphics.rectangle("line", x, y, self.width, self.height)
end

---@class Collider
Collider = Object:extend()

function Collider:new(gameobject)
    self.gameobject = gameobject
end

function Collider:check_collision(other)
    -- Placeholder for collision detection logic.
    -- Override this in subclasses.
end

function Collider:draw()
    -- Placeholder for drawing the collider.
    -- Override this in subclasses.
end

---@class Transform
Transform = Object:extend()

function Transform:new(x, y, w, h, r)
    self.position = { x = x or 0, y = y or 0 }
    self.scale = { w = w or 1, h = h or 1 }
    self.rotation = r or 0 -- Rotation in radians
end

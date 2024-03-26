--- Serves as a base for all entities in the game that require transformation properties,
--- such as position, size, rotation, and scale.
---@class Gameobject
Gameobject = Object:extend()

---@param args {Transform: table, container: Gameobject}
--**T** The transform ititializer, with keys of x|1, y|2, w|3, h|4, r|5\
--**container** optional container for this Node, defaults to G.ROOM
function Gameobject:new()
    --ID tracker, every Node has a unique ID
    G.ID = G.ID or 1
    self.ID = G.ID
    G.ID = G.ID + 1

    if not self.children then
        self.children = {}
    end

    -- Add the gameobject to the global gameobject table
    if getmetatable(self) == Gameobject then
        table.insert(G.I.GAMEOBJECT, self)
    end
end

--Draw a bounding rectangle representing the transform of this node. Used in debugging.
function Gameobject:draw_boundingrect()
    if not Game.DEBUG then return end

    -- Draw the bounding rectangle
end

--Draws self, then adds self the the draw hash, then draws all children
function Gameobject:draw()
    self:draw_boundingrect()

    for _, value in pairs(self.children) do
        value:draw()
    end

    love.graphics.circle("line", 200, 200, 100)
end

--Determines if this gameobject collides with some point. Applies any container translations and rotations, then\
--applies translations and rotations specific to this node. This means the collision detection effectively\
--determines if some point intersects this node regargless of rotation.
--
---@param point {x: number, y: number}
--**x and y** The coordinates of the cursor transformed into game units
function Gameobject:collides_with_point(point)

end

--Sets the offset of passed point in terms of this nodes T.x and T.y
--
---@param point {x: number, y: number}
---@param type string
--**x and y** The coordinates of the cursor transformed into game units
--**type** the type of offset to set for this Node, either 'Click' or 'Hover'
function Gameobject:set_offset(point, type)

end

--Translation function used before any draw calls, translates this node according to the transform of the container node
function Gameobject:translate_container()

end

--When this Gameobject needs to be deleted, removes self from any tables it may have been added to to destroy any weak references
--Also calls the remove method of all children to have them do the same
function Gameobject:remove()

end

--Prototype for a click release function, when the cursor is released on this node
function Gameobject:release(dragged) end

--Prototype for a click function
function Gameobject:click() end

--Prototype animation function for any frame manipulation needed
function Gameobject:animate() end

--Prototype update function for any object specific logic that needs to occur every frame
function Gameobject:update(dt) end

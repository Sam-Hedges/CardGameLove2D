--- Serves as a base for all entities in the game that require transformation properties,
--- such as position, size, rotation, and scale.
---@class Gameobject
Gameobject = Object:extend()

---@param args {transform: Transform, collider: Collider, parent: Gameobject}
--**T** The transform ititializer, with keys of x|1, y|2, w|3, h|4, r|5\
--**Collider** optional collider for this Gameobject, defaults to new BoxCollider\
--**parent** optional container for this Gameobject, defaults to G.ROOM\
function Gameobject:new(args)
    --ID tracker, every Node has a unique ID

    self.transform = args.transform or Transform()     -- Default to a basic Transform if none provided.
    self.collider = args.collider or BoxCollider(self) -- Default to a BoxCollider if none provided.

    -- Define velocity
    self.velocity = { x = 100, y = 100 } -- Adjust the speed as necessary.

    G.ID = G.ID or 1
    self.ID = G.ID
    G.ID = G.ID + 1

    if not self.children then
        self.children = {}
    end

    -- Add the gameobject to the global gameobject table
    if getmetatable(self) == Gameobject then
        table.insert(G.INSTANCES.GAMEOBJECT, self)
    end
end

--Draw a bounding rectangle representing the transform of this node. Used in debugging.
function Gameobject:draw_collider()
    if not G.DEBUG_COLLIDERS then return end

    -- Draw the bounding rectangle
    self.collider:draw()
end

--Draws self, then adds self the the draw hash, then draws all children
function Gameobject:draw()
    self:draw_collider()

    for _, value in pairs(self.children) do
        value:draw()
    end
end

--Prototype update function for any object specific logic that needs to occur every frame
function Gameobject:update(dt)
    -- Move the gameobject like a tv screensaver
    -- Update position based on velocity
    self.transform.position.x = self.transform.position.x + self.velocity.x * dt
    self.transform.position.y = self.transform.position.y + self.velocity.y * dt

    -- Screen boundaries
    local screenWidth, screenHeight = love.graphics.getWidth(), love.graphics.getHeight()

    -- Check for boundary collision and reverse direction if necessary
    if self.transform.position.x <= 0 or self.transform.position.x + self.transform.scale.w >= screenWidth then
        self.velocity.x = -self.velocity.x -- Reverse x direction
    end
    if self.transform.position.y <= 0 or self.transform.position.y + self.transform.scale.h >= screenHeight then
        self.velocity.y = -self.velocity.y -- Reverse y direction
    end
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

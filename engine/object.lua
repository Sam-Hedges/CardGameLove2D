--||--
--This Object implementation was taken from SNKRX (MIT license). Slightly modified, this is a very simple OOP base

-- Object is the base class for all objects, providing basic OOP functionality.
Object = {}
Object.__index = Object -- Set Object itself as the __index metamethod, enabling inheritance.

-- Initializes a new instance of an object. This method should be overridden by subclasses.
function Object:init()
end

-- Creates and returns a new class that extends this class.
function Object:extend()
    local class = {} -- Create a new class table.
    for key, value in pairs(self) do
        if key:find("__") == 1 then
            class[key] = value -- Copy all special methods (those starting with "__") to the new class.
        end
    end
    class.__index = class     -- Set the __index metamethod of the new class to itself.
    class.super = self        -- Establish a reference to the superclass.
    setmetatable(class, self) -- Set the current class as the metatable of the new class to inherit methods.
    return class              -- Return the new subclass.
end

-- Checks if the instance or class is of, or inherits from, a given type.
function Object:is(T)
    local metaTable = getmetatable(self)    -- Get the metatable of the current object or class.
    while metaTable do                      -- Traverse the inheritance chain.
        if metaTable == T then
            return true                     -- Return true if a match is found in the chain.
        end
        metaTable = getmetatable(metaTable) -- Move up the inheritance chain.
    end
    return false                            -- Return false if no match is found.
end

-- Allows an object to be called like a function, creating and returning a new instance of the object.
function Object:__call(...)
    local obj = setmetatable({}, self) -- Create a new object instance, setting its metatable to the class.
    obj:init(...)                      -- Initialize the new object by calling its init method.
    return obj                         -- Return the new object.
end

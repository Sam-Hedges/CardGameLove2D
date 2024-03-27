--- The base class for inheritable objects, with
--- basic object-oriented capabilities like instantiation, method inheritance, and type checking.
Object = {}
Object.__index = Object

--- Initializes a new instance of an object.
--- This method should be overridden by subclasses to implement specific initializations.
function Object:new(...)
end

--- Creates and returns a new class that extends this class.
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

--- Checks if the instance or class is of, or inherits from, a given type.
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

--- Allows an object to be called like a function, creating and returning a new instance of the object.
--- This method should be used in conjunction with a `new` method defined in subclasses, where actual initialization should happen.
function Object:__call(...)
    -- '...' is variadic argument operator, which allows the function to accept any number of arguments.
    local obj = setmetatable({}, self)
    obj:new(...)
    return obj
end

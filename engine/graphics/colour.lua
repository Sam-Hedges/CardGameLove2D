---Converts a hexadecimal color string to a RGBA color table compatible with Love2D.
-- The function expects a hex string and converts it to a table containing the RGBA values
-- scaled to the range [0, 1]. If the alpha value is not provided in the hex string,
-- it defaults to 'FF' (opaque).
---@param value string A string representing the color in hexadecimal format. This can be in the form of
-- 'RRGGBB' or 'RRGGBBAA'. If 'AA' (alpha) is not provided, it defaults to 'FF'.
---@return table colour A table containing the RGBA color values as numbers in the range [0, 1]. The table
-- structure is {red, green, blue, alpha}, where each value is scaled between 0 and 1.
function HexToRGBA(value)
    -- If the hex string does not include an alpha value, append 'FF' to make it opaque
    if #value <= 6 then value = value .. "FF" end

    -- Extract the RGBA components from the hex string
    local _, _, r, g, b, a = value:find('(%x%x)(%x%x)(%x%x)(%x%x)')

    -- Convert the hex components to a RGBA color table,
    -- Each component converted to numbers using tonumber() with base 16,
    -- Divide each component by 255 to scale it to the range [0, 1]
    local colour = {
        tonumber(r, 16) / 255,       -- Red component
        tonumber(g, 16) / 255,       -- Green component
        tonumber(b, 16) / 255,       -- Blue component
        tonumber(a, 16) / 255 or 255 -- Alpha component, defaulting to 255 if nil
    }

    return colour
end

---Converts a hexadecimal color string to a RGBA color table compatible with Love2D.
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

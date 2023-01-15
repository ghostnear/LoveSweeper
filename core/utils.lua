local Utils = {}

function Utils.getWindowSize()
    local screenWidth, screenHeight, _ = love.window.getMode()
    return screenWidth, screenHeight
end

function Utils.createColor(r, g, b, a)
    -- Alpha has default value.
    a = a or 0xFF
    return {
        r = r / 0xFF,
        g = g / 0xFF,
        b = b / 0xFF,
        a = a / 0xFF
    }
end

function Utils.setDrawColor(color)
    love.graphics.setColor(color.r, color.g, color.b, color.a)
end

function Utils.table_copy(obj, seen)
    if type(obj) ~= 'table' then return obj end
    if seen and seen[obj] then return seen[obj] end
    local s = seen or {}
    local res = setmetatable({}, getmetatable(obj))
    s[obj] = res
    for k, v in pairs(obj) do res[Utils.table_copy(k, s)] = Utils.table_copy(v, s) end
    return res
end

return Utils
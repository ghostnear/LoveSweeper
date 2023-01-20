-- Import stuff.
if Utils == nil then
    Utils = require("core.utils")
end

local stars = {
    _count = 0,
    _stars = {}
}

function stars:init()
    self._count = love.math.random(100) + 100
    for _ = 0, self._count, 1 do
        local newStar = {
            x = love.math.random(1920),
            y = love.math.random(1080),
            r = 1
        }
        table.insert(self._stars, Utils.table_copy(newStar))
    end
end

function stars:update(dt)
    for _, element in pairs(self._stars) do
        element.x = element.x - dt * 30
        if element.x < 0 then
            element.x = 1920 + element.x
        end
    end 
end

function stars:draw()
    love.graphics.setColor(0.9, 0.9, 0.9)
    for _, element in pairs(self._stars) do
        love.graphics.circle("fill", element.x, element.y, element.r)
    end
end

return stars
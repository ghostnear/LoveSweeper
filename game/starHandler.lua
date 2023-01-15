-- Import stuff.
if Utils == nil then
    Utils = require("core.utils")
end

local stars = {
    count = 0,
    stars = {}
}

function stars:init()
    self.count = love.math.random(100) + 100
    for x = 0, self.count, 1 do
        local newStar = require("game.star")
        newStar.x = love.math.random(1920)
        newStar.y = love.math.random(1080)
        newStar.r = 1
        table.insert(self.stars, Utils.table_copy(newStar))
    end
end

function stars:update(dt)
    for key, element in pairs(self.stars) do 
        element.x = element.x - dt * 30
        if element.x < 0 then
            element.x = 1920 + element.x
        end
    end 
end

function stars:draw()
    love.graphics.setColor(0.9, 0.9, 0.9)
    for key, element in pairs(self.stars) do 
        element:draw()
    end
end

return stars
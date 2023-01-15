local table = require("game.table")
local starHandler = require("game.starHandler")

function love.load()
    -- Init a 15x15 table with 15% mines.
    table:init(15, 15, 0.15)

    starHandler:init()
end

function love.update(dt)
    starHandler:update(dt)
end

function love.mousepressed(x, y, button, isTouch, presses)
    -- Send the button press to the table.
    table:mousePressed({ x = x, y = y }, button)
end

-- Reset game.
function love.keypressed(key, scancode, isrepeat)
    if key == 'r' then
        table:reset()
    end
end

function love.mousemoved(x, y, dx, dy, isTouch)
    -- If the mouse moved, check for new highlights.
    table:mouseMoved({ x = x, y = y })
end

function love.draw()
    -- Draw background.
    starHandler:draw()

    -- Draw game table.
    table:draw()
end
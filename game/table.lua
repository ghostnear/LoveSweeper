-- Import stuff.
if Utils == nil then
    Utils = require("core.utils")
end

local MineSweeperTable = {
    _textColor = Utils.createColor(0xAA, 0xAA, 0xAA),
    _backgroundColor = Utils.createColor(0x1F, 0x1F, 0x1F),
    _font = love.graphics.newFont("assets/fonts/ubuntu/Ubuntu-Regular.ttf", 24),
    _foregroundColor = Utils.createColor(0x2F, 0x2F, 0x2F),
    _borderColor = Utils.createColor(0x4F, 0x4F, 0x4F),
    _highlightedPosition = { x = -1, y = -1 },
    _lineWidth = 3,
    _generated = false,
    _mineCount = 0,
    _lost = false,
    _table = {},
    _size = {}
}

function MineSweeperTable:init(sizeX, sizeY, mineCount)
    -- Save size.
    self._size.x = sizeX
    self._size.y = sizeY
    self._mineCount = math.floor(mineCount * sizeX * sizeY)

    -- Random seed for the generator.
    math.randomseed(os.time())

    -- Create table if correct.
    for row = 0, self._size.x - 1 do
        self._table[row] = {}
        for col = 0, self._size.y - 1 do
            self._table[row][col] = nil
        end
    end
end

function MineSweeperTable:_checkInsideGrid(position)
    return position.x >= 0 and position.y >= 0 and position.x < self._size.x and position.y < self._size.y
end

function MineSweeperTable:positionToTable(position)
    -- Table is square so let's get the displayed sizes.
    local screenWidth, screenHeight = Utils.getWindowSize()
    local usedScreenSize = math.min(screenWidth, screenHeight)

    -- Update input position to local coordonates.
    position.x = position.x - (screenWidth - usedScreenSize) / 2
    position.y = position.y - (screenHeight - usedScreenSize) / 2

    return position
end

function MineSweeperTable:_addMine(position)
    -- Mark position.
    self._table[position.x][position.y] = 0

    -- Mark everything as +1 around.
    for offsetX = -1, 1 do
        for offsetY = -1, 1 do
            -- Don't add in center.
            if offsetX ~= 0 or offsetY ~= 0 then
                local newPosition = {
                    x = position.x + offsetX,
                    y = position.y + offsetY
                }

                -- If is writtable.
                if self:_checkInsideGrid(newPosition) and self._table[newPosition.x][newPosition.y] ~= 0 then
                    -- Empty spaces should be 0.
                    if self._table[newPosition.x][newPosition.y] == nil then
                        self._table[newPosition.x][newPosition.y] = 0
                    end

                    -- Increment mine count.
                    self._table[newPosition.x][newPosition.y] = self._table[newPosition.x][newPosition.y] + 1
                end
            end
        end
    end
end

function MineSweeperTable:_generateMine()
    local result = {
        x = math.random(self._size.x - 1),
        y = math.random(self._size.y - 1)
    }

    while self._table[result.x][result.y] == 0 do
        result = {
            x = math.random(self._size.x - 1),
            y = math.random(self._size.y - 1)
        }
    end

    return result
end

function MineSweeperTable:generateTable()
    -- Generate mines.
    for mineIndex = 0, self._mineCount - 1 do
        self:_addMine(self:_generateMine())
    end
    self._generated = true
end

function MineSweeperTable:_mouseFloodFill(position)
    -- Stop on already seen positions.
    if self._table[position.x][position.y] ~= nil and (self._table[position.x][position.y] >= 10 or self._table[position.x][position.y] == 0) then
        return
    end

    -- Empty spaces are 10's.
    if self._table[position.x][position.y] == nil then
        self._table[position.x][position.y] = 0
    end

    -- Mark space as seen.
    self._table[position.x][position.y] = self._table[position.x][position.y] + 10
    
    -- Check neighbours. Don't propagate if the current position is a number.
    if self._table[position.x][position.y] == 10 then
        for offsetX = -1, 1 do
            for offsetY = -1, 1 do
                -- Don't infinite loop. Thanks.
                if offsetX ~= 0 or offsetY ~= 0 then
                    local newPosition = {
                        x = position.x + offsetX,
                        y = position.y + offsetY
                    }

                    -- If is writtable, mark as visible.
                    if self:_checkInsideGrid(newPosition) and
                        (self._table[newPosition.x][newPosition.y] == nil or
                        (self._table[newPosition.x][newPosition.y] ~= 0 and
                        self._table[newPosition.x][newPosition.y] < 10)) then
                        self:_mouseFloodFill(newPosition)
                    end
                end
            end
        end
    end
end

function MineSweeperTable:mousePressed(position, button)
    -- Check highlighting.
    self:mouseMoved(position)

    -- Generate table if not generated.
    if self._generated == false then
        self:generateTable()
    end

    -- Flood fill the area to mark visible positions. SAFE!
    if self._table[self._highlightedPosition.x][self._highlightedPosition.y] ~= 0 then
        self:_mouseFloodFill(self._highlightedPosition)
     -- A mine. DEAD!
    else
        self._lost = true
        self._highlightedPosition = {
            x = -1,
            y = -1
        }
    end
end

function MineSweeperTable:mouseMoved(position)
    -- Table is square so let's get the displayed sizes.
    local screenWidth, screenHeight = Utils.getWindowSize()
    local usedScreenSize = math.min(screenWidth, screenHeight)

    -- Update input position to local coordonates.
    position = self:positionToTable(position)

    -- Check if it is outside.
    if position.x < 0 or position.y < 0 or position.x > usedScreenSize or position.y > usedScreenSize then
        self._highlightedPosition = {
            x = -1,
            y = -1
        }
        return
    end

    -- It is inside.
    self._highlightedPosition = {
        x = math.floor(position.x / usedScreenSize * self._size.x),
        y = math.floor(position.y / usedScreenSize * self._size.y)
    } 
end

function MineSweeperTable:draw()
    -- Table is square so let's get the displayed sizes.
    local screenWidth, screenHeight, _ = love.window.getMode()
    local usedScreenSize = math.min(screenWidth, screenHeight)
    local tablePosition = {
        x = (screenWidth - usedScreenSize) / 2,
        y = (screenHeight - usedScreenSize) / 2
    }

    -- Draw background.
    Utils.setDrawColor(self._backgroundColor)
    love.graphics.rectangle(
        "fill",
        tablePosition.x, tablePosition.y,
        usedScreenSize, usedScreenSize
    )

    -- Draw foreground grid.
    Utils.setDrawColor(self._foregroundColor)
    local rectangleSize = {
        x = usedScreenSize / self._size.x,
        y = usedScreenSize / self._size.y
    }
    self._lineWidth = 1.5 * usedScreenSize / 420
    love.graphics.setLineWidth(self._lineWidth)
    for row = 0, self._size.x - 1 do
        for col = 0, self._size.y - 1 do
            -- Draw the square grids.
            local drawMode = "line"
            if (row == self._highlightedPosition.x and col == self._highlightedPosition.y) or (self._table[row][col] ~= nil and self._table[row][col] >= 10) then
                drawMode = "fill"
            end

            love.graphics.rectangle(
                drawMode,
                tablePosition.x + row * rectangleSize.x,
                tablePosition.y + col * rectangleSize.y,
                rectangleSize.x,
                rectangleSize.y
            )

            -- Draw the text inside if it is needed.
            if self._table[row][col] ~= nil and self._table[row][col] > 10 then
                Utils.setDrawColor(self._textColor)
                love.graphics.setFont(self._font)

                -- Game is designed for 420 x 420.
                local text = tostring(self._table[row][col] - 10)
                local textScale = usedScreenSize / 420

                love.graphics.print(
                    text,
                    tablePosition.x + (row + 0.5) * rectangleSize.x - self._font:getWidth(text) / 2 * textScale,
                    tablePosition.y + (col + 0.5) * rectangleSize.y - self._font:getHeight() / 2 * textScale,
                    0, textScale, textScale
                )
                
                Utils.setDrawColor(self._foregroundColor)
            end
        end
    end

    -- Border.
    Utils.setDrawColor(self._borderColor)
    love.graphics.rectangle(
        "line",
        (screenWidth - usedScreenSize) / 2,
        (screenHeight - usedScreenSize) / 2,
        usedScreenSize, usedScreenSize
    )

    love.graphics.reset()
end

return MineSweeperTable
-- Import stuff.
if Utils == nil then
    Utils = require("core.utils")
end

local MineSweeperTable = {
    _flagImage = love.graphics.newImage("assets/images/flag.png"),
    _mineImage = love.graphics.newImage("assets/images/mine.png"),
    _textColor = Utils.createColor(0xAA, 0xAA, 0xAA),
    _correctColor = Utils.createColor(0x11, 0x77, 0x11),
    _wrongColor = Utils.createColor(0x77, 0x11, 0x11),
    _backgroundColor = Utils.createColor(0x1F, 0x1F, 0x1F),
    _font = love.graphics.newFont("assets/fonts/ubuntu/Ubuntu-Regular.ttf", 24),
    _foregroundColor = Utils.createColor(0x2F, 0x2F, 0x2F),
    _borderColor = Utils.createColor(0x4F, 0x4F, 0x4F),
    _flagColor = Utils.createColor(0xAA, 0xAA, 0xAA),
    _highlightedPosition = { x = -1, y = -1 },
    _lineWidth = 1.5,
    _generated = false,
    _mineCount = 0,
    _ended = false,
    _flagTable = {},
    _table = {},
    _size = {}
}

function MineSweeperTable:reset()
    -- Random seed for the generator.
    math.randomseed(os.time())

    -- Create table.
    for row = 0, self._size.x - 1 do
        self._table[row] = {}
        self._flagTable[row] = {}
        for col = 0, self._size.y - 1 do
            self._table[row][col] = nil
            self._flagTable[row][col] = false
        end
    end

    self._generated = false
    self._ended = false
end

function MineSweeperTable:init(sizeX, sizeY, minePercentage)
    self._size.x = sizeX
    self._size.y = sizeY
    self._mineCount = math.floor(minePercentage * sizeX * sizeY)

    self:reset()
end

function MineSweeperTable:_checkInsideTable(position)
    return position.x >= 0 and position.y >= 0 and position.x < self._size.x and position.y < self._size.y
end

function MineSweeperTable:coordsToTable(position)
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
                if self:_checkInsideTable(newPosition) and self._table[newPosition.x][newPosition.y] ~= 0 then
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

    while self._table[result.x][result.y] == 0 or (result.x == self._highlightedPosition.x and result.y == self._highlightedPosition.y) do
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
    local tileValue = self:_getValue(position)

    -- Stop on already seen positions.
    if tileValue ~= nil and (tileValue >= 10 or tileValue == 0) then
        return
    end

    -- Empty spaces are 10's.
    if tileValue == nil then
        tileValue = 0
        self._table[position.x][position.y] = tileValue
    end

    -- Mark space as seen.
    self._table[position.x][position.y] = tileValue + 10
    tileValue = tileValue + 10
    
    -- Check neighbours. Don't propagate if the current position is a number.
    if tileValue ~= 10 then
        return
    end

    for offsetX = -1, 1 do
        for offsetY = -1, 1 do
            -- Don't infinite loop. Thanks.
            if offsetX ~= 0 or offsetY ~= 0 then
                local newPosition = {
                    x = position.x + offsetX,
                    y = position.y + offsetY
                }

                -- If is writtable, mark as visible.
                if self:_checkInsideTable(newPosition) and
                    (self._table[newPosition.x][newPosition.y] == nil or
                    (self._table[newPosition.x][newPosition.y] ~= 0 and
                    self._table[newPosition.x][newPosition.y] < 10)) then
                    self:_mouseFloodFill(newPosition)
                end
            end
        end
    end
end

function MineSweeperTable:_setFlag(position, value)
    self._flagTable[position.x][position.y] = value
end

function MineSweeperTable:_getFlag(position)
    return self._flagTable[position.x][position.y]
end

function MineSweeperTable:_getValue(position)
    return self._table[position.x][position.y]
end

function MineSweeperTable:_checkForGameEnd()
    local position = { x = 0, y = 0}
    for row = 0, self._size.x - 1 do
        for col = 0, self._size.y - 1 do
            position.x = row
            position.y = col
            if   self:_getValue(position) == nil or
                (self:_getValue(position) < 9 and self:_getValue(position) > 0) or
                (self:_getValue(position) == 0 and not self:_getFlag(position)) then
                return false
            end
        end
    end
    return true
end

function MineSweeperTable:mousePressed(position, button)
    if self._ended then
        return
    end

    -- Check highlighting.
    self:mouseMoved(position)

    -- Left click.
    if button == 1 then
        -- If there is a flag on the block.
        if self:_getFlag(self._highlightedPosition) == true then
            return
        end

        -- Generate table if not generated.
        if self._generated == false then
            self:generateTable()
        end

        if self:_getValue(self._highlightedPosition) ~= 0 then
            self:_mouseFloodFill(self._highlightedPosition)
        else
            self._ended = true
            self._highlightedPosition = {
                x = -1,
                y = -1
            }
            return
        end

    -- Right click.
    elseif button == 2 then
        -- Toggle flag.
        if self:_getValue(self._highlightedPosition) == nil or self:_getValue(self._highlightedPosition) < 9 then
            self:_setFlag(self._highlightedPosition, not self:_getFlag(self._highlightedPosition))
        end
    end

    self._ended = self:_checkForGameEnd()
end

function MineSweeperTable:mouseMoved(position)
    if self._ended then
        return
    end

    -- Table is square so let's get the displayed sizes.
    local screenWidth, screenHeight = Utils.getWindowSize()
    local usedScreenSize = math.min(screenWidth, screenHeight)

    -- Update input position to local coordonates.
    position = self:coordsToTable(position)
    self._highlightedPosition = {
        x = math.floor(position.x / usedScreenSize * self._size.x),
        y = math.floor(position.y / usedScreenSize * self._size.y)
    }

    -- Check if it is outside.
    if not self:_checkInsideTable(self._highlightedPosition) then
        self._highlightedPosition = {
            x = -1,
            y = -1
        }
    end
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
    local rectangleSize = {
        x = usedScreenSize / self._size.x,
        y = usedScreenSize / self._size.y
    }
    love.graphics.setLineWidth(self._lineWidth * usedScreenSize / 420)
    for row = 0, self._size.x - 1 do
        for col = 0, self._size.y - 1 do

            -- Draw the square grids.
            local drawMode = "line"
            if (row == self._highlightedPosition.x and col == self._highlightedPosition.y) or (self._table[row][col] ~= nil and self._table[row][col] >= 10) then
                drawMode = "fill"
            end

            if self._ended and self._table[row][col] == 0 then
                drawMode = "fill"

                Utils.setDrawColor(self._wrongColor)
                if self._flagTable[row][col] then
                    Utils.setDrawColor(self._correctColor)
                end
            else
                Utils.setDrawColor(self._foregroundColor)
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
                local textScale = usedScreenSize / 420 * 15 / math.min(self._size.x, self._size.y)

                love.graphics.print(
                    text,
                    tablePosition.x + (row + 0.5) * rectangleSize.x - self._font:getWidth(text) / 2 * textScale,
                    tablePosition.y + (col + 0.5) * rectangleSize.y - self._font:getHeight() / 2 * textScale,
                    0, textScale, textScale
                )

            -- Draw the mine if needed.
            elseif self._ended and self._table[row][col] == 0 then
                Utils.setDrawColor(self._flagColor)
                love.graphics.draw(
                    self._mineImage,
                    tablePosition.x + row * rectangleSize.x + rectangleSize.x * (1 - 200 / 300) / 2,
                    tablePosition.y + col * rectangleSize.y + rectangleSize.y * (1 - 200 / 300) / 2,
                    0, rectangleSize.x / 300, rectangleSize.y / 300
                )
            -- Draw the flag on top if needed.
            elseif self._flagTable[row][col] == true then
                Utils.setDrawColor(self._flagColor)
                love.graphics.draw(
                    self._flagImage,
                    tablePosition.x + row * rectangleSize.x + rectangleSize.x * (1 - 512 / 700) / 2,
                    tablePosition.y + col * rectangleSize.y + rectangleSize.y * (1 - 512 / 700) / 2,
                    0, rectangleSize.x / 700, rectangleSize.y / 700
                )
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
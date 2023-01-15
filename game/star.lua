local star = {
    x = 0,
    y = 0,
    r = 1
}

function star:draw()
    love.graphics.circle("fill", self.x, self.y, self.r)
end

return star
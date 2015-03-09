Bullet = {
    x = 0,
    y = 0,
    xvel = 0,
    yvel = 0,
}

function Bullet:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Bullet:update(dt)
    self.x = self.x + self.xvel * dt
    self.y = self.y + self.yvel * dt
end

function Bullet:collides_with_wall()
    local x = math.floor(self.x / tile_w)
    local y = math.floor(self.y / tile_h)
    return x < 0 or x > map.width or y < 0 or y > map.height or
        map.grid[x][y] == tiles.wall
end

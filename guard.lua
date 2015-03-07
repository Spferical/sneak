Guard = {
    x = 0,
    y = 0,
    target = nil,
    path = {},
    speed = 200
}

function Guard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Guard:update(dt)
    if self.path[1] ~= nil then
        target_x, target_y = self.path[1].x, self.path[1].y
        dx = target_x - self.x
        dy = target_y - self.y

        -- normalize vector
        mag = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
        dx = dx / mag * dt * self.speed
        dy = dy / mag * dt * self.speed

        if math.sqrt(math.pow(dx, 2) + math.pow(dy, 2)) < mag then
            self.x = self.x + dx
            self.y = self.y + dy
        else
            self.x = target_x
            self.y = target_y
            table.remove(self.path, 1)
        end
    else
        self:begin_wander()
    end
end

function Guard:begin_wander()
    -- get a path with map coordinates
    self_map_x = math.floor(self.x / tile_w)
    self_map_y = math.floor(self.y / tile_h)
    x = random:random(map.width - 1)
    y = random:random(map.height - 1)
    while map.grid[x][y] ~= tiles.floor do
        x = random:random(map.width - 1)
        y = random:random(map.height - 1)
    end
    self.path = get_path(self_map_x, self_map_y, x, y)

    -- convert path to world coordinates
    for i, point in ipairs(self.path) do
        point.x = point.x * tile_w
        point.y = point.y * tile_h
    end
end

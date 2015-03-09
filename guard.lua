require("bullet")
Guard = {
    x = 0,
    y = 0,
    target = nil,
    path = {},
    speed = 200,
    bullet_speed = 500,
    view_dist = 500,
    state = 'wander',
    fire_cooldown = 0.2,
    time_since_fire = 0,
}

function Guard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Guard:update(dt)
    self.time_since_fire = self.time_since_fire + dt
    if self:player_is_in_sight() then
        self.state = 'chase'
        self:chase_player()
        if self.time_since_fire > self.fire_cooldown then
            px, py = get_player_center()
            self:fire_at(px, py)
            self.time_since_fire = 0
        end
    elseif self.path[1] ~= nil then
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
        self.state = 'wander'
    end
end

function distance(x1, y1, x2, y2)
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end

function Guard:fire_at(x, y)
    local bullet = Bullet:new()
    bullet.x = self.x
    bullet.y = self.y
    local dx = x - self.x
    local dy = y - self.y
    -- jitter
    dx = dx + math.random(-20, 20)
    dy = dy + math.random(-20, 20)
    local mag = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
    bullet.xvel = dx / mag * self.bullet_speed
    bullet.yvel = dy / mag * self.bullet_speed
    table.insert(bullets, bullet)
end

function Guard:player_is_in_sight()
    -- return false if player is too far away
    px, py = get_player_center()
    if distance(self.x, self.y, px, py) > self.view_dist then
        return false
    end
    -- else, check if our sight is unbroken by walls
    sx, sy = self.x, self.y
    return line_intersects_wall(sx, sy, px, py) == px, py
end

function Guard:chase_player()
    player_map_x = math.floor(player.x / tile_w)
    player_map_y = math.floor(player.y / tile_h)
    self.path = self:get_path_to(player_map_x, player_map_y)
end

function Guard:begin_wander()
    -- get a path with map coordinates
    x = random:random(map.width - 1)
    y = random:random(map.height - 1)
    while map.grid[x][y] ~= tiles.floor do
        x = random:random(map.width - 1)
        y = random:random(map.height - 1)
    end
    self.path = self:get_path_to(x, y)
end

function Guard:get_path_to(x, y)
    self_map_x = math.floor(self.x / tile_w)
    self_map_y = math.floor(self.y / tile_h)
    path = get_path(self_map_x, self_map_y, x, y)

    -- we don't need to walk to the square we're already in
    table.remove(path, 1)

    -- convert path to world coordinates
    for i, point in ipairs(path) do
        point.x = point.x * tile_w
        point.y = point.y * tile_h
    end
    return path
end

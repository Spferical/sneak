require("bullet")
Guard = {
    x = 0,
    y = 0,
    width = 32,
    height = 32,
    target = nil,
    path = {},
    speed = 75,
    alert_speed = 200,
    bullet_speed = 1000,
    base_view_dist = 500,
    state = 'wander',
    alert = false,
    fov_range = math.pi / 3,
    direction = 0,
    target_direction = 0,
    fire_cooldown = 0.2,
    time_since_fire = 0,
    dead = false,
    look_time = 0,
}

function Guard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Guard:get_center()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Guard:get_view_dist()
    local view_dist = self.base_view_dist
    if player:has_active_ability('sneakiness') then
        view_dist = view_dist / 4
    end
    return view_dist
end

function Guard:update(dt)
    self.time_since_fire = self.time_since_fire + dt
    -- slowly-ish turn towards our target direction
    local look_speed_factor = 20
    if self.alert then
        look_speed_factor = 5
    end
    self.direction = (look_speed_factor * self.direction
        + self.target_direction) / (look_speed_factor + 1)
    if self:player_is_in_sight() then
        self.state = 'chase'
        self.alert = true
        self:chase_player()
        if self.time_since_fire > self.fire_cooldown then
            px, py = player:get_center()
            self:fire_at(px, py)
            self.time_since_fire = 0
        end
    elseif self.state == 'looking' then
        self.look_time = self.look_time - dt
        if self.look_time <= 0 then
            self.state = 'wander'
        end
        if math.abs(self.direction - self.target_direction) < math.pi / 64 then
            self.target_direction = random:random(- math.pi, math.pi)
        end
    elseif self.path[1] ~= nil then
        if random:random() < 1 / 1000 then
            -- look around
            self.state = 'looking'
            self.look_time = random:random(2, 5)
            self.target_direction = random:random(- math.pi, math.pi)
        else
            -- continue on path
            target_x = self.path[1].x + (tile_w - self.width) / 2
            target_y = self.path[1].y + (tile_h - self.height) / 2
            dx = target_x - self.x
            dy = target_y - self.y
            self.target_direction = math.atan2(dy, dx)

            -- normalize vector
            mag = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))

            if self.alert then
                speed = self.alert_speed
            else
                speed = self.speed
            end
            dx = dx / mag * dt * speed
            dy = dy / mag * dt * speed

            if math.sqrt(math.pow(dx, 2) + math.pow(dy, 2)) < mag then
                self.x = self.x + dx
                self.y = self.y + dy
            else
                self.x = target_x
                self.y = target_y
                table.remove(self.path, 1)
            end
        end
    else
        self:begin_wander()
        self.state = 'wander'
    end
end

function Guard:fire_at(x, y)
    local bullet = Bullet:new()
    bullet.x, bullet.y = self:get_center()
    local dx = x - bullet.x
    local dy = y - bullet.y
    -- jitter
    dx = dx + math.random(-10, 10)
    dy = dy + math.random(-10, 10)
    local mag = math.sqrt(math.pow(dx, 2) + math.pow(dy, 2))
    bullet.xvel = dx / mag * self.bullet_speed
    bullet.yvel = dy / mag * self.bullet_speed
    table.insert(bullets, bullet)
end

function Guard:player_is_in_sight()
    -- if player is invisible, we can't see them
    if player:has_active_ability('invisibility') then
        return false
    end
    px, py = player:get_center()
    return self:is_in_fov(px, py)
end

function Guard:is_in_fov(x, y)
    -- can't be too far away
    local sx, sy = self:get_center()
    if distance(sx, sy, x, y) > self:get_view_dist() then
        return false
    end
    -- has to be within fov angle
    local angle = math.atan2(y - sy, x - sx)
    if math.abs(angle - self.direction) > self.fov_range then
        return false
    end
    -- else, check if our sight is unbroken by walls
    return line_intersects_wall(sx, sy, x, y) == x, y
end

function Guard:chase_player()
    local x, y = player:get_center()
    player_map_x = math.floor(x / tile_w)
    player_map_y = math.floor(y / tile_h)
    self.path = self:get_path_to(player_map_x, player_map_y)
    local sx, sy = self:get_center()
    self.target_direction = math.atan2(y - sy, x - sx)
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
    local sx, sy = self:get_center()
    self_map_x = math.floor(sx / tile_w)
    self_map_y = math.floor(sy / tile_h)
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

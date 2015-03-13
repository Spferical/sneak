require("map")
require("guard")
require("target")
require("abilities")
ROT = require("rotLove/rotLove/rotLove")
Camera = require "hump.camera"
debug = true

random = love.math.newRandomGenerator()

function love.load(arg)
    title_font = love.graphics.newFont("assets/kenpixel.ttf", 70)
    main_font = love.graphics.newFont("assets/kenpixel.ttf", 20)
    gamestate = 'menu'
    real_time_since_item_get = 5
    ability_just_found = 'none'
    player_image = love.graphics.newImage("assets/player.png")
    guard_image = love.graphics.newImage("assets/guard.png")
    guard_alert_image = love.graphics.newImage("assets/guard_alert.png")
    guard_dead_image = love.graphics.newImage("assets/guard_dead.png")
    bullet_image = love.graphics.newImage("assets/bullet.png")
    target_image = love.graphics.newImage("assets/target.png")
    target_dead_image = love.graphics.newImage("assets/target_dead.png")
    item_image = love.graphics.newImage("assets/item.png")
end

function distance(x1, y1, x2, y2)
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end

Player = {
    x = 100,
    y = 100,
    height = 32,
    width = 32,
    xmove = 0,
    ymove = 0,
    speed = 200,
    abilities = {},
    abilities_by_name = {},
}

function Player:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Player:get_center()
    return self.x + self.width / 2, self.y + self.height / 2
end

function Player:check_collision()
    local x, y = self:get_center()
    x, y = pixel_to_map_coords(x, y)
    return map.grid[x][y] == tiles.wall
end

function Player:has_ability(name)
    return self.abilities_by_name[name]
end

function Player:has_active_ability(name)
    return self:has_ability(name) and self.abilities_by_name[name].active
end

function start_level(num)
    level = num
    if num == 1 then
        player = Player:new()
    end

    guards = {}
    bullets = {}
    items = {}
    generate_map(num)
    player.x = map.spawn[1] * tile_w
    player.y = map.spawn[2] * tile_h
    camera = Camera(player.x, player.y)
    camera:zoomTo(get_scale())
    spawn_guards()
    spawn_target()
    spawn_items()
    gamestate = 'playing'
end

function point_in_player(x, y)
    -- whether we are inside the player's enclosing rectangle
    return player.x < x and x < player.x + player.width and
        player.y < y and y < player.y + player.height
end

function path_callback(x, y)
    return map.grid[x][y] ~= tiles.wall
end

function get_path(from_x, from_y, to_x, to_y)
    path = {}
    astar = ROT.Path.AStar(to_x, to_y, path_callback,
        {topology=4})
    function callback(x, y)
        table.insert(path, {x = x, y = y})
    end
    astar:compute(from_x, from_y, callback)
    return path
end

function love.update(dt)
    action = handle_player_keys(dt)
    if gamestate == 'playing' then
        update_camera(dt)
        real_time_since_item_get = real_time_since_item_get + dt
        if action then
            update_items(dt)
            update_target(dt)
            update_guards(dt)
            update_bullets(dt)
            update_abilities(dt)
            if target.dead then
                local x, y = player:get_center()
                x, y = pixel_to_map_coords(x, y)
                local sx, sy = map.spawn[1], map.spawn[2]
                if x == sx and y == sy then
                    -- player wins level
                    if level < 5 then
                        gamestate = 'win'
                    else
                        gamestate = 'victory'
                    end
                end
            end
        end
    end
end

function update_guards(dt)
    -- iterate back-to-front to avoid skipping
    for i = #guards, 1, -1 do
        local guard = guards[i]
        if not guard.dead then
            local x, y = guard:get_center()
            if point_in_player(x, y) then
                guard.dead = true
            elseif not player:has_active_ability('freeze time') then
                guard:update(dt)
            end
        else
            -- guard is dead! alert any guards who see him
            for j, guard2 in ipairs(guards) do
                local x, y = guard:get_center()
                if guard2:is_in_fov(x, y) then
                    guard2.alert = true
                end
            end
        end
    end
end

function update_abilities(dt)
    for i, ability in ipairs(player.abilities) do
        if ability.active then
            ability.charge = ability.charge - dt * 100
            if ability.charge <= 0 then
                ability.charge = 0
                ability.active = false
            end
        elseif ability.charge < ability.max_charge then
            ability.charge = ability.charge + dt * 10
            if ability.charge > ability.max_charge then
                ability.charge = ability.max_charge
            end
        end
    end
end

function update_bullets(dt)
    -- iterate back-to-front to avoid skipping
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        if not player:has_active_ability('freeze time') then
            bullet:update(dt)
        end
        if not debug and point_in_player(bullet.x, bullet.y) then
            gamestate = 'gameover'
        elseif bullet:collides_with_wall() then
            table.remove(bullets, i)
        end
    end
end

function update_target(dt)
    local x, y = target:get_center()
    if point_in_player(x, y) then
        target.dead = true
    end
end

function update_items(dt)
    for i, item in ipairs(items) do
        local x, y = item.x + item.width / 2, item.y + item.height / 2
        local px, py = player:get_center()
        if distance(x, y, px, py) < (item.width + player.width) / 2 then
            -- player picks up item
            ability = Ability:new()
            ability.name = item.ability
            table.insert(player.abilities, ability)
            player.abilities_by_name[ability.name] = ability
            real_time_since_item_get = 0
            ability_just_found = ability.name
            table.remove(items, i)
            return
        end
    end
end

function spawn_guards()
    for i, pos in ipairs(map.guard_spawns) do
        guard = Guard:new()
        guard.x = pos.x
        guard.y = pos.y
        table.insert(guards, guard)
    end
end

function spawn_target()
    -- just spawn him in the upper left of the map
    x = 1
    y = 1
    while map.grid[x][y] == tiles.wall do
        x = x + 1
        if x >= map.width then
            y = y + 1
            x = 1
        end
    end
    target = Target:new()
    target.x = x * tile_w
    target.y = y * tile_h
end

function spawn_items()
    if #player.abilities == #abilities then
        -- player already has all abilities
        return
    end
    -- spawn an item on a random floor tile
    local x = math.floor(random:random(map.width - 1))
    local y = math.floor(random:random(map.height - 1))
    -- keep selecting random floor tiles until we get one away from the
    -- player
    local px, py = pixel_to_map_coords(player.x, player.y)
    while not (map.grid[x][y] == tiles.floor and distance(x, y, px, py) > 10) do
        x = math.floor(random:random(map.width - 1))
        y = math.floor(random:random(map.height - 1))
        px, py = pixel_to_map_coords(player.x, player.y)
    end

    -- spawn an item
    local item = Item:new()
    item.x = x * tile_w + (tile_w - item.width) / 2
    item.y = y * tile_h + (tile_h - item.height) / 2
    -- keep randomly picking an ability until we have one the player does not
    -- have
    item.ability = abilities[
        math.floor(random:random(#abilities))]
    while player:has_ability(item.ability) do
        item.ability = abilities[
            math.floor(random:random(#abilities))]
    end
    table.insert(items, item)
end

function update_camera(dt)
    local dx, dy = player.x - camera.x, player.y - camera.y
    camera:move(dx/20, dy/20)
end


function love.keypressed(key, code)
    if key == 'return' then
        if gamestate == 'menu' then
            start_level(1)
        elseif gamestate == 'gameover' then
            gamestate = 'menu'
        elseif gamestate == 'win' then
            start_level(level + 1)
        elseif gamestate == 'victory' then
            gamestate = 'menu'
        end
    elseif gamestate == 'playing' then
        for i, ability in ipairs(player.abilities) do
            if key == ability_keys[i] then
                ability:toggle()
            end
        end
    end
end


function handle_player_keys(dt)
    -- returns action, if any taken
    if gamestate == 'playing' then
        player.ymove = 0
        player.xmove = 0

        -- find out how the player wants to move
        if love.keyboard.isDown(".") then
            return true -- no action, but advance time
        end
        if love.keyboard.isDown("up") then
            player.ymove = player.ymove - 1
        end
        if love.keyboard.isDown("down") then
            player.ymove = player.ymove + 1
        end
        if love.keyboard.isDown("left") then
            player.xmove = player.xmove - 1
        end
        if love.keyboard.isDown("right") then
            player.xmove = player.xmove + 1
        end

        if player.xmove ~= 0 or player.ymove ~= 0 then
            -- do the movements, and undo them if the player bumpts into a wall
            old_x = player.x
            old_y = player.y
            local speed = player.speed
            if player:has_ability('quickness') then
                if player.abilities_by_name['quickness'].active then
                    speed = speed * 2
                end
            end
            player.x = player.x + player.xmove * speed * dt
            if player:check_collision() then
                player.x = old_x
            end
            player.y = player.y + player.ymove * speed * dt
            if player:check_collision() then
                player.y = old_y
            end

            return true
        else
            return false
        end
    end
end

function love.resize(w, h)
    if gamestate == 'playing' or gamestate == 'gameover' or gamestate == 'win' or gamestate == 'victory' then
        camera:zoomTo(get_scale())
    end
end

function get_scale()
    local map_height = tile_h * map.height
    return math.max(love.graphics.getHeight() / map_height,
        love.graphics.getHeight() / 768 / 4)
end

function get_camera_edges()
    -- returns (x1, y1, x2, y2)
    scale = get_scale()
    x, y = camera:pos()
    w, h = love.graphics.getDimensions()
    w = w / scale
    h = h / scale
    return x - w / 2, y - h / 2, x + w / 2, y + h / 2
end

function draw_guards()
    for i, guard in ipairs(guards) do
        local image
        if guard.dead then
            image = guard_dead_image
        elseif guard.alert then
            image = guard_alert_image
        else
            image = guard_image
        end
        love.graphics.draw(image, guard.x, guard.y)
    end
end

function draw_bullets()
    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet_image, bullet.x, bullet.y)
    end
end

function draw_items()
    for i, item in ipairs(items) do
        love.graphics.draw(item_image, item.x, item.y)
    end
end

function draw_target()
    if target.dead then
        love.graphics.draw(target_dead_image, target.x, target.y)
    else
        love.graphics.draw(target_image, target.x, target.y)
    end
end

function draw_player()
    if player:has_active_ability('invisibility') then
        love.graphics.setColor(100, 100, 255, 100)
    end
    love.graphics.draw(player_image, player.x , player.y)
    love.graphics.setColor(255, 255, 255, 255)
end

function love.draw()
    if gamestate == 'menu' then
        love.graphics.setFont(title_font)
        love.graphics.printf("Sneak", 25, 25, love.graphics.getWidth() - 50, "center")
        love.graphics.setFont(main_font)
        love.graphics.printf("Press enter to start", 25, love.graphics.getHeight() - 50, love.graphics.getWidth() - 50, "center")
    elseif gamestate == 'playing' or gamestate == 'gameover' or gamestate == 'win' or gamestate == 'victory' then
        camera:attach()
        draw_map(camera)
        for i, guard in ipairs(guards) do
            if not guard.dead then
                if guard:player_is_in_sight() then
                    love.graphics.setColor(255, 0, 0, 100)
                else
                    love.graphics.setColor(255, 255, 0, 100)
                end
                local gx, gy  = guard:get_center()
                local angle1 = guard.direction - guard.fov_range
                local angle2 = guard.direction + guard.fov_range
                for j, t in ipairs(get_fov(gx, gy, angle1, angle2, guard.view_dist)) do
                    love.graphics.polygon('fill', t)
                end
            end
        end
        love.graphics.setColor(255, 255, 255, 255)
        draw_player()
        draw_guards()
        draw_target()
        draw_bullets()
        draw_items()
        camera:detach()
        if real_time_since_item_get < 5 then
            love.graphics.setFont(main_font)
            love.graphics.setColor(0, 255, 0, 255)
            love.graphics.printf("You found an item!\n\nNew ability: "
                 .. ability_just_found,
                 50, 50, love.graphics.getWidth() - 50, "center")
            love.graphics.setColor(255, 255, 255, 255)
        end
        for i, ability in ipairs(player.abilities) do
            love.graphics.setFont(main_font)
            local x = love.graphics.getWidth() - 200
            local y = love.graphics.getHeight() - 300 + 50 * i
            if ability.active then
                love.graphics.setColor(255, 0, 0, 255)
            else
                love.graphics.setColor(255, 255, 255, 255)
            end
            love.graphics.print("["..ability_keys[i].."] "..ability.name, x, y)
            local charge = ability.charge
            love.graphics.setColor(255, 0, 0, 200)
            love.graphics.rectangle('fill', x, y + 30, charge, 10)
            love.graphics.setColor(255, 255, 255, 200)
            love.graphics.rectangle('fill', x + charge, y + 30, 100 - charge, 10)
            love.graphics.setColor(255, 255, 255, 255)
        end
        if debug then
            love.graphics.setFont(main_font)
            love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
        end
        if gamestate == 'gameover' then
            love.graphics.setColor(255, 0, 0, 255)
            love.graphics.printf("YOU DIED!\n Press enter to return to the main menu.",
                50, 50, love.graphics.getWidth() - 50, "center")
        elseif gamestate == 'win' then
            love.graphics.setColor(0, 255, 0, 255)
            love.graphics.printf("YOU WIN!\n Press enter to continue to the next level.",
                50, 50, love.graphics.getWidth() - 50, "center")
        elseif gamestate == 'victory' then
            love.graphics.setColor(255, 255, 255, 255)
            love.graphics.printf("YOU WIN THE GAME!\n\nCongratulations!\n\nPress enter to return to the main menu.",
                50, 50, love.graphics.getWidth() - 50, "center")
        end
    end
end

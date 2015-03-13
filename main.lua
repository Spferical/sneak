require("map")
require("guard")
require("target")
require("abilities")
ROT = require("rotLove/rotLove/rotLove")
Camera = require "hump.camera"
debug = true

random = love.math.newRandomGenerator()

function get_player_center()
    return player.x + player.width / 2, player.y + player.height / 2
end

function love.load(arg)
    title_font = love.graphics.newFont("assets/kenpixel.ttf", 70)
    main_font = love.graphics.newFont("assets/kenpixel.ttf", 20)
    gamestate = 'menu'
    real_time_since_item_get = 5
    ability_just_found = 'none'
    player_image = love.graphics.newImage("assets/player.png")
    guard_image = love.graphics.newImage("assets/guard.png")
    guard_alert_image = love.graphics.newImage("assets/guard_alert.png")
    bullet_image = love.graphics.newImage("assets/bullet.png")
    target_image = love.graphics.newImage("assets/target.png")
    target_dead_image = love.graphics.newImage("assets/target_dead.png")
    item_image = love.graphics.newImage("assets/item.png")
end

function distance(x1, y1, x2, y2)
    return math.sqrt(math.pow(x2 - x1, 2) + math.pow(y2 - y1, 2))
end

function start_level(num)
    level = num
    if num == 1 then
        player = {
            x = 100,
            y = 100,
            image = nil,
            height = 32,
            width = 32,
            xmove = 0,
            ymove = 0,
            speed = 200,
            abilities = {},
        }
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
    return map.grid[x][y] == tiles.floor
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
            if target.dead then
                local x, y = get_player_center()
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
        local x, y = guard:get_center()
        if point_in_player(x, y) then
            table.remove(guards, i)
        else
            guard:update(dt)
        end
    end
end

function update_bullets(dt)
    -- iterate back-to-front to avoid skipping
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update(dt)
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
        local px, py = get_player_center()
        if distance(x, y, px, py) < (item.width + player.width) / 2 then
            -- player picks up item
            player.abilities[item.ability] = true
            real_time_since_item_get = 0
            ability_just_found = item.ability
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
    local possible_abilities = {}
    for i, ability in ipairs(abilities) do
        if not player.abilities[ability] then
            table.insert(possible_abilities, ability)
        end
    end
    if #possible_abilities == 0 then
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
    item.ability = possible_abilities[
        math.floor(random:random(#possible_abilities))]
    while player.abilities[item.ability] do
        item.ability = possible_abilities[
            math.floor(random:random(#possible_abilities))]
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
            player.x = player.x + player.xmove * player.speed * dt
            if check_player_collision() then
                player.x = old_x
            end
            player.y = player.y + player.ymove * player.speed * dt
            if check_player_collision() then
                player.y = old_y
            end

            return true
        else
            return false
        end
    end
end

function check_player_collision()
    local x, y = get_player_center()
    x, y = pixel_to_map_coords(x, y)
    return map.grid[x][y] == tiles.wall
end

function love.resize(w, h)
    if gamestate == 'playing' or gamestate == 'gameover' or gamestate == 'win' or gamestate == 'victory' then
        camera:zoomTo(get_scale())
    end
end

function get_scale()
    local map_height = tile_h * map.height
    return math.max(love.graphics.getHeight() / map_height,
        love.graphics.getHeight() / 480 / 4)
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
        if guard.alert then
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
            if guard:player_is_in_sight() then
                love.graphics.setColor(255, 0, 0, 100)
            else
                love.graphics.setColor(255, 255, 0, 100)
            end
            local gx, gy  = guard:get_center()
            for j, t in ipairs(get_fov(gx, gy, guard.view_dist)) do
                love.graphics.polygon('fill', t)
            end
        end
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(player_image, player.x , player.y)
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

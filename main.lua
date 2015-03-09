require("map")
require("guard")
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
    player_image = love.graphics.newImage("assets/player.png")
    guard_image = love.graphics.newImage("assets/guard.png")
    bullet_image = love.graphics.newImage("assets/bullet.png")
end

function start_level()
    player = {
        x = 100,
        y = 100,
        image = nil,
        height = 32,
        width = 32,
        xmove = 0,
        ymove = 0,
        speed = 400,
    }

    guards = {}
    bullets = {}
    generate_map()
    player.x = map.width * tile_w / 2
    player.y = (map.height - 2) * tile_h
    while point_is_in_wall(player.x, player.y) do
        player.y = player.y - tile_h
    end
    camera = Camera(player.x, player.y)
    camera:zoomTo(get_scale())
    spawn_guards()
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
    astar = ROT.Path.AStar(to_x, to_y, path_callback)
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
        if action then
            update_guards(dt)
            update_bullets(dt)
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
        if point_in_player(bullet.x, bullet.y) then
            gamestate = 'gameover'
        elseif bullet:collides_with_wall() then
            table.remove(bullets, i)
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

function update_camera(dt)
    local dx, dy = player.x - camera.x, player.y - camera.y
    camera:move(dx/20, dy/20)
end


function love.keypressed(key, code)
    if gamestate == 'menu' then
        if key == 'return' then
            start_level()
            gamestate = 'playing'
        end
    elseif gamestate == 'gameover' then
        if key == 'return' then
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
    x1 = math.floor(player.x / tile_w)
    y1 = math.floor(player.y / tile_h)
    x2 = math.floor((player.x + player.width) / tile_w)
    y2 = math.floor((player.y + player.height) / tile_h)
    return map.grid[x1][y1] == tiles.wall or map.grid[x2][y2] == tiles.wall or
        map.grid[x2][y1] == tiles.wall or map.grid[x1][y2] == tiles.wall
end

function love.resize(w, h)
    if gamestate == 'playing' or gamestate == 'gameover' then
        camera:zoomTo(get_scale())
    end
end

function get_scale()
    return love.graphics.getHeight() / 480 / 4
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
        love.graphics.draw(guard_image, guard.x, guard.y)
    end
end

function draw_bullets()
    for i, bullet in ipairs(bullets) do
        love.graphics.draw(bullet_image, bullet.x, bullet.y)
    end
end

function love.draw()
    if gamestate == 'menu' then
        love.graphics.setFont(title_font)
        love.graphics.printf("Sneak", 25, 25, love.graphics.getWidth() - 50, "center")
        love.graphics.setFont(main_font)
        love.graphics.printf("Press enter to start", 25, love.graphics.getHeight() - 50, love.graphics.getWidth() - 50, "center")
    elseif gamestate == 'playing' or gamestate == 'gameover' then
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
        draw_bullets()
        camera:detach()
        if debug then
            love.graphics.setFont(main_font)
            love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
        end
        if gamestate == 'gameover' then
            love.graphics.printf("YOU DIED!\n Press enter to return to the main menu.",
                50, 50, love.graphics.getWidth() - 50, "center")
        end
    end
end

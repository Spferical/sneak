require("map")
require("guard")
ROT = require("rotLove/rotLove/rotLove")
Camera = require "hump.camera"
debug = true

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

random = love.math.newRandomGenerator()


function love.load(arg)
    player.image = love.graphics.newImage("assets/player.png")
    guard_image = love.graphics.newImage("assets/guard.png")
    generate_map()
    player.x = map.width * tile_w / 2
    player.y = (map.height - 2) * tile_h
    camera = Camera(player.x, player.y)
    camera:zoomTo(1/4)
    spawn_guards()
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
    if handle_player_keys(dt) then
        update_guards(dt)
    end
    update_camera(dt)
end

function update_guards(dt)
    for i, guard in ipairs(guards) do
        guard:update(dt)
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


function handle_player_keys(dt)
    -- returns whether or not the player moved

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
        -- do the movements, and undo them if the player collides with something
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

function check_player_collision()
    x1 = math.floor(player.x / tile_w)
    y1 = math.floor(player.y / tile_h)
    x2 = math.floor((player.x + player.width) / tile_w)
    y2 = math.floor((player.y + player.height) / tile_h)
    return map.grid[x1][y1] == tiles.wall or map.grid[x2][y2] == tiles.wall or
        map.grid[x2][y1] == tiles.wall or map.grid[x1][y2] == tiles.wall
end

function love.resize(w, h)
    camera:zoomTo(get_scale())
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

function love.draw()
    camera:attach()
    draw_map(camera)
    for i, guard in ipairs(guards) do
        if guard:player_is_in_sight() then
            love.graphics.setColor(255, 0, 0, 100)
        else
            love.graphics.setColor(255, 255, 0, 100)
        end
        for j, t in ipairs(get_fov(guard.x, guard.y, guard.view_dist)) do
            love.graphics.polygon('fill', t)
        end
    end
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(player.image, player.x , player.y)
    draw_guards()
    camera:detach()
    if debug then
        love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
    end
end

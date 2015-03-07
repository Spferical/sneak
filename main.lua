require("map")
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
    speed = 100,
}

random = love.math.newRandomGenerator()


function love.load(arg)
    player.image = love.graphics.newImage("assets/player.png")
    generate_map()
    player.x = map.width * tile_w / 2
    player.y = (map.height - 2) * tile_h
    camera = Camera(player.x, player.y)
end

function love.update(dt)
    handle_player_keys(dt)
end

function handle_player_keys(dt)
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

    -- update camera
    local dx, dy = player.x - camera.x, player.y - camera.y
    camera:move(dx/20, dy/20)
end

function check_player_collision()
    x1 = math.floor(player.x / tile_w)
    y1 = math.floor(player.y / tile_h)
    x2 = math.floor((player.x + player.width) / tile_w)
    y2 = math.floor((player.y + player.height) / tile_h)
    return map.grid[x1][y1] == tiles.wall or map.grid[x2][y2] == tiles.wall
end

function love.resize(w, h)
    camera:zoomTo(h / 1080)
end

function love.draw()
    camera:attach()
    draw_map(camera)
    love.graphics.draw(player.image, player.x , player.y)
    camera:detach()
end

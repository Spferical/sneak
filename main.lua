require("map")
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

    -- update map offset
    map.offset.x = player.x - love.window.getWidth() / 2
    map.offset.x = math.max(map.offset.x, 0)
    map.offset.x = math.min(map.offset.x, map.height * tile_h - love.window.getWidth())
    map.offset.y = player.y - love.window.getHeight() / 2
    map.offset.y = math.max(map.offset.y, 0)
    map.offset.y = math.min(map.offset.y, map.width * tile_w - love.window.getHeight())
end

function check_player_collision()
    x1 = math.floor(player.x / tile_w)
    y1 = math.floor(player.y / tile_h)
    x2 = math.floor((player.x + player.width) / tile_w)
    y2 = math.floor((player.y + player.height) / tile_h)
    return map.grid[x1][y1] == tiles.wall or map.grid[x2][y2] == tiles.wall
end

function love.draw()
    draw_map()
    love.graphics.draw(player.image,
        player.x - map.offset.x, player.y - map.offset.y)
end

require("map")
debug = true

player = {
    x = 20,
    y = 20,
}

player_image = nil
player_height = 32
player_width = 32
random = love.math.newRandomGenerator()


function love.load(arg)
    player_image = love.graphics.newImage("assets/player.png")
end

function love.update(dt)
end

function love.keypressed(key, unicode)
    xmove = 0
    ymove = 0
    if key == 'up' then
        ymove = ymove - 1
    end
    if key == 'down' then
        ymove = ymove + 1
    end
    if key == 'left' then
        xmove = xmove - 1
    end
    if key == 'right' then
        xmove = xmove + 1
    end
    player.x = player.x + xmove
    if check_player_collision() then
        player.x = player.x - xmove
    end
    player.y = player.y + ymove
    if check_player_collision() then
        player.y = player.y - ymove
    end
end

function check_player_collision()
    x1 = math.floor(player.x / tile_w)
    y1 = math.floor(player.y / tile_h)
    x2 = math.floor((player.x + player_width) / tile_w)
    y2 = math.floor((player.y + player_height) / tile_h)
    return map_grid[x1][y1] == tiles.wall or map_grid[x2][y2] == tiles.wall
end

function love.draw()
    draw_map()
    love.graphics.draw(player_image, player.x, player.y)
end

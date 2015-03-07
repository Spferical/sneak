require("map")
debug = true

player = {
    pos = {
        x = 0,
        y = 0,
    },
}

tiles = {
    floor = 0,
    wall = 1,
}

player_image = nil
random = love.math.newRandomGenerator()


function love.load(arg)
    player_image = love.graphics.newImage("assets/player.png")
end

function love.update(dt)
end

function love.draw()
    draw_map()
    love.graphics.draw(player_image, player.pos.x, player.pos.y)
end

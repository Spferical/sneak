tiles = {
    floor = 1,
    wall = 2,
}

tile_images = {
    love.graphics.newImage("assets/floor.png"),
    love.graphics.newImage("assets/wall.png")
}

map = {
    offset = {x = 0, y = 0},
    width = 100,
    height = 100,
    grid = nil,
}

map_offset = {x = 0, y = 0}

tile_w = 48
tile_h = 48


function generate_map()
    map.grid = {}
    -- fill the map with floor tiles
    for i = 0, map.width-1 do
        map.grid[i] = {}
        for j = 0, map.height-1 do
            map.grid[i][j] = 1
        end
    end
end

function draw_map()
    map_display_w = love.window.getWidth() / tile_w
    map_display_h = love.window.getHeight() / tile_h
    for x=0, map_display_w do
        for y=0, map_display_h do
            love.graphics.draw(
                tile_images[map.grid[x][y]],
                x * tile_w + map.offset.x,
                y * tile_h + map.offset.y)
        end
    end
end


generate_map()

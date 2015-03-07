tiles = {
    floor = 0,
    wall = 1,
}

tile_images = {
    love.graphics.newImage("assets/floor.png"),
    love.graphics.newImage("assets/wall.png")
}

map_offset = {x = 0, y = 0}

map_width = 100
map_height = 100
tile_w = 48
tile_h = 48
map_grid = nil


function generate_map()
    map_grid = {}
    -- fill the map with floor tiles
    for i = 1, map_width do
        map_grid[i] = {}
        for j = 1, map_height do
            map_grid[i][j] = 1
        end
    end
end

function draw_map()
    map_display_w = love.window.getWidth() / tile_w + 1
    map_display_h = love.window.getHeight() / tile_h + 1
    for x=1, map_display_w do
        for y=1, map_display_h do
            love.graphics.draw(
                tile_images[map_grid[x][y]],
                (x-1) * tile_w + map_offset.x,
                (y-1) * tile_h + map_offset.y)
        end
    end
end


generate_map()

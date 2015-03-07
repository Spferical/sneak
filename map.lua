ROT=require 'rotLove/rotLove/rotLove'


tiles = {
    floor = 1,
    wall = 2,
}

tile_images = {
    love.graphics.newImage("assets/floor.png"),
    love.graphics.newImage("assets/wall.png")
}

map = {
    width = 50,
    height = 50,
    grid = nil,
}

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
    brogue = ROT.Map.Brogue(map.width, map.height)
    function callback(x, y, val)
        if val == 2 or val == 0 then
            map.grid[x-1][y-1] = tiles.floor
        else
            map.grid[x-1][y-1] = tiles.wall
        end
    end
    brogue:create(callback, true)
end

function draw_map(camera)
    map_display_w = math.ceil(love.graphics.getWidth() / tile_w)
    map_display_h = math.ceil(love.graphics.getHeight() / tile_h)
    for x = 0, map.width-1 do
        for y = 0, map.height-1 do
            love.graphics.draw(
                tile_images[map.grid[x][y]],
                x * tile_w,
                y * tile_h)
        end
    end
end

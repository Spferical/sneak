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
    offset = {x = 0, y = 0},
    width = 30,
    height = 30,
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
            if (i == 0 or j == 0 or i == map.width-1 or j == map.height-1) then
                -- wall tiles on outer edge
                map.grid[i][j] = 2
            else
                map.grid[i][j] = 1
            end
        end
    end
    brogue = ROT.Map.Brogue(map.width, map.height)
    function callback(x, y, val)
        print(x, y, val)
        if val == 2 or val == 0 then
            map.grid[x-1][y-1] = tiles.floor
        else
            map.grid[x-1][y-1] = tiles.wall
        end
    end
    brogue:create(callback, true)
end

function draw_map()
    map_display_w = math.ceil(love.window.getWidth() / tile_w)
    map_display_h = math.ceil(love.window.getHeight() / tile_h)
    startx = math.floor(map.offset.x / tile_w)
    starty = math.floor(map.offset.y / tile_h)
    map_display_w = math.min(map_display_w, map.width - startx - 1)
    map_display_h = math.min(map_display_h, map.height - starty - 1)
    for x = startx, startx + map_display_w do
        for y = starty, starty + map_display_h do
            love.graphics.draw(
                tile_images[map.grid[x][y]],
                x * tile_w - map.offset.x,
                y * tile_h - map.offset.y)
        end
    end
end

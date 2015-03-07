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
    x1, y1, x2, y2 = get_camera_edges()
    map_display_w = math.ceil((x2 - x1) / tile_w)
    map_display_h = math.ceil((y2 - y1) / tile_h)
    startx = math.floor(x1 / tile_w)
    starty = math.floor(y1 / tile_h)
    startx = math.max(0, startx)
    starty = math.max(0, starty)
    map_display_w = math.min(map_display_w, map.width - startx - 1)
    map_display_h = math.min(map_display_h, map.height - starty - 1)
    for x = startx, startx + map_display_w do
        for y = starty, starty + map_display_h do
            love.graphics.draw(
                tile_images[map.grid[x][y]],
                x * tile_w,
                y * tile_h)
        end
    end
end

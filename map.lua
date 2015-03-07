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
    num_guards = 10,
    guard_spawns = {},
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

    spawn_section_height = map.height / map.num_guards
    for g = 1, map.num_guards do
        y = spawn_section_height * g
        x = random:random(map.width - 1)
        while map.grid[x][y] ~= tiles.floor do
            y = y + 1
            for i = 1, 10 do
                x = random:random(map.width - 1)
                if map.grid[x][y] == tiles.floor then
                    break
                end
            end
            if y >= map.height then
                y = 1
            end
        end
        table.insert(map.guard_spawns, {x = x * tile_w, y = y * tile_h})
    end
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

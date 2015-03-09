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


function line_intersects_wall(x1, y1, x2, y2)
    -- returns the wall intersection closest to (x1, y1) if one exists on the
    -- line. else, returns {x2, y2}
    points = grid_line_intersection(x1 / tile_w, y1 / tile_h,
        x2 / tile_w, y2 / tile_h)
    for i, p in ipairs(points) do
        map_x = math.floor(p.x)
        map_y = math.floor(p.y)
        if map.grid[map_x][map_y] == tiles.wall then
            -- return intersection point
            return (map_x + .5) * tile_w, (map_y + .5) * tile_h
        end
    end
    return x2, y2
end

function grid_line_intersection(x1, y1, x2, y2)
    -- returns the map points that are intersected by a given line
    -- via https://github.com/Yonaba/Algorithm-Implementations/blob/master/Bresenham_Based_Supercover_Line/Lua/Yonaba/bresenham_based_supercover.lua
    local points = {}
    local xstep, ystep, err, errprev, ddx, ddy
    local x, y = x1, y1
    local dx, dy = x2 - x1, y2 - y1
    points[#points + 1] = {x = x1, y = y1}
    if dy < 0 then
        ystep = - 1
        dy = -dy
    else
        ystep = 1
    end
    if dx < 0 then
        xstep = - 1
        dx = -dx
    else
        xstep = 1
    end
    ddx, ddy = dx * 2, dy * 2
    if ddx >= ddy then
        errprev, err = dx, dx
        for i = 1, dx do
            x = x + xstep
            err = err + ddy
            if err > ddx then
                y = y + ystep
                err = err - ddx
                if err + errprev < ddx then
                    points[#points + 1] = {x = x, y = y - ystep}
                elseif err + errprev > ddx then
                    points[#points + 1] = {x = x - xstep, y = y}
                else
                    points[#points + 1] = {x = x, y = y - ystep}
                    points[#points + 1] = {x = x - xstep, y = y}
                end
            end
            points[#points + 1] = {x = x, y = y}
            errprev = err
        end
    else
        errprev, err = dy, dy
        for i = 1, dy do
            y = y + ystep
            err = err + ddx
            if err > ddy then
                x = x + xstep
                err = err - ddy
                if err + errprev < ddy then
                    points[#points + 1] = {x = x - xstep, y = y}
                elseif err + errprev > ddy then
                    points[#points + 1] = {x = x, y = y - ystep}
                else
                    points[#points + 1] = {x = x, y = y - ystep}
                    points[#points + 1] = {x = x - xstep, y = y}
                end
            end
            points[#points + 1] = {x = x, y = y}
            errprev = err
        end
    end
    return points
end

function pixel_to_map_coords(x, y)
    return math.floor(x / tile_w), math.floor(y / tile_h)
end

function point_is_in_wall(x, y)
    local x = math.floor(x / tile_w)
    local y = math.floor(y / tile_h)
    return map.grid[x][y] == tiles.wall
end

function get_fov(x, y, dist)
    -- algorithm described at http://www.redblobgames.com/articles/visibility/
    triangles = {}
    step = math.pi / 50
    for i = 0, 2 * math.pi - step, step do
        x1 = x + math.cos(i) * dist
        y1 = y + math.sin(i) * dist
        x2 = x + math.cos(i + step) * dist
        y2 = y + math.sin(i + step) * dist
        x1, y1 = line_intersects_wall(x, y, x1, y1)
        x2, y2 = line_intersects_wall(x, y, x2, y2)
        table.insert(triangles, {x, y, x1, y1, x2, y2})
    end
    return triangles
end


function generate_map()
    map.grid = {}
    -- fill the map with floor tiles
    for i = 0, map.width-1 do
        map.grid[i] = {}
        for j = 0, map.height-1 do
            map.grid[i][j] = 1
        end
    end
    mapgen = ROT.Map.Digger(map.width, map.height,
        {dugPercentage = 0.75})
    function callback(x, y, val)
        if val == 2 or val == 0 then
            map.grid[x-1][y-1] = tiles.floor
        else
            map.grid[x-1][y-1] = tiles.wall
        end
    end
    mapgen:create(callback)

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

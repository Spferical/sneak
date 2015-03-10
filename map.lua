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
    width = 40,
    height = 40,
    grid = nil,
    num_guards = 5,
    guard_spawns = {},
}

tile_w = 48
tile_h = 48


function line_intersects_wall(x1, y1, x2, y2)
    -- returns the wall intersection closest to (x1, y1) if one exists on the
    -- line. else, returns {x2, y2}
    local points = grid_line_intersection(x1 / tile_w, y1 / tile_h,
        x2 / tile_w, y2 / tile_h)
    for i, p in ipairs(points) do
        local map_x = math.floor(p.x)
        local map_y = math.floor(p.y)
        if map_x >= 0 and map_x < map.width and map_y >= 0 and map_y < map.height and map.grid[map_x][map_y] == tiles.wall then
            -- return intersection point
            local mx = map_x * tile_w
            local my = map_y * tile_h
            local left = mx - 1
            local right = mx + tile_w + 1
            local top = my - 1
            local bottom = my + tile_h + 1
            if x1 <= mx then
                local x, y = findIntersect(x1, y1, x2, y2, mx, my, mx, my + tile_h, true, true)
                if x ~= false then
                    return x, y
                end
            elseif x1 >= mx then
                local x, y = findIntersect(x1, y1, x2, y2, mx + tile_w, my, mx + tile_w, my + tile_h, true, true)
                if x ~= false then
                    return x, y
                end
            end
            if y1 <= my then
                local x, y = findIntersect(x1, y1, x2, y2, mx, my, mx + tile_w, my, true, true)
                if x ~= false then
                    return x, y
                end
            elseif y1 >= my then
                local x, y = findIntersect(x1, y1, x2, y2, mx, my + tile_h, mx + tile_w, my + tile_h, true, true)
                if x ~= false then
                    return x, y
                end
            end
            print('ugh', x1, y1, x2, y2, map_x, map_y, x, y)
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

-- via https://love2d.org/wiki/General_math
-- Checks if two lines intersect (or line segments if seg is true)
-- Lines are given as four numbers (two coordinates)
function findIntersect(l1p1x,l1p1y, l1p2x,l1p2y, l2p1x,l2p1y, l2p2x,l2p2y, seg1, seg2)
    local a1,b1,a2,b2 = l1p2y-l1p1y, l1p1x-l1p2x, l2p2y-l2p1y, l2p1x-l2p2x
    local c1,c2 = a1*l1p1x+b1*l1p1y, a2*l2p1x+b2*l2p1y
    local det,x,y = a1*b2 - a2*b1
    if det==0 then return false, "The lines are parallel." end
    x,y = (b2*c1-b1*c2)/det, (a1*c2-a2*c1)/det
    if seg1 or seg2 then
        local min,max = math.min, math.max
        if seg1 and not (min(l1p1x,l1p2x) <= x and x <= max(l1p1x,l1p2x) and min(l1p1y,l1p2y) <= y and y <= max(l1p1y,l1p2y)) or
           seg2 and not (min(l2p1x,l2p2x) <= x and x <= max(l2p1x,l2p2x) and min(l2p1y,l2p2y) <= y and y <= max(l2p1y,l2p2y)) then
            return false, "The lines don't intersect."
        end
    end
    return x,y
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
    -- ideal algorithm described at http://www.redblobgames.com/articles/visibility/
    local triangles = {}
    local step = math.pi / 32
    local i = 0
    local last_x, last_y = line_intersects_wall(x, y, dist, 0)
    for i = 0, 2 * math.pi - step, step do
        local x1 = x + math.cos(i) * dist
        local y1 = y + math.sin(i) * dist
        x1, y1 = line_intersects_wall(x, y, x1, y1)
        table.insert(triangles, {x, y, last_x, last_y, x1, y1})
        last_x = x1
        last_y = y1
    end
    return triangles
end


function generate_map()
    map.grid = {}
    map.guard_spawns = {}
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

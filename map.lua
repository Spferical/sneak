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
            local left = mx
            local right = mx + tile_w
            local top = my
            local bottom = my + tile_h
            local px, py = p.x * tile_w, p.y * tile_h
            if x1 <= px then
                local x, y = findIntersect(x1, y1, px, py, left, top, left, bottom, true, true)
                if x ~= 0 then
                    return x, y
                end
            else
                local x, y = findIntersect(x1, y1, px, py, right, top, right, bottom, true, true)
                if x ~= 0 then
                    return x, y
                end
            end
            if y1 <= py then
                local x, y = findIntersect(x1, y1, px, py, left, top, right, top, true, true)
                if x ~= 0 then
                    return x, y
                end
            else
                local x, y = findIntersect(x1, y1, px, py, left, bottom, right, bottom, true, true)
                if x ~= 0 then
                    return x, y
                end
            end
            return x1, y1
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

-- from https://love2d.org/wiki/General_math
-- Returns 1 if number is positive, -1 if it's negative, or 0 if it's 0.
function sign(n) return n>0 and 1 or n<0 and -1 or 0 end

-- from https://love2d.org/wiki/General_math
function checkIntersect(l1p1, l1p2, l2p1, l2p2)
    local function checkDir(pt1, pt2, pt3) return sign(((pt2.x-pt1.x)*(pt3.y-pt1.y)) - ((pt3.x-pt1.x)*(pt2.y-pt1.y))) end
    return (checkDir(l1p1,l1p2,l2p1) ~= checkDir(l1p1,l1p2,l2p2)) and (checkDir(l2p1,l2p2,l1p1) ~= checkDir(l2p1,l2p2,l1p2))
end

-- from https://love2d.org/wiki/PointWithinShape
function findIntersect(g1,h1,g2,h2,i1,j1,i2,j2 )
    local xk = 0
    local yk = 0

    if checkIntersect({x=g1, y=h1}, {x=g2, y=h2}, {x=i1, y=j1}, {x=i2, y=j2}) then
        local a = h2-h1
        local b = (g2-g1)
        local v = ((h2-h1)*g1) - ((g2-g1)*h1)

        local d = i2-i1
        local c = (j2-j1)
        local w = ((j2-j1)*i1) - ((i2-i1)*j1)

        xk = (1/((a*d)-(b*c))) * ((d*v)-(b*w))
        yk = (-1/((a*d)-(b*c))) * ((a*w)-(c*v))
    else
        xk,yk = 0,0
    end
    return xk, yk
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
    local last_x, last_y = line_intersects_wall(x, y, x - dist, y)
    local mx, my = pixel_to_map_coords(x, y)
    local map_dist = math.floor(dist / tile_w)
    local endpoints = {}
    for fmx = math.max(1, mx - map_dist), math.min(map.width - 1, mx + map_dist) do
        for fmy = math.max(1, my - map_dist), math.min(map.height - 1, my + map_dist) do
            next_to_wall =  map.grid[fmx][fmy] == tiles.wall or map.grid[fmx-1][fmy-1] == tiles.wall or map.grid[fmx][fmy-1] == tiles.wall or map.grid[fmx-1][fmy] == tiles.wall
            local fx = fmx * tile_w
            local fy = fmy * tile_h
            local angle = math.atan2(fy - y, fx - x)
            table.insert(endpoints, {angle, fx, fy, next_to_wall})
        end
    end
    local sort_func = function(a, b)
        return a[1] < b[1]
    end
    table.sort(endpoints, sort_func)

    for i, ep in ipairs(endpoints) do
        local angle, ex, ey, next_to_wall = ep[1], ep[2], ep[3], ep[4]
        if next_to_wall then
            local eix, eiy = line_intersects_wall(x, y, ex, ey)
            if almostequal(eix, ex, 1) and almostequal(eiy, ey, 1) then
                table.insert(triangles, {x, y, last_x, last_y, ex, ey})
                last_x = ex
                last_y = ey
            end
        else
            local ox1 = x + math.cos(angle) * dist
            local oy1 = y + math.sin(angle) * dist
            local x1, y1 = line_intersects_wall(x, y, ox1, oy1)
            if x1 == ox1 and y1 == oy1 then
                table.insert(triangles, {x, y, last_x, last_y, x1, y1})
                last_x = x1
                last_y = y1
            end
        end
    end
    local x1, y1 = line_intersects_wall(x, y, x - dist, y)
    table.insert(triangles, {x, y, last_x, last_y, x1, y1})
    return triangles
end


function almostequal(a, b, err)
    err = err or 0.01
    return math.abs(a - b) < err
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

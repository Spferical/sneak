ROT=require 'rotLove/rotLove/rotLove'


tiles = {
    floor = 1,
    wall = 2,
    escape = 3,
}

tile_images = {
    love.graphics.newImage("assets/floor.png"),
    love.graphics.newImage("assets/wall.png"),
    love.graphics.newImage("assets/escape.png"),
}

Map = {
    width = 20,
    height = 20,
    grid = nil,
    num_guards = 3,
    guard_spawns = {},
    spawn = nil,
}

function Map:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


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

function get_fov(x, y, angle1, angle2, dist)
    -- ideal algorithm described at http://www.redblobgames.com/articles/visibility/
    local triangles = {}
    local step = (angle2 - angle1) / 64
    local i = 0
    local last_x, last_y = x, y
    for i = angle1, angle2, step do
        local x1 = x + math.cos(i) * dist
        local y1 = y + math.sin(i) * dist
        x1, y1 = line_intersects_wall(x, y, x1, y1)
        table.insert(triangles, {x, y, last_x, last_y, x1, y1})
        last_x = x1
        last_y = y1
    end
    return triangles
end


function generate_map(level)
    map = Map:new()
    map.width = map.width + 1 * (level - 1)
    map.height = map.height + 10 * (level - 1)
    map.num_guards = map.num_guards * math.pow(2, level - 1)
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
        {dugPercentage = 0.90,
        roomWidth = {1, 5},
        roomHeight = {1, 5},
        timeLimit = 50000})
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

    -- find a spawn for the player
    local x = math.floor(map.width / 2)
    local y = map.height - 2
    while map.grid[x][y] == tiles.wall do
        y = y - 1
    end
    map.grid[x][y] = tiles.escape
    map.spawn = {x, y}
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

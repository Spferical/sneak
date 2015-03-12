
Target = {
    x = 0,
    y = 0,
    width = 32,
    height = 32,
    dead = false
}

function Target:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Target:get_center()
    return self.x + self.width / 2, self.y + self.height / 2
end

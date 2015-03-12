
Target = {
    x = 0,
    y = 0,
    width = 32,
    height = 32
}

function Target:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

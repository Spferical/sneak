Guard = {
    x = 0,
    y = 0,
    target = nil,
    path = {},
}

function Guard:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

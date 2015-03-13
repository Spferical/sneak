abilities = {
    'quickness',
}

ability_keys = {'z', 'x', 'c', 'v', 'b'}

Ability = {
    name = 'ability',
    max_charge = 100,
    charge = 100,
    active = false,
}

function Ability:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Ability:toggle()
    self.active = not self.active
end


Item = {
    x = 0,
    y = 0,
    width = 32,
    height = 32,
    ability = nil,
}

function Item:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end


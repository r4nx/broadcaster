local magic = require 'broadcaster.magic'

local Session = {}
Session.__index = Session

setmetatable(Session, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

function Session:_init()
    self.handlerId = {}
    self.data = {}
end

function Session:appendHandlerId(handlerId)
    if #self.handlerId ~= magic.HANDLER_ID_LEN then
        self.handlerId[#self.handlerId + 1] = handlerId
    end
end

function Session:appendData(data)
    self.data[#self.data + 1] = data
end

function Session:isValid()
    return #self.handlerId == magic.HANDLER_ID_LEN
end

return Session

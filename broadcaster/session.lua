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
    self:updateTime()
end

function Session:appendHandlerId(handlerId)
    if #self.handlerId < magic.MAX_SESSION_CONTENT_LENGTH then
        self.handlerId[#self.handlerId + 1] = handlerId
    end
    self:updateTime()
end

function Session:appendData(data)
    if #self.data < magic.MAX_SESSION_CONTENT_LENGTH then
        self.data[#self.data + 1] = data
    end
    self:updateTime()
end

function Session:updateTime()
    self.lastUpdate = os.time()
end

return Session

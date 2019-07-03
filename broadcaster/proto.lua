local proto = {}

local packet = require 'broadcaster.packet'
local utils = require 'broadcaster.utils'
local Session = require 'broadcaster.session'
local inspect = require 'inspect'

-- local sessions = setmetatable({}, {__mode = 'kv'})
local sessions = {}

-- Args:
--    bin <table> - binary values
function proto.processPacket(bin, callback)
    local packetCode = utils.binToDec({unpack(bin, 1, 3)})
    print('debug >> packet code: ' .. packetCode)

    packetProcessors = switch({
        [packet.PACKETS_ID.START_TRANSFER] = function()
            print('debug >> proto.lua:start packet > received start packet')
            local startPacket = packet.StartTransferPacket.unpack(bin)
            local sessionId = startPacket.sessionId

            if sessions[sessionId] ~= nil then
                sessions[sessionId] = nil
                error('session collision')
            end

            sessions[sessionId] = Session()
            print('debug >> proto.lua:start packet > created new session ' .. sessionId)
            print('debug >> proto.lua:start packet > sessions list:\n' .. inspect(sessions))
        end,
        [packet.PACKETS_ID.DATA] = function()
            print('debug >> proto.lua:data packet > received data packet')
            -- TODO: pcall
            local dataPacket = packet.DataPacket.unpack(bin)
            local sessionId = dataPacket.sessionId

            local sess = sessions[sessionId]
            if sess ~= nil then
                sess:appendData(dataPacket.data)
            else
                -- TODO: remove this
                print('debug >> proto.lua:data packet > sessions list:\n' .. inspect(sessions))
                print('debug >> proto.lua:data packet > cannot found session for data packet ' .. sessionId)
            end
        end,
        [packet.PACKETS_ID.HANDLER_ID] = function()
            print('debug >> proto.lua:handler id packet > received handler id packet')
            local handlerIdPacket = packet.HandlerIdPacket.unpack(bin)
            local sessionId = handlerIdPacket.sessionId
            
            local sess = sessions[sessionId]
            if sess ~= nil then
                sess:appendHandlerId(handlerIdPacket.handlerId)
            else
                -- TODO: remove this
                print('debug >> proto.lua:hanlder id packet > cannot found session for handler id packet')
            end
        end,
        [packet.PACKETS_ID.STOP_TRANSFER] = function()
            print('debug >> proto.lua:stop packet > received stop packet')
            local stopTransferPacket = packet.StopTransferPacket.unpack(bin)
            local sessionId = stopTransferPacket.sessionId

            local sess = sessions[sessionId]
            if sess ~= nil then
                if sess:isValid() then
                    sessions[sessionId] = nil
                    callback(sess)
                end
            else
                -- TODO: remove this and join 2 ifs above
                print('debug >> proto.lua:stop packet > cannot found session for stop transfer packet')
            end
        end,
        default = function() print('received unknown packet') end
    })

    packetProcessors:case(packetCode)
end

local function randomSessionId()
    math.randomseed(os.time() ^ 5)
    return math.random(0, 15)  -- 4 bit
end

-- Args:
--    data <table> - table of decimal numbers
--    handlerId <table> - encoded handlerId
-- Returns:
--    Table of binary sequences
function proto.sendData(data, handlerId)
    local sessionId = randomSessionId()
    local packets = {packet.StartTransferPacket(sessionId):pack()}

    for _, handlerIdPart in ipairs(handlerId) do
        packets[#packets + 1] = packet.HandlerIdPacket(handlerIdPart, sessionId):pack()
    end

    for _, dataPart in ipairs(data) do
        packets[#packets + 1] = packet.DataPacket(dataPart, sessionId):pack()
    end
    
    packets[#packets + 1] = packet.StopTransferPacket(sessionId):pack()
    
    return packets
end

function proto.getSessions()
    return sessions
end

-- TODO: remove
function proto.identifyPacket(packetCode)
    for name, code in pairs(packet.PACKETS_ID) do
        if code == packetCode then return name end
    end
end

return proto

local proto = {}

local packet = require 'broadcaster.packet'
local utils = require 'broadcaster.utils'
local Session = require 'broadcaster.session'
local inspect = require 'inspect'

local logger = require 'log'
-- local sessions = setmetatable({}, {__mode = 'kv'})
local sessions = {}

-- Args:
--    bin <table> - binary values
function proto.processPacket(bin, callback)
    logger.trace('>> processPacket')
    local packetCode = utils.binToDec({unpack(bin, 1, 3)})
    logger.debug('packet code: ' .. packetCode)

    packetProcessors = switch({
        [packet.PACKETS_ID.START_TRANSFER] = function()
            logger.debug('start packet identified')
            local startPacket = packet.StartTransferPacket.unpack(bin)
            local sessionId = startPacket.sessionId

            if sessions[sessionId] ~= nil then
                sessions[sessionId] = nil
                logger.warn(('session collision: session %d was removed'):format(sessionId))
            end

            sessions[sessionId] = Session()
            logger.debug('created new session ' .. sessionId)
        end,
        [packet.PACKETS_ID.DATA] = function()
            logger.debug('data packet identified')
            -- TODO: pcall
            local dataPacket = packet.DataPacket.unpack(bin)
            local sessionId = dataPacket.sessionId

            local sess = sessions[sessionId]
            if sess ~= nil then
                sess:appendData(dataPacket.data)
            else
                -- TODO: remove this
                logger.warn('cannot found session for data packet: ' .. sessionId)
                logger.warn('sessions list:\n  ' .. inspect(sessions))
            end
        end,
        [packet.PACKETS_ID.HANDLER_ID] = function()
            logger.debug('handler id packet identified')
            local handlerIdPacket = packet.HandlerIdPacket.unpack(bin)
            local sessionId = handlerIdPacket.sessionId
            
            local sess = sessions[sessionId]
            if sess ~= nil then
                sess:appendHandlerId(handlerIdPacket.handlerId)
            else
                -- TODO: remove this
                logger.warn('cannot found session for handler id packet: ' .. sessionId)
                logger.warn('sessions list:\n  ' .. inspect(sessions))
            end
        end,
        [packet.PACKETS_ID.STOP_TRANSFER] = function()
            logger.debug('stop packet identified')
            local stopTransferPacket = packet.StopTransferPacket.unpack(bin)
            local sessionId = stopTransferPacket.sessionId

            local sess = sessions[sessionId]
            if sess ~= nil then
                if sess:isValid() then
                    sessions[sessionId] = nil
                    logger.debug(('removed session %d because stop packet received'):format(sessionId))
                    callback(sess)
                end
            else
                -- TODO: remove this and join 2 ifs above
                logger.warn('cannot found session for stop transfer packet: ' .. sessionId)
                logger.warn('sessions list:\n  ' .. inspect(sessions))
            end
        end,
        default = function() logger.warn('cannot identify packet') end
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

return proto

--local handlers = setmetatable({}, {__mode = 'v'})
local handlers = {}

local logger = require 'log'
logger.usecolor = false
logger.outfile = 'broadcaster.log'
logger.level = 'debug'

local proto = require 'broadcaster.proto'
local encoder = require 'broadcaster.encoder'
local charset = require 'broadcaster.charset'
local magic = require 'broadcaster.magic'
local utf8 = require 'lua-utf8'

local inspect = require 'inspect'

-- Args:
--    handlerId <string> - unique handler ID (2 chars)
--    callback_obj <function> - callback function
function EXPORTS.registerHandler(handlerId, callback_obj)
    -- Doing some check in advance to avoid undefined behavior
    if type(handlerId) ~= 'string' or not encoder.check(handlerId, charset.MESSAGE_ENCODE) then
        error(('invalid handler id ("%s")'):format(handlerId))
    end
    if utf8.len(handlerId) ~= magic.HANDLER_ID_LEN then
        error(('handler id have to be %d character length (got "%s")'):format(magic.HANDLER_ID_LEN, handlerId))
    end
    if handlers[handlerId] then
        error(('handler id collision: handler "%s" has been already registered'):format(handlerId))
    end    
    if not callback_obj or type(callback_obj) ~= 'function' then
        error(('callback object is not a function (handler id "%s")'):format(handlerId))
    end

    handlers[handlerId] = callback_obj
    logger.info(('Registered handler "%s"'):format(handlerId))
end

local function bitsToBitStream(bits)
    local bs = raknetNewBitStream()
    for _, bValue in ipairs(bits) do
        raknetBitStreamWriteBool(bs, bValue == 1 and true or false)
    end
    return bs
end

-- Args:
--    message <string> - message to send
--    handlerId <string> - remote handler id (2 chars)
function EXPORTS.sendMessage(message, handlerId)
    if type(message) ~= 'string' or not encoder.check(message, charset.MESSAGE_ENCODE) then
        error(('invalid message ("%s")'):format(message))
    end
    if type(handlerId) ~= 'string' or not encoder.check(handlerId, charset.MESSAGE_ENCODE) then
        error(('invalid handler id ("%s")'):format(handlerId))
    end
    if utf8.len(handlerId) ~= magic.HANDLER_ID_LEN then
        error(('handler id have to be %d character length (got "%s")'):format(magic.HANDLER_ID_LEN, handlerId))
    end

    local encodedMessage = encoder.encode(message, charset.MESSAGE_ENCODE)
    local encodedHandlerId = encoder.encode(handlerId, charset.MESSAGE_ENCODE)

    logger.debug('sendMessage > encodedMessage: ' .. inspect(encodedMessage))
    logger.debug('sendMessage > encodedHandlerId: ' .. inspect(encodedHandlerId))

    local packets = proto.sendData(encodedMessage, encodedHandlerId)
    logger.info('sendMessage > packets:\n  ' .. inspect(packets))
    for _, p in ipairs(packets) do
        local bs = bitsToBitStream(p)
        raknetBitStreamSetWriteOffset(bs, 16)
        raknetSendRpc(magic.RPC_OUT, bs)
        raknetDeleteBitStream(bs)
    end
end

-- TODO: remove
function EXPORTS._printHandlers()
    print('Handlers:')
    for handlerId, _ in pairs(handlers) do
        print(handlerId)
    end
end

function EXPORTS._printSessions()
    print('Sessions:\n' .. inspect(proto.getSessions()))
end

local function bitStreamToBits(bs)
    local bits = {}
    for _ = 1, raknetBitStreamGetNumberOfUnreadBits(bs) do
        bits[#bits + 1] = raknetBitStreamReadBool(bs) and 1 or 0
    end
    return bits
end

local function sessionHandler(session)
    logger.trace('>> broadcaster.lua:sessionHandler')
    local handlerId = encoder.decode(session.handlerId, charset.MESSAGE_DECODE)
    logger.debug(('got handler id: "%s"'):format(handlerId))
    local handler = handlers[handlerId]
    if handler ~= nil then
        handler(encoder.decode(session.data, charset.MESSAGE_DECODE))
    else
        logger.warn('handler not found, all handlers:\n  ' .. inspect(handlers))
    end
end

local function rpcHandler(rpcId, bs)
    if rpcId == magic.RPC_IN then
        raknetBitStreamResetReadPointer(bs)
        
        local bits = bitStreamToBits(bs)
        logger.info(string.rep(' ', 4) .. '[^] received bits: ' .. inspect(bits))
        
        if #bits == magic.PACKETS_LEN then
            proto.processPacket(bits, sessionHandler)
        else
            logger.warn(('bs length is not %d (%d instead)'):format(magic.PACKETS_LEN, #bits))
        end
    end
end

function main()
    logger.trace('>> broadcaster.lua:main')
    addEventHandler('onReceiveRpc', rpcHandler)
    wait(-1)
end

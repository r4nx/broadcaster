-- This file is part of broadcaster library
-- Licensed under MIT License
-- Copyright (c) 2019 Ranx
-- https://github.com/r4nx/broadcaster
-- Version 0.2.0

local packet = {}

local utils = require 'broadcaster.utils'

local logger = require 'log'
local inspect = require 'inspect'

packet.PACKETS_ID = {
    START_TRANSFER = 1,
    STOP_TRANSFER = 2,
    DATA = 3,
    HANDLER_ID = 4
}

packet.StartTransferPacket = {}
packet.StartTransferPacket.__index = packet.StartTransferPacket

setmetatable(packet.StartTransferPacket, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

-- Args:
--    sessionId <number> (decimal)
function packet.StartTransferPacket:_init(sessionId)
    self.sessionId = sessionId
end

function packet.StartTransferPacket:pack()
    local packetId = utils.decToBin(packet.PACKETS_ID.START_TRANSFER, 3)
    local sessionId = utils.decToBin(self.sessionId, 4)
    return utils.padBinary(utils.tablesConcat(packetId, sessionId), -16)
end

function packet.StartTransferPacket.unpack(bin)
    local packetId = utils.binToDec({unpack(bin, 1, 3)})
    local sessionId = utils.binToDec({unpack(bin, 4, 7)})

    return packet.StartTransferPacket(sessionId)
end



packet.StopTransferPacket = {}
packet.StopTransferPacket.__index = packet.StopTransferPacket

setmetatable(packet.StopTransferPacket, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

-- Args:
--    sessionId <number> (decimal)
function packet.StopTransferPacket:_init(sessionId)
    self.sessionId = sessionId
end

function packet.StopTransferPacket:pack()
    local packetId = utils.decToBin(packet.PACKETS_ID.STOP_TRANSFER, 3)
    local sessionId = utils.decToBin(self.sessionId, 4)
    return utils.padBinary(utils.tablesConcat(packetId, sessionId), -16)
end

function packet.StopTransferPacket.unpack(bin)
    local packetId = utils.binToDec({unpack(bin, 1, 3)})
    local sessionId = utils.binToDec({unpack(bin, 4, 7)})

    return packet.StopTransferPacket(sessionId)
end



packet.DataPacket = {}
packet.DataPacket.__index = packet.DataPacket

setmetatable(packet.DataPacket, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

-- Args:
--    data <number> - data to transfer (1 byte in decimal number system)
--    sessionId <number> (decimal)
function packet.DataPacket:_init(data, sessionId)
    if select(2, math.frexp(data)) > 8 then
        error('data is too large: only 1 byte allowed')
    end
    self.data = data
    self.sessionId = sessionId
end

function packet.DataPacket:pack()
    local packetId = utils.decToBin(packet.PACKETS_ID.DATA, 3)
    local sessionId = utils.decToBin(self.sessionId, 4)
    local parityBit = {utils.getParity(self.data) and 1 or 0}
    local data = utils.decToBin(self.data, 8)

    return utils.padBinary(utils.tablesConcat(packetId, sessionId, parityBit, data), -16)
end

function packet.DataPacket.unpack(bin)
    local packetId = utils.binToDec({unpack(bin, 1, 3)})
    logger.debug('data packet > packet id: ' .. packetId)
    local sessionId = utils.binToDec({unpack(bin, 4, 7)})
    logger.debug('data packet > session id: ' .. sessionId)
    local parityBit = bin[8]
    logger.debug('data packet > parity bit:' .. parityBit)
    local data = utils.binToDec({unpack(bin, 9, 16)})
    logger.debug('data packet > data: ' .. inspect(data))

    if (utils.getParity(data) and 1 or 0) ~= parityBit then
        logger.warn('got parity bit: ' .. parityBit)
        logger.warn('actual parity bit: ' .. (utils.getParity(data) and 1 or 0))
        error('corrupted data packet: parity bits do not match')
    end

    return packet.DataPacket(data, sessionId)
end



packet.HandlerIdPacket = {}
packet.HandlerIdPacket.__index = packet.HandlerIdPacket

setmetatable(packet.HandlerIdPacket, {
    __call = function(cls, ...)
        local self = setmetatable({}, cls)
        self:_init(...)
        return self
    end
})

-- Args:
--    handlerId <number> - handler id, decimal, 1 byte
--    sessionId <number> (decimal)
function packet.HandlerIdPacket:_init(handlerId, sessionId)
    if select(2, math.frexp(handlerId)) > 8 then
        error('handlerId is too large: only 1 byte allowed')
    end
    self.handlerId = handlerId
    self.sessionId = sessionId
end

function packet.HandlerIdPacket:pack()
    local packetId = utils.decToBin(packet.PACKETS_ID.HANDLER_ID, 3)
    local sessionId = utils.decToBin(self.sessionId, 4)
    local parityBit = {utils.getParity(self.handlerId) and 1 or 0}
    local handlerId = utils.decToBin(self.handlerId, 8)

    return utils.padBinary(utils.tablesConcat(packetId, sessionId, parityBit, handlerId), -16)
end

function packet.HandlerIdPacket.unpack(bin)
    local packetId = utils.binToDec({unpack(bin, 1, 3)})
    local sessionId = utils.binToDec({unpack(bin, 4, 7)})
    local parityBit = bin[8]
    local handlerId = utils.binToDec({unpack(bin, 9, 16)})

    if (utils.getParity(handlerId) and 1 or 0) ~= parityBit then
        logger.warn('got parity bit: ' .. parityBit)
        logger.warn('actual parity bit: ' .. (utils.getParity(handlerId) and 1 or 0))
        error('corrupted handler id packet: parity bits do not match')
    end

    return packet.HandlerIdPacket(handlerId, sessionId)
end

return packet

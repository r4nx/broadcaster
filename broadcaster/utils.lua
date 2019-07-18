-- This file is part of broadcaster library
-- Licensed under MIT License
-- Copyright (c) 2019 Ranx
-- https://github.com/r4nx/broadcaster
-- Version 0.2.0

local utils = {}

-- Convert table of binary values to decimal number
-- Args:
--    bin <table> - binary sequence
-- Returns:
--    number - decimal equivalent
function utils.binToDec(bin)
    local dec = 0
    for _, bValue in ipairs(bin) do
        dec = bit.bor(bit.lshift(dec, 1), bValue)
    end
    return dec
end

-- Convert decimal number to table of binary numbers
-- Args:
--    dec <number> - decimal number
--    padding <number> - optional leading zeros padding
-- Returns:
--    table - binary equivalent
function utils.decToBin(dec, padding)
    local bits = {}
    local bitsCount = padding or math.max(1, select(2, math.frexp(dec)))

    for b = bitsCount, 1, -1 do
        bits[b] = math.fmod(dec, 2)
        dec = math.floor((dec - bits[b]) / 2)
    end

    return bits
end

-- Join multiple tables together
-- Args:
--    t1 <table>
--    t2 <table>
--    tn.. <table>
-- Returns:
--    table
function utils.tablesConcat(t1, ...)
    for _, tn in ipairs({...}) do
        for i = 1, #tn do
            t1[#t1 + 1] = tn[i]
        end
    end
    return t1
end

-- Args:
--    t <table> - key-value table
-- Returns:
--    number
function utils.tableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

-- Args:
--    dec <number>
-- Returns:
--    bool
function utils.getParity(n)
    local parity = false
    while n > 0 do
        parity = not parity
        n = bit.band(n, n - 1)
    end
    return parity
end

-- Pads binary sequence with leading zeros, also trim it if it is too long
-- Args:
--    bin <table> - binary sequence
--    bits <number> - padding (negative padding - pad with ending zeros)
-- Returns:
--    Binary sequence
function utils.padBinary(bin, bits)
    local padded = bin
    if #padded > math.abs(bits) then
        if bits > 0 then
            padded = {unpack(padded, #padded - math.abs(bits) + 1)}
        else
            padded = {unpack(padded, 1, math.abs(bits))}
        end
    end

    while #padded < math.abs(bits) do
        if bits > 0 then
            table.insert(padded, 1, 0)
        else
            padded[#padded + 1] = 0
        end
    end

    return padded
end

function utils.switch(t)
    t.case = function(self, x)
        local f = self[x] or self.default
        if f then
            if type(f) == "function" then
                f(x, self)
            else
                error("case " .. tostring(x) .. " not a function")
            end
        end
    end
    return t
end

return utils

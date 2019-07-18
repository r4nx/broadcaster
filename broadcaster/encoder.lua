-- This file is part of broadcaster library
-- Licensed under MIT License
-- Copyright (c) 2019 Ranx
-- https://github.com/r4nx/broadcaster
-- Version 0.2.0

local utf8 = require 'lua-utf8'

local encoder = {}

-- Encodes message according to specified charset
-- Args:
--    message <string> - message to encode
--    charset <table> - charset to use for encoding (use charset.lua)
-- Returns:
--    Table of integers
function encoder.encode(message, charset)
    local encoded = {}
    utf8.gsub(message, '.', function(c)
        encoded[#encoded + 1] = charset[c]
    end)
    return encoded
end

-- Decodes table of integers back to message
-- Args:
--    data <table> - data to decode
--    charset <table> - charset to use for decoding (use charset.lua)
-- Returns:
--    string
function encoder.decode(data, charset)
    local decoded = {}
    for _, c in ipairs(data) do
        decoded[#decoded + 1] = charset[c]
    end
    return table.concat(decoded, '')
end

-- Check if all message characters are in charset
-- Args:
--    message <string> - message to encode
--    charset <table> - charset to use for encoding (use charset.lua)
-- Returns:
--    bool
function encoder.check(message, charset)
    local unknownCharacter = false
    utf8.gsub(message, '.', function(c)
        if charset[c] == nil then
            unknownCharacter = true
        end
    end)
    return not unknownCharacter
end

return encoder

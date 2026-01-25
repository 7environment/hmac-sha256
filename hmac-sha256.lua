-- Используем встроенные bit32-операции Roblox
local bxor = bit32.bxor
local band = bit32.band
local bnot = bit32.bnot
local rrotate = bit32.rrotate
local rshift = bit32.rshift

-- lshift для 32-битных чисел
local function lshift(x, n)
    if n >= 32 then return 0 end
    return bit32.lshift(x, n)
end

-- Константы SHA-256
local k = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}

-- Преобразование 4 байт в число (big-endian)
local function s232num(s, i)
    return 
        bit32.bor(
            bit32.lshift(string.byte(s, i), 24),
            bit32.bor(
                bit32.lshift(string.byte(s, i+1), 16),
                bit32.bor(
                    bit32.lshift(string.byte(s, i+2), 8),
                    string.byte(s, i+3)
                )
            )
        )
end

-- Преобразование числа в 4 байта (big-endian)
local function num2s(n)
    return string.char(
        bit32.rshift(n, 24) % 256,
        bit32.rshift(n, 16) % 256,
        bit32.rshift(n, 8) % 256,
        n % 256
    )
end

-- Преобразование строки в hex
local function str2hexa(s)
    return (s:gsub(".", function(c) return string.format("%02x", string.byte(c)) end))
end

-- Подготовка сообщения
local function preproc(msg)
    local len = #msg
    local extra = (64 - ((len + 9) % 64)) % 64
    local len_bits_lo = len * 8
    local len_bits_hi = 0  -- для сообщений < 2^29 байт
    
    return msg .. "\128" .. string.rep("\0", extra) .. 
           num2s(len_bits_hi) .. num2s(len_bits_lo)
end

-- SHA-256
local function sha256(msg)
    msg = preproc(msg)
    local H = {
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    }
    
    for i = 1, #msg, 64 do
        local w = {}
        for j = 1, 16 do
            w[j] = s232num(msg, i + (j-1)*4)
        end
        
        for j = 17, 64 do
            local s0 = bxor(rrotate(w[j-15], 7), rrotate(w[j-15], 18), rshift(w[j-15], 3))
            local s1 = bxor(rrotate(w[j-2], 17), rrotate(w[j-2], 19), rshift(w[j-2], 10))
            w[j] = band(w[j-16] + s0 + w[j-7] + s1, 0xFFFFFFFF)
        end
        
        local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
        
        for j = 1, 64 do
            local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local temp1 = band(h + S1 + ch + k[j] + w[j], 0xFFFFFFFF)
            local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local maj = bxor(band(a, b), band(a, c), band(b, c))
            local temp2 = band(S0 + maj, 0xFFFFFFFF)
            
            h, g, f, e, d, c, b, a = 
                g, f, e, band(d + temp1, 0xFFFFFFFF), c, b, a, band(temp1 + temp2, 0xFFFFFFFF)
        end
        
        H[1] = band(H[1] + a, 0xFFFFFFFF)
        H[2] = band(H[2] + b, 0xFFFFFFFF)
        H[3] = band(H[3] + c, 0xFFFFFFFF)
        H[4] = band(H[4] + d, 0xFFFFFFFF)
        H[5] = band(H[5] + e, 0xFFFFFFFF)
        H[6] = band(H[6] + f, 0xFFFFFFFF)
        H[7] = band(H[7] + g, 0xFFFFFFFF)
        H[8] = band(H[8] + h, 0xFFFFFFFF)
    end
    
    return str2hexa(num2s(H[1]) .. num2s(H[2]) .. num2s(H[3]) .. num2s(H[4]) ..
                   num2s(H[5]) .. num2s(H[6]) .. num2s(H[7]) .. num2s(H[8]))
end

-- HMAC-SHA256
local function hmac_sha256(key, message)
    local block_size = 64
    
    -- Если ключ длиннее блока - хешируем его
    if #key > block_size then
        local hex_key = sha256(key)
        key = ""
        for i = 1, #hex_key, 2 do
            key = key .. string.char(tonumber(hex_key:sub(i, i+1), 16))
        end
    end
    
    -- Дополняем ключ нулями до block_size
    while #key < block_size do
        key = key .. "\0"
    end
    
    -- Создаем ipad и opad
    local ipad, opad = "", ""
    for i = 1, block_size do
        local byte = string.byte(key, i)
        ipad = ipad .. string.char(bxor(byte, 0x36))
        opad = opad .. string.char(bxor(byte, 0x5C))
    end
    
    -- Внутренний хеш
    local inner_hash_hex = sha256(ipad .. message)
    local inner_hash = ""
    for i = 1, #inner_hash_hex, 2 do
        inner_hash = inner_hash .. string.char(tonumber(inner_hash_hex:sub(i, i+1), 16))
    end
    
    -- Внешний хеш
    return sha256(opad .. inner_hash)
end

return hmac_sha256

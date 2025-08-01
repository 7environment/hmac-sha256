local hmac_sha256 = loadstring(game:HttpGet("https://raw.githubusercontent.com/7environment/hmac-sha256/refs/heads/main/hmac-sha256.lua", true))()
local function tableToString(t, seen)
    seen = seen or {}
    if seen[t] then return "table_recursion" end
    seen[t] = true

    local keys = {}
    for k in pairs(t) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        if type(a) == "number" and type(b) == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)

    local parts = {}
    for _, k in ipairs(keys) do
        local v = t[k]
        local keyPart = tostring(k)
        local valPart

        if type(v) == "table" then
            valPart = "table{" .. tableToString(v, seen) .. "}"
        elseif type(v) == "string" then
            valPart = '"' .. v .. '"'
        else
            valPart = tostring(v)
        end

        table.insert(parts, keyPart .. ":" .. valPart)
    end

    return table.concat(parts, ",")
end

local function signData(SECRET_KEY, data)
    local queryString = {}
    for k, v in pairs(data) do
        local valueStr
        if type(v) == "table" then
            valueStr = "table{" .. tableToString(v) .. "}"
        elseif type(v) == "string" then
            valueStr = '"' .. v .. '"'
        else
            valueStr = tostring(v)
        end
        table.insert(queryString, tostring(k) .. "=" .. valueStr)
    end

    -- Сортируем по ключу
    table.sort(queryString)

    local message = table.concat(queryString, "\n")
    return hmac_sha256(SECRET_KEY, message)
end

return signData

local hmac_sha256 = loadstring(game:HttpGet("https://raw.githubusercontent.com/7environment/hmac-sha256/refs/heads/main/hmac-sha256.lua", true))()
local function tableToString(t, seen)
    seen = seen or {}
    if seen[t] then return "recursion" end
    seen[t] = true

    -- Проверяем, является ли таблица массивом (числовые ключи 1,2,3...)
    local is_array = true
    local max_key = 0
    for k in pairs(t) do
        if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
            is_array = false
        end
        if type(k) == "number" then
            max_key = math.max(max_key, k)
        end
    end

    -- Если это массив, сортируем по индексу
    if is_array then
        local parts = {}
        for i = 1, max_key do
            local v = t[i]
            if v ~= nil then
                if type(v) == "table" then
                    parts[i] = "table{" .. tableToString(v, seen) .. "}"
                elseif type(v) == "string" then
                    parts[i] = '"' .. v .. '"'
                else
                    parts[i] = tostring(v)
                end
            end
        end
        return "table{" .. table.concat(parts, ",") .. "}"
    end

    -- Обычный объект (ключ=значение)
    local keys = {}
    for k in pairs(t) do table.insert(keys, k) end
    table.sort(keys, function(a, b)
        if type(a) == "number" and type(b) == "number" then return a < b end
        return tostring(a) < tostring(b)
    end)

    local parts = {}
    for _, k in ipairs(keys) do
        local v = t[k]
        local keyStr = type(k) == "string" and k or "[" .. tostring(k) .. "]"
        local valStr
        if type(v) == "table" then
            valStr = "table{" .. tableToString(v, seen) .. "}"
        elseif type(v) == "string" then
            valStr = '"' .. v .. '"'
        else
            valStr = tostring(v)
        end
        table.insert(parts, keyStr .. ":" .. valStr)
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
    print(message)
    return hmac_sha256(SECRET_KEY, message)
end

return signData

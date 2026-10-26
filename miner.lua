-- Configuración de túneles y salas, siguiendo la API Android
local tunnelConfig = {
    pathDirection = {x = 1, y = 0, z = 0}, -- avanzar en X positivo
    tunnelLength  = 40,                  -- longitud del túnel
    tunnelWidth   = 3,                   -- ancho del túnel (en Z)
    tunnelHeight  = 3,                   -- altura del túnel (en Y)
    roomSize = {w = 16, h = 16, d = 16}, -- sala 16x16x16
    leftOffsetZ  = -8,                   -- desplazamiento para sala izquierda
    rightOffsetZ =  8,                   -- desplazamiento para sala derecha
    roomInterval = 16                    -- distancia entre salas a lo largo del túnel
}

local oreTypes = {
    "minecraft:coal_ore","minecraft:iron_ore","minecraft:copper_ore",
    "minecraft:gold_ore","minecraft:redstone_ore","minecraft:lapis_ore",
    "minecraft:diamond_ore","minecraft:emerald_ore","minecraft:ancient_debris"
}

-- Acceso a la API Android expuesta en global "android" (según tu documentación)
local androidApi = _G.android

-- Utilidades básicas
local function report(...)
    -- Imprime en consola/log; opcional adaptar a tu sistema de logs
    print(table.concat({...}, " "))
end

local function callApi(name, ...)
    if androidApi and type(androidApi[name]) == "function" then
        return true, androidApi[name](...)
    else
        -- Intento alternativo usando _G si existe
        local f = _G[name]
        if type(f) == "function" then
            local ok, res = pcall(f, ...)
            if ok then return true, res end
        end
        return false, "API no disponible: " .. tostring(name)
    end
end

local function autoRefuel()
    -- Placeholder: ajusta con tu lógica de recarga si aplica
    return true
end

local function placeLight(x, y, z, kind)
    if androidApi and type(androidApi.placeBlock) == "function" then
        return androidApi.placeBlock(x, y, z, kind)
    end
    return true
end

local function mineralDetected()
    -- Detección simplificada basada en bloques cercanos
    for _, t in ipairs(oreTypes) do
        local ok, res = callApi("getBlockType", 0, 0, 0)
        if ok and res and res ~= "air" then
            return true
        end
    end
    return false
end

local function tunnelSegment(length)
    for i = 1, length do
        local baseX, baseY, baseZ = i - 1, 0, 0

        for dz = -math.floor(tunnelConfig.tunnelWidth / 2),
                  math.floor(tunnelConfig.tunnelWidth / 2) do
            for dy = 0, tunnelConfig.tunnelHeight - 1 do
                local x, y, z = baseX, dy, baseZ + dz
                local ok, _ = callApi("breakBlock", x, y, z)
                if not ok then
                    return false
                end
            end
        end

        if not autoRefuel() then
            return false
        end

        -- Si tu entorno permite movimiento, podrías hacer moveTo aquí
        -- androidApi.moveTo(baseX + 1, 0, baseZ)
    end
    return true
end

local function createRoomAt(cx, cy, cz, size)
    local w, h, d = size.w, size.h, size.d
    local x0 = cx - math.floor(w / 2)
    local x1 = cx + math.floor(w / 2)
    local y0 = cy - math.floor(h / 2)
    local y1 = cy + math.floor(h / 2)
    local z0 = cz - math.floor(d / 2)
    local z1 = cz + math.floor(d / 2)

    for x = x0, x1 do
        for y = y0, y1 do
            for z = z0, z1 do
                local ok, _ = callApi("breakBlock", x, y, z)
                if not ok then
                    return false
                end
            end
        end
    end

    local lights = {
        {x = x0 + 2, y = y0 + 2, z = z0 + 2},
        {x = x1 - 2, y = y0 + 2, z = z1 - 2},
        {x = x0 + 2, y = y0 + 2, z = z1 - 2},
        {x = x1 - 2, y = y0 + 2, z = z0 + 2},
    }
    for _, L in ipairs(lights) do
        placeLight(L.x, L.y, L.z, "minecraft:torch")
    end

    return true
end

local function tunnelAndRooms()
    if not tunnelSegment(tunnelConfig.tunnelLength) then
        return false
    end

    local tramo = 0
    local paso = tunnelConfig.roomInterval

    while tramo < tunnelConfig.tunnelLength do
        tramo = tramo + paso

        -- Coordenadas sala izquierda
        local leftCX = tramo
        local leftCY = 8
        local leftCZ = -math.floor(tunnelConfig.tunnelWidth / 2) + tunnelConfig.leftOffsetZ

        -- Coordenadas sala derecha
        local rightCX = tramo
        local rightCY = 8
        local rightCZ =  math.floor(tunnelConfig.tunnelWidth / 2) + tunnelConfig.rightOffsetZ

        if not createRoomAt(leftCX, leftCY, leftCZ, tunnelConfig.roomSize) then
            return false
        end
        if not createRoomAt(rightCX, rightCY, rightCZ, tunnelConfig.roomSize) then
            return false
        end

        if mineralDetected() then
            report("Minerales detectados en tramo " .. tostring(tramo))
        else
            report("Sin minerales detectados en tramo " .. tostring(tramo))
        end

        if not autoRefuel() then
            return false
        end
    end

    return true
end

local function empezarTunelesYSalas()
    if not tunnelAndRooms() then
        report("Fallo al generar túneles o salas.")
        return false
    end
    report("Túneles rectos con salas 16x16 a izquierda y derecha creados exitosamente.")
    return true
end

local function main()
    local ok = empezarTunelesYSalas()
    if not ok then
        report("Ejecución terminada con errores.")
    end
end

main()

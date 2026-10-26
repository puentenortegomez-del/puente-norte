-- Configuración de túneles y salas
local tunnelConfig = {
    pathDirection = {x = 1, y = 0, z = 0}, -- avanzar en X positivo
    tunnelLength = 40,      -- longitud del túnel
    tunnelWidth  = 3,       -- ancho de la sección del túnel (en Z)
    tunnelHeight = 3,        -- altura del túnel (en Y)
    roomSize = {w = 16, h = 16, d = 16}, -- sala 16x16x16
    roomOffsetZLeft  = -math.floor(3/2) - 8,  -- desplazamiento relativo para sala izquierda
    roomOffsetZRight =  math.floor(3/2) + 8,   -- desplazamiento relativo para sala derecha
    roomSpacing = 6            -- separación entre túnel y cada sala (aprox)
}

-- Lista de minerales para detección
local oreTypes = {
    "minecraft:coal_ore", "minecraft:deepslate_coal_ore",
    "minecraft:iron_ore", "minecraft:deepslate_iron_ore",
    "minecraft:copper_ore", "minecraft:deepslate_copper_ore",
    "minecraft:gold_ore", "minecraft:deepslate_gold_ore",
    "minecraft:redstone_ore", "minecraft:deepslate_redstone_ore",
    "minecraft:lapis_ore", "minecraft:deepslate_lapis_ore",
    "minecraft:diamond_ore", "minecraft:deepslate_diamond_ore",
    "minecraft:emerald_ore", "minecraft:deepslate_emerald_ore",
    "minecraft:ancient_debris"
}

-- Utilidades existentes (asumiendo que ya están en tu archivo)
local androidApi = rawget(_G, "android")
local function report(...) ... end
local function callApi(...) ... end
local function stashHeldItem() ... end
local function autoRefuel() ... end
local function placeLight(...) ... end

-- Ver si hay minerales en el área cercana (simplificado)
local function mineralDetected()
    local ok, found = callApi("getBlocksOfType", androidApi and androidApi.getBlocksOfType, oreTypes[1])
    -- Si no devuelve, asumimos que no hay mineral detectable de momento
    if not ok or type(found) ~= "table" or #found == 0 then
        return false
    end
    return true
end

-- Crear túnel recto en X
local function tunnelSegment(length)
    for i = 1, length do
        local baseX, baseY, baseZ = i - 1, 0, 0
        for dz = -math.floor(tunnelConfig.tunnelWidth / 2),
                  math.floor(tunnelConfig.tunnelWidth / 2) do
            for dy = 0, tunnelConfig.tunnelHeight - 1 do
                local x, y, z = baseX, dy, baseZ + dz
                if not callApi("breakBlock", androidApi and androidApi.breakBlock, x, y, z) then
                    return false
                end
            end
        end
        if not autoRefuel() then return false end
        -- Mover al siguiente paso si tienes control de movimiento (opcional)
        -- moveForward(1)
    end
    return true
end

-- Crear sala centrada alrededor del centro
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
                if not callApi("breakBlock", androidApi and androidApi.breakBlock, x, y, z) then
                    return false
                end
            end
        end
    end

    -- Iluminación básica en puntos interiores
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

-- Crear túneles y salas a izquierda y derecha respecto al túnel
local function tunnelAndRooms()
    if not tunnelSegment(tunnelConfig.tunnelLength) then
        return false
    end

    -- Crear salas a intervalos a izquierda y derecha
    local tramo = 0
    local paso = 16 -- cada cuántos bloques se genera una sala

    while tramo < tunnelConfig.tunnelLength do
        tramo = tramo + paso

        -- Coordenadas de sala izquierda
        local leftCX = tramo
        local leftCY = 8
        local leftCZ = -math.floor(tunnelConfig.tunnelWidth / 2) - 8

        -- Coordenadas de sala derecha
        local rightCX = tramo
        local rightCY = 8
        local rightCZ =  math.floor(tunnelConfig.tunnelWidth / 2) + 8

        if not createRoomAt(leftCX, leftCY, leftCZ, tunnelConfig.roomSize) then
            return false
        end
        if not createRoomAt(rightCX, rightCY, rightCZ, tunnelConfig.roomSize) then
            return false
        end

        -- Detección de minerales: si no hay, seguimos; si hay, podemos ajustar
        if mineralDetected() then
            report("Minerales detectados en tramo " .. tostring(tramo))
        else
            report("Sin minerales detectados en tramo " .. tostring(tramo))
        end

        if not autoRefuel() then return false end
    end

    return true
end

-- Inicio
local function empezarTunelesYSalas()
    if not tunnelAndRooms() then
        report("Fallo al generar túneles o salas.")
        return false
    end
    report("Túneles rectos con salas 16x16 a izquierda y derecha creados exitosamente.")
    return true
end

-- Ejecutar
local function main()
    local ok = empezarTunelesYSalas()
    if not ok then
        report("Ejecución terminada con errores.")
    end
end

main()

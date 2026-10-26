-- Configuración de túneles y salas
local tunnelConfig = {
    pathDirection = {x = 1, y = 0, z = 0}, -- avanzar en X positivo
    tunnelLength = 40,      -- longitud del túnel
    tunnelWidth  = 3,       -- ancho de la sección del túnel (en Z)
    tunnelHeight = 3,        -- altura del túnel (en Y)
    roomSize = {w = 16, h = 16, d = 16}, -- sala 16x16x16
    roomOffsetZ = 0,         -- desplazamiento en Z respecto al centro del túnel
    roomSpacing = 6            -- separación entre túnel y cada sala (aprox)
}

-- Utilidades auxiliares existentes (asumidas ya en tu código)
-- local androidApi = rawget(_G, "android")
-- local function report(...) ... end
-- local function callApi(...) ... end
-- local function stashHeldItem() ... end
-- etc.

-- Crear ruta base de túnel: perfora y limpia un túnel recto en X
local function tunnelSegment(length)
    -- Supongamos que ya estamos posicionados en el inicio del segmento
    for i = 1, length do
        -- Coordenadas absolutas del bloque a perforar en este paso
        -- Ajusta baseX/baseY/baseZ según tu sistema de movimiento real
        local baseX, baseY, baseZ = i - 1, 0, 0

        for dz = -math.floor(tunnelConfig.tunnelWidth / 2),
                math.floor(tunnelConfig.tunnelWidth / 2) do
            for dy = 0, tunnelConfig.tunnelHeight - 1 do
                local x = baseX
                local y = dy
                local z = baseZ + dz
                -- Perforar (si es necesario) el bloque en (x,y,z)
                if not callApi("breakBlock", androidApi and androidApi.breakBlock, x, y, z) then
                    return false
                end
            end
        end

        -- Avanza la posición del jugador/bot en el mundo si tienes control de movimiento
        -- Si no tienes una función de movimiento, este bloque puede ser opcional o simulado
        -- moveForward(1)
        -- Puedes añadir un chequeo de combustible
        if not autoRefuel() then
            return false
        end
    end
    return true
end

-- Crear una sala de tamaño 16x16x16 centrada en (cx, cy, cz)
local function createRoomAt(cx, cy, cz, size)
    local w, h, d = size.w, size.h, size.d
    -- Rango de la sala alrededor del centro
    local x0 = cx - math.floor(w / 2)
    local x1 = cx + math.floor(w / 2)
    local y0 = cy - math.floor(h / 2)
    local y1 = cy + math.floor(h / 2)
    local z0 = cz - math.floor(d / 2)
    local z1 = cz + math.floor(d / 2)

    for x = x0, x1 do
        for y = y0, y1 do
            for z = z0, z1 do
                -- Si el bloque es sólido, lo perforamos para crear la sala
                if not callApi("breakBlock", androidApi and androidApi.breakBlock, x, y, z) then
                    return false
                end
            end
        end
    end

    -- Iluminación básica en esquinas centrales de cada cara
    placeLight = function(xx, yy, zz, kind)
        -- Reutiliza tu API de iluminación si tienes una
        if not callApi("placeBlock/light", androidApi and androidApi.placeBlock, xx, yy, zz, kind) then
            -- Si no tienes función de iluminación, puedes omitir
        end
    end

    -- Coloca antorchas en esquinas interiores de la sala
    local lx = x0 + 2
    local hx = x1 - 2
    local ly = y0 + 2
    local hz = z0 + 2
    local hz2 = z1 - 2
    placeLight(lx, ly, hz, "minecraft:torch")
    placeLight(lx, ly, hz2, "minecraft:torch")
    placeLight(hx, ly, hz, "minecraft:torch")
    placeLight(hx, ly, hz2, "minecraft:torch")

    return true
end

-- Crear túneles y salas a izquierda y derecha respecto al túnel
local function tunnelAndRooms()
    -- Supón que ya estamos al inicio del túnel en coordenadas (0,0,0)
    -- Túnel recto de longitud tunnelLength
    if not tunnelSegment(tunnelConfig.tunnelLength) then
        return false
    end

    -- Después de cada tramo, crear salas a izquierda y derecha respecto al eje Z
    -- Usaremos posiciones relativas a lo largo del túnel:
    local tramo = 0
    local paso = 16 -- cada cuánto crear una sala (p. ej. cada 16 bloques de longitud)
    while tramo < tunnelConfig.tunnelLength do
        tramo = tramo + paso

        -- Centro de la sala a la izquierda (Z menor)
        local leftCX = tramo
        local leftCY = 8 -- altura media de la sala
        local leftCZ = -tunnelConfig.tunnelWidth - math.floor(tunnelConfig.roomOffsetZ / 2)

        -- Centro de la sala a la derecha (Z mayor)
        local rightCX = tramo
        local rightCY = 8
        local rightCZ =  tunnelConfig.tunnelWidth + math.floor(tunnelConfig.roomOffsetZ / 2)

        -- Crear sala izquierda
        if not createRoomAt(leftCX, leftCY, leftCZ, tunnelConfig.roomSize) then
            return false
        end

        -- Crear sala derecha
        if not createRoomAt(rightCX, rightCY, rightCZ, tunnelConfig.roomSize) then
            return false
        end

        -- Recarga durante el progreso
        if not autoRefuel() then
            return false
        end
        -- Opcional: registrar progreso o mapa de exploración
    end

    return true
end

-- Función de entrada para iniciar el proceso completo
local function empezarTunelesYSalas()
    -- Preparar estado inicial si es necesario
    -- Posicionar solución: si ya hemos perforado un tramo, adaptamos la posición

    if not tunnelAndRooms() then
        report("Fallo al generar túneles o salas.")
        return false
    end

    report("Túneles rectos con salas de 16x16 creados exitosamente a izquierda y derecha.")
    return true
end

-- Inicio
local function main()
    local ok = empezarTunelesYSalas()
    if not ok then
        report("Ejecución terminada con errores.")
    end
end

-- Ejecutar
main()

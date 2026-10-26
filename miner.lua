
-- ==========================================
-- TUNELES Y SALAS - CC:ANDROIDs
-- Minecraft 1.20.1 / CC:Androids 1.3.0
-- Direccion principal: X positivo
-- ==========================================

local A = _G.android

if type(A) ~= "table" then
    print("ERROR: API android no disponible")
    return
end

local CFG = {
    tunnelLength = 40,
    tunnelWidth = 3,
    tunnelHeight = 3,
    roomWidth = 16,
    roomHeight = 16,
    roomDepth = 16,
    roomInterval = 16,
    leftOffsetZ = -10,
    rightOffsetZ = 10
}

local ORES = {
    "minecraft:coal_ore",
    "minecraft:iron_ore",
    "minecraft:copper_ore",
    "minecraft:gold_ore",
    "minecraft:redstone_ore",
    "minecraft:lapis_ore",
    "minecraft:diamond_ore",
    "minecraft:emerald_ore",
    "minecraft:ancient_debris",
    "minecraft:deepslate_coal_ore",
    "minecraft:deepslate_iron_ore",
    "minecraft:deepslate_copper_ore",
    "minecraft:deepslate_gold_ore",
    "minecraft:deepslate_redstone_ore",
    "minecraft:deepslate_lapis_ore",
    "minecraft:deepslate_diamond_ore",
    "minecraft:deepslate_emerald_ore"
}

local function report(message)
    print("[Tuneles] " .. tostring(message))
end

-- Llamada segura a una funcion sin argumentos.
local function call0(name)
    local fn = A[name]

    if type(fn) ~= "function" then
        return false, "Funcion inexistente: " .. name
    end

    local ok, result = pcall(fn)

    if not ok then
        return false, tostring(result)
    end

    if type(result) == "table" and result[1] == true then
        return false, tostring(result[2] or "Error API")
    end

    return true, result
end

-- Llamada segura a una funcion con un argumento.
local function call1(name, a)
    local fn = A[name]

    if type(fn) ~= "function" then
        return false, "Funcion inexistente: " .. name
    end

    local ok, result = pcall(fn, a)

    if not ok then
        return false, tostring(result)
    end

    if type(result) == "table" and result[1] == true then
        return false, tostring(result[2] or "Error API")
    end

    return true, result
end

-- Llamada segura a una funcion con tres coordenadas.
local function call3(name, x, y, z)
    local fn = A[name]

    if type(fn) ~= "function" then
        return false, "Funcion inexistente: " .. name
    end

    local ok, result = pcall(fn, x, y, z)

    if not ok then
        return false, tostring(result)
    end

    if type(result) == "table" and result[1] == true then
        return false, tostring(result[2] or "Error API")
    end

    return true, result
end

local function getPosition()
    local ok, info = call0("getSelf")

    if not ok or type(info) ~= "table" then
        report("No se pudo obtener la posicion")
        return nil
    end

    if type(info.posX) ~= "number"
        or type(info.posY) ~= "number"
        or type(info.posZ) ~= "number" then
        report("Coordenadas no validas")
        return nil
    end

    return {
        x = math.floor(info.posX),
        y = math.floor(info.posY),
        z = math.floor(info.posZ)
    }
end

local function hasFuel()
    local ok, fuel = call0("fuelLevel")

    if not ok or type(fuel) ~= "number" then
        report("No se pudo consultar el combustible")
        return false
    end

    if fuel <= 0 then
        report("Sin combustible. Recarga el androide")
        return false
    end

    return true
end

local function dig(x, y, z)
    if not hasFuel() then
        return false
    end

    local ok, err = call3("breakBlock", x, y, z)

    if not ok then
        report(
            "Fallo en "
            .. tostring(x) .. ","
            .. tostring(y) .. ","
            .. tostring(z) .. ": "
            .. tostring(err)
        )
        return false
    end

    return true
end

-- Excava un tramo de tunel.
local function digTunnel(start)
    report("Comenzando tunel")

    local half = math.floor(CFG.tunnelWidth / 2)

    for dx = 0, CFG.tunnelLength - 1 do
        local x = start.x + dx

        for dz = -half, half do
            for dy = 0, CFG.tunnelHeight - 1 do
                local y = start.y + dy
                local z = start.z + dz

                if not dig(x, y, z) then
                    return false
                end
            end
        end

        if dx % 5 == 0 then
            report("Progreso del tunel: " .. tostring(dx))
        end
    end

    report("Tunel terminado")
    return true
end

-- Excava una sala de dimensiones exactas.
-- La altura inicial es la posicion Y del androide.
local function digRoom(cx, baseY, cz)
    local x0 = cx - math.floor(CFG.roomWidth / 2)
    local z0 = cz - math.floor(CFG.roomDepth / 2)

    report(
        "Sala en X=" .. tostring(cx)
        .. " Y=" .. tostring(baseY)
        .. " Z=" .. tostring(cz)
    )

    for dx = 0, CFG.roomWidth - 1 do
        for dy = 0, CFG.roomHeight - 1 do
            for dz = 0, CFG.roomDepth - 1 do
                local x = x0 + dx
                local y = baseY + dy
                local z = z0 + dz

                if not dig(x, y, z) then
                    return false
                end
            end
        end
    end

    report("Sala terminada")
    return true
end

-- Detecta minerales visibles para el androide.
local function findOres()
    local total = 0

    for i = 1, #ORES do
        local ok, blocks = call1("getBlocksOfType", ORES[i])

        if ok and type(blocks) == "table" then
            local count = #blocks

            if count > 0 then
                report(ORES[i] .. ": " .. tostring(count))
                total = total + count
            end
        end
    end

    if total == 0 then
        report("No se encontraron minerales visibles")
    else
        report("Bloques minerales detectados: " .. tostring(total))
    end
end

local function main()
    local start = getPosition()

    if start == nil then
        return
    end

    report(
        "Inicio X=" .. tostring(start.x)
        .. " Y=" .. tostring(start.y)
        .. " Z=" .. tostring(start.z)
    )

    if not hasFuel() then
        return
    end

    -- Primero excava el tunel principal.
    if not digTunnel(start) then
        report("Tunel interrumpido")
        return
    end

    -- Despues crea las salas a intervalos regulares.
    local distance = CFG.roomInterval

    while distance < CFG.tunnelLength do
        local roomX = start.x + distance
        local leftZ = start.z + CFG.leftOffsetZ
        local rightZ = start.z + CFG.rightOffsetZ

        if not digRoom(roomX, start.y, leftZ) then
            report("Error al excavar la sala izquierda")
            return
        end

        if not digRoom(roomX, start.y, rightZ) then
            report("Error al excavar la sala derecha")
            return
        end

        findOres()

        distance = distance + CFG.roomInterval
    end

    report("Todas las operaciones han terminado")
end

main()

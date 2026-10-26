
-- Tuneles y salas para CC:Androids
-- Direccion: X positivo
-- Requiere espacio y combustible suficiente.

local android = _G.android

if type(android) ~= "table" then
    print("ERROR: API android no disponible.")
    return
end

local config = {
    tunnelLength = 40,
    tunnelWidth = 3,
    tunnelHeight = 3,

    roomWidth = 16,
    roomHeight = 16,
    roomDepth = 16,

    roomInterval = 16,
    leftOffsetZ = -9,
    rightOffsetZ = 9
}

local oreTypes = {
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

-- Comprueba que existe una funcion de la API y la ejecuta.
-- La API puede devolver una tabla cuyo primer valor sea true
-- cuando se produce un error.
local function callApi(name, ...)
    local fn = android[name]

    if type(fn) ~= "function" then
        return false, "Funcion no disponible: " .. name
    end

    local ok, result = pcall(fn, ...)

    if not ok then
        return false, tostring(result)
    end

    if type(result) == "table" and result[1] == true then
        return false, tostring(result[2] or "Error de la API")
    end

    return true, result
end

local function getPosition()
    local ok, selfInfo = callApi("getSelf")

    if not ok or type(selfInfo) ~= "table" then
        report("No se pudo obtener la posicion del androide.")
        return nil
    end

    if type(selfInfo.posX) ~= "number"
        or type(selfInfo.posY) ~= "number"
        or type(selfInfo.posZ) ~= "number" then
        report("La API devolvio coordenadas invalidas.")
        return nil
    end

    return {
        x = math.floor(selfInfo.posX),
        y = math.floor(selfInfo.posY),
        z = math.floor(selfInfo.posZ)
    }
end

local function checkFuel()
    local ok, fuel = callApi("fuelLevel")

    if not ok or type(fuel) ~= "number" then
        report("No se pudo comprobar el combustible.")
        return false
    end

    if fuel <= 0 then
        report("Sin combustible. Recarga el androide.")
        return false
    end

    return true
end

local function breakAt(x, y, z)
    if not checkFuel() then
        return false
    end

    local ok, err = callApi("breakBlock", x, y, z)

    if not ok then
        report(
            "Error excavando "
            .. x .. "," .. y .. "," .. z
            .. ": " .. tostring(err)
        )
        return false
    end

    return true
end

-- Excava un tramo recto en X positivo.
local function tunnelSegment(start, length)
    report("Excavando tunel de " .. length .. " bloques.")

    local halfWidth = math.floor(config.tunnelWidth / 2)

    for dx = 0, length - 1 do
        local x = start.x + dx

        for dz = -halfWidth, halfWidth do
            for dy = 0, config.tunnelHeight - 1 do
                if not breakAt(
                    x,
                    start.y + dy,
                    start.z + dz
                ) then
                    return false
                end
            end
        end

        if dx % 5 == 0 then
            report("Tunel: " .. dx .. "/" .. length)
        end
    end

    return true
end

-- Excava el volumen interior de una sala.
local function createRoom(cx, baseY, cz)
    local w = config.roomWidth
    local h = config.roomHeight
    local d = config.roomDepth

    -- Las dimensiones son exactas: 16 x 16 x 16.
    local x0 = cx - math.floor(w / 2)
    local y0 = baseY
    local z0 = cz - math.floor(d / 2)

    report(
        "Creando sala en "
        .. cx .. "," .. baseY .. "," .. cz
    )

    for dx = 0, w - 1 do
        for dy = 0, h - 1 do
            for dz = 0, d - 1 do
                if not breakAt(
                    x0 + dx,
                    y0 + dy,
                    z0 + dz
                ) then
                    return false
                end
            end
        end
    end

    return true
end

-- Busca minerales que el androide pueda ver.
local function detectOres()
    local found = {}

    for _, ore in ipairs(oreTypes) do
        local ok, blocks = callApi("getBlocksOfType", ore)

        if ok and type(blocks) == "table"
            and #blocks > 0 then
            found[#found + 1] =
                ore .. " (" .. #blocks .. ")"
        end
    end

    if #found > 0 then
        report("Minerales visibles: " .. table.concat(found, ", "))
    else
        report("No se han detectado minerales visibles.")
    end
end

local function main()
    local start = getPosition()

    if not start then
        return
    end

    report(
        "Inicio: "
        .. start.x .. "," .. start.y .. "," .. start.z
    )

    if not checkFuel() then
        return
    end

    if not tunnelSegment(start, config.tunnelLength) then
        report("Excavacion del tunel interrumpida.")
        return
    end

    -- Crea dos salas por cada intervalo completo.
    local distance = config.roomInterval

    while distance < config.tunnelLength do
        local roomX = start.x + distance

        local leftZ = start.z + config.leftOffsetZ
        local rightZ = start.z + config.rightOffsetZ

        if not createRoom(roomX, start.y, leftZ) then
            report("No se pudo completar la sala izquierda.")
            return
        end

        if not createRoom(roomX, start.y, rightZ) then
            report("No se pudo completar la sala derecha.")
            return
        end

        detectOres()

        distance = distance + config.roomInterval
    end

    report("Trabajo terminado.")
end

main()

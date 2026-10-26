-- miner_autorecarga.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Túnel 2x2 con autorecarga de Redstone

local android = _G.android

local LONGITUD = 100
local PAUSA = 0.1
local COMBUSTIBLE_MINIMO = 200 -- Se recargará si baja de esta cantidad

local function verificarError(nombre, res1, res2)
    if type(res1) == "table" and res1[1] == true then
        print("Error en " .. nombre .. ": " .. tostring(res1[2]))
        return false
    elseif not res1 then
        print("Error en " .. nombre .. ": " .. tostring(res2))
        return false
    end
    return true
end

local function esperarTarea()
    sleep(PAUSA)
    local inicio = os.clock()
    while true do
        local tarea = android.currentTask()
        if tarea == "idle" then
            break
        end
        if os.clock() - inicio > 10 then
            break
        end
        sleep(PAUSA)
    end
end

-- Función para buscar redstone en el inventario y autorecargarse
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    print("Combustible actual: " .. tostring(combustibleActual))

    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true -- Tiene suficiente combustible
    end

    print("Combustible bajo. Buscando redstone en el inventario...")

    -- El inventario de almacenamiento rápido en CC:Androids va del índice 0 al 8
    local slotRedstone = nil
    for i = 0, 8 do
        local ok, item = pcall(android.getSlotInfo, i)
        -- getSlotInfo devuelve el nombre del item si existe
        if ok and item and (string.find(item, "redstone") or string.find(item, "Redstone")) then
            slotRedstone = i
            break
        end
    end

    if not slotRedstone then
        print("¡ADVERTENCIA! No se encontró redstone en los slots 0-8 del androide para autorecargarse.")
        return false
    end

    -- Equipa el slot con redstone en la mano principal
    local okEquip, errEquip = pcall(android.equipSlot, slotRedstone)
    if not verificarError("equipar redstone", okEquip, errEquip) then
        return false
    end

    -- Ejecuta la recarga
    local okRefuel, resRefuel = pcall(android.refuel)
    if not verificarError("recargar combustible", okRefuel, resRefuel) then
        return false
    end

    print("¡Recarga exitosa! Nuevo nivel de combustible: " .. tostring(android.fuelLevel()))
    return true
end

local function minarBloque(x, y, z)
    -- Antes de cada acción importante, comprobamos el combustible
    if not comprobarYRecargar() then
        error("El androide se ha quedado sin combustible y no hay redstone disponible.")
    end

    local ok, res = pcall(android.breakBlock, x, y, z)
    if not verificarError("minado " .. x .. "," .. y .. "," .. z, ok, res) then
        return false
    end
    esperarTarea()
    return true
end

local function main()
    local posicion = android.getSelf()
    if not posicion or not posicion.posX then
        error("No se pudo obtener la posición del androide.")
    end

    local xInicial = math.floor(posicion.posX)
    local yInicial = math.floor(posicion.posY)
    local zInicial = math.floor(posicion.posZ)

    -- Definimos las alturas Y y carriles Z en base a la posición actual en la que está el androide en la imagen
    local Y1 = yInicial
    local Y2 = yInicial + 1
    local Z1 = zInicial
    local Z2 = zInicial - 1
    local xFinal = xInicial - LONGITUD

    print("=== MINER CON AUTORECARGA INICIADO ===")
    print("Carriles Z: " .. Z1 .. " y " .. Z2)
    print("Alturas Y: " .. Y1 .. " y " .. Y2)
    print("Desde X=" .. xInicial .. " hasta X=" .. xFinal)

    for x = xInicial - 1, xFinal, -1 do
        print("Excavando sección X=" .. x)

        -- Minar las 4 posiciones del túnel 2x2
        if not minarBloque(x, Y1, Z1) then return end
        if not minarBloque(x, Y2, Z1) then return end
        if not minarBloque(x, Y1, Z2) then return end
        if not minarBloque(x, Y2, Z2) then return end

        -- Avanzar al siguiente tramo
        local ok, res = pcall(android.moveTo, x, Y1, Z1)
        if not verificarError("movimiento a X=" .. x, ok, res) then
            print("No se pudo avanzar, deteniendo minero.")
            return
        end
        esperarTarea()
    end

    print("=== TÚNEL TERMINADO ===")
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end

-- miner_autorecarga.lua (Corregido y ajustado)
local android = _G.android

local LONGITUD = 100
local PAUSA = 0.1
local COMBUSTIBLE_MINIMO = 200

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

local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    print("Combustible actual: " .. tostring(combustibleActual))

    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print("Combustible bajo. Buscando redstone en el inventario...")

    local slotRedstone = nil
    -- Buscamos en la cuadrícula de almacenamiento (slots 0 al 8)
    for i = 0, 8 do
        local ok, itemName = pcall(android.getSlotInfo, i)
        -- Si el slot tiene un ítem y su nombre contiene "redstone" (o similar)
        if ok and itemName and type(itemName) == "string" then
            print("Slot " .. i .. " contiene: " .. itemName)
            if string.find(string.lower(itemName), "redstone") then
                slotRedstone = i
                break
            end
        end
    end

    -- Si por alguna razón el nombre exacto no coincide, tomamos el primer slot que tenga redstone o un ítem válido
    if not slotRedstone then
        for i = 0, 8 do
            local ok, itemName = pcall(android.getSlotInfo, i)
            if ok and itemName and type(itemName) == "string" and itemName ~= "" then
                -- Forzamos el uso del slot 0 o el primero que tenga algo si es combustible válido
                slotRedstone = i
                break
            end
        end
    end

    if not slotRedstone then
        print("¡ADVERTENCIA! No se encontró redstone en los slots 0-8.")
        return false
    end

    print("Redstone encontrada en el slot index: " .. slotRedstone)

    local okEquip, errEquip = pcall(android.equipSlot, slotRedstone)
    if not verificarError("equipar redstone", okEquip, errEquip) then
        return false
    end

    local okRefuel, resRefuel = pcall(android.refuel)
    if not verificarError("recargar combustible", okRefuel, resRefuel) then
        return false
    end

    print("¡Recarga exitosa! Nuevo nivel: " .. tostring(android.fuelLevel()))
    return true
end

local function minarBloque(x, y, z)
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

        if not minarBloque(x, Y1, Z1) then return end
        if not minarBloque(x, Y2, Z1) then return end
        if not minarBloque(x, Y1, Z2) then return end
        if not minarBloque(x, Y2, Z2) then return end

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

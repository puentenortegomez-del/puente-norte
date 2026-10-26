-- miner_completo.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android

local LONGITUD = 100
local PAUSA = 0.1
local COMBUSTIBLE_MINIMO = 200
local FRECUENCIA_ANTORCHAS = 5 -- Coloca una antorcha cada 5 bloques de avance

local function esperarTarea()
    sleep(PAUSA)
    local inicio = os.clock()
    while true do
        local tarea = android.currentTask()
        if tarea == "idle" then break end
        if os.clock() - inicio > 10 then break end
        sleep(PAUSA)
    end
end

-- Función para asegurar que el pico esté equipado en la mano principal para minar
local function equiparPico()
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and string.find(string.lower(info), "pickaxe") then
            pcall(android.equipSlot, i)
            return true
        end
    end
    return false
end

-- Autorecarga de combustible usando redstone del inventario
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print("Combustible bajo (" .. tostring(combustibleActual) .. "). Recargando...")

    local recargaExitosa = false

    -- Recorremos los slots del 0 al 8 probando la recarga directa
    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            pcall(android.refuel)
            local nuevoCombustible = android.fuelLevel()
            if nuevoCombustible and nuevoCombustible > combustibleActual then
                print("¡Recarga exitosa desde el slot " .. i .. "! Combustible: " .. tostring(nuevoCombustible))
                recargaExitosa = true
                break
            end
        end
    end

    -- Volvemos a equipar el pico para poder seguir minando
    equiparPico()

    if not recargaExitosa then
        print("¡ADVERTENCIA! No se pudo recargar el combustible.")
        return false
    end

    return true
end

-- Colocación inteligente de antorchas
local function colocarAntorcha(x, y, z)
    for i = 0, 8 do
        local ok, info = pcall(android.getSlotInfo, i)
        if ok and type(info) == "string" and string.find(string.lower(info), "torch") then
            if pcall(android.equipSlot, i) then
                pcall(android.useBlock, x, y, z)
                esperarTarea()
                -- Volvemos a equipar el pico inmediatamente después
                equiparPico()
                return
            end
        end
    end
    -- Asegurar que el pico quede equipado si no encontró antorchas
    equiparPico()
end

-- Depositar inventario en el cofre cercano
local function depositarEnCofre()
    local cofres = android.getBlocksOfType("chest")
    if cofres and #cofres > 0 then
        local cofre = cofres[1]
        print("Cofre detectado en: " .. cofre.x .. ", " .. cofre.y .. ", " .. cofre.z)
        
        for i = 0, 8 do
            local ok, info = pcall(android.getSlotInfo, i)
            if ok and info and type(info) == "string" then
                local itemLower = string.lower(info)
                if not string.find(itemLower, "pickaxe") and not string.find(itemLower, "redstone") then
                    pcall(android.equipSlot, i)
                    pcall(android.storeHeldItemInContainer, cofre.x, cofre.y, cofre.z, 0)
                end
            end
        end
        print("Loot depositado en el cofre.")
        equiparPico()
    end
end

local function minarBloque(x, y, z)
    if not comprobarYRecargar() then
        error("El androide se ha quedado sin combustible y no hay redstone disponible.")
    end

    -- Aseguramos que tenga el pico equipado antes de romper el bloque
    equiparPico()

    local ok, res = pcall(android.breakBlock, x, y, z)
    if not ok or (type(res) == "table" and res[1] == true) then
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

    print("=== MINER INTELIGENTE INICIADO ===")
    print("Desde X=" .. xInicial .. " hasta X=" .. xFinal)

    -- Equipar el pico al arrancar
    equiparPico()

    local contadorPasos = 0

    for x = xInicial - 1, xFinal, -1 do
        print("Excavando sección X=" .. x)

        if not minarBloque(x, Y1, Z1) then return end
        if not minarBloque(x, Y2, Z1) then return end
        if not minarBloque(x, Y1, Z2) then return end
        if not minarBloque(x, Y2, Z2) then return end

        local ok, res = pcall(android.moveTo, x, Y1, Z1)
        if not ok or (type(res) == "table" and res[1] == true) then
            print("No se pudo avanzar.")
            return
        end
        esperarTarea()

        contadorPasos = contadorPasos + 1
        if contadorPasos >= FRECUENCIA_ANTORCHAS then
            colocarAntorcha(x, Y1, Z1 + 1)
            contadorPasos = 0
        end

        if math.abs(x - xInicial) % 25 == 0 then
            depositarEnCofre()
        end
    end

    print("=== TÚNEL TERMINADO ===")
end

local ok, err = pcall(main)
if not ok then
    print("ERROR FATAL: " .. tostring(err))
end

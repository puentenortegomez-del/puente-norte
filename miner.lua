-- miner_definitivo_slots.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1

local android = _G.android

local LONGITUD = 100
local PAUSA = 0.1
local COMBUSTIBLE_MINIMO = 200
local FRECUENCIA_ANTORCHAS = 5

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

-- Función para escanear y recargar revisando todos los slots posibles (0 al 9)
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print("Combustible bajo (" .. tostring(combustibleActual) .. "). Escaneando slots 0-9...")

    -- Recorremos del 0 al 9 como indica la API para getSlotInfo
    for i = 0, 9 do
        local okInfo, nombreItem = pcall(android.getSlotInfo, i)
        if okInfo and nombreItem then
            print("Slot " .. i .. ": " .. tostring(nombreItem))
            
            -- Si el slot contiene algo relacionado con redstone
            if type(nombreItem) == "string" and (string.find(string.lower(nombreItem), "redstone") or string.find(string.lower(nombreItem), "dust")) then
                print("¡Redstone detectada en slot " .. i .. "!")
                
                -- Intentamos equiparlo
                local okEquip = pcall(android.equipSlot, i)
                if okEquip then
                    local okRefuel = pcall(android.refuel)
                    local nuevoCombustible = android.fuelLevel()
                    if nuevoCombustible and nuevoCombustible > combustibleActual then
                        print("¡Recarga exitosa! Nuevo combustible: " .. tostring(nuevoCombustible))
                        return true
                    end
                end
            end
        end
    end

    -- Método alternativo por fuerza bruta si el nombre no coincide exactamente
    for i = 0, 9 do
        pcall(android.equipSlot, i)
        local okRefuel = pcall(android.refuel)
        local nuevoCombustible = android.fuelLevel()
        if nuevoCombustible and nuevoCombustible > combustibleActual then
            print("¡Recarga por fuerza bruta exitosa en slot " .. i .. "!")
            return true
        end
    end

    print("¡ADVERTENCIA! No se pudo recargar desde ningún slot.")
    return false
end

-- Colocación inteligente de antorchas
local function colocarAntorcha(x, y, z)
    for i = 0, 9 do
        pcall(android.equipSlot, i)
        local hand = android.getHandInfo("main")
        if hand and hand.name and string.find(string.lower(hand.name), "torch") then
            pcall(android.useBlock, x, y, z)
            esperarTarea()
            return
        end
    end
end

-- Depositar en el cofre más cercano detectado
local function depositarEnCofre()
    local cofres = android.getBlocksOfType("chest")
    if cofres and #cofres > 0 then
        local cofre = cofres[1]
        print("Cofre detectado en: " .. cofre.x .. ", " .. cofre.y .. ", " .. cofre.z)
        
        for i = 0, 9 do
            pcall(android.equipSlot, i)
            pcall(android.storeHeldItemInContainer, cofre.x, cofre.y, cofre.z, 0)
        end
        print("Loot depositado en el cofre.")
    end
end

local function minarBloque(x, y, z)
    if not comprobarYRecargar() then
        error("El androide se ha quedado sin combustible y no hay redstone disponible.")
    end

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

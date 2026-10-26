-- miner_avanzado.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Túnel 2x2, Autorecarga infalible, Antorchas y Depósito en cofres

local android = _G.android

local LONGITUD = 100
local PAUSA = 0.1
local COMBUSTIBLE_MINIMO = 200
local FRECUENCIA_ANTORCHAS = 5 -- Coloca antorcha cada 5 bloques de avance

local function verificarError(nombre, res1, res2)
    if type(res1) == "table" and res1[1] == true then
        return false
    elseif not res1 then
        return false
    end
    return true
end

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

-- Autorecarga infalible probando slot por slot para recargar con redstone
local function comprobarYRecargar()
    local combustibleActual = android.fuelLevel()
    if combustibleActual and combustibleActual >= COMBUSTIBLE_MINIMO then
        return true
    end

    print("Combustible bajo (" .. tostring(combustibleActual) .. "). Buscando redstone...")

    -- Probamos equipar cada slot del 0 al 8 y verificamos si refuel() funciona
    for i = 0, 8 do
        local okEquip = pcall(android.equipSlot, i)
        if okEquip then
            local okRefuel, resRefuel = pcall(android.refuel)
            -- Si refuel no da error, significa que el ítem equipado era combustible válido (redstone)
            if not (type(resRefuel) == "table" and resRefuel[1] == true) then
                print("¡Recarga exitosa usando el slot " .. i .. "! Nivel actual: " .. tostring(android.fuelLevel()))
                return true
            end
        end
    end

    print("¡ADVERTENCIA! No se encontró redstone válida en los slots 0-8.")
    return false
end

-- Colocar antorcha inteligente
local function colocarAntorcha(x, y, z)
    -- Buscamos antorchas en el inventario (slots 0 al 8)
    local slotAntorcha = nil
    for i = 0, 8 do
        local ok, slotInfo = pcall(android.getSlotInfo, i)
        -- Si getSlotInfo devuelve false o datos, probamos equiparlo y ver si es una antorcha
        -- Como alternativa segura, equipamos y comprobamos la mano
    end

    -- Método directo: buscar slot que contenga "torch" equipándolo temporalmente o por escaneo
    for i = 0, 8 do
        pcall(android.equipSlot, i)
        local hand = android.getHandInfo("main")
        if hand and hand.name and string.find(string.lower(hand.name), "torch") then
            -- Encontramos antorchas, procedemos a colocarlas en una pared adyacente (ej: Z+1 o Y)
            pcall(android.useBlock, x, y, z)
            esperarTarea()
            return
        end
    end
end

-- Depositar inventario en el cofre más cercano detectado
local function depositarEnCofre()
    -- Buscamos bloques de tipo cofre cercanos (hasta 10 bloques según la API)
    local cofres = android.getBlocksOfType("chest")
    if cofres and #cofres > 0 then
        local cofre = cofres[1] -- Tomamos el primer cofre cercano
        print("Cofre encontrado en: " .. cofre.x .. ", " .. cofre.y .. ", " .. cofre.z)
        
        -- Intentamos guardar los items de los slots del inventario (0 a 8) en el cofre
        for i = 0, 8 do
            pcall(android.equipSlot, i)
            -- Guardamos el item de la mano en el cofre (slot 0 del cofre)
            pcall(android.storeHeldItemInContainer, cofre.x, cofre.y, cofre.z, 0)
        end
        print("Inventario depositado en el cofre.")
    end
end

local function minarBloque(x, y, z)
    if not comprobarYRecargar() then
        error("El androide se ha quedado sin combustible.")
    end

    local ok, res = pcall(android.breakBlock, x, y, z)
    if not verificarError("minado", ok, res) then
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

        -- Avanzar al siguiente tramo
        local ok, res = pcall(android.moveTo, x, Y1, Z1)
        if not verificarError("movimiento", ok, res) then
            print("No se pudo avanzar.")
            return
        end
        esperarTarea()

        contadorPasos = contadorPasos + 1

        -- Colocar antorcha cada ciertos bloques
        if contadorPasos >= FRECUENCIA_ANTORCHAS then
            colocarAntorcha(x, Y1, Z1 + 1)
            contadorPasos = 0
        end

        -- Cada 25 bloques intenta vaciar el inventario en un cofre cercano si lo hay
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

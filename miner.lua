-- miner.lua
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Tunel 2x2 hacia X negativo

local android = _G.android

local Z1 = -801
local Z2 = -802
local Y1 = 33
local Y2 = 34

local LONGITUD = 100
local PAUSA = 0.2

local function esperarTarea()
    local inicio = os.clock()
    local vioTarea = false

    while os.clock() - inicio < 30 do
        sleep(PAUSA)

        local tarea = android.currentTask()

        if tarea ~= "idle" then
            vioTarea = true
        elseif vioTarea then
            return true
        end
    end

    return false
end

local function ejecutar(nombre, funcion, ...)
    local ok, resultado = pcall(funcion, ...)

    if not ok then
        print("Error en " .. nombre .. ": " .. tostring(resultado))
        return false
    end

    if type(resultado) == "table" and resultado[1] == true then
        print("Error en " .. nombre .. ": " .. tostring(resultado[2]))
        return false
    end

    esperarTarea()
    return true
end

local function minarBloque(x, y, z)
    return ejecutar(
        "minado " .. x .. "," .. y .. "," .. z,
        android.breakBlock,
        x, y, z
    )
end

local function minarSeccion(x)
    -- Primera columna
    if not minarBloque(x, Y1, Z1) then return false end
    if not minarBloque(x, Y2, Z1) then return false end

    -- Segunda columna
    if not minarBloque(x, Y1, Z2) then return false end
    if not minarBloque(x, Y2, Z2) then return false end

    return true
end

local function main()
    local posicion = android.getSelf()
    local xInicial = math.floor(posicion.posX)
    local xFinal = xInicial - LONGITUD

    print("=== MINER INICIADO ===")
    print("Direccion: X negativo")
    print("Carriles Z: " .. Z1 .. " y " .. Z2)
    print("Alturas Y: " .. Y1 .. " y " .. Y2)
    print("Desde X=" .. xInicial .. " hasta X=" .. xFinal)

    for x = xInicial - 1, xFinal, -1 do
        print("Excavando X=" .. x)

        if not minarSeccion(x) then
            print("Miner detenido por un error.")
            return
        end

        -- Avanza al siguiente tramo por el mismo túnel.
        ejecutar("movimiento", android.moveTo, x, Y1, Z1)
    end

    print("=== TUNEL TERMINADO ===")
end

local ok, err = pcall(main)

if not ok then
    print("ERROR FATAL: " .. tostring(err))
end


-- miner.lua
-- CC:Androids 1.3.0 / Forge 1.20.1
-- Tunel 2x2 hacia X negativo

local a = _G.android

local Z1, Z2 = -801, -802
local Y1, Y2 = 33, 34
local LONGITUD = 100
local TIMEOUT = 30

local function posicion()
    local p = a.getSelf()
    return math.floor(p.posX), math.floor(p.posY), math.floor(p.posZ)
end

local function esperarFin(timeout)
    local inicio = os.clock()
    local activa = false

    repeat
        sleep(0.2)
        local tarea = a.currentTask()

        if tarea ~= "idle" then
            activa = true
        elseif activa then
            return true
        end
    until os.clock() - inicio >= timeout

    return a.currentTask() == "idle" and activa
end

local function ejecutar(nombre, funcion, x, y, z)
    a.cancelTask()
    sleep(0.2)

    local ok, resultado = pcall(funcion, x, y, z)

    if not ok then
        error(nombre .. ": " .. tostring(resultado))
    end

    if type(resultado) == "table" and resultado[1] == true then
        error(nombre .. ": " .. tostring(resultado[2]))
    end

    local tareaInicial = a.currentTask()

    if tareaInicial == "idle" then
        error(nombre .. ": CC:Androids no ha iniciado la tarea. Comprueba que el bloque objetivo sea sólido y alcanzable: " .. x .. "," .. y .. "," .. z)
    end

    if not esperarFin(TIMEOUT) then
        a.cancelTask()
        error(nombre .. ": tiempo agotado en " .. x .. "," .. y .. "," .. z)
    end
end

local function minar(x, y, z)
    ejecutar("Minado", a.breakBlock, x, y, z)
end

local function main()
    local p = a.getSelf()
    local xInicial = math.floor(p.posX)

    print("MINER: tunel 2x2 hacia X negativo")
    print("Inicio X=" .. xInicial .. " Y=" .. p.posY .. " Z=" .. p.posZ)

    for x = xInicial - 1, xInicial - LONGITUD, -1 do
        print("Minando X=" .. x)

        minar(x, Y1, Z1)
        minar(x, Y2, Z1)
        minar(x, Y1, Z2)
        minar(x, Y2, Z2)

        -- Solo avanza después de minar las cuatro posiciones.
        ejecutar("Movimiento", a.moveTo, x, Y1, Z1)
    end

    print("MINER: tunel terminado")
end

local ok, err = pcall(main)

if not ok then
    a.cancelTask()
    print("MINER DETENIDO: " .. tostring(err))
end

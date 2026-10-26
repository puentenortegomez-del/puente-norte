
-- CC:Androids 1.3.0 - Tunel continuo
-- Direccion: X negativo
-- Posicion de trabajo: Y=33
-- Suelo Y=33: NO ROMPER
-- Excavacion: Y=34 y Y=35
-- Ancho: 3 bloques
-- Longitud: infinita

local android = _G.android

local FLOOR_Y = 33
local WORK_Y = 33
local CENTER_Z = -801
local WIDTH = 3
local HEIGHT = 2
local WAIT_DELAY = 0.25
local MAX_WAIT = 120

local function getPosition()
    local p = android.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo leer la posicion del androide")
    end

    return p
end

local function waitIdle()
    for i = 1, MAX_WAIT do
        local ok, task = pcall(function()
            return android.currentTask()
        end)

        if ok and task == "idle" then
            return
        end

        sleep(WAIT_DELAY)
    end

    error("La tarea anterior no ha terminado")
end

local function runTask(method, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return android[method](x, y, z)
    end)

    if not ok then
        error(method .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(method .. ": " .. tostring(result[2]))
    end

    waitIdle()
end

local function mineFace(x, z)
    -- Romper solo los bloques por encima del suelo.
    -- Nunca se llama a breakBlock para Y=33.
    for y = FLOOR_Y + 1, FLOOR_Y + HEIGHT do
        for dz = -1, 1 do
            runTask("breakBlock", x, y, z + dz)
        end
    end
end

local function main()
    local p = getPosition()
    local x = p.posX
    local z = p.posZ

    print("Tunel continuo iniciado")
    print("Direccion: X negativo")
    print("Posicion de trabajo: Y=33")
    print("Suelo Y=33 protegido")
    print("Excavacion: Y=34 y Y=35")

    while true do
        local nextX = x - 1

        -- Excavar la siguiente seccion.
        mineFace(nextX, z)

        -- Mantener Y=33 al avanzar.
        runTask("moveTo", nextX, WORK_Y, z)

        local current = getPosition()

        if current.posX >= x then
            error(
                "No avanzo hacia X negativo. X actual="
                .. tostring(current.posX)
            )
        end

        x = current.posX
        z = current.posZ

        print("Avance correcto: X=" .. tostring(x))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        android.cancelTask()
    end)

    print("MINADO DETENIDO: " .. tostring(err))
end


-- CC:Androids 1.3.0 - Tunel continuo
-- Direccion X negativa
-- Ancho: 3 bloques
-- Alto: 2 bloques
-- No romper Y=33
-- Longitud ilimitada

local a = _G.android

local FLOOR_Y = 33
local TUNNEL_HEIGHT = 2
local WIDTH = 3
local WAIT_DELAY = 0.25
local MAX_WAIT = 120

local function getPos()
    local p = a.getSelf()
    if not p or p.posX == nil or p.posY == nil or p.posZ == nil then
        error("No se pudo obtener la posicion")
    end
    return p
end

local function waitIdle()
    for i = 1, MAX_WAIT do
        local ok, task = pcall(function()
            return a.currentTask()
        end)
        if ok and task == "idle" then
            return
        end
        sleep(WAIT_DELAY)
    end
    error("Tiempo agotado esperando la tarea")
end

local function runTask(method, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return a[method](x, y, z)
    end)

    if not ok then
        error(method .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(method .. ": " .. tostring(result[2]))
    end

    waitIdle()
end

local function mineFace(blockX, centerZ)
    -- Solo se excavan Y=34 e Y=35.
    -- Y=33 nunca se pasa a breakBlock().
    for y = FLOOR_Y + 1, FLOOR_Y + TUNNEL_HEIGHT do
        for dz = -1, 1 do
            runTask(
                "breakBlock",
                blockX,
                y,
                centerZ + dz
            )
        end
    end
end

local function main()
    local p = getPos()

    -- Separar las coordenadas enteras de los bloques
    -- de la posicion fisica, que puede tener decimales.
    local blockX = math.floor(p.posX)
    local centerZ = math.floor(p.posZ)

    print("Minero iniciado")
    print("Posicion inicial X=" .. tostring(p.posX)
        .. " Y=" .. tostring(p.posY)
        .. " Z=" .. tostring(p.posZ))
    print("Siguiente bloque X=" .. tostring(blockX - 1))
    print("Suelo Y=33 protegido")

    while true do
        local nextX = blockX - 1

        print("Excavando columna X=" .. tostring(nextX))

        -- Limpiar la siguiente seccion.
        mineFace(nextX, centerZ)

        -- No usar la posicion decimal para calcular
        -- el siguiente bloque.
        runTask(
            "moveTo",
            nextX,
            p.posY,
            centerZ
        )

        local current = getPos()

        -- Comprobar el avance por bloque, no por decimales.
        local currentBlockX = math.floor(current.posX)

        if currentBlockX >= blockX then
            error(
                "No entro en el siguiente bloque. "
                .. "Objetivo X=" .. tostring(nextX)
                .. ", posicion X=" .. tostring(current.posX)
            )
        end

        blockX = nextX
        p = current

        print("Bloque alcanzado. Siguiente X="
            .. tostring(blockX - 1))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        a.cancelTask()
    end)
    print("MINADO DETENIDO: " .. tostring(err))
end

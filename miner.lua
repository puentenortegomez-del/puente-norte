
-- CC:Androids 1.3.0 - Tunel continuo
-- Direccion: X negativo
-- Seccion: 3 ancho x 2 alto
-- Suelo: Y=33 (no romper)
-- Bloques excavados: Y=34 y Y=35
-- Sin limite de longitud

local a = _G.android

local FLOOR_Y = 33
local CENTER_Z = -801
local WIDTH = 3
local HEIGHT = 2
local WAIT_DELAY = 0.25
local MAX_WAIT = 120

local function getPosition()
    local p = a.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo leer la posicion del androide")
    end

    return p
end

local function waitIdle()
    local checks = 0

    while checks < MAX_WAIT do
        local ok, task = pcall(function()
            return a.currentTask()
        end)

        if ok and task == "idle" then
            return
        end

        sleep(WAIT_DELAY)
        checks = checks + 1
    end

    error("La tarea anterior no termina")
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

local function mineFace(x, centerZ)
    -- Excavar exclusivamente Y=34 e Y=35.
    -- No se rompe ningun bloque en Y=33.
    for y = FLOOR_Y + 1, FLOOR_Y + HEIGHT do
        for dz = -1, 1 do
            runTask(
                "breakBlock",
                x,
                y,
                centerZ + dz
            )
        end
    end
end

local function main()
    -- Aceptar la posicion real, sea cual sea su altura.
    local p = getPosition()
    local x = p.posX
    local z = p.posZ

    print("Mineria continua iniciada")
    print("Posicion inicial: X=" .. tostring(p.posX)
        .. " Y=" .. tostring(p.posY)
        .. " Z=" .. tostring(p.posZ))
    print("Direccion: X negativo")
    print("Suelo protegido: Y=33")
    print("Altura excavada: Y=34 y Y=35")

    while true do
        local targetX = x - 1

        -- Despejar la siguiente cara del tunel.
        mineFace(targetX, z)

        -- Leer la altura real; no exigir Y=34.
        local current = getPosition()

        runTask(
            "moveTo",
            targetX,
            current.posY,
            current.posZ
        )

        local nextPos = getPosition()

        if nextPos.posX >= x then
            error(
                "No avanzo hacia X negativo. "
                .. "X anterior=" .. tostring(x)
                .. ", X actual=" .. tostring(nextPos.posX)
            )
        end

        x = nextPos.posX
        z = nextPos.posZ

        print("Avance correcto: X=" .. tostring(x))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        a.cancelTask()
    end)

    print("MINADO DETENIDO: " .. tostring(err))
end

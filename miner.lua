
-- CC:Androids 1.3.0
-- Tunel recto hacia X negativo
-- Seccion: 3 bloques de ancho x 2 de alto
-- Suelo Y=33 protegido: nunca se rompe
-- Excavacion: Y=34 y Y=35
-- Longitud ilimitada

local a = _G.android

local FLOOR_Y = 33
local HEIGHT = 2
local WIDTH = 3
local WAIT_DELAY = 0.25
local MAX_WAIT = 120

local function getPos()
    local p = a.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo obtener la posicion del androide")
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

    error("La tarea anterior no ha terminado")
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
    -- Centro primero y luego los laterales.
    -- Nunca se rompe Y=33.
    local offsets = {0, -1, 1}

    for y = FLOOR_Y + 1, FLOOR_Y + HEIGHT do
        for i = 1, #offsets do
            runTask(
                "breakBlock",
                x,
                y,
                centerZ + offsets[i]
            )
        end
    end
end

local function main()
    local p = getPos()

    -- Mantener la altura y el eje Z iniciales.
    local x = math.floor(p.posX)
    local workY = p.posY
    local centerZ = math.floor(p.posZ)

    print("Tunel recto iniciado")
    print("Posicion inicial X=" .. tostring(p.posX)
        .. " Y=" .. tostring(p.posY)
        .. " Z=" .. tostring(p.posZ))
    print("Direccion: X negativo")
    print("Suelo Y=33 protegido")

    while true do
        local nextX = x - 1

        print("Excavando seccion X=" .. tostring(nextX))

        -- Excavar la cara siguiente.
        mineFace(nextX, centerZ)

        -- Regresar al eje central y avanzar.
        -- No se cambia la altura de trabajo.
        runTask(
            "moveTo",
            nextX,
            workY,
            centerZ
        )

        local current = getPos()
        local currentBlockX = math.floor(current.posX)

        if currentBlockX >= x then
            error(
                "No avanzo hacia X negativo. X="
                .. tostring(current.posX)
                .. " Z=" .. tostring(current.posZ)
            )
        end

        -- Usar el bloque real alcanzado, no una suposicion.
        x = currentBlockX
        workY = current.posY

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

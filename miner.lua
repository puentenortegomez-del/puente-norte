
-- CC:Androids 1.3.0
-- Tunel recto hacia X negativo
-- Ancho 3, alto 2
-- Suelo Y=33 protegido

local a = _G.android

local FLOOR_Y = 33
local CENTER_Z = -802
local HEIGHT = 2
local WIDTH = 3
local WAIT_DELAY = 0.25
local MAX_WAIT = 120

local function getPos()
    return a.getSelf()
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

    error("La tarea no termina")
end

local function runTask(name, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return a[name](x, y, z)
    end)

    if not ok then
        error(name .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(name .. ": " .. tostring(result[2]))
    end

    waitIdle()
end

local function mineFace(x)
    -- Centro primero, despues los dos laterales.
    local offsets = {0, -1, 1}

    for y = FLOOR_Y + 1, FLOOR_Y + HEIGHT do
        for i = 1, #offsets do
            runTask(
                "breakBlock",
                x,
                y,
                CENTER_Z + offsets[i]
            )
        end
    end
end

local function main()
    local p = getPos()
    local x = math.floor(p.posX)

    print("Tunel recto iniciado")
    print("Direccion: X negativo")
    print("Eje fijo Z=" .. CENTER_Z)
    print("Suelo Y=33 protegido")

    while true do
        local nextX = x - 1

        mineFace(nextX)

        -- Avanzar por el eje central, sin cambiar Z.
        runTask(
            "moveTo",
            nextX,
            p.posY,
            CENTER_Z
        )

        local current = getPos()

        if math.floor(current.posX) >= x then
            error(
                "No avanzo. Posicion: X="
                .. tostring(current.posX)
                .. " Z=" .. tostring(current.posZ)
            )
        end

        x = nextX
        p = current

        print("Avance recto: X=" .. tostring(x))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        a.cancelTask()
    end)
    print("MINADO DETENIDO: " .. tostring(err))
end

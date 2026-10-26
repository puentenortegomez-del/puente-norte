
-- CC:Androids 1.3.0 - Tunel continuo
-- Direccion: X NEGATIVO
-- Tunel: 3 bloques de ancho x 2 de alto
-- Detener: cancelar la tarea desde el control del androide

local a = _G.android

local WIDTH = 3
local HEIGHT = 2
local STEP_DELAY = 0.25

local function waitIdle()
    while true do
        local ok, task = pcall(function()
            return a.currentTask()
        end)

        if ok and task == "idle" then
            return
        end

        sleep(STEP_DELAY)
    end
end

local function call(method, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return a[method](x, y, z)
    end)

    if not ok then
        error(method .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(tostring(result[2]))
    end

    waitIdle()
end

local function mineFace(x, y, z)
    local half = math.floor(WIDTH / 2)

    -- Primero el centro y luego los laterales.
    local offsets = {0, -1, 1}

    for h = 0, HEIGHT - 1 do
        for i = 1, #offsets do
            local targetZ = z + offsets[i]
            call("breakBlock", x, y + h, targetZ)
        end
    end
end

local function main()
    local self = a.getSelf()
    local y = self.posY
    local z = self.posZ
    local x = self.posX

    print("Mineria continua hacia X negativo")
    print("Inicio: X=" .. x .. " Y=" .. y .. " Z=" .. z)

    while true do
        local nextX = x - 1

        -- Despejar la siguiente seccion.
        mineFace(nextX, y, z)

        -- Avanzar un bloque hacia X negativo.
        call("moveTo", nextX, y, z)

        -- No usar una coordenada supuesta para el siguiente tramo.
        local current = a.getSelf()

        if current.posX >= x then
            error(
                "El androide no avanzo hacia X negativo. " ..
                "Posicion actual X=" .. current.posX
            )
        end

        x = current.posX
        y = current.posY
        z = current.posZ
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        a.cancelTask()
    end)
    print("MINADO INTERRUMPIDO: " .. tostring(err))
end

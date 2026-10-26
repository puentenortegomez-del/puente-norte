
-- miner.lua
-- CC:Androids 1.3.0 / Minecraft Forge 1.20.1
-- Tunel hacia X negativo
-- Seccion: 3 de ancho (eje Z) x 2 de alto
-- Suelo protegido: Y=33
-- Excavacion: Y=34 y Y=35

local a = _G.android

local FLOOR_Y = 33
local HEIGHT_TOP = 35
local WAIT_STEP = 0.2
local MAX_WAIT = 300

-- Comprueba si la API esta disponible
if not a or not a.getSelf or not a.breakBlock
    or not a.moveTo or not a.currentTask then
    error("API de CC:Androids no disponible")
end

local function getPos()
    local p = a.getSelf()
    if type(p) ~= "table"
        or type(p.posX) ~= "number"
        or type(p.posY) ~= "number"
        or type(p.posZ) ~= "number" then
        error("No se pudo leer la posicion real del androide")
    end
    return p
end

local function waitIdle()
    local waited = 0
    while a.currentTask() ~= "idle" do
        sleep(WAIT_STEP)
        waited = waited + WAIT_STEP
        if waited >= MAX_WAIT then
            error("Tiempo agotado esperando a que termine la tarea")
        end
    end
end

local function execute(method, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return a[method](x, y, z)
    end)

    if not ok then
        error(method .. " fallo: " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(method .. " fallo: " .. tostring(result[2]))
    end

    waitIdle()
end

local function breakSafe(x, y, z)
    -- Nunca ordenar romper el suelo ni bloques inferiores
    if y <= FLOOR_Y then
        return
    end

    execute("breakBlock", x, y, z)
end

local function main()
    local p = getPos()

    -- Coordenadas iniciales reales, incluidos los decimales
    local centerZ = math.floor(p.posZ + 0.5)
    local workY = p.posY
    local currentX = p.posX

    print("Tunel recto iniciado")
    print("Inicio X=" .. currentX ..
        " Y=" .. p.posY .. " Z=" .. p.posZ)
    print("Direccion: X negativo")
    print("Centro Z=" .. centerZ)
    print("Suelo Y=33 protegido")
    print("Excavacion: Y=34 y Y=35")

    while true do
        -- Cada seccion corresponde al siguiente bloque en X negativo.
        -- Se usa la posicion REAL actual, no una coordenada inicial fija.
        local targetX = math.floor(currentX) - 1

        print("Excavando seccion X=" .. targetX)

        -- Excavar primero el centro y luego los laterales.
        breakSafe(targetX, 34, centerZ)
        breakSafe(targetX, 35, centerZ)

        breakSafe(targetX, 34, centerZ - 1)
        breakSafe(targetX, 35, centerZ - 1)

        breakSafe(targetX, 34, centerZ + 1)
        breakSafe(targetX, 35, centerZ + 1)

        -- Volver al eje central a la altura de trabajo original.
        execute("moveTo", targetX, workY, centerZ)

        local after = getPos()

        -- Tolerancia para coordenadas decimales del movimiento.
        if after.posX >= currentX - 0.05 then
            error("No avanzo hacia X negativo. X anterior=" ..
                currentX .. " X actual=" .. after.posX)
        end

        if math.abs(after.posZ - centerZ) > 1.0 then
            error("Desvio lateral detectado. Z actual=" ..
                after.posZ .. " Z objetivo=" .. centerZ)
        end

        currentX = after.posX
        print("Avance correcto: X=" .. currentX ..
            " Z=" .. after.posZ)
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        a.cancelTask()
    end)
    print("MINADO DETENIDO: " .. tostring(err))
end

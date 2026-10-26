
-- CC:Androids 1.3.0
-- Tunel recto hacia X negativo
-- Ancho: 3 bloques (Z - 1, Z, Z + 1)
-- Altura: Y=34 y Y=35
-- Suelo Y=33 protegido

local a = _G.android

local FLOOR_Y = 33
local CENTER_Z = -801
local START_X = 2212
local WORK_Y = 32
local WAIT_TIME = 0.2
local MAX_WAIT = 600

local function position()
    local p = a.getSelf()
    return p.posX, p.posY, p.posZ
end

local function waitIdle()
    local elapsed = 0
    while a.currentTask() ~= "idle" do
        sleep(WAIT_TIME)
        elapsed = elapsed + WAIT_TIME
        if elapsed >= MAX_WAIT then
            error("Tiempo agotado esperando al androide")
        end
    end
end

local function run(method, x, y, z)
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

local function mineBlock(x, y, z)
    -- Protección absoluta del suelo
    if y <= FLOOR_Y then
        return
    end

    run("breakBlock", x, y, z)
end

local function main()
    local x = START_X

    print("MINERO: avance hacia X negativo")
    print("Inicio: X=2212 Y=32 Z=-801")
    print("Suelo Y=33 protegido")
    print("Excavacion: Y=34 y Y=35")

    while true do
        local targetX = x - 1

        print("Excavando seccion X=" .. targetX)

        -- Primero despejar la parte central y superior.
        mineBlock(targetX, 34, CENTER_Z)
        mineBlock(targetX, 35, CENTER_Z)

        -- Después los laterales, sin tocar el suelo.
        mineBlock(targetX, 34, CENTER_Z - 1)
        mineBlock(targetX, 35, CENTER_Z - 1)
        mineBlock(targetX, 34, CENTER_Z + 1)
        mineBlock(targetX, 35, CENTER_Z + 1)

        -- Volver al eje central antes de continuar.
        run("moveTo", targetX, WORK_Y, CENTER_Z)

        local px, py, pz = position()
        print("Posicion actual: X=" .. px ..
              " Y=" .. py .. " Z=" .. pz)

        -- No continuar si no ha alcanzado la siguiente sección.
        if px > targetX + 0.8 or px < targetX - 1.8 then
            error("Posicion inesperada en X: " .. px)
        end

        if math.abs(pz - CENTER_Z) > 0.8 then
            error("Se ha desviado del eje Z: " .. pz)
        end

        x = targetX
    end
end

local ok, err = pcall(main)
if not ok then
    pcall(function() a.cancelTask() end)
    print("MINADO DETENIDO: " .. tostring(err))
end

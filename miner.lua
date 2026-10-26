
-- miner.lua
-- CC:Androids 1.3.0
-- Tunel hacia X negativo
-- Ancho: Z=-801 y Z=-802
-- Alto: Y=33 y Y=34

local a = _G.android

local Z1, Z2 = -801, -802
local Y1, Y2 = 33, 34
local WAIT = 0.2
local TIMEOUT = 300

local function getPos()
    local p = a.getSelf()
    if type(p) ~= "table"
        or type(p.posX) ~= "number"
        or type(p.posY) ~= "number"
        or type(p.posZ) ~= "number" then
        error("No se pudo leer la posicion del androide")
    end
    return p
end

local function waitIdle()
    local elapsed = 0
    while a.currentTask() ~= "idle" do
        sleep(WAIT)
        elapsed = elapsed + WAIT
        if elapsed >= TIMEOUT then
            error("Tiempo agotado esperando la tarea")
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

local function mineSection(x)
    -- Romper solo las cuatro posiciones del tunel.
    run("breakBlock", x, Y1, Z1)
    run("breakBlock", x, Y2, Z1)
    run("breakBlock", x, Y1, Z2)
    run("breakBlock", x, Y2, Z2)
end

local function main()
    local p = getPos()
    local currentX = math.floor(p.posX)

    print("Tunel hacia X negativo")
    print("Inicio X=" .. p.posX ..
        " Y=" .. p.posY .. " Z=" .. p.posZ)
    print("Ancho: Z=-801 y Z=-802")
    print("Altura: Y=33 y Y=34")

    while true do
        local targetX = currentX - 1
        print("Excavando X=" .. targetX)

        mineSection(targetX)

        -- Actualizar siempre la posicion real despues de excavar.
        p = getPos()
        currentX = math.floor(p.posX)

        -- Continuar desde la siguiente seccion en X negativo.
        targetX = currentX - 1
        run("moveTo", targetX, Y1, Z1)

        p = getPos()
        currentX = math.floor(p.posX)

        print("Posicion actual X=" .. p.posX ..
            " Y=" .. p.posY .. " Z=" .. p.posZ)
    end
end

local ok, err = pcall(main)
if not ok then
    pcall(function() a.cancelTask() end)
    print("MINADO DETENIDO: " .. tostring(err))
end

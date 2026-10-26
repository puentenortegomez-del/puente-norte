
-- miner.lua
-- CC:Androids 1.3.0
-- Tunel recto hacia X negativo
-- Ancho: Z=-801 y Z=-802
-- Alto: Y=33 y Y=34

local a = _G.android

local Z1 = -801
local Z2 = -802
local Y1 = 33
local Y2 = 34
local WAIT = 0.2
local TIMEOUT = 300

local function pos()
    local p = a.getSelf()
    if not p or type(p.posX) ~= "number" then
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
            error("Tiempo agotado esperando una tarea")
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
    -- Excava solo las cuatro posiciones de la seccion.
    run("breakBlock", x, Y1, Z1)
    run("breakBlock", x, Y2, Z1)
    run("breakBlock", x, Y1, Z2)
    run("breakBlock", x, Y2, Z2)
end

local function main()
    local p = pos()
    local currentX = math.floor(p.posX)

    print("Tunel iniciado hacia X negativo")
    print("Carriles: Z=-801 y Z=-802")
    print("Altura: Y=33 y Y=34")
    print("Posicion inicial X=" .. p.posX ..
        " Y=" .. p.posY .. " Z=" .. p.posZ)

    while true do
        local targetX = currentX - 1
        print("Excavando X=" .. targetX)

        mineSection(targetX)

        -- Al terminar la seccion, avanza por el carril Z=-801.
        run("moveTo", targetX, Y1, Z1)

        local after = pos()

        if after.posX >= currentX then
            error("No avanzo hacia X negativo. X=" .. after.posX)
        end

        currentX = math.floor(after.posX)
        print("Avance confirmado: X=" .. after.posX)
    end
end

local ok, err = pcall(main)
if not ok then
    pcall(function() a.cancelTask() end)
    print("MINADO DETENIDO: " .. tostring(err))
end


-- miner.lua
-- CC:Androids 1.3.0
-- Tunel hacia X negativo
-- Carriles Z=-801 y Z=-802
-- Alturas Y=33 y Y=34

local a = _G.android

local ZS = {-801, -802}
local YS = {33, 34}
local WAIT = 0.2
local TIMEOUT = 300

local function position()
    local p = a.getSelf()
    assert(type(p) == "table" and type(p.posX) == "number",
        "No se puede leer la posicion")
    return p
end

local function waitIdle()
    local t = 0
    while a.currentTask() ~= "idle" do
        sleep(WAIT)
        t = t + WAIT
        if t >= TIMEOUT then
            error("Tiempo agotado esperando al androide")
        end
    end
end

local function task(method, x, y, z)
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
    for _, z in ipairs(ZS) do
        for _, y in ipairs(YS) do
            task("breakBlock", x, y, z)
        end
    end
end

local function main()
    local p = position()
    local nextX = math.floor(p.posX) - 1

    print("MINER V2 iniciado")
    print("Direccion: X negativo")
    print("Z=-801 y Z=-802; Y=33 y Y=34")
    print("Posicion inicial: X=" .. p.posX ..
        " Y=" .. p.posY .. " Z=" .. p.posZ)

    while true do
        print("Picando seccion X=" .. nextX)
        mineSection(nextX)

        -- Actualizar el objetivo desde la posicion real.
        p = position()
        local reachedX = math.floor(p.posX)

        -- Si el androide no avanzo, intentar acercarlo al eje.
        if reachedX > nextX then
            task("moveTo", nextX, 33, -801)
            p = position()
            reachedX = math.floor(p.posX)
        end

        print("Posicion actual: X=" .. p.posX ..
            " Y=" .. p.posY .. " Z=" .. p.posZ)

        nextX = math.min(nextX - 1, reachedX - 1)
    end
end

local ok, err = pcall(main)
if not ok then
    pcall(function() a.cancelTask() end)
    print("MINADO DETENIDO: " .. tostring(err))
end

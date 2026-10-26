
-- CC:Androids 1.3.0 - Minero
-- Direccion: X NEGATIVO
-- Tunel: 3 ancho x 2 alto
-- Salas: 16 x 16 x 16, cada 16 bloques de avance

local android = _G.android

local CFG = {
    startX = 2212,
    startY = 32,
    startZ = -801,

    length = 40,
    width = 3,
    height = 2,

    roomEvery = 16,
    roomSizeX = 16,
    roomSizeY = 16,
    roomSizeZ = 16,

    waitLimit = 240
}

local function waitIdle()
    local checks = 0

    while checks < CFG.waitLimit do
        local ok, task = pcall(function()
            return android.currentTask()
        end)

        if ok and task == "idle" then
            return true
        end

        sleep(0.25)
        checks = checks + 1
    end

    return false
end

local function runTask(method, x, y, z)
    if not waitIdle() then
        error("El androide no termino la tarea anterior.")
    end

    local ok, result = pcall(function()
        return android[method](x, y, z)
    end)

    if not ok then
        error("Fallo " .. method .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error("Error de la API: " .. tostring(result[2]))
    end

    if not waitIdle() then
        error("Tiempo agotado esperando a " .. method)
    end
end

local function mineBlock(x, y, z)
    runTask("breakBlock", x, y, z)
end

-- Excava una cara vertical delante del androide.
-- X siempre disminuye.
local function clearTunnelFace(x)
    local halfWidth = math.floor(CFG.width / 2)

    for y = CFG.startY, CFG.startY + CFG.height - 1 do
        for z = CFG.startZ - halfWidth,
                 CFG.startZ + halfWidth do
            mineBlock(x, y, z)
        end
    end
end

-- Sala situada a un lado del tunel.
-- El tunel pasa por el centro de la pared de entrada.
local function clearRoom(backX)
    local halfWidth = math.floor(CFG.roomSizeZ / 2)
    local minZ = CFG.startZ - halfWidth
    local minY = CFG.startY

    print("Excavando sala en X=" .. backX)

    -- Cada capa avanza en X negativo.
    for dx = 1, CFG.roomSizeX do
        local x = backX - dx

        for dy = 0, CFG.roomSizeY - 1 do
            for dz = 0, CFG.roomSizeZ - 1 do
                mineBlock(x, minY + dy, minZ + dz)
            end
        end
    end

    print("Sala terminada en X=" .. (backX - CFG.roomSizeX))
end

local function main()
    print("Minero iniciado: direccion X negativa")
    print("Tunel 3x2; longitud " .. CFG.length)

    for step = 1, CFG.length do
        local nextX = CFG.startX - step

        print("Despejando tramo X=" .. nextX)
        clearTunnelFace(nextX)

        -- Avanza solo cuando la cara esta despejada.
        runTask("moveTo", nextX, CFG.startY, CFG.startZ)

        if step % CFG.roomEvery == 0 then
            clearRoom(nextX)
        end
    end

    print("Recorrido terminado.")
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        android.cancelTask()
    end)
    print("MINADO DETENIDO: " .. tostring(err))
end

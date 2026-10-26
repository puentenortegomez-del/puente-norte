
-- CC:Androids 1.3.0 - Tunel continuo
-- Forge 1.20.1
-- Direccion: X NEGATIVO
-- Tunel: 3 ancho x 2 alto
-- Suelo: Y=33 (NO ROMPER)
-- Bloques excavados: Y=34 y Y=35

local android = _G.android

local CFG = {
    floorY = 33,
    centerZ = -801,
    width = 3,
    height = 2,
    waitDelay = 0.25,
    maxWait = 120
}

local function getPosition()
    local p = android.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo obtener la posicion del androide")
    end

    return p
end

local function waitIdle()
    local count = 0

    while count < CFG.maxWait do
        local ok, task = pcall(function()
            return android.currentTask()
        end)

        if ok and task == "idle" then
            return
        end

        sleep(CFG.waitDelay)
        count = count + 1
    end

    error("Tiempo agotado esperando a que termine la tarea")
end

local function runTask(method, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return android[method](x, y, z)
    end)

    if not ok then
        error(method .. ": " .. tostring(result))
    end

    if type(result) == "table" and result[1] == true then
        error(method .. ": " .. tostring(result[2]))
    end

    waitIdle()
end

local function mineFace(x, z)
    -- Nunca se llama a breakBlock en Y=33.
    for y = CFG.floorY + 1,
            CFG.floorY + CFG.height do
        for dz = -1, 1 do
            runTask(
                "breakBlock",
                x,
                y,
                z + dz
            )
        end
    end
end

local function main()
    local p = getPosition()

    -- Respetar la posicion real del androide.
    local x = p.posX
    local y = p.posY
    local z = p.posZ

    print("Tunel continuo iniciado")
    print("Inicio X=" .. tostring(x)
        .. " Y=" .. tostring(y)
        .. " Z=" .. tostring(z))
    print("Direccion: X negativo")
    print("Suelo protegido: Y=33")
    print("Excavacion: Y=34 y Y=35")

    while true do
        local targetX = x - 1

        -- Despejar la siguiente cara.
        mineFace(targetX, z)

        -- Entrar en el tramo despejado manteniendo
        -- la altura y la profundidad reales.
        runTask("moveTo", targetX, y, z)

        local current = getPosition()

        if current.posX >= x then
            error(
                "El androide no avanzo hacia X negativo. "
                .. "X anterior=" .. tostring(x)
                .. ", X actual=" .. tostring(current.posX)
            )
        end

        x = current.posX
        y = current.posY
        z = current.posZ

        print("Avance correcto: X=" .. tostring(x))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        android.cancelTask()
    end)

    print("MINADO DETENIDO: " .. tostring(err))
end


-- CC:Androids 1.3.0 - Tunel continuo
-- Minecraft Forge 1.20.1
-- Direccion: X NEGATIVO
-- Tunel: 3 bloques de ancho x 2 de alto
-- Suelo conservado: Y=33
-- Espacio excavado: Y=34 y Y=35
-- Sin limite de longitud

local a = _G.android

local CFG = {
    floorY = 33,
    centerZ = -801,
    width = 3,
    height = 2,
    waitDelay = 0.25,
    maxWait = 120
}

local running = true

local function getPosition()
    local p = a.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo leer la posicion del androide.")
    end

    return p
end

local function waitIdle()
    local count = 0

    while count < CFG.maxWait do
        local ok, task = pcall(function()
            return a.currentTask()
        end)

        if ok and task == "idle" then
            return true
        end

        sleep(CFG.waitDelay)
        count = count + 1
    end

    error("La tarea no termina. Se cancela el minado.")
end

local function runTask(method, x, y, z)
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

local function mineFace(x)
    local half = math.floor(CFG.width / 2)

    -- Romper solo la cara inmediata.
    -- Nunca se excava el suelo Y=33.
    for y = CFG.floorY + 1,
            CFG.floorY + CFG.height do
        for _, dz in ipairs({0, -1, 1}) do
            runTask(
                "breakBlock",
                x,
                y,
                CFG.centerZ + dz
            )
        end
    end
end

local function main()
    local initial = getPosition()

    if initial.posY ~= CFG.floorY + 1 then
        error(
            "Coloca el androide dentro del tunel a Y=34. " ..
            "Posicion actual Y=" .. tostring(initial.posY)
        )
    end

    if initial.posZ ~= CFG.centerZ then
        error(
            "Coloca el androide en Z=" ..
            tostring(CFG.centerZ) ..
            ". Posicion actual Z=" .. tostring(initial.posZ)
        )
    end

    local x = initial.posX

    print("Tunel infinito iniciado")
    print("Direccion: X negativo")
    print("Suelo: Y=33; altura libre: Y=34-35")

    while running do
        local previousX = x
        local nextX = previousX - 1

        -- Primero despejar la siguiente seccion.
        mineFace(nextX)

        -- Entrar en la seccion despejada.
        runTask(
            "moveTo",
            nextX,
            CFG.floorY + 1,
            CFG.centerZ
        )

        local current = getPosition()

        -- No permitir que el script continue si retrocede
        -- o no consigue avanzar.
        if current.posX >= previousX then
            error(
                "El androide no avanzo hacia X negativo. " ..
                "X anterior=" .. tostring(previousX) ..
                ", X actual=" .. tostring(current.posX)
            )
        end

        x = current.posX
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

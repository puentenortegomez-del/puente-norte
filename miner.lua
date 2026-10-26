
-- CC:Androids 1.3.0 - Tunel continuo
-- Minecraft Forge 1.20.1
--
-- Direccion: X NEGATIVO
-- Ancho: 3 bloques
-- Alto: 2 bloques
-- Suelo: Y=33 (NO SE ROMPE)
-- Espacio excavado: Y=34 y Y=35
-- Longitud: infinita

local android = _G.android

local CFG = {
    floorY = 33,
    centerZ = -801,
    width = 3,
    height = 2,
    waitDelay = 0.25,
    maxWait = 120
}

local function position()
    local p = android.getSelf()

    if type(p) ~= "table"
        or p.posX == nil
        or p.posY == nil
        or p.posZ == nil then
        error("No se pudo leer la posicion del androide")
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

local function runTask(name, x, y, z)
    waitIdle()

    local ok, result = pcall(function()
        return android[name](x, y, z)
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
    local halfWidth = math.floor(CFG.width / 2)

    -- Solo se rompen bloques en Y=34 e Y=35.
    -- Y=33 nunca se pasa a breakBlock().
    for y = CFG.floorY + 1,
            CFG.floorY + CFG.height do

        for dz = -halfWidth, halfWidth do
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
    local p = position()

    if p.posY ~= CFG.floorY + 1 then
        error(
            "El androide debe estar a Y=34. Posicion actual: Y="
            .. tostring(p.posY)
        )
    end

    if p.posZ ~= CFG.centerZ then
        error(
            "El androide debe estar en Z="
            .. tostring(CFG.centerZ)
            .. ". Posicion actual: Z="
            .. tostring(p.posZ)
        )
    end

    local x = p.posX

    print("Mineria continua iniciada")
    print("Direccion: X negativo")
    print("Suelo intacto: Y=33")
    print("Altura excavada: Y=34 y Y=35")

    while true do
        local targetX = x - 1

        -- 1. Excavar la siguiente seccion.
        mineFace(targetX)

        -- 2. Avanzar hacia X negativo.
        runTask(
            "moveTo",
            targetX,
            CFG.floorY + 1,
            CFG.centerZ
        )

        -- 3. Verificar la posicion real.
        local current = position()

        if current.posX >= x then
            error(
                "No avanzo hacia X negativo. Antes: "
                .. tostring(x)
                .. ", ahora: "
                .. tostring(current.posX)
            )
        end

        x = current.posX

        print("Avance correcto. X=" .. tostring(x))
    end
end

local ok, err = pcall(main)

if not ok then
    pcall(function()
        android.cancelTask()
    end)

    print("MINADO DETENIDO: " .. tostring(err))
end

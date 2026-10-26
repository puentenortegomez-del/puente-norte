
-- ==========================================
-- MINERO CC:ANDROIDs 1.3.0
-- Excavacion hacia X negativo
-- ==========================================

local A = _G.android

if type(A) ~= "table" then
    print("ERROR: API android no disponible")
    return
end

local CFG = {
    startX = 2212,
    startY = 32,
    startZ = -801,

    length = 40,
    width = 3,
    height = 3,

    maxWaitChecks = 120
}

local function report(message)
    print("[MINERO] " .. tostring(message))
end

local function callAPI(name, x, y, z)
    local fn = A[name]

    if type(fn) ~= "function" then
        return false, "Funcion no disponible: " .. name
    end

    local ok, result = pcall(fn, x, y, z)

    if not ok then
        return false, tostring(result)
    end

    if type(result) == "table" and result[1] == true then
        return false, tostring(result[2] or "Error de API")
    end

    return true
end

local function waitForIdle()
    if type(A.currentTask) ~= "function" then
        report("No existe currentTask")
        return false
    end

    if type(sleep) ~= "function" then
        report("No existe sleep; se cancela por seguridad")
        return false
    end

    for i = 1, CFG.maxWaitChecks do
        local ok, task = pcall(A.currentTask)

        if not ok then
            report("Error consultando la tarea")
            return false
        end

        if task == "idle" then
            return true
        end

        sleep(0.25)
    end

    report("Tiempo de espera agotado")

    if type(A.cancelTask) == "function" then
        pcall(A.cancelTask)
    end

    return false
end

local function checkFuel()
    if type(A.fuelLevel) ~= "function" then
        report("No se puede consultar el combustible")
        return false
    end

    local ok, fuel = pcall(A.fuelLevel)

    if not ok or type(fuel) ~= "number" then
        report("Error leyendo combustible")
        return false
    end

    if fuel <= 0 then
        report("Sin combustible")
        return false
    end

    return true
end

local function mineBlock(x, y, z)
    if not checkFuel() then
        return false
    end

    local ok, err = callAPI("breakBlock", x, y, z)

    if not ok then
        report(
            "Error en X=" .. x
            .. " Y=" .. y
            .. " Z=" .. z
            .. ": " .. tostring(err)
        )
        return false
    end

    return waitForIdle()
end

local function main()
    report("Inicio de la excavacion")
    report("Direccion: X negativo")
    report("Inicio: 2212, 32, -801")

    local halfWidth = math.floor(CFG.width / 2)

    for step = 0, CFG.length - 1 do
        -- Avanza numericamente hacia X negativo.
        local x = CFG.startX - step

        for dz = -halfWidth, halfWidth do
            for dy = 0, CFG.height - 1 do
                local y = CFG.startY + dy
                local z = CFG.startZ + dz

                if not mineBlock(x, y, z) then
                    report("Excavacion detenida")
                    return
                end
            end
        end

        report("Columna completada en X=" .. x)
    end

    report(
        "Tunel terminado. Ultima X="
        .. (CFG.startX - CFG.length + 1)
    )
end

main()

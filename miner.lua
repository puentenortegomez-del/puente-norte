-- miner.lua (Corregido)
-- CC:Androids 1.3.0 | Minecraft 1.20.1
-- Túnel 2x2 hacia X negativo

local android = _G.android

-- Coordenadas Z y Y fijas del túnel 2x2
local Z1 = -801
local Z2 = -802
local Y1 = 33
local Y2 = 34

local LONGITUD = 100
local PAUSA = 0.1

-- Función auxiliar para verificar si una función de la API devolvió un error en tabla
local function verificarError(nombre, res1, res2)
    -- Si la función devuelve una tabla con true en la primera posición, es un error de la API
    if type(res1) == "table" and res1[1] == true then
        print("Error en " .. nombre .. ": " .. tostring(res1[2]))
        return false
    -- Si pcall atrapó un error de Lua
    elseif not res1 then
        print("Error en " .. nombre .. ": " .. tostring(res2))
        return false
    end
    return true
end

-- Espera inteligente a que el androide termine su tarea actual
local function esperarTarea()
    -- Pequeña pausa inicial para dar tiempo a que el juego registre la orden
    sleep(PAUSA)
    
    local inicio = os.clock()
    -- Espera activa mientras el androide esté ocupado rompiendo o moviéndose
    while true do
        local tarea = android.currentTask()
        if tarea == "idle" then
            break
        end
        
        -- Timeout de seguridad por si se queda atascado (10 segundos máx por bloque/movimiento)
        if os.clock() - inicio > 10 then
            print("Aviso: Timeout esperando tarea, continuando...")
            break
        end
        
        sleep(PAUSA)
    end
end

local function minarBloque(x, y, z)
    -- breakBlock(x, y, z) se mueve al bloque y lo rompe (requiere combustible)
    local ok, res = pcall(android.breakBlock, x, y, z)
    
    if not verificarError("minado " .. x .. "," .. y .. "," .. z, ok, res) then
        return false
    end
    
    esperarTarea()
    return true
end

local function minarSeccion(x)
    -- Columna 1
    if not minarBloque(x, Y1, Z1) then return false end
    if not minarBloque(x, Y2, Z1) then return false end

    -- Columna 2
    if not minarBloque(x, Y1, Z2) then return false end
    if not minarBloque(x, Y2, Z2) then return false end

    return true
end

local function main()
    local posicion = android.getSelf()
    if not posicion or not posicion.posX then
        error("No se pudo obtener la posición del androide. ¿Está cargado el mundo?")
    end

    local xInicial = math.floor(posicion.posX)
    local xFinal = xInicial - LONGITUD

    print("=== MINER INICIADO ===")
    print("Dirección: X negativo")
    print("Carriles Z: " .. Z1 .. " y " .. Z2)
    print("Alturas Y: " .. Y1 .. " y " .. Y2)
    print("Desde X=" .. xInicial .. " hasta X=" .. xFinal)

    for x = xInicial - 1, xFinal, -1 do
        print("Excavando sección X=" .. x)

        if not minarSeccion(x) then
            print("Miner detenido por un error al minar.")
            return
        end

        -- Opcional: Avanzar de posición al terminar la columna usando moveTo
        local ok, res = pcall(android.moveTo, x, Y1, Z1)
        if not verificarError("movimiento a X=" .. x, ok, res) then
            print("No se pudo avanzar, deteniendo minero.")
            return
        end
        esperarTarea()
    end

    print("=== TÚNEL TERMINADO ===")
end

local ok, err = pcall(main)

if not ok then
    print("ERROR FATAL: " .. tostring(err))
end

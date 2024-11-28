-- Nombre del archivo: mod_updater.lua

-- Función para ejecutar el script de Python
local function run_python_script()
    -- Asegúrate de que la ruta al script de Python sea correcta
    local python_script = "mods/mod_updater/updater.py"
    
    -- Ejecuta el script de Python
    os.execute("python " .. python_script)
end

-- Registra el hook para ejecutar cuando se inicia el juego
Hooks:Add("MenuManagerOnOpenMenu", "ModUpdaterCheck", function(menu_manager, menu, index)
    if menu == "menu_main" then
        run_python_script()
    end
end)
-- Nombre del archivo: mod_updater.lua

-- Función para ejecutar el script de Python
local function run_python_script()
    local python_script = ModPath .. "updater/updater.py"
    os.execute("python " .. python_script)
end

-- Registra el hook para ejecutar cuando se inicia el juego
Hooks:Add("MenuManagerOnOpenMenu", "ModUpdaterCheck", function(menu_manager, menu, index)
    if menu == "menu_main" then
        run_python_script()
    end
end)
local HttpService = game:GetService("HttpService")

local SaveManager = {
    Library = nil,
    Folder = "Configs",
    CurrentConfig = nil,
    IgnoreList = {} -- Сюда можно добавлять индексы элементов, которые НЕ нужно сохранять
}

-- Инициализация менеджера сохранений
function SaveManager:Init(lib)
    self.Library = lib
    
    -- Создаем папку для конфигов в директории эксплоита, если её нет
    if makefolder and not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

-- Исключить определенный индекс из сохранения (например, бинды или вкладку тем)
function SaveManager:Ignore(idx)
    self.IgnoreList[idx] = true
end

-- Сборка всех текущих данных интерфейса в чистую таблицу
function SaveManager:GetSaveData()
    local data = {
        Toggles = {},
        Options = {}
    }

    -- Сохраняем состояния Тогглов
    for idx, toggle in pairs(self.Library.Toggles) do
        if not self.IgnoreList[idx] then
            data.Toggles[idx] = toggle.Value
        end
    end

    -- Сохраняем значения Слайдеров (и других опций в будущем)
    for idx, option in pairs(self.Library.Options) do
        if not self.IgnoreList[idx] and option.Type == "Slider" then
            data.Options[idx] = option.Value
        end
    end

    return data
end

-- Сохранение конфигурации в JSON-файл
function SaveManager:Save(name)
    if not writefile then return false, "Executor does not support writefile" end
    if not name or name == "" then name = "default" end
    
    self.CurrentConfig = name
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, self:GetSaveData())
    
    if success then
        writefile(self.Folder .. "/" .. name .. ".json", encoded)
        return true
    else
        return false, "Failed to encode config data"
    end
end

-- Загрузка конфигурации с диска и применение к элементам UI
function SaveManager:Load(name)
    if not readfile then return false, "Executor does not support readfile" end
    if not name or name == "" then name = "default" end
    
    local filePath = self.Folder .. "/" .. name .. ".json"
    if not isfile(filePath) then return false, "Config file does not exist" end
    
    local content = readfile(filePath)
    local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
    
    if success and decoded then
        self.CurrentConfig = name
        
        -- Поток для безопасного выставления значений без краша интерфейса
        task.spawn(function()
            -- Восстанавливаем тогглы
            if decoded.Toggles then
                for idx, value in pairs(decoded.Toggles) do
                    if self.Library.Toggles[idx] then
                        self.Library.Toggles[idx]:SetValue(value)
                    end
                end
            end
            
            -- Восстанавливаем слайдеры
            if decoded.Options then
                for idx, value in pairs(decoded.Options) do
                    if self.Library.Options[idx] then
                        self.Library.Options[idx]:SetValue(value)
                    end
                end
            end
        end)
        
        return true
    else
        return false, "Failed to decode config file"
    end
end

-- Удаление файла конфигурации
function SaveManager:Delete(name)
    if not delfile then return false, "Executor does not support delfile" end
    local filePath = self.Folder .. "/" .. name .. ".json"
    
    if isfile(filePath) then
        delfile(filePath)
        if self.CurrentConfig == name then self.CurrentConfig = nil end
        return true
    end
    return false, "Config not found"
end

-- Получить список всех созданных файлов конфигураций (для списков/дропдаунов)
function SaveManager:GetConfigs()
    if not listfiles then return {} end
    local configs = {}
    
    for _, filePath in ipairs(listfiles(self.Folder)) do
        if filePath:sub(-5) == ".json" then
            -- Отрезаем путь папки и расширение, оставляя только имя
            local name = filePath:match("([^/^\\]+)%.json$")
            if name then
                table.insert(configs, name)
            end
        end
    end
    
    return configs
end

-- Автоматическое построение секции управления конфигами в интерфейсе
function SaveManager:BuildFolderSection(tabObject)
    local Group = tabObject:AddGroupbox("Configuration Manager")
    
    -- Поскольку у нас в группе пока реализованы только AddToggle и AddSlider,
    -- мы временно заигнорим внутренние переключатели тем из конфигов
    if self.Library.ThemeManager then
        for name, _ in pairs(self.Library.ThemeManager.Themes) do
            self:Ignore("ThemeToggle_" .. name)
        end
    end

    -- Добавляем быстрые кнопки управления через Тогглы в качестве триггеров действия
    -- (Полноценные кнопки/текстбоксы ты сможешь добавить сюда, когда расширишь методы Groupbox)
    
    Group:AddToggle("Config_SaveDefault", {
        Text = "Save 'default' Config",
        Default = false,
        Callback = function(state)
            if state then
                self:Save("default")
                -- Сбрасываем тоггл обратно в визуальное выключенное состояние, работая как кнопка
                task.wait(0.2)
                self.Library.Toggles["Config_SaveDefault"]:SetValue(false)
            end
        end
    })

    Group:AddToggle("Config_LoadDefault", {
        Text = "Load 'default' Config",
        Default = false,
        Callback = function(state)
            if state then
                self:Load("default")
                task.wait(0.2)
                self.Library.Toggles["Config_LoadDefault"]:SetValue(false)
            end
        end
    })
    
    -- Автоматическое сохранение при выходе из игры (Опционально)
    Group:AddToggle("Config_AutoSave", {
        Text = "Auto-Save on Close",
        Default = false,
        Callback = function(state)
            if state then
                if not _G.KronexAutoSaveConnection then
                    _G.KronexAutoSaveConnection = game:GetService("Players").LocalPlayer.Destroying:Connect(function()
                        self:Save(self.CurrentConfig or "default")
                    end)
                end
            else
                if _G.KronexAutoSaveConnection then
                    _G.KronexAutoSaveConnection:Disconnect()
                    _G.KronexAutoSaveConnection = nil
                end
            end
        end
    })
end

return SaveManager

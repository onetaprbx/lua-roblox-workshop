local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local ThemeManager = {
    Library = nil,
    Folder = "KronexThemes",
    CurrentTheme = "Default",
    
    -- Пресеты цветовых схем
    Themes = {
        ["Default"] = {
            MainBackground = Color3.fromRGB(12, 11, 14),
            SidebarBackground = Color3.fromRGB(18, 16, 22),
            CardBackground = Color3.fromRGB(18, 16, 22),
            Accent = Color3.fromRGB(163, 133, 247),
            Text = Color3.fromRGB(240, 240, 240),
            SubText = Color3.fromRGB(150, 150, 150),
            ElementsBackground = Color3.fromRGB(36, 32, 44)
        },
        ["Midnight"] = {
            MainBackground = Color3.fromRGB(8, 8, 10),
            SidebarBackground = Color3.fromRGB(12, 12, 16),
            CardBackground = Color3.fromRGB(14, 14, 20),
            Accent = Color3.fromRGB(0, 180, 216),
            Text = Color3.fromRGB(255, 255, 255),
            SubText = Color3.fromRGB(140, 147, 161),
            ElementsBackground = Color3.fromRGB(26, 26, 36)
        },
        ["Mantis"] = {
            MainBackground = Color3.fromRGB(15, 18, 15),
            SidebarBackground = Color3.fromRGB(22, 26, 22),
            CardBackground = Color3.fromRGB(22, 26, 22),
            Accent = Color3.fromRGB(82, 183, 136),
            Text = Color3.fromRGB(240, 245, 240),
            SubText = Color3.fromRGB(145, 155, 145),
            ElementsBackground = Color3.fromRGB(38, 47, 38)
        },
        ["Light"] = {
            MainBackground = Color3.fromRGB(245, 245, 248),
            SidebarBackground = Color3.fromRGB(230, 230, 235),
            CardBackground = Color3.fromRGB(235, 235, 240),
            Accent = Color3.fromRGB(120, 80, 220),
            Text = Color3.fromRGB(30, 30, 35),
            SubText = Color3.fromRGB(110, 110, 120),
            ElementsBackground = Color3.fromRGB(210, 210, 220)
        }
    },
    
    -- Список всех отслеживаемых GUI-элементов
    Objects = {}
}

-- Инициализация менеджера и привязка к ядру библиотеки
function ThemeManager:Init(lib)
    self.Library = lib
    
    -- Безопасное создание корневой папки для тем в директории эксплоита
    if makefolder and not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

-- Регистрация GUI-объекта в таблице отслеживания тем
-- instance: ссылка на элемент (Frame, TextLabel и т.д.)
-- propType: строка свойства (например, "BackgroundColor3", "TextColor3")
-- themeKey: ключ из таблицы темы (например, "Accent", "MainBackground")
function ThemeManager:RegisterObject(instance, propType, themeKey)
    local objectData = {
        Instance = instance,
        Property = propType,
        Key = themeKey
    }
    
    table.insert(self.Objects, objectData)
    
    -- Сразу красим объект в текущую активную тему
    local activeTheme = self.Themes[self.CurrentTheme]
    if activeTheme and activeTheme[themeKey] then
        instance[propType] = activeTheme[themeKey]
    end
    
    -- Автоматическая очистка при удалении объекта из игры (чтобы не забивать память)
    instance.Destroying:Connect(function()
        for idx, obj in ipairs(self.Objects) do
            if obj.Instance == instance then
                table.remove(self.Objects, idx)
                break
            end
        end
    end)
end

-- Динамическое переключение темы на лету с плавными анимациями
function ThemeManager:ApplyTheme(themeName)
    if not self.Themes[themeName] then return end
    self.CurrentTheme = themeName
    local themeData = self.Themes[themeName]

    for _, obj in ipairs(self.Objects) do
        if obj.Instance and obj.Instance.Parent then
            local targetColor = themeData[obj.Key]
            if targetColor then
                TweenService:Create(obj.Instance, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [obj.Property] = targetColor
                }):Play()
            end
        end
    end
end

-- Сохранение настроек в JSON-конфиг
function ThemeManager:SaveTheme(profileName)
    if not writefile then return end
    profileName = profileName or "default_theme"
    
    -- Сериализуем кастомную тему (если пользователь менял ползунки вручную)
    local serializedCustom = nil
    if self.Themes["Custom"] then
        serializedCustom = {}
        for k, color in pairs(self.Themes["Custom"]) do
            serializedCustom[k] = {R = color.R, G = color.G, B = color.B}
        end
    end
    
    local configData = {
        SelectedTheme = self.CurrentTheme,
        CustomTheme = serializedCustom
    }
    
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, configData)
    if success then
        writefile(self.Folder .. "/" .. profileName .. ".json", encoded)
    end
end

-- Загрузка и парсинг JSON-конфига с диска
function ThemeManager:LoadTheme(profileName)
    if not readfile then return end
    profileName = profileName or "default_theme"
    local filePath = self.Folder .. "/" .. profileName .. ".json"
    
    if isfile(filePath) then
        local content = readfile(filePath)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        
        if success and decoded then
            -- Восстанавливаем кастомные Color3 из сохраненных RGB-таблиц
            if decoded.CustomTheme then
                self.Themes["Custom"] = {}
                for k, rgb in pairs(decoded.CustomTheme) do
                    if type(rgb) == "table" and rgb.R then
                        self.Themes["Custom"][k] = Color3.new(rgb.R, rgb.G, rgb.B)
                    end
                end
            end
            
            -- Применяем сохраненный пресет
            if decoded.SelectedTheme and self.Themes[decoded.SelectedTheme] then
                self:ApplyTheme(decoded.SelectedTheme)
            end
        end
    end
end

-- Генерация кнопок выбора темы прямо внутри указанного Groupbox
function ThemeManager:BuildThemeSection(tabObject)
    local Group = tabObject:AddGroupbox("Theme Settings")
    
    -- Собираем список всех названий доступных пресетов
    local themeNames = {}
    for name, _ in pairs(self.Themes) do
        table.insert(themeNames, name)
    end
    
    -- Сортируем для ровного отображения (опционально)
    table.sort(themeNames)
    
    -- Создаем тогглы переключения для каждого пресета
    for _, name in ipairs(themeNames) do
        local toggleIndex = "ThemeToggle_" .. name
        
        Group:AddToggle(toggleIndex, {
            Text = name .. " Style",
            Default = (self.CurrentTheme == name),
            Callback = function(state)
                if state then
                    self:ApplyTheme(name)
                    self:SaveTheme()
                    
                    -- Сбрасываем визуальное состояние остальных тогглов тем
                    for _, otherName in ipairs(themeNames) do
                        if otherName ~= name and self.Library.Toggles["ThemeToggle_" .. otherName] then
                            -- Отключаем флаг без вызова повторного коллбека, чтобы избежать зацикливания твинов
                            self.Library.Toggles["ThemeToggle_" .. otherName]:SetValue(false)
                        end
                    end
                end
            end
        })
    end
end

return ThemeManager

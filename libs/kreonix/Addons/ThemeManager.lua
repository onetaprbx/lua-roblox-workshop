local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local ThemeManager = {
    Library = nil,
    Folder = "KronexThemes",
    CurrentTheme = "Default",
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
    Objects = {} -- Сюда библиотека будет регистрировать элементы для динамической смены тем
}

-- Инициализация менеджера тем, связка с основной библиотекой
function ThemeManager:Init(lib)
    self.Library = lib
    
    -- Создаем папку для сохранений, если её нет
    if makefolder and not isfolder(self.Folder) then
        makefolder(self.Folder)
    end
end

-- Регистрация объекта для автоматического изменения цвета
function ThemeManager:RegisterObject(instance, propType, themeKey)
    table.insert(self.Objects, {
        Instance = instance,
        Property = propType, -- "BackgroundColor3", "TextColor3", "ImageColor3"
        Key = themeKey
    })
    
    -- Сразу применяем текущий цвет
    local currentTheme = self.Themes[self.CurrentTheme]
    if currentTheme and currentTheme[themeKey] then
        instance[propType] = currentTheme[themeKey]
    end
end

-- Применение темы с плавным твином для всех зарегистрированных объектов
function ThemeManager:ApplyTheme(themeName)
    if not self.Themes[themeName] then return end
    self.CurrentTheme = themeName
    local themeData = self.Themes[themeName]

    for _, obj in ipairs(self.Objects) do
        if obj.Instance and obj.Instance.Parent then
            local targetColor = themeData[obj.Key]
            if targetColor then
                TweenService:Create(obj.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    [obj.Property] = targetColor
                }):Play()
            end
        end
    end
end

-- Сохранение текущей темы в файл конфигурации
function ThemeManager:SaveTheme(profileName)
    if not writefile then return end
    profileName = profileName or "default_theme"
    
    local data = {
        SelectedTheme = self.CurrentTheme,
        CustomTheme = self.Themes["Custom"]
    }
    
    local success, encoded = pcall(HttpService.JSONEncode, HttpService, data)
    if success then
        writefile(self.Folder .. "/" .. profileName .. ".json", encoded)
    end
end

-- Загрузка сохраненной темы
function ThemeManager:LoadTheme(profileName)
    if not readfile then return end
    profileName = profileName or "default_theme"
    local path = self.Folder .. "/" .. profileName .. ".json"
    
    if isfile(path) then
        local content = readfile(path)
        local success, decoded = pcall(HttpService.JSONDecode, HttpService, content)
        
        if success and decoded then
            if decoded.CustomTheme then
                -- Восстанавливаем кастомные цвета из Color3 значений (JSON не сохраняет userdata напрямую)
                self.Themes["Custom"] = {}
                for k, v in pairs(decoded.CustomTheme) do
                    if type(v) == "table" and v.R then
                        self.Themes["Custom"][k] = Color3.new(v.R, v.G, v.B)
                    end
                end
            end
            
            if decoded.SelectedTheme and self.Themes[decoded.SelectedTheme] then
                self:ApplyTheme(decoded.SelectedTheme)
            end
        end
    end
end

-- Создание готового UI-дропдауна или элементов управления в вашей вкладке настроек
function ThemeManager:BuildThemeSection(tabObject)
    local Group = tabObject:AddGroupbox("Theme Settings")
    
    -- Получаем список имен тем для отображения
    local themeList = {}
    for themeName, _ in pairs(self.Themes) do
        table.insert(themeList, themeName)
    end
    
    -- Допущение: в вашей библиотеке планируется элемент выбора/дропдаун, либо можно использовать связку кнопок/слайдеров.
    -- Ниже пример добавления быстрых переключателей основных тем
    for _, name in ipairs(themeList) do
        -- Пример интеграции через функционал кнопок или тогглов, если они будут расширены в вашей библиотеке.
        -- На данный момент, используя существующие методы группы (AddToggle):
        Group:AddToggle("Theme_" .. name, {
            Text = "Enable " .. name .. " Theme",
            Default = (self.CurrentTheme == name),
            Callback = function(state)
                if state then
                    self:ApplyTheme(name)
                    self:SaveTheme()
                end
            end
        })
    end
end

return ThemeManager

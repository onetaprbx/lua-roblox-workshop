local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local KronexLib = {
    CurrentTab = nil,
    Registry = {},
    Toggled = true,
    Options = {},
    Toggles = {},
    ShowToggleFrameInKeybinds = true,
    ShowCustomCursor = true,
    NotifySide = "Left",
    ThemeManager = nil -- Ссылка на объект ThemeManager
}

-- =============================================================================
-- ИНТЕГРАЦИЯ БАЗЫ ИКОНОК LUCIDE (RAYFIELD FETCH)
-- =============================================================================
local LucideDatabase = {}
local DatabaseLoaded = false

task.spawn(function()
    local success, res = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua")
    end)

    if success and res then
        local pcallLoad, loadedFunc = pcall(loadstring, res)
        if pcallLoad and type(loadedFunc) == "function" then
            local pcallExec, rawTable = pcall(loadedFunc)
            if pcallExec and type(rawTable) == "table" and rawTable["48px"] then
                for name, data in pairs(rawTable["48px"]) do
                    LucideDatabase[string.lower(name)] = {
                        Texture = "rbxassetid://" .. tostring(data[1]),
                        Offset = Vector2.new(data[2][1], data[2][2]),
                        Size = Vector2.new(48, 48)
                    }
                end
            end
        end
    end
    DatabaseLoaded = true
end)

local function ApplyLucideIcon(imageLabel, iconName)
    local cleanName = string.lower(iconName or ""):gsub("%s+", "-")
    local iconData = LucideDatabase[cleanName]

    if iconData then
        imageLabel.Image = iconData.Texture
        imageLabel.ImageRectOffset = iconData.Offset
        imageLabel.ImageRectSize = iconData.Size
    else
        imageLabel.Image = "rbxassetid://10734947426" 
        imageLabel.ImageRectOffset = Vector2.new(0, 0)
        imageLabel.ImageRectSize = Vector2.new(0, 0)
    end
end

-- =============================================================================
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-- =============================================================================
local function CreateUICorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function ApplySmoothDrag(frame)
    local dragging, dragInput, dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

-- Хелпер для быстрой регистрации UI элементов в менеджере тем
local function RegisterTheme(instance, prop, key)
    if KronexLib.ThemeManager and KronexLib.ThemeManager.RegisterObject then
        KronexLib.ThemeManager:RegisterObject(instance, prop, key)
    end
end

-- =============================================================================
-- ОСНОВНЫЕ МЕТОДЫ ИНТЕРФЕЙСА
-- =============================================================================
function KronexLib:CreateWindow(cfg)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "Kronex_Gui"
    ScreenGui.ResetOnSpawn = false
    if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end
    ScreenGui.Parent = CoreGui

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 850, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -425, 0.5, -260)
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    CreateUICorner(MainFrame, 12)
    ApplySmoothDrag(MainFrame)
    RegisterTheme(MainFrame, "BackgroundColor3", "MainBackground")

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 210, 1, 0)
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame
    CreateUICorner(Sidebar, 12)
    RegisterTheme(Sidebar, "BackgroundColor3", "SidebarBackground")

    local SidebarFix = Instance.new("Frame")
    SidebarFix.Size = UDim2.new(0, 15, 1, 0)
    SidebarFix.Position = UDim2.new(1, -15, 0, 0)
    SidebarFix.BorderSizePixel = 0
    SidebarFix.Parent = Sidebar
    RegisterTheme(SidebarFix, "BackgroundColor3", "SidebarBackground")

    local Logo = Instance.new("TextLabel")
    Logo.Size = UDim2.new(1, 0, 0, 65)
    Logo.BackgroundTransparency = 1
    Logo.Text = cfg.Title or "kronex.fun"
    Logo.Font = Enum.Font.GothamBold
    Logo.TextSize = 24
    Logo.Parent = Sidebar
    RegisterTheme(Logo, "TextColor3", "Accent")

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -12, 1, -140)
    TabContainer.Position = UDim2.new(0, 6, 0, 65)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -225, 1, -20)
    ContentArea.Position = UDim2.new(0, 220, 0, 10)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    -- Overlay для биндов
    local BindOverlay = Instance.new("Frame")
    BindOverlay.Size = UDim2.new(1, 0, 1, 0)
    BindOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BindOverlay.BackgroundTransparency = 1
    BindOverlay.Visible = false
    BindOverlay.ZIndex = 10
    BindOverlay.Parent = MainFrame

    local BindModal = Instance.new("Frame")
    BindModal.Size = UDim2.new(0, 280, 0, 120)
    BindModal.Position = UDim2.new(0.5, -140, 0.5, -60)
    BindModal.Parent = BindOverlay
    CreateUICorner(BindModal, 8)
    RegisterTheme(BindModal, "BackgroundColor3", "SidebarBackground")

    local BindTitle = Instance.new("TextLabel")
    BindTitle.Size = UDim2.new(1, 0, 0, 40)
    BindTitle.BackgroundTransparency = 1
    BindTitle.Text = "Binding Module"
    BindTitle.Font = Enum.Font.GothamBold
    BindTitle.TextSize = 14
    BindTitle.Parent = BindModal
    RegisterTheme(BindTitle, "TextColor3", "Text")

    local BindPrompt = Instance.new("TextButton")
    BindPrompt.Size = UDim2.new(1, -40, 0, 40)
    BindPrompt.Position = UDim2.new(0, 20, 0, 50)
    BindPrompt.Text = "Press Key"
    BindPrompt.Font = Enum.Font.GothamSemibold
    BindPrompt.TextSize = 12
    BindPrompt.Parent = BindModal
    CreateUICorner(BindPrompt, 6)
    RegisterTheme(BindPrompt, "BackgroundColor3", "ElementsBackground")
    RegisterTheme(BindPrompt, "TextColor3", "Accent")

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightShift then
            KronexLib.Toggled = not KronexLib.Toggled
            TweenService:Create(MainFrame, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = KronexLib.Toggled and UDim2.new(0, 850, 0, 520) or UDim2.new(0, 850, 0, 0)
            }):Play()
        end
    end)

    self.MainFrame = MainFrame
    self.ContentArea = ContentArea
    self.TabContainer = TabContainer
    self.BindOverlay = BindOverlay
    self.BindTitle = BindTitle
    self.BindPrompt = BindPrompt

    return self
end

function KronexLib:AddTab(name, iconName)
    local TabButton = Instance.new("TextButton")
    TabButton.Size = UDim2.new(1, 0, 0, 40)
    TabButton.BackgroundTransparency = 1
    TabButton.Text = ""
    TabButton.Parent = self.TabContainer
    CreateUICorner(TabButton, 6)
    RegisterTheme(TabButton, "BackgroundColor3", "Accent")

    local Icon = Instance.new("ImageLabel")
    Icon.Size = UDim2.new(0, 18, 0, 18)
    Icon.Position = UDim2.new(0, 12, 0.5, -9)
    Icon.BackgroundTransparency = 1
    Icon.Parent = TabButton
    ApplyLucideIcon(Icon, iconName)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Position = UDim2.new(0, 40, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = name
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = TabButton
    RegisterTheme(Label, "TextColor3", "SubText")

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.Visible = false
    Page.ScrollBarThickness = 0
    Page.Parent = self.ContentArea

    local Grid = Instance.new("UIGridLayout")
    Grid.CellSize = UDim2.new(0, 295, 0, 235)
    Grid.CellPadding = UDim2.new(0, 15, 0, 15)
    Grid.Parent = Page

    Grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        Page.CanvasSize = UDim2.new(0, 0, 0, Grid.AbsoluteContentSize.Y + 20)
    end)

    local function activate()
        if KronexLib.CurrentTab then
            TweenService:Create(KronexLib.CurrentTab.Button, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
            TweenService:Create(KronexLib.CurrentTab.Icon, TweenInfo.new(0.2), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
            KronexLib.CurrentTab.Page.Visible = false
        end
        TweenService:Create(TabButton, TweenInfo.new(0.2), {BackgroundTransparency = 0.9}):Play()
        
        Page.Position = UDim2.new(0, 30, 0, 0)
        Page.Visible = true
        TweenService:Create(Page, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(0, 0, 0, 0)}):Play()
        
        KronexLib.CurrentTab = {Button = TabButton, Page = Page, Icon = Icon, Label = Label}
    end

    TabButton.MouseButton1Click:Connect(activate)
    
    TabButton.MouseEnter:Connect(function()
        if not KronexLib.CurrentTab or KronexLib.CurrentTab.Button ~= TabButton then
            TweenService:Create(Label, TweenInfo.new(0.15), {TextColor3 = Color3.fromRGB(220, 220, 220)}):Play()
        end
    end)
    TabButton.MouseLeave:Connect(function()
        if not KronexLib.CurrentTab or KronexLib.CurrentTab.Button ~= TabButton then
            local targetColor = (KronexLib.ThemeManager and KronexLib.ThemeManager.Themes[KronexLib.ThemeManager.CurrentTheme].SubText) or Color3.fromRGB(150, 150, 150)
            TweenService:Create(Label, TweenInfo.new(0.15), {TextColor3 = targetColor}):Play()
        end
    end)

    task.spawn(function()
        while not DatabaseLoaded do task.wait(0.1) end
        ApplyLucideIcon(Icon, iconName)
        if not KronexLib.CurrentTab then activate() end
    end)

    local TabObj = {Page = Page, Main = self}

    -- =============================================================================
    -- КАРТОЧКИ ГРУПП (GROUPBOX)
    -- =============================================================================
    function TabObj:AddGroupbox(groupName)
        local Card = Instance.new("Frame")
        Card.Parent = Page
        CreateUICorner(Card, 8)
        RegisterTheme(Card, "BackgroundColor3", "CardBackground")

        local Header = Instance.new("TextLabel")
        Header.Size = UDim2.new(1, -40, 0, 35)
        Header.Position = UDim2.new(0, 12, 0, 0)
        Header.BackgroundTransparency = 1
        Header.Text = groupName
        Header.Font = Enum.Font.GothamBold
        Header.TextSize = 14
        Header.TextXAlignment = Enum.TextXAlignment.Left
        Header.Parent = Card
        RegisterTheme(Header, "TextColor3", "Text")

        local ElementsList = Instance.new("ScrollingFrame")
        ElementsList.Size = UDim2.new(1, -10, 1, -40)
        ElementsList.Position = UDim2.new(0, 5, 0, 40)
        ElementsList.BackgroundTransparency = 1
        ElementsList.ScrollBarThickness = 0
        ElementsList.Parent = Card

        local ListLayout = Instance.new("UIListLayout")
        ListLayout.Padding = UDim.new(0, 6)
        ListLayout.Parent = ElementsList

        local GroupObj = {}

        -- =============================================================================
        -- ЭЛЕМЕНТ: TOGGLE
        -- =============================================================================
        function GroupObj:AddToggle(idx, cfg)
            local ToggleData = {Value = cfg.Default or false, Type = "Toggle", ChangedCallbacks = {}}
            if cfg.Callback then table.insert(ToggleData.ChangedCallbacks, cfg.Callback) end

            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Size = UDim2.new(1, -10, 0, 32)
            ToggleFrame.BackgroundTransparency = 1
            ToggleFrame.Parent = ElementsList

            local ClickBtn = Instance.new("TextButton")
            ClickBtn.Size = UDim2.new(1, 0, 1, 0)
            ClickBtn.BackgroundTransparency = 1
            ClickBtn.Text = ""
            ClickBtn.Parent = ToggleFrame

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -40, 1, 0)
            Label.Position = UDim2.new(0, 8, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = cfg.Text or idx
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 13
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = ToggleFrame
            RegisterTheme(Label, "TextColor3", "SubText")

            local Box = Instance.new("Frame")
            Box.Size = UDim2.new(0, 24, 0, 14)
            Box.Position = UDim2.new(1, -32, 0.5, -7)
            Box.Parent = ToggleFrame
            CreateUICorner(Box, 7)
            RegisterTheme(Box, "BackgroundColor3", "ElementsBackground")

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 10, 0, 10)
            Dot.Position = UDim2.new(0, 2, 0.5, -5)
            Dot.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
            Dot.Parent = Box
            CreateUICorner(Dot, 5)

            local function update()
                local currentTheme = KronexLib.ThemeManager and KronexLib.ThemeManager.Themes[KronexLib.ThemeManager.CurrentTheme]
                
                local targetColor = ToggleData.Value and (currentTheme and currentTheme.Accent or Color3.fromRGB(163, 133, 247)) or (currentTheme and currentTheme.ElementsBackground or Color3.fromRGB(36, 32, 44))
                local targetDotColor = ToggleData.Value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(150, 150, 150)
                local targetPos = ToggleData.Value and UDim2.new(0, 12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
                
                TweenService:Create(Box, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundColor3 = targetColor}):Play()
                TweenService:Create(Dot, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = targetPos, BackgroundColor3 = targetDotColor}):Play()
                
                for _, cb in ipairs(ToggleData.ChangedCallbacks) do cb(ToggleData.Value) end
            end

            function ToggleData:OnChanged(cb) table.insert(ToggleData.ChangedCallbacks, cb) end
            function ToggleData:SetValue(val) ToggleData.Value = val update() end

            ClickBtn.MouseButton1Click:Connect(function()
                ToggleData.Value = not ToggleData.Value
                update()
            end)

            task.spawn(update)
            KronexLib.Toggles[idx] = ToggleData
            return ToggleData
        end

        -- =============================================================================
        -- ЭЛЕМЕНТ: SLIDER
        -- =============================================================================
        function GroupObj:AddSlider(idx, cfg)
            local SliderData = {Value = cfg.Default or cfg.Min, Type = "Slider", ChangedCallbacks = {}}
            if cfg.Callback then table.insert(SliderData.ChangedCallbacks, cfg.Callback) end

            local SliderFrame = Instance.new("Frame")
            SliderFrame.Size = UDim2.new(1, -10, 0, 48)
            SliderFrame.BackgroundTransparency = 1
            SliderFrame.Parent = ElementsList

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -60, 0, 20)
            Label.Position = UDim2.new(0, 8, 0, 2)
            Label.BackgroundTransparency = 1
            Label.Text = cfg.Text or idx
            Label.Font = Enum.Font.GothamMedium
            Label.TextSize = 12
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = SliderFrame
            RegisterTheme(Label, "TextColor3", "SubText")

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 50, 0, 20)
            ValueLabel.Position = UDim2.new(1, -58, 0, 2)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(SliderData.Value)
            ValueLabel.Font = Enum.Font.GothamBold
            ValueLabel.TextSize = 12
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame
            RegisterTheme(ValueLabel, "TextColor3", "Accent")

            local SliderBar = Instance.new("TextButton")
            SliderBar.Size = UDim2.new(1, -16, 0, 4)
            SliderBar.Position = UDim2.new(0, 8, 0, 32)
            SliderBar.Text = ""
            SliderBar.Parent = SliderFrame
            CreateUICorner(SliderBar, 2)
            RegisterTheme(SliderBar, "BackgroundColor3", "ElementsBackground")

            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new(0, 0, 1, 0)
            SliderFill.Parent = SliderBar
            CreateUICorner(SliderFill, 2)
            RegisterTheme(SliderFill, "BackgroundColor3", "Accent")

            local SliderBtn = Instance.new("Frame")
            SliderBtn.Size = UDim2.new(0, 10, 0, 10)
            SliderBtn.Position = UDim2.new(0, 0, 0.5, -5)
            SliderBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            SliderBtn.Parent = SliderBar
            CreateUICorner(SliderBtn, 5)

            local function updateVisuals(snap)
                local pct = (SliderData.Value - cfg.Min) / (cfg.Max - cfg.Min)
                if snap then
                    SliderFill.Size = UDim2.new(pct, 0, 1, 0)
                    SliderBtn.Position = UDim2.new(pct, -5, 0.5, -5)
                end
                ValueLabel.Text = tostring(SliderData.Value)
            end

            RunService.RenderStepped:Connect(function()
                local targetPct = (SliderData.Value - cfg.Min) / (cfg.Max - cfg.Min)
                local currentPct = SliderFill.Size.X.Scale
                local lerpPct = currentPct + (targetPct - currentPct) * 0.22 

                SliderFill.Size = UDim2.new(lerpPct, 0, 1, 0)
                SliderBtn.Position = UDim2.new(lerpPct, -5, 0.5, -5)
            end)

            local sliding = false
            local function updateFromInput(input)
                local pos = math.clamp((input.Position.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
                local val = cfg.Min + (cfg.Max - cfg.Min) * pos
                val = cfg.Rounding and math.round(val / cfg.Rounding) * cfg.Rounding or math.round(val * 100) / 100
                if val ~= SliderData.Value then
                    SliderData.Value = val
                    updateVisuals(false)
                    for _, cb in ipairs(SliderData.ChangedCallbacks) do cb(val) end
                end
            end

            function SliderData:OnChanged(cb) table.insert(SliderData.ChangedCallbacks, cb) end
            function SliderData:SetValue(val) SliderData.Value = math.clamp(val, cfg.Min, cfg.Max) updateVisuals(true) end

            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    sliding = true
                    updateFromInput(input)
                    TweenService:Create(SliderBar, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, 6), Position = UDim2.new(0, 8, 0, 31)}):Play()
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and sliding then
                    sliding = false
                    TweenService:Create(SliderBar, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(1, -16, 0, 4), Position = UDim2.new(0, 8, 0, 32)}):Play()
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if sliding and input.UserInputType == Enum.UserInputType.MouseMovement then
                    updateFromInput(input)
                end
            end)

            task.spawn(function() updateVisuals(true) end)
            KronexLib.Options[idx] = SliderData
            return SliderData
        end

        return GroupObj
    end

    return TabObj
end

return KronexLib

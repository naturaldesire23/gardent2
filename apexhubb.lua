local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local mouse = Players.LocalPlayer:GetMouse()
local old_Fallen = CoreGui:FindFirstChild('Fallen')

if old_Fallen then
    Debris:AddItem(old_Fallen, 0)
end

pcall(function()
    if getgenv()._Fallen_Cleanup then
        getgenv()._Fallen_Cleanup()
        getgenv()._Fallen_Cleanup = nil
    end
end)

if not isfolder("Fallen") then
    makefolder("Fallen")
end

function convertStringToTable(inputString)
    local result = {}
    for value in string.gmatch(inputString, "([^,]+)") do
        local trimmedValue = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmedValue)
    end
    return result
end

function convertTableToString(inputTable)
    return table.concat(inputTable, ", ")
end

local Connections = {
    disconnect = function(self, connection)
        if not self[connection] then return end
        self[connection]:Disconnect()
        self[connection] = nil
    end,
    disconnect_all = function(self)
        for k, value in pairs(self) do
            if typeof(value) == 'function' then continue end
            if typeof(value) == 'RBXScriptConnection' then
                value:Disconnect()
                self[k] = nil
            end
        end
    end
}

local Config = {
    save = function(self, file_name, config)
        pcall(function()
            writefile('Fallen/'..file_name..'.json', HttpService:JSONEncode(config))
        end)
    end,
    load = function(self, file_name, config)
        local ok, result = pcall(function()
            if not isfile('Fallen/'..file_name..'.json') then
                self:save(file_name, config)
                return config
            end
            local flags = readfile('Fallen/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return config
            end
            return HttpService:JSONDecode(flags)
        end)
        if not ok or not result then
            result = { _flags = {}, _keybinds = {} }
        end
        return result
    end
}

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {} }),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _flag_registry = {},
    _notification_enabled = true,
    _keybind_list_data = {},
    _keybind_overlay = nil,
    _keybind_overlay_visible = false,
    _minimized = false,
    _hide_when_minimized = false,
}
Library.__index = Library
Library.Connections = Connections

function Library.new()
    local self = setmetatable({ _tab = 0 }, Library)
    self:create_ui()
    self:create_keybind_overlay()
    return self
end

local NotificationContainer = Instance.new("Frame")
NotificationContainer.Name = "RobloxCoreGuis"
NotificationContainer.Size = UDim2.new(0, 300, 0, 0)
NotificationContainer.AnchorPoint = Vector2.new(0, 1)
NotificationContainer.Position = UDim2.new(0, 22, 1, -22)
NotificationContainer.BackgroundTransparency = 1
NotificationContainer.ClipsDescendants = false
local NotificationRoot = CoreGui:FindFirstChild("RobloxGui")
local NotificationHost = NotificationRoot and NotificationRoot:FindFirstChild("RobloxCoreGuis")

if not NotificationHost then
    NotificationHost = Instance.new("ScreenGui")
    NotificationHost.Name = "FallenNotifications"
    NotificationHost.ResetOnSpawn = false
    NotificationHost.IgnoreGuiInset = true
    NotificationHost.DisplayOrder = 101
    NotificationHost.Parent = NotificationRoot or CoreGui
end

NotificationContainer.Parent = NotificationHost
NotificationContainer.AutomaticSize = Enum.AutomaticSize.Y

local UIListLayout_Notif = Instance.new("UIListLayout")
UIListLayout_Notif.FillDirection = Enum.FillDirection.Vertical
UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
UIListLayout_Notif.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout_Notif.Padding = UDim.new(0, 8)
UIListLayout_Notif.Parent = NotificationContainer

function Library.SendNotification(settings)
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)
    InnerFrame.Position = UDim2.new(-1, -320, 0, 0)
    InnerFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    InnerFrame.BackgroundTransparency = 0
    InnerFrame.BorderSizePixel = 0
    InnerFrame.Name = "InnerFrame"
    InnerFrame.ZIndex = 1
    InnerFrame.Parent = Notification

    local InnerGradient = Instance.new("UIGradient")
    InnerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    InnerGradient.Rotation = 90
    InnerGradient.Parent = InnerFrame

    local InnerUICorner = Instance.new("UICorner")
    InnerUICorner.CornerRadius = UDim.new(0, 8)
    InnerUICorner.Parent = InnerFrame

    local InnerStroke = Instance.new("UIStroke")
    InnerStroke.Color = Color3.fromRGB(255, 255, 255)
    InnerStroke.Transparency = 0.72
    InnerStroke.Thickness = 1
    InnerStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    InnerStroke.Parent = InnerFrame

    local Title = Instance.new("TextLabel")
    Title.Text = settings.title or "Notification"
    Title.TextColor3 = Color3.fromRGB(238, 238, 242)
    Title.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Title.TextSize = 16
    Title.Size = UDim2.new(1, -28, 0, 15)
    Title.Position = UDim2.new(0, 14, 0, 12)
    Title.BackgroundTransparency = 1
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextYAlignment = Enum.TextYAlignment.Center
    Title.TextTruncate = Enum.TextTruncate.AtEnd
    Title.ZIndex = 2
    Title.Parent = InnerFrame

    local Body = Instance.new("TextLabel")
    Body.Text = settings.text or "Notification message"
    Body.TextColor3 = Color3.fromRGB(142, 142, 151)
    Body.FontFace = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    Body.TextSize = 14
    Body.Size = UDim2.new(1, -28, 0, 14)
    Body.Position = UDim2.new(0, 14, 0, 33)
    Body.BackgroundTransparency = 1
    Body.TextXAlignment = Enum.TextXAlignment.Left
    Body.TextYAlignment = Enum.TextYAlignment.Center
    Body.TextTruncate = Enum.TextTruncate.AtEnd
    Body.ZIndex = 2
    Body.Parent = InnerFrame

    task.spawn(function()
        TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.wait(settings.duration or 5)
        local t = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(-1, -320, 0, 0)
        })
        t:Play()
        t.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library:get_screen_scale()
    local viewport_size_x = workspace.CurrentCamera.ViewportSize.X
    self._ui_scale = viewport_size_x / 1400
end

function Library:get_device()
    local device = 'Unknown'
    if not UserInputService.TouchEnabled and UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
        device = 'PC'
    elseif UserInputService.TouchEnabled then
        device = 'Mobile'
    elseif UserInputService.GamepadEnabled then
        device = 'Console'
    end
    self._device = device
end

function Library:removed(action)
    self._ui.AncestryChanged:Once(action)
end

function Library:flag_type(flag, flag_type)
    if Library._config._flags[flag] == nil then return end
    return typeof(Library._config._flags[flag]) == flag_type
end

function Library:remove_table_value(__table, table_value)
    for index, value in __table do
        if value ~= table_value then continue end
        table.remove(__table, index)
    end
end

function Library:register_keybind(flag, label, key, get_state_fn)
    if not self._keybind_list_data then self._keybind_list_data = {} end
    self._keybind_list_data[flag] = {
        label = label or flag,
        key = key or "None",
        get_state = get_state_fn or function() return nil end
    }
    self:update_keybind_list()
end

function Library:unregister_keybind(flag)
    if self._keybind_list_data then
        self._keybind_list_data[flag] = nil
        self:update_keybind_list()
    end
end

function Library:update_keybind_entry(flag)
    if not self._keybind_overlay then return end
    local container = self._keybind_overlay:FindFirstChild("Entries")
    if not container then return end
    local entry = container:FindFirstChild("KB_" .. flag)
    if not entry then return end
    local data = self._keybind_list_data[flag]
    if not data then return end

    local keyLabel = entry:FindFirstChild("KeyBadge")
    if keyLabel then
        local keyText = keyLabel:FindFirstChild("KeyText")
        if keyText then keyText.Text = data.key end
    end

    local state = data.get_state()
    local bg = entry:FindFirstChild("BG")
    local dot = entry:FindFirstChild("Dot")
    local nameLbl = entry:FindFirstChild("NameLabel")

    if state == true then
        if bg then bg.BackgroundColor3 = Color3.fromRGB(28, 28, 36) end
        if dot then dot.BackgroundColor3 = Color3.fromRGB(160, 200, 160) end
        if nameLbl then nameLbl.TextColor3 = Color3.fromRGB(200, 200, 210) end
        if keyLabel then keyLabel.BackgroundColor3 = Color3.fromRGB(42, 42, 52) end
    elseif state == false then
        if bg then bg.BackgroundColor3 = Color3.fromRGB(16, 16, 20) end
        if dot then dot.BackgroundColor3 = Color3.fromRGB(50, 50, 58) end
        if nameLbl then nameLbl.TextColor3 = Color3.fromRGB(90, 90, 100) end
        if keyLabel then keyLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 36) end
    else
        if bg then bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25) end
        if dot then dot.BackgroundColor3 = Color3.fromRGB(120, 120, 180) end
        if nameLbl then nameLbl.TextColor3 = Color3.fromRGB(160, 160, 175) end
        if keyLabel then keyLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 42) end
    end
end

function Library:update_keybind_list()
    if not self._keybind_overlay then return end
    local container = self._keybind_overlay:FindFirstChild("Entries")
    if not container then return end

    for _, child in container:GetChildren() do
        if child.Name:sub(1, 3) == "KB_" then child:Destroy() end
    end

    local count = 0
    for flag, data in pairs(self._keybind_list_data or {}) do
        count = count + 1
        local state = data.get_state and data.get_state() or nil

        local entry = Instance.new("Frame")
        entry.Name = "KB_" .. flag
        entry.Size = UDim2.new(1, -8, 0, 20)
        entry.BackgroundTransparency = 1
        entry.LayoutOrder = count
        entry.Parent = container

        local bg = Instance.new("Frame")
        bg.Name = "BG"
        bg.Size = UDim2.new(1, 0, 1, 0)
        bg.BackgroundTransparency = 0
        bg.BorderSizePixel = 0
        if state == true then
            bg.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
        elseif state == false then
            bg.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
        else
            bg.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
        end
        bg.Parent = entry
        local bgCorner = Instance.new("UICorner")
        bgCorner.CornerRadius = UDim.new(0, 4)
        bgCorner.Parent = bg

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.Size = UDim2.new(0, 5, 0, 5)
        dot.Position = UDim2.new(0, 7, 0.5, 0)
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.BackgroundTransparency = 0
        dot.BorderSizePixel = 0
        if state == true then
            dot.BackgroundColor3 = Color3.fromRGB(160, 200, 160)
        elseif state == false then
            dot.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
        else
            dot.BackgroundColor3 = Color3.fromRGB(120, 120, 180)
        end
        dot.Parent = bg
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Name = "NameLabel"
        nameLbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
        nameLbl.TextSize = 10
        nameLbl.Text = data.label or flag
        nameLbl.Size = UDim2.new(1, -75, 1, 0)
        nameLbl.Position = UDim2.new(0, 16, 0, 0)
        nameLbl.BackgroundTransparency = 1
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        if state == true then
            nameLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
        elseif state == false then
            nameLbl.TextColor3 = Color3.fromRGB(90, 90, 100)
        else
            nameLbl.TextColor3 = Color3.fromRGB(160, 160, 175)
        end
        nameLbl.Parent = bg

        local keyBadge = Instance.new("Frame")
        keyBadge.Name = "KeyBadge"
        keyBadge.Size = UDim2.new(0, 44, 0, 14)
        keyBadge.AnchorPoint = Vector2.new(1, 0.5)
        keyBadge.Position = UDim2.new(1, -5, 0.5, 0)
        keyBadge.BackgroundTransparency = 0
        keyBadge.BorderSizePixel = 0
        if state == true then
            keyBadge.BackgroundColor3 = Color3.fromRGB(42, 42, 52)
        elseif state == false then
            keyBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
        else
            keyBadge.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
        end
        keyBadge.Parent = bg
        local kbCorner = Instance.new("UICorner")
        kbCorner.CornerRadius = UDim.new(0, 3)
        kbCorner.Parent = keyBadge

        local keyText = Instance.new("TextLabel")
        keyText.Name = "KeyText"
        keyText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        keyText.TextSize = 9
        keyText.Text = data.key or "None"
        keyText.TextColor3 = Color3.fromRGB(175, 175, 185)
        keyText.Size = UDim2.new(1, -6, 1, 0)
        keyText.Position = UDim2.new(0, 3, 0, 0)
        keyText.BackgroundTransparency = 1
        keyText.TextXAlignment = Enum.TextXAlignment.Center
        keyText.Parent = keyBadge
    end
end

function Library:set_keybind_overlay_visible(state)
    self._keybind_overlay_visible = state
    if self._keybind_overlay then
        self._keybind_overlay.Enabled = state
    end
end

function Library:create_keybind_overlay()
    local sg = Instance.new("ScreenGui")
    sg.Name = "FallenKeybindList"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 102
    sg.Parent = CoreGui
    sg.Enabled = false

    local main = Instance.new("Frame")
    main.Name = "KeybindOverlay"
    main.Size = UDim2.new(0, 195, 0, 0)
    main.AutomaticSize = Enum.AutomaticSize.Y
    main.AnchorPoint = Vector2.new(1, 1)
    main.Position = UDim2.new(1, -16, 1, -16)
    main.BackgroundColor3 = Color3.fromRGB(12, 12, 15)
    main.BackgroundTransparency = 0.18
    main.BorderSizePixel = 0
    main.Active = true
    main.Parent = sg

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 8)
    mainCorner.Parent = main

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Color = Color3.fromRGB(255, 255, 255)
    mainStroke.Transparency = 0.82
    mainStroke.Thickness = 1
    mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    mainStroke.Parent = main

    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Size = UDim2.new(1, 0, 0, 24)
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Parent = main

    local headerLbl = Instance.new("TextLabel")
    headerLbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    headerLbl.TextSize = 10
    headerLbl.Text = "KEYBINDS"
    headerLbl.TextColor3 = Color3.fromRGB(100, 100, 110)
    headerLbl.Size = UDim2.new(1, -10, 1, 0)
    headerLbl.Position = UDim2.new(0, 10, 0, 0)
    headerLbl.BackgroundTransparency = 1
    headerLbl.TextXAlignment = Enum.TextXAlignment.Left
    headerLbl.Parent = header

    local entries = Instance.new("Frame")
    entries.Name = "Entries"
    entries.Size = UDim2.new(1, 0, 0, 0)
    entries.AutomaticSize = Enum.AutomaticSize.Y
    entries.BackgroundTransparency = 1
    entries.BorderSizePixel = 0
    entries.Position = UDim2.new(0, 0, 0, 24)
    entries.Parent = main

    local entryList = Instance.new("UIListLayout")
    entryList.Padding = UDim.new(0, 3)
    entryList.SortOrder = Enum.SortOrder.LayoutOrder
    entryList.Parent = entries

    local entryPad = Instance.new("UIPadding")
    entryPad.PaddingLeft = UDim.new(0, 4)
    entryPad.PaddingRight = UDim.new(0, 4)
    entryPad.PaddingBottom = UDim.new(0, 4)
    entryPad.Parent = entries

    self._keybind_overlay = main
    self._keybind_overlay_visible = false

    local dragging_kb = false
    local drag_start_kb = nil
    local kb_position = nil

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging_kb = true
            drag_start_kb = input.Position
            kb_position = main.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging_kb = false
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging_kb then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - drag_start_kb
        main.Position = UDim2.new(
            kb_position.X.Scale, kb_position.X.Offset + delta.X,
            kb_position.Y.Scale, kb_position.Y.Offset + delta.Y
        )
    end)

    task.spawn(function()
        while task.wait(0.5) do
            if not self._keybind_overlay or not self._keybind_overlay.Parent then break end
            for flag, _ in pairs(self._keybind_list_data or {}) do
                self:update_keybind_entry(flag)
            end
        end
    end)
end

function Library:set_minimized(state)
    self._minimized = state
    if not self._ui then return end
    local container = self._ui:FindFirstChild("Container")
    if not container then return end
    if state then
        if self._hide_when_minimized then
            self._ui.Enabled = false
        else
            TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
        end
    else
        self._ui.Enabled = true
        TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    end
    Config:save(game.GameId, Library._config)
end

function Library:set_hide_when_minimized(state)
    self._hide_when_minimized = state
    if self._minimized and state then
        if self._ui then self._ui.Enabled = false end
    elseif self._minimized and not state then
        if self._ui then
            self._ui.Enabled = true
            local container = self._ui:FindFirstChild("Container")
            if container then
                TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(104.5, 52)
                }):Play()
            end
        end
    end
    Config:save(game.GameId, Library._config)
end

function Library:create_ui()
    local old_Fallen = CoreGui:FindFirstChild('Fallen')
    if old_Fallen then
        Debris:AddItem(old_Fallen, 0)
    end

    local Fallen = Instance.new('ScreenGui')
    Fallen.ResetOnSpawn = false
    Fallen.Name = 'Fallen'
    Fallen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Fallen.Parent = CoreGui

    local Container = Instance.new('Frame')
    Container.ClipsDescendants = true
    Container.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Container.AnchorPoint = Vector2.new(0.5, 0.5)
    Container.Name = 'Container'
    Container.BackgroundTransparency = 0
    Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Container.Position = UDim2.new(0.5, 0, 0.5, 0)
    Container.Size = UDim2.new(0, 0, 0, 0)
    Container.Active = true
    Container.BorderSizePixel = 0
    Container.Parent = Fallen

    local ShadowHolder = Instance.new('Frame')
    ShadowHolder.Name = 'ShadowHolder'
    ShadowHolder.AnchorPoint = Container.AnchorPoint
    ShadowHolder.Position = Container.Position
    ShadowHolder.Size = Container.Size
    ShadowHolder.BackgroundTransparency = 1
    ShadowHolder.BorderSizePixel = 0
    ShadowHolder.ZIndex = 0
    ShadowHolder.Parent = Fallen
    ShadowHolder.Visible = false

    local ShadowOuter = Instance.new('ImageLabel')
    ShadowOuter.Name = 'SoftShadowOuter'
    ShadowOuter.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowOuter.Position = UDim2.new(0.5, 0, 0.5, 2)
    ShadowOuter.Size = UDim2.new(1, 58, 1, 58)
    ShadowOuter.BackgroundTransparency = 1
    ShadowOuter.BorderSizePixel = 0
    ShadowOuter.Image = 'rbxassetid://6014261993'
    ShadowOuter.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowOuter.ImageTransparency = 0.43
    ShadowOuter.ScaleType = Enum.ScaleType.Slice
    ShadowOuter.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowOuter.ZIndex = 0
    ShadowOuter.Parent = ShadowHolder

    local ShadowInner = Instance.new('ImageLabel')
    ShadowInner.Name = 'SoftShadowInner'
    ShadowInner.AnchorPoint = Vector2.new(0.5, 0.5)
    ShadowInner.Position = UDim2.new(0.5, 0, 0.5, 1)
    ShadowInner.Size = UDim2.new(1, 32, 1, 32)
    ShadowInner.BackgroundTransparency = 1
    ShadowInner.BorderSizePixel = 0
    ShadowInner.Image = 'rbxassetid://6014261993'
    ShadowInner.ImageColor3 = Color3.fromRGB(0, 0, 0)
    ShadowInner.ImageTransparency = 0.30
    ShadowInner.ScaleType = Enum.ScaleType.Slice
    ShadowInner.SliceCenter = Rect.new(49, 49, 450, 450)
    ShadowInner.ZIndex = 0
    ShadowInner.Parent = ShadowHolder

    Container:GetPropertyChangedSignal('Position'):Connect(function()
        ShadowHolder.Position = Container.Position
    end)
    Container:GetPropertyChangedSignal('Size'):Connect(function()
        ShadowHolder.Size = Container.Size
    end)

    local ContainerGradient = Instance.new("UIGradient")
    ContainerGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    ContainerGradient.Rotation = 90
    ContainerGradient.Parent = Container

    local Background = Instance.new('ImageLabel')
    Background.Name = 'Background'
    Background.Size = UDim2.new(1, 0, 1, 0)
    Background.Position = UDim2.new(0, 0, 0, 0)
    Background.BackgroundTransparency = 1
    Background.BorderSizePixel = 0
    Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Background.Image = ''
    Background.ImageTransparency = 0.5
    Background.ScaleType = Enum.ScaleType.Crop
    Background.Visible = false
    Background.ZIndex = 0
    Background.Parent = Container

    local UICorner_bg = Instance.new('UICorner')
    UICorner_bg.CornerRadius = UDim.new(0, 10)
    UICorner_bg.Parent = Background

    local Texture = Instance.new('ImageLabel')
    Texture.Name = 'Texture'
    Texture.Size = UDim2.new(1, 0, 1, 0)
    Texture.Position = UDim2.new(0, 0, 0, 0)
    Texture.BackgroundTransparency = 1
    Texture.BorderSizePixel = 0
    Texture.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Texture.Image = 'rbxassetid://9968344227'
    Texture.ImageColor3 = Color3.fromRGB(0, 0, 0)
    Texture.ImageTransparency = 0.88
    Texture.ScaleType = Enum.ScaleType.Tile
    Texture.TileSize = UDim2.new(0, 128, 0, 128)
    Texture.ZIndex = 0
    Texture.Parent = Container

    local SideBar = Instance.new("Frame")
    SideBar.Name = "GradientSide"
    SideBar.Parent = Container
    SideBar.Size = UDim2.new(0, 10, 1, 0)
    SideBar.Position = UDim2.new(0, 0, 0, 0)
    SideBar.BackgroundTransparency = 1

    local SideGradient = Instance.new("UIGradient")
    SideGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(92, 92, 92)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
    }
    SideGradient.Rotation = 90
    SideGradient.Parent = SideBar

    local UICorner = Instance.new('UICorner')
    UICorner.CornerRadius = UDim.new(0, 10)
    UICorner.Parent = Container

    local UIStroke = Instance.new('UIStroke')
    UIStroke.Color = Color3.fromRGB(68, 68, 68)
    UIStroke.Transparency = 0.58
    UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    UIStroke.Parent = Container

    local Handler = Instance.new('Frame')
    Handler.BackgroundTransparency = 1
    Handler.Name = 'Handler'
    Handler.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Handler.Size = UDim2.new(0, 752, 0, 479)
    Handler.BorderSizePixel = 0
    Handler.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Handler.Parent = Container

    local Tabs = Instance.new('ScrollingFrame')
    Tabs.ScrollBarImageTransparency = 1
    Tabs.ScrollBarThickness = 0
    Tabs.Name = 'Tabs'
    Tabs.Size = UDim2.new(0, 129, 0, 401)
    Tabs.Selectable = false
    Tabs.AutomaticCanvasSize = Enum.AutomaticSize.XY
    Tabs.BackgroundTransparency = 1
    Tabs.Position = UDim2.new(0, 18, 0, 67)
    Tabs.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Tabs.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Tabs.BorderSizePixel = 0
    Tabs.CanvasSize = UDim2.new(0, 0, 0.5, 0)
    Tabs.Parent = Handler

    local UIListLayout_Tabs = Instance.new('UIListLayout')
    UIListLayout_Tabs.Padding = UDim.new(0, 4)
    UIListLayout_Tabs.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout_Tabs.Parent = Tabs

    local ClientName = Instance.new('TextLabel')
    ClientName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
    ClientName.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextStrokeTransparency = 1
    ClientName.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.TextTransparency = 0
    ClientName.Text = 'Fallen'
    ClientName.Name = 'ClientName'
    ClientName.Size = UDim2.new(0, 110, 0, 19)
    ClientName.AnchorPoint = Vector2.new(0, 0.5)
    ClientName.Position = UDim2.new(0, 43, 0, 26)
    ClientName.BackgroundTransparency = 1
    ClientName.TextXAlignment = Enum.TextXAlignment.Left
    ClientName.BorderSizePixel = 0
    ClientName.BorderColor3 = Color3.fromRGB(0, 0, 0)
    ClientName.TextSize = 16
    ClientName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ClientName.Parent = Handler

    local Logo = Instance.new('ImageLabel')
    Logo.Name = 'Logo'
    Logo.Size = UDim2.new(0, 26, 0, 26)
    Logo.AnchorPoint = Vector2.new(0, 0.5)
    Logo.Position = UDim2.new(0, 14, 0, 26)
    Logo.BackgroundTransparency = 1
    Logo.BorderSizePixel = 0
    Logo.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Logo.Image = 'rbxassetid://86155014390461'
    Logo.ImageColor3 = Color3.fromRGB(255, 255, 255)
    Logo.ImageTransparency = 0
    Logo.ScaleType = Enum.ScaleType.Fit
    Logo.Parent = Handler

    local Pin = Instance.new('Frame')
    Pin.Name = 'Pin'
    Pin.Position = UDim2.new(0, 18, 0, 79)
    Pin.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Pin.Size = UDim2.new(0, 2, 0, 16)
    Pin.BorderSizePixel = 0
    Pin.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    Pin.Parent = Handler

    local UICorner2 = Instance.new('UICorner')
    UICorner2.CornerRadius = UDim.new(1, 0)
    UICorner2.Parent = Pin

    local Divider = Instance.new('Frame')
    Divider.Name = 'Divider'
    Divider.BackgroundTransparency = 0.65
    Divider.Position = UDim2.new(0, 164, 0, 75)
    Divider.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Divider.Size = UDim2.new(0, 1, 0, 330)
    Divider.BorderSizePixel = 0
    Divider.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    Divider.Parent = Handler

    local Sections = Instance.new('Folder')
    Sections.Name = 'Sections'
    Sections.Parent = Handler

    local Minimize = Instance.new('TextButton')
    Minimize.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    Minimize.TextColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Minimize.Text = ''
    Minimize.AutoButtonColor = false
    Minimize.Name = 'Minimize'
    Minimize.BackgroundTransparency = 1
    Minimize.Position = UDim2.new(0.020057305693626404, 0, 0.02922755666077137, 0)
    Minimize.Size = UDim2.new(0, 24, 0, 24)
    Minimize.BorderSizePixel = 0
    Minimize.TextSize = 14
    Minimize.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Minimize.Parent = Handler

    local Search = Instance.new('ImageButton')
    Search.Name = 'Search'
    Search.AutoButtonColor = false
    Search.BackgroundTransparency = 1
    Search.BorderSizePixel = 0
    Search.BorderColor3 = Color3.fromRGB(0, 0, 0)
    Search.Image = 'rbxassetid://102373102520464'
    Search.ImageColor3 = Color3.fromRGB(188, 188, 188)
    Search.ImageTransparency = 0
    Search.ScaleType = Enum.ScaleType.Fit
    Search.AnchorPoint = Vector2.new(1, 0.5)
    Search.Position = UDim2.new(0, 734, 0, 26)
    Search.Size = UDim2.new(0, 22, 0, 22)
    Search.Parent = Handler

    local UIScale = Instance.new('UIScale')
    UIScale.Parent = Container

    local ShadowScale
    if UserInputService.TouchEnabled then
        ShadowScale = Instance.new('UIScale')
        ShadowScale.Scale = UIScale.Scale
        ShadowScale.Parent = ShadowHolder
    end

    self._ui = Fallen

    local function on_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._drag_start = input.Position
            self._container_position = Container.Position
            Connections['container_input_ended'] = input.Changed:Connect(function()
                if input.UserInputState ~= Enum.UserInputState.End then return end
                Connections:disconnect('container_input_ended')
                self._dragging = false
            end)
        end
    end

    local function update_drag(input)
        local delta = input.Position - self._drag_start
        local position = UDim2.new(self._container_position.X.Scale, self._container_position.X.Offset + delta.X, self._container_position.Y.Scale, self._container_position.Y.Offset + delta.Y)
        TweenService:Create(Container, TweenInfo.new(0.2), { Position = position }):Play()
    end

    local function drag(input)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        Connections:disconnect_all()
    end)

    function self:change_visiblity(state)
        Library._ui_open = state
        ShadowHolder.Visible = state
        if state then
            ContainerGradient.Enabled = true
            ContainerGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
                ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
            }
            ContainerGradient.Rotation = 90
            Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Logo.Position = UDim2.new(0, 14, 0, 26)
            ClientName.Position = UDim2.new(0, 43, 0, 26)
            Library._minimized = false
            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        else
            ContainerGradient.Enabled = true
            ContainerGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0.00, Color3.fromRGB(72, 72, 72)),
                ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))
            }
            ContainerGradient.Rotation = 90
            Container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Logo.Position = UDim2.new(0, 10, 0, 26)
            ClientName.Position = UDim2.new(0, 39, 0, 26)
            Library._minimized = true
            if Library._hide_when_minimized then
                Fallen.Enabled = false
            else
                TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(104.5, 52)
                }):Play()
            end
        end
    end

    function self:set_gui_visibility(state)
        if not self._ui then return end
        if state then
            self._ui.Enabled = true
            Container.Size = UDim2.fromOffset(0, 0)
            TweenService:Create(Container, TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        else
            local t = TweenService:Create(Container, TweenInfo.new(0.25, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {
                Size = UDim2.fromOffset(0, 0)
            })
            t:Play()
            t.Completed:Once(function()
                self._ui.Enabled = false
            end)
        end
    end

    function self:load()
        self:get_device()
        if self._device == 'Mobile' or self._device == 'Unknown' then
            self:get_screen_scale()
            UIScale.Scale = self._ui_scale
            if ShadowScale then ShadowScale.Scale = self._ui_scale end
            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
                if ShadowScale then ShadowScale.Scale = self._ui_scale end
            end)
        end
        ShadowHolder.Visible = true
        TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    end

    function self:update_tabs(tab)
        for _, object in Tabs:GetChildren() do
            if object.Name ~= 'Tab' then continue end
            if object == tab then
                if object.BackgroundTransparency ~= 0.5 then
                    local offset = object.LayoutOrder * 42
                    TweenService:Create(Pin, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 18, 0, 79 + offset)
                    }):Play()
                    TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundTransparency = 0.5
                    }):Play()
                    local tl = object:FindFirstChild("TextLabel")
                    if tl then
                        TweenService:Create(tl, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            TextTransparency = 0,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                        local tg = tl:FindFirstChild("UIGradient")
                        if tg then
                            TweenService:Create(tg, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                                Offset = Vector2.new(1, 0)
                            }):Play()
                        end
                    end
                    local ic = object:FindFirstChild("Icon")
                    if ic then
                        TweenService:Create(ic, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageColor3 = ic:GetAttribute('ActiveColor') or Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end
                end
                continue
            end
            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()
                local tl = object:FindFirstChild("TextLabel")
                if tl then
                    TweenService:Create(tl, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Color3.fromRGB(138, 138, 138)
                    }):Play()
                    local tg = tl:FindFirstChild("UIGradient")
                    if tg then
                        TweenService:Create(tg, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Offset = Vector2.new(0, 0)
                        }):Play()
                    end
                end
                local ic = object:FindFirstChild("Icon")
                if ic then
                    TweenService:Create(ic, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageColor3 = ic:GetAttribute('IdleColor') or Color3.fromRGB(138, 138, 138)
                    }):Play()
                end
            end
        end
    end

    function self:update_sections(left_section, right_section)
        for _, object in Sections:GetChildren() do
            if object == left_section or object == right_section then
                object.Visible = true
                continue
            end
            object.Visible = false
        end
    end

    function self:create_tab(title, icon, icon_size, idle_color, active_color)
        local TabManager = {}

        local font_params = Instance.new('GetTextBoundsParams')
        font_params.Text = title
        font_params.Font = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        font_params.Size = 13
        font_params.Width = 10000

        local font_size = TextService:GetTextBoundsAsync(font_params)
        local first_tab = not Tabs:FindFirstChild('Tab')

        local Tab = Instance.new('TextButton')
        Tab.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        Tab.TextColor3 = Color3.fromRGB(0, 0, 0)
        Tab.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Tab.Text = ''
        Tab.AutoButtonColor = false
        Tab.BackgroundTransparency = 1
        Tab.Name = 'Tab'
        Tab.Size = UDim2.new(0, 129, 0, 38)
        Tab.BorderSizePixel = 0
        Tab.TextSize = 14
        Tab.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        Tab.Parent = Tabs
        Tab.LayoutOrder = self._tab

        local UICorner_Tab = Instance.new('UICorner')
        UICorner_Tab.CornerRadius = UDim.new(0, 5)
        UICorner_Tab.Parent = Tab

        local TextLabel = Instance.new('TextLabel')
        TextLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        TextLabel.TextColor3 = Color3.fromRGB(138, 138, 138)
        TextLabel.TextTransparency = 0
        TextLabel.Text = title
        TextLabel.Size = UDim2.new(0, font_size.X, 0, 16)
        TextLabel.AnchorPoint = Vector2.new(0, 0.5)
        TextLabel.Position = UDim2.new(0, 37, 0.5, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.BorderSizePixel = 0
        TextLabel.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextLabel.TextSize = 13
        TextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextLabel.Parent = Tab

        local UIGradient_Tab = Instance.new('UIGradient')
        UIGradient_Tab.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient_Tab.Parent = TextLabel

        local Icon = Instance.new('ImageLabel')
        Icon.Name = 'Icon'
        Icon.Size = UDim2.new(0, icon_size or 16, 0, icon_size or 16)
        Icon.AnchorPoint = Vector2.new(0.5, 0.5)
        Icon.Position = UDim2.new(0, 19, 0.5, 0)
        Icon.BackgroundTransparency = 1
        Icon.BorderSizePixel = 0
        Icon.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Icon.Image = icon or ''
        Icon.ImageColor3 = idle_color or Color3.fromRGB(138, 138, 138)
        Icon:SetAttribute('IdleColor', idle_color or Color3.fromRGB(138, 138, 138))
        Icon:SetAttribute('ActiveColor', active_color or Color3.fromRGB(255, 255, 255))
        Icon.ImageTransparency = 0
        Icon.ScaleType = Enum.ScaleType.Fit
        Icon.Parent = Tab

        local LeftSection = Instance.new('ScrollingFrame')
        LeftSection.Name = 'LeftSection'
        LeftSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        LeftSection.ScrollBarThickness = 0
        LeftSection.ScrollBarImageTransparency = 1
        LeftSection.Size = UDim2.new(0, 243, 0, 395)
        LeftSection.Selectable = false
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 203, 0, 67)
        LeftSection.BorderSizePixel = 0
        LeftSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        LeftSection.Visible = false
        LeftSection.Parent = Sections

        local UIListLayout_L = Instance.new('UIListLayout')
        UIListLayout_L.Padding = UDim.new(0, 11)
        UIListLayout_L.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_L.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_L.Parent = LeftSection
        local UIPadding_L = Instance.new('UIPadding')
        UIPadding_L.PaddingTop = UDim.new(0, 1)
        UIPadding_L.Parent = LeftSection

        local RightSection = Instance.new('ScrollingFrame')
        RightSection.Name = 'RightSection'
        RightSection.AutomaticCanvasSize = Enum.AutomaticSize.XY
        RightSection.ScrollBarThickness = 0
        RightSection.Size = UDim2.new(0, 243, 0, 395)
        RightSection.Selectable = false
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
        RightSection.BorderSizePixel = 0
        RightSection.CanvasSize = UDim2.new(0, 0, 0.5, 0)
        RightSection.Visible = false
        RightSection.Parent = Sections

        local UIListLayout_R = Instance.new('UIListLayout')
        UIListLayout_R.Padding = UDim.new(0, 11)
        UIListLayout_R.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_R.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_R.Parent = RightSection

        local UIPadding_R = Instance.new('UIPadding')
        UIPadding_R.PaddingTop = UDim.new(0, 1)
        UIPadding_R.Parent = RightSection

        self._tab += 1

        if first_tab then
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0
            }

local module_flag = settings.flag or ("module_" .. tostring(self._tab or 0) .. "_" .. tostring(LayoutOrderModule or 0))

            if settings.section == 'right' then
                settings.section = RightSection
            else
                settings.section = LeftSection
            end

            local Module = Instance.new('Frame')
            Module.ClipsDescendants = true
            Module.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Module.BackgroundTransparency = 0
            Module.Position = UDim2.new(0.004115226212888956, 0, 0, 0)
            Module.Name = 'Module'
            Module.Size = UDim2.new(0, 241, 0, 93)
            Module.BorderSizePixel = 0
            Module.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Module.Parent = settings.section

            local UIListLayout_Mod = Instance.new('UIListLayout')
            UIListLayout_Mod.Padding = UDim.new(0, 2)
            UIListLayout_Mod.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Mod.Parent = Module

            local UICorner_Mod = Instance.new('UICorner')
            UICorner_Mod.CornerRadius = UDim.new(0, 9)
            UICorner_Mod.Parent = Module

            local UIStroke_Mod = Instance.new('UIStroke')
            UIStroke_Mod.Color = Color3.fromRGB(255, 255, 255)
            UIStroke_Mod.Transparency = 0.72
            UIStroke_Mod.Thickness = 1
            UIStroke_Mod.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke_Mod.Parent = Module

            local ModuleScrollTrack = Instance.new('Frame')
            ModuleScrollTrack.Name = 'ModuleScrollTrack'
            ModuleScrollTrack.AnchorPoint = Vector2.new(1, 0)
            ModuleScrollTrack.Position = UDim2.new(1, 9, 0, 4)
            ModuleScrollTrack.Size = UDim2.new(0, 4, 0, 140)
            ModuleScrollTrack.BackgroundColor3 = Color3.fromRGB(72, 72, 78)
            ModuleScrollTrack.BackgroundTransparency = 0.55
            ModuleScrollTrack.BorderSizePixel = 0
            ModuleScrollTrack.ZIndex = 20
            ModuleScrollTrack.Visible = false
            ModuleScrollTrack.Parent = Handler

            local ModuleScrollTrackCorner = Instance.new('UICorner')
            ModuleScrollTrackCorner.CornerRadius = UDim.new(1, 0)
            ModuleScrollTrackCorner.Parent = ModuleScrollTrack

            local ModuleScrollThumb = Instance.new('Frame')
            ModuleScrollThumb.Name = 'Thumb'
            ModuleScrollThumb.AnchorPoint = Vector2.new(0.5, 0)
            ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
            ModuleScrollThumb.Size = UDim2.new(1, 0, 0, 88)
            ModuleScrollThumb.BackgroundColor3 = Color3.fromRGB(232, 232, 236)
            ModuleScrollThumb.BackgroundTransparency = 0.08
            ModuleScrollThumb.BorderSizePixel = 0
            ModuleScrollThumb.ZIndex = 21
            ModuleScrollThumb.Parent = ModuleScrollTrack

            local ModuleScrollThumbCorner = Instance.new('UICorner')
            ModuleScrollThumbCorner.CornerRadius = UDim.new(1, 0)
            ModuleScrollThumbCorner.Parent = ModuleScrollThumb

            local function UpdateModuleScrollIndicator()
                local scale = UIScale.Scale
                local useScale = UserInputService.TouchEnabled
                local moduleX = useScale and (Module.AbsolutePosition.X - Handler.AbsolutePosition.X) / scale or (Module.AbsolutePosition.X - Handler.AbsolutePosition.X)
                local moduleY = useScale and (Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale or (Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y)
                local sectionTop = useScale and (settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale or (settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y)
                local viewportHeight = useScale and settings.section.AbsoluteWindowSize.Y / scale or settings.section.AbsoluteWindowSize.Y
                local moduleWidth = useScale and Module.AbsoluteSize.X / scale or Module.AbsoluteSize.X
                local moduleHeight = useScale and Module.AbsoluteSize.Y / scale or Module.AbsoluteSize.Y

                local moduleTop = math.max(moduleY + 4, sectionTop + 4)
                local moduleBottom = math.min(moduleY + moduleHeight - 4, sectionTop + viewportHeight - 4)
                local trackHeight = math.max(moduleBottom - moduleTop, 1)
                ModuleScrollTrack.Position = UDim2.fromOffset(moduleX + moduleWidth + 10, moduleTop)
                ModuleScrollTrack.Size = UDim2.new(0, 4, 0, trackHeight)

                local vpH = useScale and settings.section.AbsoluteWindowSize.Y / scale or settings.section.AbsoluteWindowSize.Y
                local canvasH = useScale and settings.section.AbsoluteCanvasSize.Y / scale or settings.section.AbsoluteCanvasSize.Y
                local scrollable = canvasH > vpH + 1
                ModuleScrollTrack.Visible = ModuleManager._state and settings.section.Visible and Library._ui_open

                if not scrollable then
                    ModuleScrollThumb.Size = UDim2.new(1, 0, 0, math.clamp(ModuleScrollTrack.AbsoluteSize.Y * 0.52, 80, 112))
                    ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
                    return
                end

                local tH = math.max(ModuleScrollTrack.AbsoluteSize.Y, 1)
                local thumbMin = math.min(80, tH)
                local thumbMax = math.min(math.max(thumbMin, 112), tH)
                local thumbHeight = math.clamp(tH * (vpH / canvasH), thumbMin, thumbMax)
                local maxCanvas = math.max(canvasH - vpH, 1)
                local maxThumb = math.max(tH - thumbHeight, 0)
                local thumbPos = maxThumb * math.clamp(settings.section.CanvasPosition.Y / maxCanvas, 0, 1)

                ModuleScrollThumb.Size = UDim2.new(1, 0, 0, thumbHeight)
                ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, thumbPos)
            end

            settings.section:GetPropertyChangedSignal('CanvasPosition'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('AbsoluteCanvasSize'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('AbsoluteWindowSize'):Connect(UpdateModuleScrollIndicator)
            settings.section:GetPropertyChangedSignal('Visible'):Connect(UpdateModuleScrollIndicator)
            Module:GetPropertyChangedSignal('AbsoluteSize'):Connect(UpdateModuleScrollIndicator)
            Module:GetPropertyChangedSignal('AbsolutePosition'):Connect(UpdateModuleScrollIndicator)

            local Header = Instance.new('TextButton')
            Header.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Header.TextColor3 = Color3.fromRGB(0, 0, 0)
            Header.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Header.Text = ''
            Header.AutoButtonColor = false
            Header.BackgroundTransparency = 1
            Header.Name = 'Header'
            Header.Size = UDim2.new(0, 241, 0, 93)
            Header.BorderSizePixel = 0
            Header.TextSize = 14
            Header.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Header.Parent = Module

            local ModuleName = Instance.new('TextLabel')
            ModuleName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleName.TextColor3 = Color3.fromRGB(238, 238, 242)
            ModuleName.TextTransparency = 0
            if not settings.rich then
                ModuleName.Text = settings.title or "Module"
            else
                ModuleName.RichText = true
                ModuleName.Text = settings.richtext or "<font color='rgb(255,255,255)'>Fallen</font> user"
            end
            ModuleName.Name = 'ModuleName'
            ModuleName.Size = UDim2.new(0, 205, 0, 13)
            ModuleName.AnchorPoint = Vector2.new(0, 0.5)
            ModuleName.Position = UDim2.new(0, 14, 0, 22)
            ModuleName.BackgroundTransparency = 1
            ModuleName.TextXAlignment = Enum.TextXAlignment.Left
            ModuleName.BorderSizePixel = 0
            ModuleName.TextSize = 13
            ModuleName.Parent = Header

            local LockIcon = Instance.new('ImageLabel')
            LockIcon.Name = 'LockIcon'
            LockIcon.Image = 'rbxassetid://132906779122559'
            LockIcon.ImageColor3 = Color3.fromRGB(178, 178, 185)
            LockIcon.ImageTransparency = 0.14
            LockIcon.ScaleType = Enum.ScaleType.Fit
            LockIcon.AnchorPoint = Vector2.new(1, 0)
            LockIcon.Position = UDim2.new(1, -12, 0, 8.5)
            LockIcon.Size = UDim2.fromOffset(23, 23)
            LockIcon.BackgroundTransparency = 1
            LockIcon.BorderSizePixel = 0
            LockIcon.Parent = Header

            local Description = Instance.new('TextLabel')
            Description.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            Description.TextColor3 = Color3.fromRGB(142, 142, 151)
            Description.TextTransparency = 0
            Description.Text = settings.description or ''
            Description.Name = 'Description'
            Description.Size = UDim2.new(0, 205, 0, 13)
            Description.AnchorPoint = Vector2.new(0, 0.5)
            Description.Position = UDim2.new(0, 14, 0, 40)
            Description.BackgroundTransparency = 1
            Description.TextXAlignment = Enum.TextXAlignment.Left
            Description.BorderSizePixel = 0
            Description.TextSize = 10
            Description.Parent = Header

            local Toggle = Instance.new('Frame')
            Toggle.Name = 'Toggle'
            Toggle.BackgroundTransparency = 0
            Toggle.Position = UDim2.new(0, 229, 0, 76)
            Toggle.AnchorPoint = Vector2.new(1, 0.5)
            Toggle.Size = UDim2.new(0, 30, 0, 16)
            Toggle.BorderSizePixel = 0
            Toggle.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
            Toggle.Parent = Header

            local ToggleCorner = Instance.new('UICorner')
            ToggleCorner.CornerRadius = UDim.new(1, 0)
            ToggleCorner.Parent = Toggle

            local Circle = Instance.new('Frame')
            Circle.AnchorPoint = Vector2.new(0, 0.5)
            Circle.BackgroundTransparency = 0
            Circle.Position = UDim2.new(0, 2, 0.5, 0)
            Circle.Name = 'Circle'
            Circle.Size = UDim2.new(0, 12, 0, 12)
            Circle.BorderSizePixel = 0
            Circle.BackgroundColor3 = Color3.fromRGB(126, 126, 136)
            Circle.Parent = Toggle

            local CircleCorner = Instance.new('UICorner')
            CircleCorner.CornerRadius = UDim.new(1, 0)
            CircleCorner.Parent = Circle

            local Keybind = Instance.new('TextButton')
            Keybind.Name = 'Keybind'
            Keybind.AutoButtonColor = false
            Keybind.Text = ''
            Keybind.BackgroundTransparency = 0
            Keybind.Position = UDim2.new(0, 34, 0, 67)
            Keybind.Size = UDim2.new(0, 38, 0, 16)
            Keybind.BorderSizePixel = 0
            Keybind.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            Keybind.Parent = Header

            local HeaderIcon = Instance.new('ImageLabel')
            HeaderIcon.Name = 'Icon'
            HeaderIcon.Image = settings.icon or 'rbxassetid://79095934438045'
            HeaderIcon.ImageColor3 = Color3.fromRGB(195, 195, 202)
            HeaderIcon.ImageTransparency = 0
            HeaderIcon.ScaleType = Enum.ScaleType.Fit
            HeaderIcon.AnchorPoint = Vector2.new(0, 0.5)
            HeaderIcon.Position = UDim2.new(0, 13, 0, 75)
            HeaderIcon.Size = UDim2.fromOffset(17, 17)
            HeaderIcon.BackgroundTransparency = 1
            HeaderIcon.BorderSizePixel = 0
            HeaderIcon.Parent = Header

            local KeybindCorner = Instance.new('UICorner')
            KeybindCorner.CornerRadius = UDim.new(0, 2)
            KeybindCorner.Parent = Keybind

            local KeybindStroke = Instance.new('UIStroke')
            KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
            KeybindStroke.Transparency = 0.68
            KeybindStroke.Thickness = 1
            KeybindStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            KeybindStroke.Parent = Keybind

            local KeybindLabel = Instance.new('TextLabel')
            KeybindLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            KeybindLabel.TextColor3 = Color3.fromRGB(195, 195, 202)
            KeybindLabel.Text = 'None'
            KeybindLabel.Size = UDim2.new(1, -10, 1, 0)
            KeybindLabel.Position = UDim2.new(0, 5, 0, 0)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Center
            KeybindLabel.TextYAlignment = Enum.TextYAlignment.Center
            KeybindLabel.BorderSizePixel = 0
            KeybindLabel.TextSize = 10
            KeybindLabel.Parent = Keybind

            local Divider1 = Instance.new('Frame')
            Divider1.AnchorPoint = Vector2.new(0.5, 0)
            Divider1.BackgroundTransparency = 0.72
            Divider1.Position = UDim2.new(0.5, 0, 0.62, 0)
            Divider1.Name = 'Divider'
            Divider1.Size = UDim2.new(0, 241, 0, 1)
            Divider1.BorderSizePixel = 0
            Divider1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider1.Parent = Header

            local Divider2 = Instance.new('Frame')
            Divider2.AnchorPoint = Vector2.new(0.5, 0)
            Divider2.BackgroundTransparency = 0.72
            Divider2.Position = UDim2.new(0.5, 0, 1, 0)
            Divider2.Name = 'Divider'
            Divider2.Size = UDim2.new(0, 241, 0, 1)
            Divider2.BorderSizePixel = 0
            Divider2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider2.Parent = Header

            local Options = Instance.new('Frame')
            Options.Name = 'Options'
            Options.BackgroundTransparency = 1
            Options.Position = UDim2.new(0, 0, 1, 2)
            Options.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Options.Size = UDim2.new(0, 241, 0, 8)
            Options.BorderSizePixel = 0
            Options.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Options.Parent = Module

            local UIPadding = Instance.new('UIPadding')
            UIPadding.PaddingTop = UDim.new(0, 8)
            UIPadding.Parent = Options

            local UIListLayout_Opts = Instance.new('UIListLayout')
            UIListLayout_Opts.Padding = UDim.new(0, 7)
            UIListLayout_Opts.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_Opts.SortOrder = Enum.SortOrder.LayoutOrder
            UIListLayout_Opts.Parent = Options

            local saved_kb = Library._config._keybinds[module_flag] or "None"
            KeybindLabel.Text = saved_kb
            local module_kb = saved_kb
            local choosing_kb = false

            local function format_key(keycode)
                local name = tostring(keycode)
                name = name:gsub("Enum.KeyCode.", "")
                if name == "LeftShift" then name = "L-Shift"
                elseif name == "RightShift" then name = "R-Shift"
                elseif name == "LeftControl" then name = "L-Ctrl"
                elseif name == "RightControl" then name = "R-Ctrl"
                elseif name == "LeftAlt" then name = "L-Alt"
                elseif name == "RightAlt" then name = "R-Alt"
                elseif name == "MouseButton1" then name = "MB1"
                elseif name == "MouseButton2" then name = "MB2"
                elseif name == "MouseButton3" then name = "MB3"
                end
                return name
            end

            local function update_toggle_visual(state)
                if state then
                    TweenService:Create(Toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(200, 200, 210)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 16, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                    }):Play()
                else
                    TweenService:Create(Toggle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                    }):Play()
                end
            end

            function ModuleManager:change_state(state)
                self._state = state
                Library._config._flags[module_flag] = state
                Config:save(game.GameId, Library._config)
                ModuleScrollTrack.Visible = self._state and settings.section.Visible
                task.defer(UpdateModuleScrollIndicator)
                task.delay(0.3, UpdateModuleScrollIndicator)
                Library:update_keybind_entry(module_flag)

                if self._state then
                    TweenService:Create(Module, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93 + self._size)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 229, 0, 76 + self._size)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, self._size)
                    }):Play()
                    TweenService:Create(Divider2, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0.5, 0, 1, 0)
                    }):Play()
                else
                    TweenService:Create(Module, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93)
                    }):Play()
                    TweenService:Create(Toggle, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 229, 0, 76)
                    }):Play()
                    TweenService:Create(Options, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 8)
                    }):Play()
                    TweenService:Create(Divider2, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0.5, 0, 0.62, 0)
                    }):Play()
                end
            end

            local saved_state = Library._config._flags[module_flag]
            if saved_state ~= nil then
                ModuleManager._state = saved_state
                update_toggle_visual(saved_state)
                if saved_state then
                    Module.Size = UDim2.new(0, 241, 0, 93)
                    Options.Size = UDim2.new(0, 241, 0, 8)
                    Toggle.Position = UDim2.new(0, 229, 0, 76)
                    Divider2.Position = UDim2.new(0.5, 0, 0.62, 0)
                end
            end

            Library:register_keybind(module_flag, settings.title or module_flag, module_kb, function()
                return ModuleManager._state
            end)

            Toggle.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    local new_state = not ModuleManager._state
                    ModuleManager:change_state(new_state)
                    update_toggle_visual(new_state)
                end
            end)

            Header.MouseButton1Click:Connect(function(input)
                if choosing_kb then return end
                local new_state = not ModuleManager._state
                ModuleManager:change_state(new_state)
                update_toggle_visual(new_state)
            end)

            Keybind.MouseButton1Click:Connect(function()
                choosing_kb = true
                Library._choosing_keybind = true
                KeybindLabel.Text = '...'
            end)

            Connections['module_kb_' .. module_flag] = UserInputService.InputBegan:Connect(function(input, gp)
                if not choosing_kb then return end
                if gp then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    choosing_kb = false
                    Library._choosing_keybind = false
                    module_kb = format_key(input.KeyCode)
                    KeybindLabel.Text = module_kb
                    Library._config._keybinds[module_flag] = module_kb
                    Config:save(game.GameId, Library._config)
                    Library:register_keybind(module_flag, settings.title or module_flag, module_kb, function()
                        return ModuleManager._state
                    end)
                end
            end)

            Connections['module_kb_exec_' .. module_flag] = UserInputService.InputBegan:Connect(function(input, gp)
                if choosing_kb then return end
                if gp then return end
                if Library._choosing_keybind then return end
                if input.UserInputType == Enum.UserInputType.Keyboard then
                    if format_key(input.KeyCode) == module_kb then
                        local new_state = not ModuleManager._state
                        ModuleManager:change_state(new_state)
                        update_toggle_visual(new_state)
                    end
                end
            end)

            function ModuleManager:toggle(toggle_settings)
                LayoutOrderModule += 1
                local flag = toggle_settings.flag or (module_flag .. "_opt_" .. LayoutOrderModule)
                local default = toggle_settings.default or false
                local callback = toggle_settings.callback or function() end

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end
                local current = Library._config._flags[flag]

                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 20)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = Color3.fromRGB(160, 160, 168)
                lbl.Text = toggle_settings.text or flag
                lbl.Size = UDim2.new(0.7, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 11
                lbl.Parent = row

                local btn = Instance.new('TextButton')
                btn.Size = UDim2.new(0, 36, 0, 16)
                btn.AnchorPoint = Vector2.new(1, 0.5)
                btn.Position = UDim2.new(1, 0, 0.5, 0)
                btn.BackgroundColor3 = current and Color3.fromRGB(200, 200, 210) or Color3.fromRGB(40, 40, 45)
                btn.BorderSizePixel = 0
                btn.Text = ''
                btn.AutoButtonColor = false
                btn.Parent = row
                Instance.new('UICorner').Parent = btn
                btn.UICorner.CornerRadius = UDim.new(1, 0)

                local dot = Instance.new('Frame')
                dot.Size = UDim2.new(0, 12, 0, 12)
                dot.AnchorPoint = Vector2.new(0, 0.5)
                dot.Position = current and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0)
                dot.BackgroundColor3 = current and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(100, 100, 108)
                dot.BorderSizePixel = 0
                dot.Parent = btn
                Instance.new('UICorner').Parent = dot
                dot.UICorner.CornerRadius = UDim.new(1, 0)

                btn.MouseButton1Click:Connect(function()
                    current = not current
                    Library._config._flags[flag] = current
                    Config:save(game.GameId, Library._config)
                    TweenService:Create(btn, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = current and Color3.fromRGB(200, 200, 210) or Color3.fromRGB(40, 40, 45)
                    }):Play()
                    TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = current and UDim2.new(0, 20, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = current and Color3.fromRGB(0, 0, 0) or Color3.fromRGB(100, 100, 108)
                    }):Play()
                    callback(current)
                end)

                ModuleManager._size += 20
                return ModuleManager
            end

            function ModuleManager:slider(slider_settings)
                LayoutOrderModule += 1
                local flag = slider_settings.flag or (module_flag .. "_opt_" .. LayoutOrderModule)
                local min_val = slider_settings.min or 0
                local max_val = slider_settings.max or 100
                local default = slider_settings.default or min_val
                local suffix = slider_settings.suffix or ""
                local fmt = slider_settings.format or "%.1f"
                local callback = slider_settings.callback or function() end

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end
                local current = Library._config._flags[flag]

                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 38)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local topRow = Instance.new('Frame')
                topRow.Size = UDim2.new(1, 0, 0, 14)
                topRow.BackgroundTransparency = 1
                topRow.BorderSizePixel = 0
                topRow.Parent = row

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = Color3.fromRGB(160, 160, 168)
                lbl.Text = slider_settings.text or flag
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 11
                lbl.Parent = topRow

                local valLbl = Instance.new('TextLabel')
                valLbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                valLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                valLbl.Text = fmt:format(current) .. suffix
                valLbl.Size = UDim2.new(0.4, 0, 1, 0)
                valLbl.AnchorPoint = Vector2.new(1, 0)
                valLbl.Position = UDim2.new(1, 0, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.TextXAlignment = Enum.TextXAlignment.Right
                valLbl.TextSize = 11
                valLbl.Parent = topRow

                local track = Instance.new('Frame')
                track.Size = UDim2.new(1, 0, 0, 6)
                track.Position = UDim2.new(0, 0, 0, 20)
                track.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                track.BorderSizePixel = 0
                track.Parent = row
                Instance.new('UICorner').Parent = track
                track.UICorner.CornerRadius = UDim.new(1, 0)

                local fill = Instance.new('Frame')
                fill.Size = UDim2.new(0, 0, 1, 0)
                fill.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
                fill.BorderSizePixel = 0
                fill.Parent = track
                Instance.new('UICorner').Parent = fill
                fill.UICorner.CornerRadius = UDim.new(1, 0)

                local input = Instance.new('TextButton')
                input.Size = UDim2.new(1, 0, 0, 20)
                input.Position = UDim2.new(0, 0, 0, 16)
                input.BackgroundTransparency = 1
                input.Text = ''
                input.AutoButtonColor = false
                input.Parent = row

                local function update(val)
                    local clamped = math.clamp(val, min_val, max_val)
                    current = clamped
                    Library._config._flags[flag] = clamped
                    local pct = (clamped - min_val) / (max_val - min_val)
                    fill.Size = UDim2.new(pct, 0, 1, 0)
                    valLbl.Text = fmt:format(clamped) .. suffix
                    Config:save(game.GameId, Library._config)
                end

                update(current)

                local sliding = false
                input.MouseButton1Down:Connect(function() sliding = true end)
                UserInputService.InputEnded:Connect(function(inp)
                    if (inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch) and sliding then
                        sliding = false
                        callback(current)
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not sliding then return end
                    if inp.UserInputType ~= Enum.UserInputType.MouseMovement and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                    local rx = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                    update(min_val + rx * (max_val - min_val))
                end)

                ModuleManager._size += 38
                return ModuleManager
            end

            function ModuleManager:dropdown(dropdown_settings)
                LayoutOrderModule += 1
                local flag = dropdown_settings.flag or (module_flag .. "_opt_" .. LayoutOrderModule)
                local list = dropdown_settings.list or {}
                local default = dropdown_settings.default or list[1] or ""
                local callback = dropdown_settings.callback or function() end
                local multi = dropdown_settings.multi or false

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = multi and {default} or default
                end
                local current = Library._config._flags[flag]
                local is_open = false

                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 22)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.ClipsDescendants = false
                row.Parent = Options

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = Color3.fromRGB(160, 160, 168)
                lbl.Text = dropdown_settings.text or flag
                lbl.Size = UDim2.new(1, 0, 0, 12)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 11
                lbl.Parent = row

                local btn = Instance.new('TextButton')
                btn.Size = UDim2.new(1, 0, 0, 18)
                btn.Position = UDim2.new(0, 0, 0, 14)
                btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                btn.BorderSizePixel = 0
                btn.Text = ''
                btn.AutoButtonColor = false
                btn.Parent = row
                Instance.new('UICorner').Parent = btn
                btn.UICorner.CornerRadius = UDim.new(0, 4)

                local valLbl = Instance.new('TextLabel')
                valLbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                valLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                valLbl.Text = multi and convertTableToString(current) or tostring(current)
                valLbl.Size = UDim2.new(1, -20, 1, 0)
                valLbl.Position = UDim2.new(0, 6, 0, 0)
                valLbl.BackgroundTransparency = 1
                valLbl.TextXAlignment = Enum.TextXAlignment.Left
                valLbl.TextSize = 10
                valLbl.TextTruncate = Enum.TextTruncate.AtEnd
                valLbl.Parent = btn

                local arrow = Instance.new('TextLabel')
                arrow.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                arrow.TextColor3 = Color3.fromRGB(120, 120, 128)
                arrow.Text = '∨'
                arrow.Size = UDim2.new(0, 14, 1, 0)
                arrow.AnchorPoint = Vector2.new(1, 0)
                arrow.Position = UDim2.new(1, 3, 0, 0)
                arrow.BackgroundTransparency = 1
                arrow.TextSize = 11
                arrow.Parent = btn

                local dropList = Instance.new('Frame')
                dropList.Size = UDim2.new(1, 0, 0, 0)
                dropList.Position = UDim2.new(0, 0, 0, 34)
                dropList.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
                dropList.BorderSizePixel = 0
                dropList.ClipsDescendants = true
                dropList.Visible = false
                dropList.ZIndex = 10
                dropList.Parent = row
                Instance.new('UICorner').Parent = dropList
                dropList.UICorner.CornerRadius = UDim.new(0, 4)

                local dropListLayout = Instance.new('UIListLayout')
                dropListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                dropListLayout.Parent = dropList
                local dropListPad = Instance.new('UIPadding')
                dropListPad.PaddingTop = UDim.new(0, 2)
                dropListPad.PaddingBottom = UDim.new(0, 2)
                dropListPad.Parent = dropList

                local function refresh()
                    for _, c in dropList:GetChildren() do
                        if c:IsA('TextButton') then c:Destroy() end
                    end
                    for i, item in ipairs(list) do
                        local b = Instance.new('TextButton')
                        b.Size = UDim2.new(1, -4, 0, 18)
                        b.Position = UDim2.new(0, 2, 0, 0)
                        b.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                        b.BackgroundTransparency = 0
                        b.BorderSizePixel = 0
                        b.Text = ''
                        b.AutoButtonColor = false
                        b.LayoutOrder = i
                        b.Parent = dropList

                        local sel = false
                        if multi then
                            for _, v in ipairs(current) do if v == item then sel = true break end end
                        else
                            sel = (current == item)
                        end

                        local il = Instance.new('TextLabel')
                        il.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                        il.TextColor3 = sel and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 168)
                        il.Text = item
                        il.Size = UDim2.new(1, -18, 1, 0)
                        il.Position = UDim2.new(0, 6, 0, 0)
                        il.BackgroundTransparency = 1
                        il.TextXAlignment = Enum.TextXAlignment.Left
                        il.TextSize = 10
                        il.TextTruncate = Enum.TextTruncate.AtEnd
                        il.Parent = b

                        b.MouseButton1Click:Connect(function()
                            if multi then
                                local found = false
                                for idx, v in ipairs(current) do
                                    if v == item then table.remove(current, idx) found = true break end
                                end
                                if not found then table.insert(current, item) end
                                valLbl.Text = convertTableToString(current)
                            else
                                current = item
                                valLbl.Text = tostring(item)
                            end
                            Library._config._flags[flag] = current
                            Config:save(game.GameId, Library._config)
                            refresh()
                            callback(current)
                        end)

                        b.MouseEnter:Connect(function()
                            TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                        end)
                        b.MouseLeave:Connect(function()
                            TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(30, 30, 35)}):Play()
                        end)
                    end
                    dropList.AutomaticSize = Enum.AutomaticSize.Y
                end

                refresh()
                ModuleManager._size += 24

                btn.MouseButton1Click:Connect(function()
                    is_open = not is_open
                    dropList.Visible = is_open
                    arrow.Text = is_open and '∧' or '∨'
                    if is_open then
                        ModuleManager._size = ModuleManager._size - 24 + 24 + dropListLayout.AbsoluteContentSize.Y + 4
                        ModuleManager:change_state(ModuleManager._state)
                    else
                        ModuleManager._size = ModuleManager._size - dropListLayout.AbsoluteContentSize.Y - 4
                        ModuleManager:change_state(ModuleManager._state)
                    end
                end)

                return ModuleManager
            end

            function ModuleManager:keybind(kb_settings)
                LayoutOrderModule += 1
                local flag = kb_settings.flag or (module_flag .. "_kb_" .. LayoutOrderModule)
                local default = kb_settings.default or "None"
                local callback = kb_settings.callback or function() end
                local ignore_pressed = kb_settings.ignore_pressed or false

                if Library._config._keybinds[flag] == nil then
                    Library._config._keybinds[flag] = default
                end
                local current_key = Library._config._keybinds[flag]
                local choosing = false

                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 20)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = Color3.fromRGB(160, 160, 168)
                lbl.Text = kb_settings.text or flag
                lbl.Size = UDim2.new(0.6, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 11
                lbl.Parent = row

                local kbBtn = Instance.new('TextButton')
                kbBtn.Size = UDim2.new(0, 60, 0, 16)
                kbBtn.AnchorPoint = Vector2.new(1, 0.5)
                kbBtn.Position = UDim2.new(1, 0, 0.5, 0)
                kbBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                kbBtn.BorderSizePixel = 0
                kbBtn.Text = ''
                kbBtn.AutoButtonColor = false
                kbBtn.Parent = row
                Instance.new('UICorner').Parent = kbBtn
                kbBtn.UICorner.CornerRadius = UDim.new(0, 3)

                local kbLbl = Instance.new('TextLabel')
                kbLbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                kbLbl.TextColor3 = Color3.fromRGB(200, 200, 210)
                kbLbl.Text = current_key
                kbLbl.Size = UDim2.new(1, 0, 1, 0)
                kbLbl.BackgroundTransparency = 1
                kbLbl.TextSize = 9
                kbLbl.Parent = kbBtn

                Library:register_keybind(flag, kb_settings.text or flag, current_key, function() return nil end)

                kbBtn.MouseButton1Click:Connect(function()
                    choosing = true
                    Library._choosing_keybind = true
                    kbLbl.Text = '...'
                end)

                Connections['opt_kb_' .. flag] = UserInputService.InputBegan:Connect(function(input, gp)
                    if not choosing then return end
                    if gp and not kb_settings.allow_game_processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        choosing = false
                        Library._choosing_keybind = false
                        current_key = format_key(input.KeyCode)
                        kbLbl.Text = current_key
                        Library._config._keybinds[flag] = current_key
                        Config:save(game.GameId, Library._config)
                        Library:register_keybind(flag, kb_settings.text or flag, current_key, function() return nil end)
                        if not ignore_pressed then callback(current_key) end
                    end
                end)

                Connections['opt_kb_exec_' .. flag] = UserInputService.InputBegan:Connect(function(input, gp)
                    if choosing then return end
                    if gp then return end
                    if Library._choosing_keybind then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard and format_key(input.KeyCode) == current_key then
                        callback(current_key)
                    end
                end)

                ModuleManager._size += 20
                return ModuleManager
            end

            function ModuleManager:button(button_settings)
                LayoutOrderModule += 1
                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 24)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local btn = Instance.new('TextButton')
                btn.Size = UDim2.new(1, 0, 0, 24)
                btn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                btn.BorderSizePixel = 0
                btn.Text = button_settings.text or "Button"
                btn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                btn.TextColor3 = Color3.fromRGB(200, 200, 210)
                btn.TextSize = 11
                btn.AutoButtonColor = false
                btn.Parent = row
                Instance.new('UICorner').Parent = btn
                btn.UICorner.CornerRadius = UDim.new(0, 5)

                btn.MouseButton1Click:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(55, 55, 60)}):Play()
                    task.wait(0.1)
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
                    button_settings.callback()
                end)
                btn.MouseEnter:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(45, 45, 50)}):Play()
                end)
                btn.MouseLeave:Connect(function()
                    TweenService:Create(btn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(35, 35, 40)}):Play()
                end)

                ModuleManager._size += 26
                return ModuleManager
            end

            function ModuleManager:label(label_settings)
                LayoutOrderModule += 1
                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 14)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = label_settings.color or Color3.fromRGB(120, 120, 128)
                lbl.Text = label_settings.text or ""
                lbl.Size = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 10
                lbl.TextTruncate = Enum.TextTruncate.AtEnd
                lbl.Parent = row

                ModuleManager._size += 14
                return ModuleManager
            end

            function ModuleManager:separator()
                LayoutOrderModule += 1
                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 8)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local line = Instance.new('Frame')
                line.Size = UDim2.new(1, 0, 0, 1)
                line.Position = UDim2.new(0, 0, 0.5, 0)
                line.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                line.BackgroundTransparency = 0.5
                line.BorderSizePixel = 0
                line.Parent = row

                ModuleManager._size += 10
                return ModuleManager
            end

            function ModuleManager:input(input_settings)
                LayoutOrderModule += 1
                local flag = input_settings.flag or (module_flag .. "_inp_" .. LayoutOrderModule)
                local default = input_settings.default or ""

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end
                local current = Library._config._flags[flag]

                local row = Instance.new('Frame')
                row.Size = UDim2.new(0, 227, 0, 36)
                row.BackgroundTransparency = 1
                row.BorderSizePixel = 0
                row.LayoutOrder = LayoutOrderModule
                row.Parent = Options

                local lbl = Instance.new('TextLabel')
                lbl.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                lbl.TextColor3 = Color3.fromRGB(160, 160, 168)
                lbl.Text = input_settings.text or flag
                lbl.Size = UDim2.new(1, 0, 0, 14)
                lbl.BackgroundTransparency = 1
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.TextSize = 11
                lbl.Parent = row

                local box = Instance.new('TextBox')
                box.Size = UDim2.new(1, 0, 0, 18)
                box.Position = UDim2.new(0, 0, 0, 16)
                box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                box.BorderSizePixel = 0
                box.Text = current
                box.PlaceholderText = input_settings.placeholder or ""
                box.PlaceholderColor3 = Color3.fromRGB(80, 80, 88)
                box.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                box.TextColor3 = Color3.fromRGB(200, 200, 210)
                box.TextSize = 10
                box.ClearTextOnFocus = false
                box.Parent = row
                Instance.new('UICorner').Parent = box
                box.UICorner.CornerRadius = UDim.new(0, 4)
                local boxPad = Instance.new('UIPadding')
                boxPad.PaddingLeft = UDim.new(0, 6)
                boxPad.PaddingRight = UDim.new(0, 6)
                boxPad.Parent = box

                box.FocusLost:Connect(function()
                    current = box.Text
                    Library._config._flags[flag] = current
                    Config:save(game.GameId, Library._config)
                    if input_settings.callback then input_settings.callback(current) end
                end)

                ModuleManager._size += 36
                return ModuleManager
            end

            return ModuleManager
        end

        return TabManager
    end

    Minimize.MouseButton1Click:Connect(function()
        Library._ui_open = not Library._ui_open
        self:change_visiblity(Library._ui_open)
    end)

    UserInputService.InputBegan:Connect(function(input, game_processed)
        if game_processed then return end
        if Library._choosing_keybind then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            Library._ui_open = not Library._ui_open
            self:change_visiblity(Library._ui_open)
        end
    end)
end

getgenv()._Fallen_Cleanup = function()
    Connections:disconnect_all()
    for _, v in {CoreGui:FindFirstChild('Fallen'), CoreGui:FindFirstChild('FallenKeybindList'), CoreGui:FindFirstChild('FallenNotifications')} do
        if v then v:Destroy() end
    end
end

return Library.new()

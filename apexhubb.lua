local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local HttpService = game:GetService('HttpService')
local TextService = game:GetService('TextService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local Debris = game:GetService('Debris')
local Workspace = game:GetService('Workspace')
local Stats = game:GetService('Stats')

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
        for _, value in pairs(self) do
            if typeof(value) == 'function' then continue end
            if type(value) == 'RBXScriptConnection' then
                value:Disconnect()
            end
        end
    end
}

local Config = {
    save = function(self, file_name, config)
        local success, result = pcall(function()
            local flags = HttpService:JSONEncode(config)
            writefile('Fallen/'..file_name..'.json', flags)
        end)
        if not success then warn('failed to save config', result) end
    end,
    load = function(self, file_name, config)
        local success, result = pcall(function()
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
        if not success or not result then
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
    _keybind_list_container = nil,
    _fps_overlay = nil,
    _ping_overlay = nil,
    _fps_dragging = false,
    _ping_dragging = false,
    _fps_drag_start = nil,
    _ping_drag_start = nil,
    _fps_position = nil,
    _ping_position = nil,
    _ping_mode = "number",
    _ping_history = {},
    _fps_visible = false,
    _ping_visible = false,
    _minimized = false,
    _hide_when_minimized = false,
}
Library.__index = Library
Library.Connections = Connections

function Library.new()
    local self = setmetatable({ _tab = 0 }, Library)
    self:create_ui()
    self:init_overlays()
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
    if not Library._notification_enabled then return end
    
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
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 0, 0, 0)
        })
        tweenIn:Play()

        task.wait(settings.duration or 5)

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = UDim2.new(-1, -320, 0, 0)
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
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

function Library:register_keybind(flag, label, key)
    if not self._keybind_list_data then self._keybind_list_data = {} end
    self._keybind_list_data[flag] = {
        label = label or flag,
        key = key or "None"
    }
    self:update_keybind_list()
end

function Library:unregister_keybind(flag)
    if self._keybind_list_data then
        self._keybind_list_data[flag] = nil
        self:update_keybind_list()
    end
end

function Library:update_keybind_list()
    if not self._keybind_list_container then return end
    
    for _, child in self._keybind_list_container:GetChildren() do
        if child.Name == "KeybindEntry" then child:Destroy() end
    end
    
    local count = 0
    for flag, data in pairs(self._keybind_list_data or {}) do
        count = count + 1
        local entry = Instance.new("Frame")
        entry.Name = "KeybindEntry"
        entry.Size = UDim2.new(1, -10, 0, 22)
        entry.BackgroundTransparency = 1
        entry.LayoutOrder = count
        entry.Parent = self._keybind_list_container
        
        local label = Instance.new("TextLabel")
        label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        label.TextColor3 = Color3.fromRGB(202, 202, 209)
        label.TextSize = 11
        label.Text = data.label or flag
        label.Size = UDim2.new(0.65, -8, 1, 0)
        label.Position = UDim2.new(0, 6, 0, 0)
        label.BackgroundTransparency = 1
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = entry
        
        local keyLabel = Instance.new("TextLabel")
        keyLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
        keyLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
        keyLabel.TextSize = 10
        keyLabel.Text = data.key or "None"
        keyLabel.Size = UDim2.new(0.35, -6, 1, 0)
        keyLabel.Position = UDim2.new(0.65, 0, 0, 0)
        keyLabel.BackgroundTransparency = 1
        keyLabel.TextXAlignment = Enum.TextXAlignment.Right
        keyLabel.Parent = entry
    end
end

function Library:set_notifications_enabled(state)
    self._notification_enabled = state
    if state then
        Library.SendNotification({ title = "Notifications", text = "Enabled", duration = 1.5 })
    end
end

function Library:init_overlays()
    self:create_fps_overlay()
    self:create_ping_overlay()
    self:start_overlay_updates()
end

function Library:create_fps_overlay()
    if self._fps_overlay then self._fps_overlay:Destroy() end
    
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "FallenFPSOverlay"
    overlay.ResetOnSpawn = false
    overlay.IgnoreGuiInset = true
    overlay.DisplayOrder = 100
    overlay.Parent = CoreGui
    overlay.Enabled = false
    
    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(0, 80, 0, 28)
    frame.Position = UDim2.new(0, 20, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = false
    frame.Parent = overlay
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Name = "FPSLabel"
    label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Text = "FPS: 0"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = frame
    
    self._fps_overlay = overlay
    self._fps_frame = frame
    self._fps_label = label
    self._fps_visible = false
    
    local function on_fps_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._fps_dragging = true
            self._fps_drag_start = input.Position
            self._fps_position = frame.Position
        end
    end
    
    local function on_fps_move(input)
        if not self._fps_dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - self._fps_drag_start
        local viewport = Workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(self._fps_position.X.Offset + delta.X, 0, viewport.X - frame.AbsoluteSize.X)
        local newY = math.clamp(self._fps_position.Y.Offset + delta.Y, 0, viewport.Y - frame.AbsoluteSize.Y)
        frame.Position = UDim2.new(0, newX, 0, newY)
    end
    
    frame.InputBegan:Connect(on_fps_drag)
    UserInputService.InputChanged:Connect(on_fps_move)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._fps_dragging = false
        end
    end)
end

function Library:create_ping_overlay()
    if self._ping_overlay then self._ping_overlay:Destroy() end
    
    local overlay = Instance.new("ScreenGui")
    overlay.Name = "FallenPingOverlay"
    overlay.ResetOnSpawn = false
    overlay.IgnoreGuiInset = true
    overlay.DisplayOrder = 99
    overlay.Parent = CoreGui
    overlay.Enabled = false
    
    local frame = Instance.new("Frame")
    frame.Name = "Frame"
    frame.Size = UDim2.new(0, 100, 0, 28)
    frame.Position = UDim2.new(0, 120, 0, 20)
    frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    frame.BackgroundTransparency = 0.35
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = false
    frame.Parent = overlay
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.5
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Name = "PingLabel"
    label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 14
    label.Text = "Ping: 0ms"
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Parent = frame
    
    local graph = Instance.new("Frame")
    graph.Name = "Graph"
    graph.Size = UDim2.new(0, 80, 0, 20)
    graph.Position = UDim2.new(0, 10, 0, 4)
    graph.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    graph.BackgroundTransparency = 0.6
    graph.BorderSizePixel = 0
    graph.Visible = false
    graph.Parent = frame
    
    local graphCorner = Instance.new("UICorner")
    graphCorner.CornerRadius = UDim.new(0, 3)
    graphCorner.Parent = graph
    
    local graphStroke = Instance.new("UIStroke")
    graphStroke.Color = Color3.fromRGB(255, 255, 255)
    graphStroke.Transparency = 0.4
    graphStroke.Thickness = 0.5
    graphStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    graphStroke.Parent = graph
    
    local graphImage = Instance.new("ImageLabel")
    graphImage.Name = "GraphImage"
    graphImage.Size = UDim2.new(1, 0, 1, 0)
    graphImage.BackgroundTransparency = 1
    graphImage.BorderSizePixel = 0
    graphImage.Image = ""
    graphImage.Parent = graph
    
    self._ping_overlay = overlay
    self._ping_frame = frame
    self._ping_label = label
    self._ping_graph = graph
    self._ping_graph_image = graphImage
    self._ping_visible = false
    
    local function on_ping_drag(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._ping_dragging = true
            self._ping_drag_start = input.Position
            self._ping_position = frame.Position
        end
    end
    
    local function on_ping_move(input)
        if not self._ping_dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = input.Position - self._ping_drag_start
        local viewport = Workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(self._ping_position.X.Offset + delta.X, 0, viewport.X - frame.AbsoluteSize.X)
        local newY = math.clamp(self._ping_position.Y.Offset + delta.Y, 0, viewport.Y - frame.AbsoluteSize.Y)
        frame.Position = UDim2.new(0, newX, 0, newY)
    end
    
    frame.InputBegan:Connect(on_ping_drag)
    UserInputService.InputChanged:Connect(on_ping_move)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._ping_dragging = false
        end
    end)
end

function Library:start_overlay_updates()
    local lastUpdate = 0
    Connections['overlay_updater'] = RunService.RenderStepped:Connect(function(dt)
        if not self._fps_visible and not self._ping_visible then return end
        
        local now = tick()
        if now - lastUpdate < 0.3 then return end
        lastUpdate = now
        
        if self._fps_visible and self._fps_label then
            local fps = math.floor(1 / dt)
            if fps > 999 then fps = 999 end
            self._fps_label.Text = "FPS: " .. tostring(fps)
        end
        
        if self._ping_visible and self._ping_label then
            local ping = Stats:GetPing()
            if self._ping_mode == "number" then
                self._ping_label.Text = "Ping: " .. math.floor(ping) .. "ms"
                if self._ping_graph then self._ping_graph.Visible = false end
            else
                self._ping_label.Text = ""
                if self._ping_graph then
                    self._ping_graph.Visible = true
                    table.insert(self._ping_history, ping)
                    if #self._ping_history > 60 then table.remove(self._ping_history, 1) end
                    self:update_ping_graph()
                end
            end
        end
    end)
end

function Library:update_ping_graph()
    if not self._ping_graph_image or #self._ping_history < 2 then return end
    
    local width = self._ping_graph.AbsoluteSize.X or 80
    local height = self._ping_graph.AbsoluteSize.Y or 20
    if width < 2 or height < 2 then return end
    
    self._ping_label.Text = "Ping: " .. math.floor(self._ping_history[#self._ping_history]) .. "ms"
    if self._ping_graph then self._ping_graph.Visible = false end
end

function Library:set_fps_visible(state)
    self._fps_visible = state
    if self._fps_overlay then
        self._fps_overlay.Enabled = state
    end
    Config:save(game.GameId, Library._config)
end

function Library:set_ping_visible(state)
    self._ping_visible = state
    if self._ping_overlay then
        self._ping_overlay.Enabled = state
    end
    Config:save(game.GameId, Library._config)
end

function Library:toggle_ping_mode()
    if self._ping_mode == "number" then
        self._ping_mode = "graph"
        self._ping_history = {}
        if self._ping_label then
            self._ping_label.Text = ""
        end
        if self._ping_graph then
            self._ping_graph.Visible = true
        end
    else
        self._ping_mode = "number"
        if self._ping_graph then
            self._ping_graph.Visible = false
        end
        if self._ping_label then
            self._ping_label.Text = "Ping: " .. math.floor(Stats:GetPing()) .. "ms"
        end
    end
    Config:save(game.GameId, Library._config)
end

function Library:set_minimized(state)
    self._minimized = state
    if state then
        if self._hide_when_minimized then
            self._ui.Enabled = false
        else
            local container = self._ui:FindFirstChild("Container")
            if container then
                TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(104.5, 52)
                }):Play()
            end
        end
    else
        self._ui.Enabled = true
        local container = self._ui:FindFirstChild("Container")
        if container then
            TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(752, 479)
            }):Play()
        end
    end
end

function Library:set_hide_when_minimized(state)
    self._hide_when_minimized = state
    if self._minimized and state then
        self._ui.Enabled = false
    elseif self._minimized and not state then
        self._ui.Enabled = true
        local container = self._ui:FindFirstChild("Container")
        if container then
            TweenService:Create(container, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
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

            TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(104.5, 52)
            }):Play()
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
            if ShadowScale then
                ShadowScale.Scale = self._ui_scale
            end

            Connections['ui_scale'] = workspace.CurrentCamera:GetPropertyChangedSignal('ViewportSize'):Connect(function()
                self:get_screen_scale()
                UIScale.Scale = self._ui_scale
                if ShadowScale then
                    ShadowScale.Scale = self._ui_scale
                end
            end)
        end

        ShadowHolder.Visible = true

        TweenService:Create(Container, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(752, 479)
        }):Play()
    end

    function self:update_tabs(tab)
        for index, object in Tabs:GetChildren() do
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

                    if object:FindFirstChild("TextLabel") then
                        TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            TextTransparency = 0,
                            TextColor3 = Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end

                    if object:FindFirstChild("TextLabel") and object.TextLabel:FindFirstChild("UIGradient") then
                        TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Offset = Vector2.new(1, 0)
                        }):Play()
                    end

                    if object:FindFirstChild("Icon") then
                        TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            ImageColor3 = object.Icon:GetAttribute('ActiveColor') or Color3.fromRGB(255, 255, 255)
                        }):Play()
                    end
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()

                if object:FindFirstChild("TextLabel") then
                    TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Color3.fromRGB(138, 138, 138)
                    }):Play()
                end

                if object:FindFirstChild("TextLabel") and object.TextLabel:FindFirstChild("UIGradient") then
                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(0, 0)
                    }):Play()
                end

                if object:FindFirstChild("Icon") then
                    TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageColor3 = object.Icon:GetAttribute('IdleColor') or Color3.fromRGB(138, 138, 138)
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
        LeftSection.AnchorPoint = Vector2.new(0, 0)
        LeftSection.BackgroundTransparency = 1
        LeftSection.Position = UDim2.new(0, 203, 0, 67)
        LeftSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        LeftSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
        RightSection.AnchorPoint = Vector2.new(0, 0)
        RightSection.ScrollBarImageTransparency = 1
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
        RightSection.BorderColor3 = Color3.fromRGB(0, 0, 0)
        RightSection.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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

            local ModuleHeader = Instance.new('Frame')
            ModuleHeader.Name = 'Header'
            ModuleHeader.Size = UDim2.new(1, 0, 0, 26)
            ModuleHeader.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            ModuleHeader.BackgroundTransparency = 0
            ModuleHeader.BorderSizePixel = 0
            ModuleHeader.BorderColor3 = Color3.fromRGB(0, 0, 0)
            ModuleHeader.Parent = Module

            local HeaderCorner = Instance.new('UICorner')
            HeaderCorner.CornerRadius = UDim.new(0, 9)
            HeaderCorner.Parent = ModuleHeader

            local HeaderFix = Instance.new('Frame')
            HeaderFix.Size = UDim2.new(1, 0, 0, 10)
            HeaderFix.Position = UDim2.new(0, 0, 0.5, 0)
            HeaderFix.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
            HeaderFix.BackgroundTransparency = 0
            HeaderFix.BorderSizePixel = 0
            HeaderFix.BorderColor3 = Color3.fromRGB(0, 0, 0)
            HeaderFix.Parent = ModuleHeader

            local ModuleTitle = Instance.new('TextLabel')
            ModuleTitle.Name = 'Title'
            ModuleTitle.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ModuleTitle.TextColor3 = Color3.fromRGB(178, 178, 185)
            ModuleTitle.TextTransparency = 0
            ModuleTitle.Text = settings.title or 'Module'
            ModuleTitle.Size = UDim2.new(1, -18, 0, 14)
            ModuleTitle.Position = UDim2.new(0, 12, 0, 6)
            ModuleTitle.BackgroundTransparency = 1
            ModuleTitle.TextXAlignment = Enum.TextXAlignment.Left
            ModuleTitle.BorderSizePixel = 0
            ModuleTitle.TextSize = 12
            ModuleTitle.Parent = ModuleHeader

            local ContentFrame = Instance.new('Frame')
            ContentFrame.Name = 'Content'
            ContentFrame.Size = UDim2.new(1, 0, 0, 0)
            ContentFrame.AutomaticSize = Enum.AutomaticSize.Y
            ContentFrame.BackgroundTransparency = 1
            ContentFrame.BorderSizePixel = 0
            ContentFrame.Position = UDim2.new(0, 0, 0, 26)
            ContentFrame.Parent = Module

            local ContentList = Instance.new('UIListLayout')
            ContentList.Padding = UDim.new(0, 4)
            ContentList.SortOrder = Enum.SortOrder.LayoutOrder
            ContentList.Parent = ContentFrame

            local ContentPadding = Instance.new('UIPadding')
            ContentPadding.PaddingTop = UDim.new(0, 4)
            ContentPadding.PaddingBottom = UDim.new(0, 6)
            ContentPadding.PaddingLeft = UDim.new(0, 12)
            ContentPadding.PaddingRight = UDim.new(0, 12)
            ContentPadding.Parent = ContentFrame

            local module_elements = 0

            function ModuleManager:add_toggle(toggle_settings)
                module_elements = module_elements + 1
                local flag = toggle_settings.flag or ("toggle_" .. module_elements)
                local default = toggle_settings.default or false
                local callback = toggle_settings.callback or function() end
                local text = toggle_settings.text or flag

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end

                local ToggleFrame = Instance.new('Frame')
                ToggleFrame.Size = UDim2.new(1, 0, 0, 20)
                ToggleFrame.BackgroundTransparency = 1
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.LayoutOrder = module_elements
                ToggleFrame.Parent = ContentFrame

                local ToggleLabel = Instance.new('TextLabel')
                ToggleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                ToggleLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                ToggleLabel.TextTransparency = 0
                ToggleLabel.Text = text
                ToggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.TextSize = 11
                ToggleLabel.Parent = ToggleFrame

                local ToggleButton = Instance.new('TextButton')
                ToggleButton.Size = UDim2.new(0, 36, 0, 18)
                ToggleButton.AnchorPoint = Vector2.new(1, 0.5)
                ToggleButton.Position = UDim2.new(1, 0, 0.5, 0)
                ToggleButton.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                ToggleButton.BackgroundTransparency = 0
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Text = ''
                ToggleButton.AutoButtonColor = false
                ToggleButton.Parent = ToggleFrame

                local ToggleCorner = Instance.new('UICorner')
                ToggleCorner.CornerRadius = UDim.new(1, 0)
                ToggleCorner.Parent = ToggleButton

                local ToggleStroke = Instance.new('UIStroke')
                ToggleStroke.Color = Color3.fromRGB(60, 60, 65)
                ToggleStroke.Transparency = 0
                ToggleStroke.Thickness = 1
                ToggleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ToggleStroke.Parent = ToggleButton

                local ToggleDot = Instance.new('Frame')
                ToggleDot.Size = UDim2.new(0, 14, 0, 14)
                ToggleDot.Position = UDim2.new(0, 2, 0.5, 0)
                ToggleDot.AnchorPoint = Vector2.new(0, 0.5)
                ToggleDot.BackgroundColor3 = Color3.fromRGB(100, 100, 108)
                ToggleDot.BorderSizePixel = 0
                ToggleDot.Parent = ToggleButton

                local DotCorner = Instance.new('UICorner')
                DotCorner.CornerRadius = UDim.new(1, 0)
                DotCorner.Parent = ToggleDot

                local function update_toggle_visual(state)
                    if state then
                        TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Color3.fromRGB(200, 200, 210)
                        }):Play()
                        TweenService:Create(ToggleDot, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 20, 0.5, 0),
                            BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                        }):Play()
                        TweenService:Create(ToggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Transparency = 1
                        }):Play()
                    else
                        TweenService:Create(ToggleButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                        }):Play()
                        TweenService:Create(ToggleDot, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Position = UDim2.new(0, 2, 0.5, 0),
                            BackgroundColor3 = Color3.fromRGB(100, 100, 108)
                        }):Play()
                        TweenService:Create(ToggleStroke, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Transparency = 0
                        }):Play()
                    end
                end

                local current_state = Library._config._flags[flag]
                update_toggle_visual(current_state)

                ToggleButton.MouseButton1Click:Connect(function()
                    current_state = not current_state
                    Library._config._flags[flag] = current_state
                    update_toggle_visual(current_state)
                    Config:save(game.GameId, Library._config)
                    callback(current_state)
                end)

                Library._flag_registry[flag] = {
                    type = 'toggle',
                    get = function() return current_state end,
                    set = function(val)
                        current_state = val
                        Library._config._flags[flag] = val
                        update_toggle_visual(val)
                        Config:save(game.GameId, Library._config)
                    end
                }

                return ModuleManager
            end

            function ModuleManager:add_slider(slider_settings)
                module_elements = module_elements + 1
                local flag = slider_settings.flag or ("slider_" .. module_elements)
                local default = slider_settings.default or slider_settings.min or 0
                local min_val = slider_settings.min or 0
                local max_val = slider_settings.max or 100
                local callback = slider_settings.callback or function() end
                local text = slider_settings.text or flag
                local suffix = slider_settings.suffix or ""
                local format_val = slider_settings.format or "%.1f"

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end

                local current_value = Library._config._flags[flag]

                local SliderFrame = Instance.new('Frame')
                SliderFrame.Size = UDim2.new(1, 0, 0, 36)
                SliderFrame.BackgroundTransparency = 1
                SliderFrame.BorderSizePixel = 0
                SliderFrame.LayoutOrder = module_elements
                SliderFrame.Parent = ContentFrame

                local SliderTopRow = Instance.new('Frame')
                SliderTopRow.Size = UDim2.new(1, 0, 0, 14)
                SliderTopRow.BackgroundTransparency = 1
                SliderTopRow.BorderSizePixel = 0
                SliderTopRow.Parent = SliderFrame

                local SliderLabel = Instance.new('TextLabel')
                SliderLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                SliderLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                SliderLabel.TextTransparency = 0
                SliderLabel.Text = text
                SliderLabel.Size = UDim2.new(0.6, 0, 1, 0)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.TextSize = 11
                SliderLabel.Parent = SliderTopRow

                local SliderValueLabel = Instance.new('TextLabel')
                SliderValueLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                SliderValueLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
                SliderValueLabel.TextTransparency = 0
                SliderValueLabel.Text = format_val:format(current_value) .. suffix
                SliderValueLabel.Size = UDim2.new(0.4, 0, 1, 0)
                SliderValueLabel.AnchorPoint = Vector2.new(1, 0)
                SliderValueLabel.Position = UDim2.new(1, 0, 0, 0)
                SliderValueLabel.BackgroundTransparency = 1
                SliderValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                SliderValueLabel.TextSize = 11
                SliderValueLabel.Parent = SliderTopRow

                local SliderTrack = Instance.new('Frame')
                SliderTrack.Size = UDim2.new(1, 0, 0, 8)
                SliderTrack.Position = UDim2.new(0, 0, 0, 18)
                SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                SliderTrack.BorderSizePixel = 0
                SliderTrack.Parent = SliderFrame

                local TrackCorner = Instance.new('UICorner')
                TrackCorner.CornerRadius = UDim.new(1, 0)
                TrackCorner.Parent = SliderTrack

                local SliderFill = Instance.new('Frame')
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderFill.BackgroundColor3 = Color3.fromRGB(200, 200, 210)
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderTrack

                local FillCorner = Instance.new('UICorner')
                FillCorner.CornerRadius = UDim.new(1, 0)
                FillCorner.Parent = SliderFill

                local SliderInput = Instance.new('TextButton')
                SliderInput.Size = UDim2.new(1, 0, 0, 22)
                SliderInput.Position = UDim2.new(0, 0, 0, 12)
                SliderInput.BackgroundTransparency = 1
                SliderInput.Text = ''
                SliderInput.AutoButtonColor = false
                SliderInput.Parent = SliderFrame

                local SliderDot = Instance.new('Frame')
                SliderDot.Size = UDim2.new(0, 12, 0, 12)
                SliderDot.AnchorPoint = Vector2.new(0.5, 0.5)
                SliderDot.Position = UDim2.new(0, 0, 0.5, 0)
                SliderDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                SliderDot.BorderSizePixel = 0
                SliderDot.ZIndex = 2
                SliderDot.Parent = SliderFill

                local DotCorner2 = Instance.new('UICorner')
                DotCorner2.CornerRadius = UDim.new(1, 0)
                DotCorner2.Parent = SliderDot

                local function update_slider(val)
                    local clamped = math.clamp(val, min_val, max_val)
                    current_value = clamped
                    Library._config._flags[flag] = clamped
                    local percentage = (clamped - min_val) / (max_val - min_val)
                    SliderFill.Size = UDim2.new(percentage, 0, 1, 0)
                    SliderDot.Position = UDim2.new(1, -6, 0.5, 0)
                    SliderValueLabel.Text = format_val:format(clamped) .. suffix
                    Config:save(game.GameId, Library._config)
                end

                update_slider(current_value)

                local sliding = false

                SliderInput.MouseButton1Down:Connect(function()
                    sliding = true
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        if sliding then
                            sliding = false
                            callback(current_value)
                        end
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not sliding then return end
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
                    local rel_x = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                    local new_val = min_val + (rel_x * (max_val - min_val))
                    update_slider(new_val)
                end)

                Library._flag_registry[flag] = {
                    type = 'slider',
                    get = function() return current_value end,
                    set = function(val) update_slider(val) callback(val) end
                }

                return ModuleManager
            end

            function ModuleManager:add_dropdown(dropdown_settings)
                module_elements = module_elements + 1
                local flag = dropdown_settings.flag or ("dropdown_" .. module_elements)
                local default = dropdown_settings.default or dropdown_settings.list and dropdown_settings.list[1] or ""
                local list = dropdown_settings.list or {}
                local callback = dropdown_settings.callback or function() end
                local text = dropdown_settings.text or flag
                local multi = dropdown_settings.multi or false

                if Library._config._flags[flag] == nil then
                    if multi then
                        Library._config._flags[flag] = { default }
                    else
                        Library._config._flags[flag] = default
                    end
                end

                local current_value = Library._config._flags[flag]
                local is_open = false

                local DropdownFrame = Instance.new('Frame')
                DropdownFrame.Size = UDim2.new(1, 0, 0, 22)
                DropdownFrame.BackgroundTransparency = 1
                DropdownFrame.BorderSizePixel = 0
                DropdownFrame.LayoutOrder = module_elements
                DropdownFrame.ClipsDescendants = false
                DropdownFrame.Parent = ContentFrame

                local DropdownLabel = Instance.new('TextLabel')
                DropdownLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                DropdownLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                DropdownLabel.TextTransparency = 0
                DropdownLabel.Text = text
                DropdownLabel.Size = UDim2.new(1, 0, 0, 14)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.TextSize = 11
                DropdownLabel.Parent = DropdownFrame

                local DropdownButton = Instance.new('TextButton')
                DropdownButton.Size = UDim2.new(1, 0, 0, 20)
                DropdownButton.Position = UDim2.new(0, 0, 0, 16)
                DropdownButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                DropdownButton.BorderSizePixel = 0
                DropdownButton.Text = ''
                DropdownButton.AutoButtonColor = false
                DropdownButton.Parent = DropdownFrame

                local DropdownCorner = Instance.new('UICorner')
                DropdownCorner.CornerRadius = UDim.new(0, 5)
                DropdownCorner.Parent = DropdownButton

                local DropdownStroke = Instance.new('UIStroke')
                DropdownStroke.Color = Color3.fromRGB(50, 50, 55)
                DropdownStroke.Transparency = 0
                DropdownStroke.Thickness = 1
                DropdownStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                DropdownStroke.Parent = DropdownButton

                local DropdownValue = Instance.new('TextLabel')
                DropdownValue.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                DropdownValue.TextColor3 = Color3.fromRGB(200, 200, 210)
                DropdownValue.TextTransparency = 0
                DropdownValue.Text = multi and convertTableToString(current_value) or tostring(current_value)
                DropdownValue.Size = UDim2.new(1, -20, 1, 0)
                DropdownValue.Position = UDim2.new(0, 8, 0, 0)
                DropdownValue.BackgroundTransparency = 1
                DropdownValue.TextXAlignment = Enum.TextXAlignment.Left
                DropdownValue.TextSize = 11
                DropdownValue.TextTruncate = Enum.TextTruncate.AtEnd
                DropdownValue.Parent = DropdownButton

                local DropdownArrow = Instance.new('TextLabel')
                DropdownArrow.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                DropdownArrow.TextColor3 = Color3.fromRGB(120, 120, 128)
                DropdownArrow.TextTransparency = 0
                DropdownArrow.Text = '∨'
                DropdownArrow.Size = UDim2.new(0, 16, 1, 0)
                DropdownArrow.AnchorPoint = Vector2.new(1, 0)
                DropdownArrow.Position = UDim2.new(1, 4, 0, 0)
                DropdownArrow.BackgroundTransparency = 1
                DropdownArrow.TextSize = 12
                DropdownArrow.Parent = DropdownButton

                local DropdownList = Instance.new('Frame')
                DropdownList.Size = UDim2.new(1, 0, 0, 0)
                DropdownList.Position = UDim2.new(0, 0, 0, 38)
                DropdownList.BackgroundColor3 = Color3.fromRGB(20, 20, 24)
                DropdownList.BorderSizePixel = 0
                DropdownList.ClipsDescendants = true
                DropdownList.Visible = false
                DropdownList.ZIndex = 10
                DropdownList.Parent = DropdownFrame

                local ListCorner = Instance.new('UICorner')
                ListCorner.CornerRadius = UDim.new(0, 5)
                ListCorner.Parent = DropdownList

                local ListStroke = Instance.new('UIStroke')
                ListStroke.Color = Color3.fromRGB(50, 50, 55)
                ListStroke.Transparency = 0
                ListStroke.Thickness = 1
                ListStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                ListStroke.Parent = DropdownList

                local ListLayout = Instance.new('UIListLayout')
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Parent = DropdownList

                local ListPadding = Instance.new('UIPadding')
                ListPadding.PaddingTop = UDim.new(0, 2)
                ListPadding.PaddingBottom = UDim.new(0, 2)
                ListPadding.Parent = DropdownList

                local function refresh_list()
                    for _, child in DropdownList:GetChildren() do
                        if child:IsA('TextButton') then child:Destroy() end
                    end

                    for i, item in ipairs(list) do
                        local btn = Instance.new('TextButton')
                        btn.Size = UDim2.new(1, -4, 0, 20)
                        btn.Position = UDim2.new(0, 2, 0, 0)
                        btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                        btn.BackgroundTransparency = 0
                        btn.BorderSizePixel = 0
                        btn.Text = ''
                        btn.AutoButtonColor = false
                        btn.LayoutOrder = i
                        btn.Parent = DropdownList

                        local selected = false
                        if multi then
                            for _, v in ipairs(current_value) do
                                if v == item then selected = true break end
                            end
                        else
                            selected = (current_value == item)
                        end

                        local itemLabel = Instance.new('TextLabel')
                        itemLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                        itemLabel.TextColor3 = selected and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(160, 160, 168)
                        itemLabel.Text = item
                        itemLabel.Size = UDim2.new(1, -20, 1, 0)
                        itemLabel.Position = UDim2.new(0, 8, 0, 0)
                        itemLabel.BackgroundTransparency = 1
                        itemLabel.TextXAlignment = Enum.TextXAlignment.Left
                        itemLabel.TextSize = 11
                        itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
                        itemLabel.Parent = btn

                        local checkLabel = Instance.new('TextLabel')
                        checkLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                        checkLabel.TextColor3 = selected and Color3.fromRGB(200, 200, 210) or Color3.fromRGB(60, 60, 65)
                        checkLabel.Text = selected and '✓' or ''
                        checkLabel.Size = UDim2.new(0, 14, 1, 0)
                        checkLabel.AnchorPoint = Vector2.new(1, 0)
                        checkLabel.Position = UDim2.new(1, 4, 0, 0)
                        checkLabel.BackgroundTransparency = 1
                        checkLabel.TextSize = 11
                        checkLabel.Parent = btn

                        btn.MouseButton1Click:Connect(function()
                            if multi then
                                local found = false
                                for idx, v in ipairs(current_value) do
                                    if v == item then
                                        table.remove(current_value, idx)
                                        found = true
                                        break
                                    end
                                end
                                if not found then
                                    table.insert(current_value, item)
                                end
                                DropdownValue.Text = convertTableToString(current_value)
                            else
                                current_value = item
                                DropdownValue.Text = tostring(item)
                            end
                            Library._config._flags[flag] = current_value
                            Config:save(game.GameId, Library._config)
                            refresh_list()
                            callback(current_value)
                        end)

                        btn.MouseEnter:Connect(function()
                            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
                        end)
                        btn.MouseLeave:Connect(function()
                            TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(30, 30, 35) }):Play()
                        end)
                    end

                    DropdownList.AutomaticSize = Enum.AutomaticSize.Y
                    local list_height = ListLayout.AbsoluteContentSize.Y + 4
                    DropdownList.Size = UDim2.new(1, 0, 0, list_height)
                end

                refresh_list()

                DropdownButton.MouseButton1Click:Connect(function()
                    is_open = not is_open
                    DropdownList.Visible = is_open
                    if is_open then
                        DropdownArrow.Text = '∧'
                        TweenService:Create(DropdownArrow, TweenInfo.new(0.2), { Rotation = 180 }):Play()
                    else
                        DropdownArrow.Text = '∨'
                        TweenService:Create(DropdownArrow, TweenInfo.new(0.2), { Rotation = 0 }):Play()
                    end
                end)

                Library._flag_registry[flag] = {
                    type = 'dropdown',
                    get = function() return current_value end,
                    set = function(val)
                        current_value = val
                        Library._config._flags[flag] = val
                        DropdownValue.Text = multi and convertTableToString(val) or tostring(val)
                        Config:save(game.GameId, Library._config)
                        refresh_list()
                    end
                }

                return ModuleManager
            end

            function ModuleManager:add_keybind(keybind_settings)
                module_elements = module_elements + 1
                local flag = keybind_settings.flag or ("keybind_" .. module_elements)
                local default = keybind_settings.default or "None"
                local callback = keybind_settings.callback or function() end
                local text = keybind_settings.text or flag
                local ignore_pressed = keybind_settings.ignore_pressed or false

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end

                local current_key = Library._config._flags[flag]
                local choosing = false

                local KeybindFrame = Instance.new('Frame')
                KeybindFrame.Size = UDim2.new(1, 0, 0, 20)
                KeybindFrame.BackgroundTransparency = 1
                KeybindFrame.BorderSizePixel = 0
                KeybindFrame.LayoutOrder = module_elements
                KeybindFrame.Parent = ContentFrame

                local KeybindLabel = Instance.new('TextLabel')
                KeybindLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                KeybindLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                KeybindLabel.TextTransparency = 0
                KeybindLabel.Text = text
                KeybindLabel.Size = UDim2.new(0.6, 0, 1, 0)
                KeybindLabel.BackgroundTransparency = 1
                KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
                KeybindLabel.TextSize = 11
                KeybindLabel.Parent = KeybindFrame

                local KeybindButton = Instance.new('TextButton')
                KeybindButton.Size = UDim2.new(0, 70, 0, 18)
                KeybindButton.AnchorPoint = Vector2.new(1, 0.5)
                KeybindButton.Position = UDim2.new(1, 0, 0.5, 0)
                KeybindButton.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                KeybindButton.BorderSizePixel = 0
                KeybindButton.Text = ''
                KeybindButton.AutoButtonColor = false
                KeybindButton.Parent = KeybindFrame

                local KbCorner = Instance.new('UICorner')
                KbCorner.CornerRadius = UDim.new(0, 4)
                KbCorner.Parent = KeybindButton

                local KbStroke = Instance.new('UIStroke')
                KbStroke.Color = Color3.fromRGB(50, 50, 55)
                KbStroke.Transparency = 0
                KbStroke.Thickness = 1
                KbStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                KbStroke.Parent = KeybindButton

                local KeybindValue = Instance.new('TextLabel')
                KeybindValue.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KeybindValue.TextColor3 = Color3.fromRGB(200, 200, 210)
                KeybindValue.TextTransparency = 0
                KeybindValue.Text = current_key
                KeybindValue.Size = UDim2.new(1, 0, 1, 0)
                KeybindValue.BackgroundTransparency = 1
                KeybindValue.TextSize = 10
                KeybindValue.Parent = KeybindButton

                local function format_key(keycode)
                    local name = tostring(keycode)
                    name = name:gsub("Enum.KeyCode.", "")
                    if name == "LeftShift" then name = "L-Shift"
                    elseif name == "RightShift" then name = "R-Shift"
                    elseif name == "LeftControl" then name = "L-Ctrl"
                    elseif name == "RightControl" then name = "R-Ctrl"
                    elseif name == "LeftAlt" then name = "L-Alt"
                    elseif name == "RightAlt" then name = "R-Alt"
                    end
                    return name
                end

                KeybindButton.MouseButton1Click:Connect(function()
                    choosing = true
                    KeybindValue.Text = '...'
                    Library._choosing_keybind = true
                end)

                local keybind_conn
                keybind_conn = UserInputService.InputBegan:Connect(function(input, game_processed)
                    if not choosing then return end
                    if game_processed and not keybind_settings.allow_game_processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        choosing = false
                        Library._choosing_keybind = false
                        current_key = format_key(input.KeyCode)
                        Library._config._flags[flag] = current_key
                        KeybindValue.Text = current_key
                        Config:save(game.GameId, Library._config)
                        Library:register_keybind(flag, text, current_key)
                        if not ignore_pressed then
                            callback(current_key)
                        end
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 and not choosing then
                        return
                    end
                end)

                Library:register_keybind(flag, text, current_key)

                Connections['keybind_' .. flag] = UserInputService.InputBegan:Connect(function(input, game_processed)
                    if choosing then return end
                    if game_processed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        if format_key(input.KeyCode) == current_key then
                            callback(current_key)
                        end
                    end
                end)

                Library._flag_registry[flag] = {
                    type = 'keybind',
                    get = function() return current_key end,
                    set = function(val)
                        current_key = val
                        Library._config._flags[flag] = val
                        KeybindValue.Text = val
                        Config:save(game.GameId, Library._config)
                        Library:register_keybind(flag, text, val)
                    end
                }

                return ModuleManager
            end

            function ModuleManager:add_button(button_settings)
                module_elements = module_elements + 1
                local text = button_settings.text or "Button"
                local callback = button_settings.callback or function() end

                local ButtonFrame = Instance.new('Frame')
                ButtonFrame.Size = UDim2.new(1, 0, 0, 24)
                ButtonFrame.BackgroundTransparency = 1
                ButtonFrame.BorderSizePixel = 0
                ButtonFrame.LayoutOrder = module_elements
                ButtonFrame.Parent = ContentFrame

                local Button = Instance.new('TextButton')
                Button.Size = UDim2.new(1, 0, 0, 24)
                Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Button.BorderSizePixel = 0
                Button.Text = text
                Button.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextColor3 = Color3.fromRGB(200, 200, 210)
                Button.TextSize = 11
                Button.AutoButtonColor = false
                Button.Parent = ButtonFrame

                local BtnCorner = Instance.new('UICorner')
                BtnCorner.CornerRadius = UDim.new(0, 5)
                BtnCorner.Parent = Button

                local BtnStroke = Instance.new('UIStroke')
                BtnStroke.Color = Color3.fromRGB(55, 55, 60)
                BtnStroke.Transparency = 0
                BtnStroke.Thickness = 1
                BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                BtnStroke.Parent = Button

                Button.MouseButton1Click:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.1), { BackgroundColor3 = Color3.fromRGB(55, 55, 60) }):Play()
                    task.wait(0.1)
                    TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(35, 35, 40) }):Play()
                    callback()
                end)

                Button.MouseEnter:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(45, 45, 50) }):Play()
                end)
                Button.MouseLeave:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(35, 35, 40) }):Play()
                end)

                return ModuleManager
            end

            function ModuleManager:add_label(label_settings)
                module_elements = module_elements + 1
                local text = label_settings.text or ""
                local color = label_settings.color or Color3.fromRGB(160, 160, 168)

                local LabelFrame = Instance.new('Frame')
                LabelFrame.Size = UDim2.new(1, 0, 0, 16)
                LabelFrame.BackgroundTransparency = 1
                LabelFrame.BorderSizePixel = 0
                LabelFrame.LayoutOrder = module_elements
                LabelFrame.Parent = ContentFrame

                local Label = Instance.new('TextLabel')
                Label.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                Label.TextColor3 = color
                Label.TextTransparency = 0
                Label.Text = text
                Label.Size = UDim2.new(1, 0, 1, 0)
                Label.BackgroundTransparency = 1
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextSize = 11
                Label.TextTruncate = Enum.TextTruncate.AtEnd
                Label.Parent = LabelFrame

                return ModuleManager
            end

            function ModuleManager:add_separator()
                module_elements = module_elements + 1
                local SepFrame = Instance.new('Frame')
                SepFrame.Size = UDim2.new(1, 0, 0, 8)
                SepFrame.BackgroundTransparency = 1
                SepFrame.BorderSizePixel = 0
                SepFrame.LayoutOrder = module_elements
                SepFrame.Parent = ContentFrame

                local SepLine = Instance.new('Frame')
                SepLine.Size = UDim2.new(1, 0, 0, 1)
                SepLine.Position = UDim2.new(0, 0, 0.5, 0)
                SepLine.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
                SepLine.BackgroundTransparency = 0.5
                SepLine.BorderSizePixel = 0
                SepLine.Parent = SepFrame

                return ModuleManager
            end

            function ModuleManager:add_input(input_settings)
                module_elements = module_elements + 1
                local flag = input_settings.flag or ("input_" .. module_elements)
                local default = input_settings.default or ""
                local placeholder = input_settings.placeholder or ""
                local callback = input_settings.callback or function() end
                local text = input_settings.text or flag

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = default
                end

                local current_value = Library._config._flags[flag]

                local InputFrame = Instance.new('Frame')
                InputFrame.Size = UDim2.new(1, 0, 0, 38)
                InputFrame.BackgroundTransparency = 1
                InputFrame.BorderSizePixel = 0
                InputFrame.LayoutOrder = module_elements
                InputFrame.Parent = ContentFrame

                local InputLabel = Instance.new('TextLabel')
                InputLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                InputLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                InputLabel.TextTransparency = 0
                InputLabel.Text = text
                InputLabel.Size = UDim2.new(1, 0, 0, 14)
                InputLabel.BackgroundTransparency = 1
                InputLabel.TextXAlignment = Enum.TextXAlignment.Left
                InputLabel.TextSize = 11
                InputLabel.Parent = InputFrame

                local InputBox = Instance.new('TextBox')
                InputBox.Size = UDim2.new(1, 0, 0, 20)
                InputBox.Position = UDim2.new(0, 0, 0, 16)
                InputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
                InputBox.BorderSizePixel = 0
                InputBox.Text = current_value
                InputBox.PlaceholderText = placeholder
                InputBox.PlaceholderColor3 = Color3.fromRGB(80, 80, 88)
                InputBox.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                InputBox.TextColor3 = Color3.fromRGB(200, 200, 210)
                InputBox.TextSize = 11
                InputBox.ClearTextOnFocus = false
                InputBox.Parent = InputFrame

                local InputCorner = Instance.new('UICorner')
                InputCorner.CornerRadius = UDim.new(0, 4)
                InputCorner.Parent = InputBox

                local InputStroke = Instance.new('UIStroke')
                InputStroke.Color = Color3.fromRGB(50, 50, 55)
                InputStroke.Transparency = 0
                InputStroke.Thickness = 1
                InputStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                InputStroke.Parent = InputBox

                local InputPadding = Instance.new('UIPadding')
                InputPadding.PaddingLeft = UDim.new(0, 6)
                InputPadding.PaddingRight = UDim.new(0, 6)
                InputPadding.Parent = InputBox

                InputBox.FocusLost:Connect(function()
                    current_value = InputBox.Text
                    Library._config._flags[flag] = current_value
                    Config:save(game.GameId, Library._config)
                    callback(current_value)
                end)

                Library._flag_registry[flag] = {
                    type = 'input',
                    get = function() return current_value end,
                    set = function(val)
                        current_value = val
                        Library._config._flags[flag] = val
                        InputBox.Text = val
                        Config:save(game.GameId, Library._config)
                    end
                }

                return ModuleManager
            end

            function ModuleManager:add_colorpicker(cp_settings)
                module_elements = module_elements + 1
                local flag = cp_settings.flag or ("color_" .. module_elements)
                local default = cp_settings.default or Color3.fromRGB(255, 255, 255)
                local callback = cp_settings.callback or function() end
                local text = cp_settings.text or flag

                if Library._config._flags[flag] == nil then
                    Library._config._flags[flag] = { tostring(default.R), tostring(default.G), tostring(default.B) }
                end

                local stored = Library._config._flags[flag]
                local current_color = Color3.fromRGB(tonumber(stored[1]) or 255, tonumber(stored[2]) or 255, tonumber(stored[3]) or 255)
                local is_open = false

                local CPFrame = Instance.new('Frame')
                CPFrame.Size = UDim2.new(1, 0, 0, 20)
                CPFrame.BackgroundTransparency = 1
                CPFrame.BorderSizePixel = 0
                CPFrame.LayoutOrder = module_elements
                CPFrame.Parent = ContentFrame

                local CPLabel = Instance.new('TextLabel')
                CPLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                CPLabel.TextColor3 = Color3.fromRGB(160, 160, 168)
                CPLabel.TextTransparency = 0
                CPLabel.Text = text
                CPLabel.Size = UDim2.new(0.7, 0, 1, 0)
                CPLabel.BackgroundTransparency = 1
                CPLabel.TextXAlignment = Enum.TextXAlignment.Left
                CPLabel.TextSize = 11
                CPLabel.Parent = CPFrame

                local CPButton = Instance.new('TextButton')
                CPButton.Size = UDim2.new(0, 36, 0, 18)
                CPButton.AnchorPoint = Vector2.new(1, 0.5)
                CPButton.Position = UDim2.new(1, 0, 0.5, 0)
                CPButton.BackgroundColor3 = current_color
                CPButton.BorderSizePixel = 0
                CPButton.Text = ''
                CPButton.AutoButtonColor = false
                CPButton.Parent = CPFrame

                local CPCorner = Instance.new('UICorner')
                CPCorner.CornerRadius = UDim.new(0, 4)
                CPCorner.Parent = CPButton

                local CPStroke = Instance.new('UIStroke')
                CPStroke.Color = Color3.fromRGB(60, 60, 65)
                CPStroke.Transparency = 0
                CPStroke.Thickness = 1
                CPStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
                CPStroke.Parent = CPButton

                local CPPicker = Instance.new('ColorPicker')
                CPPicker.Color = current_color
                CPPicker.Transparency = 0
                CPPicker.AnchorPoint = Vector2.new(1, 0)
                CPPicker.Position = UDim2.new(1, -4, 0, 22)
                CPPicker.Size = UDim2.new(0, 160, 0, 180)
                CPPicker.Visible = false
                CPPicker.ZIndex = 20
                CPPicker.Parent = CPFrame

                CPButton.MouseButton1Click:Connect(function()
                    is_open = not is_open
                    CPPicker.Visible = is_open
                end)

                CPPicker.ColorChanged:Connect(function(color)
                    current_color = color
                    CPButton.BackgroundColor3 = color
                    Library._config._flags[flag] = { tostring(math.floor(color.R * 255)), tostring(math.floor(color.G * 255)), tostring(math.floor(color.B * 255)) }
                    Config:save(game.GameId, Library._config)
                    callback(color)
                end)

                Library._flag_registry[flag] = {
                    type = 'colorpicker',
                    get = function() return current_color end,
                    set = function(val)
                        current_color = val
                        CPButton.BackgroundColor3 = val
                        CPPicker.Color = val
                        Library._config._flags[flag] = { tostring(math.floor(val.R * 255)), tostring(math.floor(val.G * 255)), tostring(math.floor(val.B * 255)) }
                        Config:save(game.GameId, Library._config)
                    end
                }

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
        if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.LeftShift then
            Library._ui_open = not Library._ui_open
            self:change_visiblity(Library._ui_open)
        end
    end)
end

getgenv()._Fallen_Cleanup = function()
    Connections:disconnect_all()
    local ui = CoreGui:FindFirstChild('Fallen')
    if ui then ui:Destroy() end
    local fps = CoreGui:FindFirstChild('FallenFPSOverlay')
    if fps then fps:Destroy() end
    local ping = CoreGui:FindFirstChild('FallenPingOverlay')
    if ping then ping:Destroy() end
    local notif = CoreGui:FindFirstChild('FallenNotifications')
    if notif then notif:Destroy() end
end

return Library.new()

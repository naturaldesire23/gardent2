local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local TextService = cloneref(game:GetService('TextService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))
local Debris = cloneref(game:GetService('Debris'))

local player = Players.LocalPlayer
local mouse = player:GetMouse()
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

local Connections = {}
Connections.__index = Connections

function Connections:disconnect(connection)
    if not self[connection] then return end
    self[connection]:Disconnect()
    self[connection] = nil
end

function Connections:disconnect_all()
    for key, value in pairs(self) do
        if typeof(value) == 'RBXScriptConnection' then
            value:Disconnect()
            self[key] = nil
        end
    end
end

setmetatable(Connections, Connections)

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
                return
            end
            local flags = readfile('Fallen/'..file_name..'.json')
            if not flags then
                self:save(file_name, config)
                return
            end
            return HttpService:JSONDecode(flags)
        end)
        if not success then warn('failed to load config', result) end
        if not result then
            result = { _flags = {}, _keybinds = {}, _interface = {} }
        end
        if not result._interface then
            result._interface = {}
        end
        return result
    end
}

local Library = {
    _config = Config:load(game.GameId, { _flags = {}, _keybinds = {}, _interface = {} }),
    _choosing_keybind = false,
    _device = nil,
    _ui_open = true,
    _ui_scale = 1,
    _ui = nil,
    _dragging = false,
    _drag_start = nil,
    _container_position = nil,
    _flag_registry = {},
    _keybind_registry = {},
    _overlay_state = {
        enabled = false,
        mode = "number",
        gui = nil,
        fpsConnection = nil,
        fps = 0,
        ping = 0,
        samples = {},
        maxSamples = 24,
        fpsLabel = nil,
        pingLabel = nil,
        graphPanel = nil,
        bars = {}
    },
    _notif_position = "left",
    _hide_on_minimize = false,
    _minimized = false
}
Library.__index = Library
Library.Connections = Connections

local function formatKeybind(keyCode)
    if not keyCode then return "None" end
    local name = keyCode.Name
    if name == "LeftShift" then return "L-Shift"
    elseif name == "RightShift" then return "R-Shift"
    elseif name == "LeftControl" then return "L-Ctrl"
    elseif name == "RightControl" then return "R-Ctrl"
    elseif name == "LeftAlt" then return "L-Alt"
    elseif name == "RightAlt" then return "R-Alt"
    elseif name == "MouseButton1" then return "MB1"
    elseif name == "MouseButton2" then return "MB2"
    elseif name == "MouseButton3" then return "MB3"
    end
    return name
end

local function createPerformanceOverlay()
    local state = Library._overlay_state
    if state.gui then return end

    local OverlayGui = Instance.new("ScreenGui")
    OverlayGui.Name = "FallenPerfOverlay"
    OverlayGui.ResetOnSpawn = false
    OverlayGui.IgnoreGuiInset = true
    OverlayGui.DisplayOrder = 99
    OverlayGui.Parent = (gethui and gethui()) or player.PlayerGui

    local FpsPanel = Instance.new("Frame")
    FpsPanel.Size = UDim2.new(0, 140, 0, 34)
    FpsPanel.Position = UDim2.new(0, 20, 0.5, 44)
    FpsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FpsPanel.BorderSizePixel = 0
    FpsPanel.Active = true
    FpsPanel.Parent = OverlayGui
    Instance.new("UIDragDetector", FpsPanel)
    Instance.new("UICorner", FpsPanel).CornerRadius = UDim.new(0, 12)

    local FpsStroke = Instance.new("UIStroke", FpsPanel)
    FpsStroke.Color = Color3.fromRGB(255, 255, 255)
    FpsStroke.Transparency = 0.86
    FpsStroke.Thickness = 1

    local FpsPanelGradient = Instance.new("UIGradient", FpsPanel)
    FpsPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    FpsPanelGradient.Rotation = 90

    local FpsValue = Instance.new("TextLabel", FpsPanel)
    FpsValue.Size = UDim2.new(0, 68, 1, 0)
    FpsValue.Position = UDim2.new(0, 14, 0, 0)
    FpsValue.BackgroundTransparency = 1
    FpsValue.Font = Enum.Font.GothamBold
    FpsValue.Text = "0"
    FpsValue.TextColor3 = Color3.fromRGB(255, 255, 255)
    FpsValue.TextSize = 24
    FpsValue.TextXAlignment = Enum.TextXAlignment.Left

    local FpsLabel = Instance.new("TextLabel", FpsPanel)
    FpsLabel.Size = UDim2.new(0, 48, 1, 0)
    FpsLabel.Position = UDim2.new(1, -58, 0, 0)
    FpsLabel.BackgroundTransparency = 1
    FpsLabel.Font = Enum.Font.GothamBold
    FpsLabel.Text = "FPS"
    FpsLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
    FpsLabel.TextSize = 12

    local PingLabel = Instance.new("TextLabel", FpsPanel)
    PingLabel.Size = UDim2.new(0, 80, 0, 14)
    PingLabel.Position = UDim2.new(0, 14, 1, -16)
    PingLabel.BackgroundTransparency = 1
    PingLabel.Font = Enum.Font.GothamBold
    PingLabel.Text = "0 ms"
    PingLabel.TextColor3 = Color3.fromRGB(126, 203, 255)
    PingLabel.TextSize = 12
    PingLabel.TextXAlignment = Enum.TextXAlignment.Left
    PingLabel.Visible = (state.mode == "number")

    local GraphPanel = Instance.new("Frame")
    GraphPanel.Size = UDim2.new(0, 184, 0, 76)
    GraphPanel.Position = UDim2.new(0, 20, 0.5, -38)
    GraphPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    GraphPanel.BorderSizePixel = 0
    GraphPanel.Active = true
    GraphPanel.Parent = OverlayGui
    GraphPanel.Visible = (state.mode == "graph")
    Instance.new("UIDragDetector", GraphPanel)
    Instance.new("UICorner", GraphPanel).CornerRadius = UDim.new(0, 7)

    local GraphStroke = Instance.new("UIStroke", GraphPanel)
    GraphStroke.Color = Color3.fromRGB(255, 255, 255)
    GraphStroke.Transparency = 0.88
    GraphStroke.Thickness = 1

    local GraphPanelGradient = Instance.new("UIGradient", GraphPanel)
    GraphPanelGradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(14, 14, 16)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 0, 0))
    }
    GraphPanelGradient.Rotation = 90

    local PingValueGraph = Instance.new("TextLabel", GraphPanel)
    PingValueGraph.Size = UDim2.new(0, 82, 0, 21)
    PingValueGraph.Position = UDim2.new(1, -91, 0, 4)
    PingValueGraph.BackgroundTransparency = 1
    PingValueGraph.Font = Enum.Font.GothamBold
    PingValueGraph.Text = "0 ms"
    PingValueGraph.TextColor3 = Color3.fromRGB(238, 238, 242)
    PingValueGraph.TextSize = 15
    PingValueGraph.TextXAlignment = Enum.TextXAlignment.Right

    local Divider = Instance.new("Frame", GraphPanel)
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 9, 0, 27)
    Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Divider.BackgroundTransparency = 0.92
    Divider.BorderSizePixel = 0

    local GraphArea = Instance.new("Frame", GraphPanel)
    GraphArea.Size = UDim2.new(1, -18, 0, 38)
    GraphArea.Position = UDim2.new(0, 9, 0, 32)
    GraphArea.BackgroundTransparency = 1
    GraphArea.BorderSizePixel = 0
    GraphArea.ClipsDescendants = true

    local Bars = {}
    for index = 1, state.maxSamples do
        local Bar = Instance.new("Frame", GraphArea)
        Bar.AnchorPoint = Vector2.new(0, 1)
        Bar.Size = UDim2.new(0, 7, 0, 5)
        Bar.Position = UDim2.new(0, (index - 1) * 7, 1, -4)
        Bar.BackgroundColor3 = Color3.fromRGB(126, 203, 255)
        Bar.BorderSizePixel = 0
        Bar.ZIndex = 2

        local BarGradient = Instance.new("UIGradient", Bar)
        BarGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 237, 255)),
            ColorSequenceKeypoint.new(0.3, Color3.fromRGB(151, 216, 255)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(92, 181, 242)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(48, 122, 190))
        }
        BarGradient.Rotation = 90
        Bars[index] = Bar
    end

    state.gui = OverlayGui
    state.fpsLabel = FpsValue
    state.pingLabel = PingLabel
    state.graphPanel = GraphPanel
    state.bars = Bars
    state.pingValueGraph = PingValueGraph
end

local function destroyPerformanceOverlay()
    local state = Library._overlay_state
    if state.fpsConnection then
        state.fpsConnection:Disconnect()
        state.fpsConnection = nil
    end
    if state.gui then
        state.gui:Destroy()
        state.gui = nil
    end
    state.fpsLabel = nil
    state.pingLabel = nil
    state.graphPanel = nil
    state.pingValueGraph = nil
    state.bars = {}
    table.clear(state.samples)
    state.fps = 0
    state.ping = 0
end

local function updateOverlayDisplay()
    local state = Library._overlay_state
    if not state.gui then return end

    if state.mode == "number" then
        state.pingLabel.Visible = true
        state.graphPanel.Visible = false
        state.pingLabel.Text = tostring(state.ping) .. " ms"
    else
        state.pingLabel.Visible = false
        state.graphPanel.Visible = true
        state.pingValueGraph.Text = tostring(state.ping) .. " ms"

        table.insert(state.samples, state.ping)
        if #state.samples > state.maxSamples then
            table.remove(state.samples, 1)
        end

        local maxPing = 200
        for _, sample in ipairs(state.samples) do
            if sample > maxPing then maxPing = sample end
        end

        local maxBarHeight = 34
        local minBarHeight = 3
        for index, bar in ipairs(state.bars) do
            local sample = state.samples[index] or 0
            local ratio = math.clamp(sample / maxPing, 0, 1)
            local height = minBarHeight + ratio * (maxBarHeight - minBarHeight)
            bar.Size = UDim2.new(0, 7, 0, height)
        end
    end

    state.fpsLabel.Text = tostring(state.fps)

    local fpsColor = state.fps >= 60 and Color3.fromRGB(126, 255, 126)
        or state.fps >= 30 and Color3.fromRGB(255, 220, 100)
        or Color3.fromRGB(255, 100, 100)
    state.fpsLabel.TextColor3 = fpsColor
end

local function startPerformanceUpdates()
    local state = Library._overlay_state
    if state.fpsConnection then return end
    local frameCount, elapsed, updateElapsed = 0, 0, 0

    state.fpsConnection = RunService.RenderStepped:Connect(function(dt)
        frameCount = frameCount + 1
        elapsed = elapsed + dt
        updateElapsed = updateElapsed + dt

        if elapsed >= 0.5 then
            state.fps = math.round(frameCount / elapsed)
            frameCount = 0
            elapsed = 0
        end

        if updateElapsed >= 0.5 then
            state.ping = math.round(player:GetNetworkPing() * 1000)
            updateOverlayDisplay()
            updateElapsed = 0
        end
    end)
end

local function setOverlayMode(mode)
    local state = Library._overlay_state
    state.mode = mode
    if not state.gui then return end
    updateOverlayDisplay()
end

local function setOverlayEnabled(enabled)
    local state = Library._overlay_state
    state.enabled = enabled
    if enabled then
        createPerformanceOverlay()
        startPerformanceUpdates()
    else
        destroyPerformanceOverlay()
    end
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

local function setNotificationPosition(position)
    Library._notif_position = position
    local container = NotificationContainer
    if not container then return end

    if position == "left" then
        container.AnchorPoint = Vector2.new(0, 1)
        container.Position = UDim2.new(0, 22, 1, -22)
        container.Size = UDim2.new(0, 300, 0, 0)
        UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
        UIListLayout_Notif.HorizontalAlignment = Enum.HorizontalAlignment.Left
    elseif position == "right" then
        container.AnchorPoint = Vector2.new(1, 1)
        container.Position = UDim2.new(1, -22, 1, -22)
        container.Size = UDim2.new(0, 300, 0, 0)
        UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
        UIListLayout_Notif.HorizontalAlignment = Enum.HorizontalAlignment.Right
    elseif position == "center" then
        container.AnchorPoint = Vector2.new(0.5, 1)
        container.Position = UDim2.new(0.5, 0, 1, -22)
        container.Size = UDim2.new(0, 300, 0, 0)
        UIListLayout_Notif.VerticalAlignment = Enum.VerticalAlignment.Bottom
        UIListLayout_Notif.HorizontalAlignment = Enum.HorizontalAlignment.Center
    end
end

function Library.SendNotification(settings)
    local position = Library._notif_position or "left"
    local Notification = Instance.new("Frame")
    Notification.Size = UDim2.new(1, 0, 0, 62)
    Notification.BackgroundTransparency = 1
    Notification.BorderSizePixel = 0
    Notification.Name = "Notification"
    Notification.Parent = NotificationContainer

    local InnerFrame = Instance.new("Frame")
    InnerFrame.Size = UDim2.new(1, 0, 1, 0)

    if position == "right" then
        InnerFrame.Position = UDim2.new(1, 320, 0, 0)
    elseif position == "center" then
        InnerFrame.Position = UDim2.new(0.5, 160, 0, 0)
    else
        InnerFrame.Position = UDim2.new(-1, -320, 0, 0)
    end

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
        local targetPosition = UDim2.new(0, 0, 0, 0)
        local tweenIn = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Position = targetPosition
        })
        tweenIn:Play()

        task.wait(settings.duration or 5)

        local outPosition
        if position == "right" then
            outPosition = UDim2.new(1, 320, 0, 0)
        elseif position == "center" then
            outPosition = UDim2.new(0.5, 160, 0, 0)
        else
            outPosition = UDim2.new(-1, -320, 0, 0)
        end

        local tweenOut = TweenService:Create(InnerFrame, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = outPosition
        })
        tweenOut:Play()
        tweenOut.Completed:Wait()
        Notification:Destroy()
    end)
end

function Library.new()
    local self = setmetatable({ _tab = 0 }, Library)
    self:create_ui()
    return self
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
    self._container = Container
    self._shadow_holder = ShadowHolder
    self._container_gradient = ContainerGradient
    self._logo = Logo
    self._client_name = ClientName
    self._handler = Handler

    local function on_drag(input, process)
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

    local function drag(input, process)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            update_drag(input)
        end
    end

    Connections['container_input_began'] = Container.InputBegan:Connect(on_drag)
    Connections['input_changed'] = UserInputService.InputChanged:Connect(drag)

    self:removed(function()
        self._ui = nil
        destroyPerformanceOverlay()
        Connections:disconnect_all()
    end)

    function self:change_visiblity(state)
        Library._ui_open = state
        Library._minimized = not state

        if Library._hide_on_minimize and not state then
            self._ui.Enabled = false
        end

        ShadowHolder.Visible = state
        if state then
            if Library._hide_on_minimize then
                self._ui.Enabled = true
            end
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

                    TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        TextTransparency = 0,
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()

                    TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Offset = Vector2.new(1, 0)
                    }):Play()

                    TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        ImageColor3 = object.Icon:GetAttribute('ActiveColor') or Color3.fromRGB(255, 255, 255)
                    }):Play()
                end

                continue
            end

            if object.BackgroundTransparency ~= 1 then
                TweenService:Create(object, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1
                }):Play()

                TweenService:Create(object.TextLabel, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    TextTransparency = 0,
                    TextColor3 = Color3.fromRGB(138, 138, 138)
                }):Play()

                TweenService:Create(object.TextLabel.UIGradient, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Offset = Vector2.new(0, 0)
                }):Play()

                TweenService:Create(object.Icon, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    ImageColor3 = object.Icon:GetAttribute('IdleColor') or Color3.fromRGB(138, 138, 138)
                }):Play()
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

        local UICorner = Instance.new('UICorner')
        UICorner.CornerRadius = UDim.new(0, 5)
        UICorner.Parent = Tab

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

        local UIGradient = Instance.new('UIGradient')
        UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.7, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(58, 58, 58))
        }
        UIGradient.Parent = TextLabel

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
        RightSection.BackgroundTransparency = 1
        RightSection.Position = UDim2.new(0, 474, 0, 67)
        RightSection.ScrollBarImageTransparency = 1
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
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end

        Tab.MouseButton1Click:Connect(function()
            self:update_tabs(Tab, LeftSection, RightSection)
            self:update_sections(LeftSection, RightSection)
        end)

        function TabManager:create_module(settings)
            local LayoutOrderModule = 0
            local ModuleManager = {
                _state = false,
                _size = 0,
                _multiplier = 0,
                _keybind = Library._config._keybinds[settings.title] or nil,
                _callback = nil
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

            local UICorner = Instance.new('UICorner')
            UICorner.CornerRadius = UDim.new(0, 9)
            UICorner.Parent = Module

            local UIStroke = Instance.new('UIStroke')
            UIStroke.Color = Color3.fromRGB(255, 255, 255)
            UIStroke.Transparency = 0.72
            UIStroke.Thickness = 1
            UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            UIStroke.Parent = Module

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
                local moduleX, moduleY, sectionTop, viewportHeight, moduleWidth, moduleHeight

                if UserInputService.TouchEnabled then
                    moduleX = (Module.AbsolutePosition.X - Handler.AbsolutePosition.X) / scale
                    moduleY = (Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale
                    sectionTop = (settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y) / scale
                    viewportHeight = settings.section.AbsoluteWindowSize.Y / scale
                    moduleWidth = Module.AbsoluteSize.X / scale
                    moduleHeight = Module.AbsoluteSize.Y / scale
                else
                    moduleX = Module.AbsolutePosition.X - Handler.AbsolutePosition.X
                    moduleY = Module.AbsolutePosition.Y - Handler.AbsolutePosition.Y
                    sectionTop = settings.section.AbsolutePosition.Y - Handler.AbsolutePosition.Y
                    viewportHeight = settings.section.AbsoluteWindowSize.Y
                    moduleWidth = Module.AbsoluteSize.X
                    moduleHeight = Module.AbsoluteSize.Y
                end

                local moduleTop = math.max(moduleY + 4, sectionTop + 4)
                local moduleBottom = math.min(moduleY + moduleHeight - 4, sectionTop + viewportHeight - 4)
                local trackHeight = math.max(moduleBottom - moduleTop, 1)
                ModuleScrollTrack.Position = UDim2.fromOffset(moduleX + moduleWidth + 10, moduleTop)
                ModuleScrollTrack.Size = UDim2.new(0, 4, 0, trackHeight)

                local section = settings.section
                local vHeight = UserInputService.TouchEnabled and section.AbsoluteWindowSize.Y / scale or section.AbsoluteWindowSize.Y
                local cHeight = UserInputService.TouchEnabled and section.AbsoluteCanvasSize.Y / scale or section.AbsoluteCanvasSize.Y
                local scrollable = cHeight > vHeight + 1
                ModuleScrollTrack.Visible = ModuleManager._state and section.Visible and Library._ui_open

                if not scrollable then
                    ModuleScrollThumb.Size = UDim2.new(1, 0, 0, math.clamp(ModuleScrollTrack.AbsoluteSize.Y * 0.52, 80, 112))
                    ModuleScrollThumb.Position = UDim2.new(0.5, 0, 0, 0)
                    return
                end

                local tHeight = math.max(ModuleScrollTrack.AbsoluteSize.Y, 1)
                local thumbMin = math.min(80, tHeight)
                local thumbMax = math.min(math.max(thumbMin, 112), tHeight)
                local thumbHeight = math.clamp(tHeight * (vHeight / cHeight), thumbMin, thumbMax)
                local maxCanvasPos = math.max(cHeight - vHeight, 1)
                local maxThumbPos = math.max(tHeight - thumbHeight, 0)
                local thumbPos = maxThumbPos * math.clamp(section.CanvasPosition.Y / maxCanvasPos, 0, 1)

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

            local Icon = Instance.new('ImageLabel')
            Icon.Name = 'Icon'
            Icon.Image = settings.icon or 'rbxassetid://79095934438045'
            Icon.ImageColor3 = Color3.fromRGB(195, 195, 202)
            Icon.ImageTransparency = 0
            Icon.ScaleType = Enum.ScaleType.Fit
            Icon.AnchorPoint = Vector2.new(0, 0.5)
            Icon.Position = UDim2.new(0, 13, 0, 75)
            Icon.Size = UDim2.fromOffset(17, 17)
            Icon.BackgroundTransparency = 1
            Icon.BorderSizePixel = 0
            Icon.Parent = Header

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
            KeybindLabel.Text = formatKeybind(ModuleManager._keybind)
            KeybindLabel.Size = UDim2.new(1, -10, 1, 0)
            KeybindLabel.Position = UDim2.new(0, 5, 0, 0)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Center
            KeybindLabel.TextYAlignment = Enum.TextYAlignment.Center
            KeybindLabel.BorderSizePixel = 0
            KeybindLabel.TextSize = 10
            KeybindLabel.Parent = Keybind

            local Divider1 = Instance.new('Frame')
            Divider1.BorderColor3 = Color3.fromRGB(0, 0, 0)
            Divider1.AnchorPoint = Vector2.new(0.5, 0)
            Divider1.BackgroundTransparency = 0.72
            Divider1.Position = UDim2.new(0.5, 0, 0.6200000047683716, 0)
            Divider1.Name = 'Divider'
            Divider1.Size = UDim2.new(0, 241, 0, 1)
            Divider1.BorderSizePixel = 0
            Divider1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Divider1.Parent = Header

            local Divider2 = Instance.new('Frame')
            Divider2.BorderColor3 = Color3.fromRGB(0, 0, 0)
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

            Library._keybind_registry[settings.title] = ModuleManager

            Keybind.MouseButton1Click:Connect(function()
                if Library._choosing_keybind then return end
                Library._choosing_keybind = true
                KeybindLabel.Text = "..."
                KeybindStroke.Color = Color3.fromRGB(126, 203, 255)

                local conn
                conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                        conn:Disconnect()
                        Library._choosing_keybind = false
                        ModuleManager._keybind = input.KeyCode
                        Library._config._keybinds[settings.title] = input.KeyCode
                        KeybindLabel.Text = formatKeybind(input.KeyCode)
                        KeybindStroke.Color = Color3.fromRGB(255, 255, 255)
                        Config:save(game.GameId, Library._config)
                    end
                end)
            end)

            Header.MouseButton1Click:Connect(function()
                ModuleManager._state = not ModuleManager._state
                if ModuleManager._callback then
                    ModuleManager._callback(ModuleManager._state)
                end

                if ModuleManager._state then
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(126, 203, 255)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 16, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93 + ModuleManager._size)
                    }):Play()
                else
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                    }):Play()
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93)
                    }):Play()
                end

                task.defer(UpdateModuleScrollIndicator)
                task.delay(0.3, UpdateModuleScrollIndicator)
            end)

            Connections['keybind_' .. settings.title] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if not ModuleManager._keybind then return end
                if input.KeyCode == ModuleManager._keybind then
                    Header.MouseButton1Click:Fire()
                end
            end)

            function ModuleManager:change_state(state)
                self._state = state
                ModuleScrollTrack.Visible = self._state and settings.section.Visible
                task.defer(UpdateModuleScrollIndicator)
                task.delay(0.3, UpdateModuleScrollIndicator)

                if self._state then
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(126, 203, 255)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 16, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93 + self._size)
                    }):Play()
                else
                    TweenService:Create(Toggle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(36, 36, 42)
                    }):Play()
                    TweenService:Create(Circle, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = UDim2.new(0, 2, 0.5, 0),
                        BackgroundColor3 = Color3.fromRGB(126, 126, 136)
                    }):Play()
                    TweenService:Create(Module, TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Size = UDim2.new(0, 241, 0, 93)
                    }):Play()
                end
            end

            function ModuleManager:add_slider(slider_settings)
                LayoutOrderModule += 1
                local sliderHeight = 32
                ModuleManager._size += sliderHeight + 7
                local sliderValue = Library._config._flags[slider_settings.flag] or slider_settings.default or 0
                Library._config._flags[slider_settings.flag] = sliderValue
                Library._flag_registry[slider_settings.flag] = slider_settings

                local SliderContainer = Instance.new('Frame')
                SliderContainer.Name = 'SliderContainer'
                SliderContainer.Size = UDim2.new(0, 217, 0, sliderHeight)
                SliderContainer.BackgroundTransparency = 1
                SliderContainer.BorderSizePixel = 0
                SliderContainer.Parent = Options
                SliderContainer.LayoutOrder = LayoutOrderModule

                local SliderLabel = Instance.new('TextLabel')
                SliderLabel.Name = 'SliderLabel'
                SliderLabel.Size = UDim2.new(0, 145, 0, 14)
                SliderLabel.Position = UDim2.new(0, 0, 0, 0)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                SliderLabel.Text = slider_settings.text or "Slider"
                SliderLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                SliderLabel.TextSize = 11
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderContainer

                local SliderValue = Instance.new('TextLabel')
                SliderValue.Name = 'SliderValue'
                SliderValue.Size = UDim2.new(0, 60, 0, 14)
                SliderValue.Position = UDim2.new(1, 0, 0, 0)
                SliderValue.BackgroundTransparency = 1
                SliderValue.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                SliderValue.Text = tostring(sliderValue)
                SliderValue.TextColor3 = Color3.fromRGB(238, 238, 242)
                SliderValue.TextSize = 11
                SliderValue.TextXAlignment = Enum.TextXAlignment.Right
                SliderValue.Parent = SliderContainer

                local SliderTrack = Instance.new('Frame')
                SliderTrack.Name = 'SliderTrack'
                SliderTrack.Size = UDim2.new(1, 0, 0, 6)
                SliderTrack.Position = UDim2.new(0, 0, 0, 18)
                SliderTrack.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                SliderTrack.BorderSizePixel = 0
                SliderTrack.Parent = SliderContainer
                Instance.new('UICorner', SliderTrack).CornerRadius = UDim.new(1, 0)

                local SliderFill = Instance.new('Frame')
                SliderFill.Name = 'SliderFill'
                local minVal = slider_settings.min or 0
                local maxVal = slider_settings.max or 100
                local ratio = math.clamp((sliderValue - minVal) / (maxVal - minVal), 0, 1)
                SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
                SliderFill.BackgroundColor3 = Color3.fromRGB(126, 203, 255)
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderTrack
                Instance.new('UICorner', SliderFill).CornerRadius = UDim.new(1, 0)

                local SliderInput = Instance.new('TextButton')
                SliderInput.Name = 'SliderInput'
                SliderInput.Size = UDim2.new(1, 0, 0, 22)
                SliderInput.Position = UDim2.new(0, 0, 0, 10)
                SliderInput.BackgroundTransparency = 1
                SliderInput.Text = ''
                SliderInput.AutoButtonColor = false
                SliderInput.Parent = SliderContainer

                local dragging_slider = false
                SliderInput.MouseButton1Down:Connect(function()
                    dragging_slider = true
                end)

                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging_slider = false
                    end
                end)

                UserInputService.InputChanged:Connect(function(input)
                    if not dragging_slider then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement then
                        local relX = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
                        local newValue = minVal + relX * (maxVal - minVal)
                        if slider_settings.integer then
                            newValue = math.round(newValue)
                        else
                            newValue = math.floor(newValue * 100) / 100
                        end
                        sliderValue = newValue
                        Library._config._flags[slider_settings.flag] = sliderValue
                        SliderFill.Size = UDim2.new(relX, 0, 1, 0)
                        SliderValue.Text = tostring(sliderValue)
                    end
                end)

                return sliderValue
            end

            function ModuleManager:add_toggle(toggle_settings)
                LayoutOrderModule += 1
                local toggleHeight = 22
                ModuleManager._size += toggleHeight + 7
                local toggleValue = Library._config._flags[toggle_settings.flag] or toggle_settings.default or false
                Library._config._flags[toggle_settings.flag] = toggleValue
                Library._flag_registry[toggle_settings.flag] = toggle_settings

                local ToggleContainer = Instance.new('Frame')
                ToggleContainer.Name = 'ToggleContainer'
                ToggleContainer.Size = UDim2.new(0, 217, 0, toggleHeight)
                ToggleContainer.BackgroundTransparency = 1
                ToggleContainer.BorderSizePixel = 0
                ToggleContainer.Parent = Options
                ToggleContainer.LayoutOrder = LayoutOrderModule

                local ToggleLabel = Instance.new('TextLabel')
                ToggleLabel.Name = 'ToggleLabel'
                ToggleLabel.Size = UDim2.new(0, 165, 1, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                ToggleLabel.Text = toggle_settings.text or "Toggle"
                ToggleLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                ToggleLabel.TextSize = 11
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleContainer

                local ToggleSwitch = Instance.new('Frame')
                ToggleSwitch.Name = 'ToggleSwitch'
                ToggleSwitch.Size = UDim2.new(0, 30, 0, 16)
                ToggleSwitch.Position = UDim2.new(1, -30, 0.5, -8)
                ToggleSwitch.BackgroundColor3 = toggleValue and Color3.fromRGB(126, 203, 255) or Color3.fromRGB(36, 36, 42)
                ToggleSwitch.BorderSizePixel = 0
                ToggleSwitch.Parent = ToggleContainer
                Instance.new('UICorner', ToggleSwitch).CornerRadius = UDim.new(1, 0)

                local ToggleCircle = Instance.new('Frame')
                ToggleCircle.Name = 'ToggleCircle'
                ToggleCircle.Size = UDim2.new(0, 12, 0, 12)
                ToggleCircle.Position = toggleValue and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                ToggleCircle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                ToggleCircle.BorderSizePixel = 0
                ToggleCircle.Parent = ToggleSwitch
                Instance.new('UICorner', ToggleCircle).CornerRadius = UDim.new(1, 0)

                local ToggleBtn = Instance.new('TextButton')
                ToggleBtn.Size = UDim2.new(1, 0, 1, 0)
                ToggleBtn.BackgroundTransparency = 1
                ToggleBtn.Text = ''
                ToggleBtn.AutoButtonColor = false
                ToggleBtn.Parent = ToggleContainer

                ToggleBtn.MouseButton1Click:Connect(function()
                    toggleValue = not toggleValue
                    Library._config._flags[toggle_settings.flag] = toggleValue
                    TweenService:Create(ToggleSwitch, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = toggleValue and Color3.fromRGB(126, 203, 255) or Color3.fromRGB(36, 36, 42)
                    }):Play()
                    TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        Position = toggleValue and UDim2.new(0, 16, 0.5, -6) or UDim2.new(0, 2, 0.5, -6)
                    }):Play()
                    if toggle_settings.callback then
                        toggle_settings.callback(toggleValue)
                    end
                end)

                return toggleValue
            end

            function ModuleManager:add_dropdown(dropdown_settings)
                LayoutOrderModule += 1
                local dropdownHeight = 22
                local optionHeight = 24
                local maxVisible = 4
                ModuleManager._size += dropdownHeight + 7
                local dropdownValue = Library._config._flags[dropdown_settings.flag] or dropdown_settings.default or dropdown_settings.options[1]
                Library._config._flags[dropdown_settings.flag] = dropdownValue
                Library._flag_registry[dropdown_settings.flag] = dropdown_settings

                local DropdownContainer = Instance.new('Frame')
                DropdownContainer.Name = 'DropdownContainer'
                DropdownContainer.Size = UDim2.new(0, 217, 0, dropdownHeight)
                DropdownContainer.ClipsDescendants = true
                DropdownContainer.BackgroundTransparency = 1
                DropdownContainer.BorderSizePixel = 0
                DropdownContainer.Parent = Options
                DropdownContainer.LayoutOrder = LayoutOrderModule

                local DropdownLabel = Instance.new('TextLabel')
                DropdownLabel.Name = 'DropdownLabel'
                DropdownLabel.Size = UDim2.new(0, 80, 1, 0)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                DropdownLabel.Text = dropdown_settings.text or "Dropdown"
                DropdownLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                DropdownLabel.TextSize = 11
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownContainer

                local DropdownBtn = Instance.new('TextButton')
                DropdownBtn.Name = 'DropdownBtn'
                DropdownBtn.Size = UDim2.new(0, 130, 0, 18)
                DropdownBtn.Position = UDim2.new(1, -130, 0.5, -9)
                DropdownBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                DropdownBtn.BorderSizePixel = 0
                DropdownBtn.Text = ''
                DropdownBtn.AutoButtonColor = false
                DropdownBtn.Parent = DropdownContainer
                Instance.new('UICorner', DropdownBtn).CornerRadius = UDim.new(0, 4)

                local DropdownStroke = Instance.new('UIStroke', DropdownBtn)
                DropdownStroke.Color = Color3.fromRGB(255, 255, 255)
                DropdownStroke.Transparency = 0.68
                DropdownStroke.Thickness = 1

                local SelectedLabel = Instance.new('TextLabel')
                SelectedLabel.Name = 'SelectedLabel'
                SelectedLabel.Size = UDim2.new(1, -22, 1, 0)
                SelectedLabel.Position = UDim2.new(0, 6, 0, 0)
                SelectedLabel.BackgroundTransparency = 1
                SelectedLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                SelectedLabel.Text = tostring(dropdownValue)
                SelectedLabel.TextColor3 = Color3.fromRGB(195, 195, 202)
                SelectedLabel.TextSize = 10
                SelectedLabel.TextXAlignment = Enum.TextXAlignment.Left
                SelectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
                SelectedLabel.Parent = DropdownBtn

                local Arrow = Instance.new('TextLabel')
                Arrow.Size = UDim2.new(0, 16, 1, 0)
                Arrow.Position = UDim2.new(1, -16, 0, 0)
                Arrow.BackgroundTransparency = 1
                Arrow.Text = "▸"
                Arrow.TextColor3 = Color3.fromRGB(138, 138, 138)
                Arrow.TextSize = 10
                Arrow.Rotation = -90
                Arrow.Parent = DropdownBtn

                local OptionsList = Instance.new('Frame')
                OptionsList.Name = 'OptionsList'
                OptionsList.Size = UDim2.new(1, 0, 0, 0)
                OptionsList.Position = UDim2.new(0, 0, 1, 2)
                OptionsList.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
                OptionsList.BorderSizePixel = 0
                OptionsList.ClipsDescendants = true
                OptionsList.Visible = false
                OptionsList.ZIndex = 50
                OptionsList.Parent = DropdownContainer
                Instance.new('UICorner', OptionsList).CornerRadius = UDim.new(0, 4)

                local OptionsStroke = Instance.new('UIStroke', OptionsList)
                OptionsStroke.Color = Color3.fromRGB(255, 255, 255)
                OptionsStroke.Transparency = 0.72
                OptionsStroke.Thickness = 1

                local OptionsLayout = Instance.new('UIListLayout')
                OptionsLayout.Padding = UDim.new(0, 2)
                OptionsLayout.SortOrder = Enum.SortOrder.LayoutOrder
                OptionsLayout.Parent = OptionsList

                local OptionsPadding = Instance.new('UIPadding')
                OptionsPadding.PaddingTop = UDim.new(0, 2)
                OptionsPadding.PaddingBottom = UDim.new(0, 2)
                OptionsPadding.Parent = OptionsList

                for i, opt in ipairs(dropdown_settings.options) do
                    local OptBtn = Instance.new('TextButton')
                    OptBtn.Size = UDim2.new(1, -8, 0, optionHeight)
                    OptBtn.BackgroundColor3 = opt == dropdownValue and Color3.fromRGB(126, 203, 255) or Color3.fromRGB(35, 35, 40)
                    OptBtn.BackgroundTransparency = opt == dropdownValue and 0.6 or 0
                    OptBtn.BorderSizePixel = 0
                    OptBtn.Text = tostring(opt)
                    OptBtn.TextColor3 = opt == dropdownValue and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(195, 195, 202)
                    OptBtn.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    OptBtn.TextSize = 10
                    OptBtn.AutoButtonColor = false
                    OptBtn.LayoutOrder = i
                    OptBtn.Parent = OptionsList
                    Instance.new('UICorner', OptBtn).CornerRadius = UDim.new(0, 3)

                    OptBtn.MouseButton1Click:Connect(function()
                        dropdownValue = opt
                        Library._config._flags[dropdown_settings.flag] = dropdownValue
                        SelectedLabel.Text = tostring(opt)
                        OptionsList.Visible = false
                        DropdownContainer.ClipsDescendants = true
                        TweenService:Create(DropdownContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, 217, 0, dropdownHeight)
                        }):Play()
                        for _, ob in OptionsList:GetChildren() do
                            if ob:IsA('TextButton') then
                                ob.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                                ob.BackgroundTransparency = 0
                                ob.TextColor3 = Color3.fromRGB(195, 195, 202)
                            end
                        end
                        OptBtn.BackgroundColor3 = Color3.fromRGB(126, 203, 255)
                        OptBtn.BackgroundTransparency = 0.6
                        OptBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
                        if dropdown_settings.callback then
                            dropdown_settings.callback(opt)
                        end
                    end)
                end

                local isOpen = false
                DropdownBtn.MouseButton1Click:Connect(function()
                    isOpen = not isOpen
                    if isOpen then
                        local visibleCount = math.min(#dropdown_settings.options, maxVisible)
                        OptionsList.Visible = true
                        DropdownContainer.ClipsDescendants = false
                        TweenService:Create(DropdownContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, 217, 0, dropdownHeight + visibleCount * (optionHeight + 2) + 4)
                        }):Play()
                        TweenService:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = 90
                        }):Play()
                    else
                        OptionsList.Visible = false
                        DropdownContainer.ClipsDescendants = true
                        TweenService:Create(DropdownContainer, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Size = UDim2.new(0, 217, 0, dropdownHeight)
                        }):Play()
                        TweenService:Create(Arrow, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            Rotation = -90
                        }):Play()
                    end
                end)

                return dropdownValue
            end

            function ModuleManager:add_button(button_settings)
                LayoutOrderModule += 1
                local buttonHeight = 26
                ModuleManager._size += buttonHeight + 7

                local ButtonContainer = Instance.new('Frame')
                ButtonContainer.Name = 'ButtonContainer'
                ButtonContainer.Size = UDim2.new(0, 217, 0, buttonHeight)
                ButtonContainer.BackgroundTransparency = 1
                ButtonContainer.BorderSizePixel = 0
                ButtonContainer.Parent = Options
                ButtonContainer.LayoutOrder = LayoutOrderModule

                local Button = Instance.new('TextButton')
                Button.Size = UDim2.new(1, 0, 0, 26)
                Button.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                Button.BorderSizePixel = 0
                Button.Text = button_settings.text or "Button"
                Button.TextColor3 = Color3.fromRGB(195, 195, 202)
                Button.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                Button.TextSize = 11
                Button.AutoButtonColor = false
                Button.Parent = ButtonContainer
                Instance.new('UICorner', Button).CornerRadius = UDim.new(0, 5)

                local BtnStroke = Instance.new('UIStroke', Button)
                BtnStroke.Color = Color3.fromRGB(255, 255, 255)
                BtnStroke.Transparency = 0.68
                BtnStroke.Thickness = 1

                Button.MouseButton1Click:Connect(function()
                    TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                        BackgroundColor3 = Color3.fromRGB(126, 203, 255),
                        TextColor3 = Color3.fromRGB(255, 255, 255)
                    }):Play()
                    task.delay(0.15, function()
                        TweenService:Create(Button, TweenInfo.new(0.15, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                            BackgroundColor3 = Color3.fromRGB(35, 35, 40),
                            TextColor3 = Color3.fromRGB(195, 195, 202)
                        }):Play()
                    end)
                    if button_settings.callback then
                        button_settings.callback()
                    end
                end)
            end

            function ModuleManager:add_keybind(keybind_settings)
                LayoutOrderModule += 1
                local kbHeight = 22
                ModuleManager._size += kbHeight + 7
                local kbValue = Library._config._keybinds[keybind_settings.flag] or nil
                Library._flag_registry[keybind_settings.flag] = keybind_settings

                local KbContainer = Instance.new('Frame')
                KbContainer.Name = 'KeybindContainer'
                KbContainer.Size = UDim2.new(0, 217, 0, kbHeight)
                KbContainer.BackgroundTransparency = 1
                KbContainer.BorderSizePixel = 0
                KbContainer.Parent = Options
                KbContainer.LayoutOrder = LayoutOrderModule

                local KbLabel = Instance.new('TextLabel')
                KbLabel.Size = UDim2.new(0, 145, 1, 0)
                KbLabel.BackgroundTransparency = 1
                KbLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KbLabel.Text = keybind_settings.text or "Keybind"
                KbLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                KbLabel.TextSize = 11
                KbLabel.TextXAlignment = Enum.TextXAlignment.Left
                KbLabel.Parent = KbContainer

                local KbBtn = Instance.new('TextButton')
                KbBtn.Size = UDim2.new(0, 60, 0, 18)
                KbBtn.Position = UDim2.new(1, -60, 0.5, -9)
                KbBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                KbBtn.BorderSizePixel = 0
                KbBtn.Text = ''
                KbBtn.AutoButtonColor = false
                KbBtn.Parent = KbContainer
                Instance.new('UICorner', KbBtn).CornerRadius = UDim.new(0, 3)

                local KbStroke = Instance.new('UIStroke', KbBtn)
                KbStroke.Color = Color3.fromRGB(255, 255, 255)
                KbStroke.Transparency = 0.68
                KbStroke.Thickness = 1

                local KbText = Instance.new('TextLabel')
                KbText.Size = UDim2.new(1, -10, 1, 0)
                KbText.Position = UDim2.new(0, 5, 0, 0)
                KbText.BackgroundTransparency = 1
                KbText.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                KbText.Text = formatKeybind(kbValue)
                KbText.TextColor3 = Color3.fromRGB(195, 195, 202)
                KbText.TextSize = 10
                KbText.TextXAlignment = Enum.TextXAlignment.Center
                KbText.Parent = KbBtn

                KbBtn.MouseButton1Click:Connect(function()
                    if Library._choosing_keybind then return end
                    Library._choosing_keybind = true
                    KbText.Text = "..."
                    KbStroke.Color = Color3.fromRGB(126, 203, 255)

                    local conn
                    conn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                        if gameProcessed then return end
                        if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
                            conn:Disconnect()
                            Library._choosing_keybind = false
                            kbValue = input.KeyCode
                            Library._config._keybinds[keybind_settings.flag] = kbValue
                            KbText.Text = formatKeybind(kbValue)
                            KbStroke.Color = Color3.fromRGB(255, 255, 255)
                            Config:save(game.GameId, Library._config)
                            if keybind_settings.callback then
                                keybind_settings.callback(kbValue)
                            end
                        end
                    end)
                end)
            end

            function ModuleManager:add_textbox(textbox_settings)
                LayoutOrderModule += 1
                local tbHeight = 36
                ModuleManager._size += tbHeight + 7
                local tbValue = Library._config._flags[textbox_settings.flag] or textbox_settings.default or ""
                Library._config._flags[textbox_settings.flag] = tbValue
                Library._flag_registry[textbox_settings.flag] = textbox_settings

                local TbContainer = Instance.new('Frame')
                TbContainer.Name = 'TextboxContainer'
                TbContainer.Size = UDim2.new(0, 217, 0, tbHeight)
                TbContainer.BackgroundTransparency = 1
                TbContainer.BorderSizePixel = 0
                TbContainer.Parent = Options
                TbContainer.LayoutOrder = LayoutOrderModule

                local TbLabel = Instance.new('TextLabel')
                TbLabel.Size = UDim2.new(1, 0, 0, 14)
                TbLabel.BackgroundTransparency = 1
                TbLabel.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TbLabel.Text = textbox_settings.text or "Text"
                TbLabel.TextColor3 = Color3.fromRGB(178, 178, 185)
                TbLabel.TextSize = 11
                TbLabel.TextXAlignment = Enum.TextXAlignment.Left
                TbLabel.Parent = TbContainer

                local TbInput = Instance.new('TextBox')
                TbInput.Size = UDim2.new(1, 0, 0, 20)
                TbInput.Position = UDim2.new(0, 0, 0, 16)
                TbInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
                TbInput.BorderSizePixel = 0
                TbInput.Text = tostring(tbValue)
                TbInput.TextColor3 = Color3.fromRGB(195, 195, 202)
                TbInput.PlaceholderText = textbox_settings.placeholder or ""
                TbInput.PlaceholderColor3 = Color3.fromRGB(100, 100, 108)
                TbInput.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                TbInput.TextSize = 10
                TbInput.ClearTextOnFocus = false
                TbInput.Parent = TbContainer
                Instance.new('UICorner', TbInput).CornerRadius = UDim.new(0, 4)

                local TbStroke = Instance.new('UIStroke', TbInput)
                TbStroke.Color = Color3.fromRGB(255, 255, 255)
                TbStroke.Transparency = 0.68
                TbStroke.Thickness = 1

                TbInput.FocusLost:Connect(function()
                    tbValue = TbInput.Text
                    Library._config._flags[textbox_settings.flag] = tbValue
                    Config:save(game.GameId, Library._config)
                    if textbox_settings.callback then
                        textbox_settings.callback(tbValue)
                    end
                end)
            end

            function ModuleManager:set_callback(cb)
                ModuleManager._callback = cb
            end

            return ModuleManager
        end

        function TabManager:create_keybinds_list(section_target)
            local targetSection = section_target == 'right' and RightSection or LeftSection

            local ListModule = Instance.new('Frame')
            ListModule.ClipsDescendants = false
            ListModule.BackgroundTransparency = 0
            ListModule.Name = 'KeybindsList'
            ListModule.Size = UDim2.new(0, 241, 0, 30)
            ListModule.BorderSizePixel = 0
            ListModule.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            ListModule.Parent = targetSection

            local ListUICorner = Instance.new('UICorner')
            ListUICorner.CornerRadius = UDim.new(0, 9)
            ListUICorner.Parent = ListModule

            local ListUIStroke = Instance.new('UIStroke')
            ListUIStroke.Color = Color3.fromRGB(255, 255, 255)
            ListUIStroke.Transparency = 0.72
            ListUIStroke.Thickness = 1
            ListUIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ListUIStroke.Parent = ListModule

            local ListHeader = Instance.new('Frame')
            ListHeader.Size = UDim2.new(1, 0, 0, 30)
            ListHeader.BackgroundTransparency = 1
            ListHeader.BorderSizePixel = 0
            ListHeader.Parent = ListModule

            local ListTitle = Instance.new('TextLabel')
            ListTitle.Size = UDim2.new(0, 200, 1, 0)
            ListTitle.Position = UDim2.new(0, 14, 0, 0)
            ListTitle.BackgroundTransparency = 1
            ListTitle.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
            ListTitle.Text = "Keybinds"
            ListTitle.TextColor3 = Color3.fromRGB(238, 238, 242)
            ListTitle.TextSize = 13
            ListTitle.TextXAlignment = Enum.TextXAlignment.Left
            ListTitle.Parent = ListHeader

            local ListDivider = Instance.new('Frame')
            ListDivider.Size = UDim2.new(1, -20, 0, 1)
            ListDivider.Position = UDim2.new(0, 10, 0, 29)
            ListDivider.BackgroundTransparency = 0.72
            ListDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ListDivider.BorderSizePixel = 0
            ListDivider.Parent = ListModule

            local ListContent = Instance.new('Frame')
            ListContent.Name = 'ListContent'
            ListContent.Size = UDim2.new(1, 0, 0, 0)
            ListContent.Position = UDim2.new(0, 0, 0, 31)
            ListContent.BackgroundTransparency = 1
            ListContent.BorderSizePixel = 0
            ListContent.AutomaticSize = Enum.AutomaticSize.Y
            ListContent.Parent = ListModule

            local ListLayout = Instance.new('UIListLayout')
            ListLayout.Padding = UDim.new(0, 4)
            ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ListLayout.Parent = ListContent

            local ListPadding = Instance.new('UIPadding')
            ListPadding.PaddingTop = UDim.new(0, 4)
            ListPadding.PaddingBottom = UDim.new(0, 6)
            ListPadding.PaddingLeft = UDim.new(0, 12)
            ListPadding.PaddingRight = UDim.new(0, 12)
            ListPadding.Parent = ListContent

            local function refreshList()
                for _, child in ListContent:GetChildren() do
                    if child:IsA('Frame') then
                        child:Destroy()
                    end
                end

                local order = 0
                for name, modManager in pairs(Library._keybind_registry) do
                    if not modManager._keybind then continue end
                    order += 1

                    local Entry = Instance.new('Frame')
                    Entry.Size = UDim2.new(1, 0, 0, 22)
                    Entry.BackgroundTransparency = 0.65
                    Entry.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
                    Entry.BorderSizePixel = 0
                    Entry.LayoutOrder = order
                    Entry.Parent = ListContent
                    Instance.new('UICorner', Entry).CornerRadius = UDim.new(0, 4)

                    local EntryName = Instance.new('TextLabel')
                    EntryName.Size = UDim2.new(0, 145, 1, 0)
                    EntryName.Position = UDim2.new(0, 10, 0, 0)
                    EntryName.BackgroundTransparency = 1
                    EntryName.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    EntryName.Text = name
                    EntryName.TextColor3 = Color3.fromRGB(178, 178, 185)
                    EntryName.TextSize = 10
                    EntryName.TextXAlignment = Enum.TextXAlignment.Left
                    EntryName.TextTruncate = Enum.TextTruncate.AtEnd
                    EntryName.Parent = Entry

                    local EntryKey = Instance.new('TextLabel')
                    EntryKey.Size = UDim2.new(0, 60, 1, 0)
                    EntryKey.Position = UDim2.new(1, -70, 0, 0)
                    EntryKey.BackgroundTransparency = 1
                    EntryKey.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
                    EntryKey.Text = formatKeybind(modManager._keybind)
                    EntryKey.TextColor3 = Color3.fromRGB(126, 203, 255)
                    EntryKey.TextSize = 10
                    EntryKey.TextXAlignment = Enum.TextXAlignment.Right
                    EntryKey.Parent = Entry
                end

                if order == 0 then
                    local Empty = Instance.new('TextLabel')
                    Empty.Size = UDim2.new(1, 0, 0, 20)
                    Empty.BackgroundTransparency = 1
                    Empty.FontFace = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
                    Empty.Text = "No keybinds set"
                    Empty.TextColor3 = Color3.fromRGB(100, 100, 108)
                    Empty.TextSize = 10
                    Empty.Parent = ListContent
                end
            end

            refreshList()

            return { refresh = refreshList }
        end

        function TabManager:create_interface_tab()
            local interfaceModules = {}

            local hideOnMinModule = interfaceModules['hide_minimize'] or self:create_module({
                title = "Hide on Minimize",
                description = "Completely hide UI when minimized",
                section = 'left'
            })
            hideOnMinModule:add_toggle({
                flag = "_hide_on_minimize",
                text = "Enable",
                default = Library._hide_on_minimize,
                callback = function(val)
                    Library._hide_on_minimize = val
                end
            })
            hideOnMinModule:set_callback(function(state)
                Library._hide_on_minimize = state
            end)
            interfaceModules['hide_minimize'] = hideOnMinModule

            local overlayModule = interfaceModules['overlay'] or self:create_module({
                title = "Performance Overlay",
                description = "FPS and real ping display",
                section = 'left'
            })
            overlayModule:add_toggle({
                flag = "_overlay_enabled",
                text = "Enable Overlay",
                default = Library._overlay_state.enabled,
                callback = function(val)
                    setOverlayEnabled(val)
                end
            })
            overlayModule:add_dropdown({
                flag = "_overlay_mode",
                text = "Ping Display",
                default = Library._overlay_state.mode,
                options = {"number", "graph"},
                callback = function(val)
                    setOverlayMode(val)
                end
            })
            overlayModule:set_callback(function(state)
                setOverlayEnabled(state)
            end)
            interfaceModules['overlay'] = overlayModule

            local notifModule = interfaceModules['notifications'] or self:create_module({
                title = "Notifications",
                description = "Notification appearance and position",
                section = 'right'
            })
            notifModule:add_dropdown({
                flag = "_notif_position",
                text = "Position",
                default = Library._notif_position,
                options = {"left", "right", "center"},
                callback = function(val)
                    setNotificationPosition(val)
                end
            })
            notifModule:add_button({
                text = "Test Notification",
                callback = function()
                    Library.SendNotification({
                        title = "Test",
                        text = "Notification position preview"
                    })
                end
            })
            notifModule:add_slider({
                flag = "_notif_duration",
                text = "Duration (sec)",
                min = 1,
                max = 15,
                default = 5,
                integer = true
            })
            interfaceModules['notifications'] = notifModule

            self:create_keybinds_list('right')

            return interfaceModules
        end

        return TabManager
    end

    Minimize.MouseButton1Click:Connect(function()
        self:change_visiblity(not Library._ui_open)
    end)

    Connections['minimize_keybind'] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift) then
                self:change_visiblity(not Library._ui_open)
            end
        end
        if input.KeyCode == Enum.KeyCode.P then
            self:change_visiblity(not Library._ui_open)
        end
    end)

    return self
end

return Library

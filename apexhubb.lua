-- Fallen UI Library
-- additions on top of the tested build (api unchanged):
--   + toggles fire notifications on state change (Toggle Notifications option in Customize)
--   + toggle rows darken when off, lighten when on
--   + keybind list panel darker
--   + background support: Customize controls + Window:SetBackground(id), old texture tile preserved
-- fixed earlier: notification slide/stack, slider drag math, header-only window drag,
-- separate FPS + ping overlays, keybind list overlay, minimize option

local cloneref = cloneref or function(object) return object end

local UserInputService = cloneref(game:GetService('UserInputService'))
local TweenService = cloneref(game:GetService('TweenService'))
local HttpService = cloneref(game:GetService('HttpService'))
local RunService = cloneref(game:GetService('RunService'))
local Players = cloneref(game:GetService('Players'))
local CoreGui = cloneref(game:GetService('CoreGui'))

local LocalPlayer = Players.LocalPlayer

local GUI_NAMES = { 'Fallen', 'FallenNotifications', 'FallenOverlays', 'FallenKeybinds' }

local function getGuiRoot()
    local ok, hidden = pcall(function()
        if gethui then return gethui() end
        return nil
    end)
    if ok and hidden then return hidden end
    local ok2, playerGui = pcall(function()
        return LocalPlayer and LocalPlayer.PlayerGui
    end)
    if ok2 and playerGui then return playerGui end
    return CoreGui
end

local GuiRoot = getGuiRoot()

pcall(function()
    if getgenv and getgenv()._Fallen_Cleanup then
        getgenv()._Fallen_Cleanup()
        getgenv()._Fallen_Cleanup = nil
    end
end)

for _, guiName in ipairs(GUI_NAMES) do
    local old = GuiRoot:FindFirstChild(guiName)
    if old then old:Destroy() end
    if GuiRoot ~= CoreGui then
        local oldCore = CoreGui:FindFirstChild(guiName)
        if oldCore then oldCore:Destroy() end
    end
end

local FONT = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.SemiBold, Enum.FontStyle.Normal)
local FONT_HEAVY = Font.new('rbxasset://fonts/families/GothamSSm.json', Enum.FontWeight.Heavy, Enum.FontStyle.Normal)
local FONT_NOTIF = Font.new('rbxasset://fonts/families/SFPro.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)

local COLOR_TEXT = Color3.fromRGB(238, 238, 242)
local COLOR_MUTED = Color3.fromRGB(142, 142, 151)
local COLOR_STROKE = Color3.fromRGB(255, 255, 255)
local COLOR_PING = Color3.fromRGB(126, 203, 255)

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.28, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local function addCorner(parent, radius)
    local corner = Instance.new('UICorner')
    if typeof(radius) == 'number' then
        corner.CornerRadius = UDim.new(0, radius)
    else
        corner.CornerRadius = radius or UDim.new(0, 8)
    end
    corner.Parent = parent
    return corner
end

local function addStroke(parent, transparency, color)
    local stroke = Instance.new('UIStroke')
    stroke.Color = color or COLOR_STROKE
    stroke.Transparency = transparency or 0.72
    stroke.Thickness = 1
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

local function addDarkGradient(parent, head)
    local value = head or 92
    local gradient = Instance.new('UIGradient')
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(value, value, value)),
        ColorSequenceKeypoint.new(0.34, Color3.fromRGB(18, 18, 18)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
    })
    gradient.Rotation = 90
    gradient.Parent = parent
    return gradient
end

local function addText(parent, props)
    local label = Instance.new('TextLabel')
    label.BackgroundTransparency = 1
    label.BorderSizePixel = 0
    label.FontFace = props.Font or FONT
    label.Text = props.Text or ''
    label.TextColor3 = props.Color or COLOR_TEXT
    label.TextSize = props.Size or 13
    label.AnchorPoint = props.AnchorPoint or Vector2.new(0, 0)
    label.Position = props.Position or UDim2.new(0, 0, 0, 0)
    label.Size = props.Size2 or UDim2.new(1, 0, 1, 0)
    label.TextXAlignment = props.XAlign or Enum.TextXAlignment.Left
    label.TextYAlignment = props.YAlign or Enum.TextYAlignment.Center
    label.TextTruncate = props.Truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None
    label.TextWrapped = props.Wrapped or false
    label.LayoutOrder = props.LayoutOrder or 0
    label.ZIndex = props.ZIndex or 1
    label.Parent = parent
    return label
end

local Connections = {}
Connections.__index = Connections

function Connections:disconnect(name)
    local connection = self[name]
    if connection and typeof(connection) == 'RBXScriptConnection' then
        connection:Disconnect()
        self[name] = nil
    end
end

function Connections:disconnect_all()
    for key, value in pairs(self) do
        if typeof(value) == 'RBXScriptConnection' then
            value:Disconnect()
            self[key] = nil
        end
    end
end

local uid = 0
local function nextUid()
    uid += 1
    return uid
end

local function clampFrame(frame, position)
    local parent = frame.Parent
    if not parent then return position end
    local anchor = frame.AnchorPoint
    local parentSize = parent.AbsoluteSize
    local frameSize = frame.AbsoluteSize
    local x = position.X.Scale * parentSize.X + position.X.Offset - anchor.X * frameSize.X
    local y = position.Y.Scale * parentSize.Y + position.Y.Offset - anchor.Y * frameSize.Y
    x = math.clamp(x, 4, math.max(4, parentSize.X - frameSize.X - 4))
    y = math.clamp(y, 4, math.max(4, parentSize.Y - frameSize.Y - 4))
    return UDim2.new(0, math.floor(x + anchor.X * frameSize.X + 0.5), 0, math.floor(y + anchor.Y * frameSize.Y + 0.5))
end

local function makeDraggable(frame)
    local dragging = false
    local dragStart, startPos
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Connections['drag_' .. nextUid()] = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = clampFrame(frame, UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            ))
        end
    end)
end

local function watchResize(frame)
    local gui = frame:FindFirstAncestorOfClass('ScreenGui')
    if not gui then return end
    Connections['resize_' .. nextUid()] = gui:GetPropertyChangedSignal('AbsoluteSize'):Connect(function()
        frame.Position = clampFrame(frame, frame.Position)
    end)
end

local hasFileSystem = (typeof(writefile) == 'function')
    and (typeof(readfile) == 'function')
    and (typeof(isfile) == 'function')
    and (typeof(isfolder) == 'function')
    and (typeof(makefolder) == 'function')

local CONFIG_FOLDER = 'Fallen'
local CONFIG_FILE = CONFIG_FOLDER .. '/' .. tostring(game.GameId) .. '.json'

local Library = {}
Library.__index = Library
Library.Connections = Connections
Library._flags = {}
Library._keybinds = {}
Library._interface = {}
Library._keybind_registry = {}
Library._choosing = nil
Library._window = nil

local function defaultInterface()
    return {
        show_keybinds = false,
        show_fps = false,
        show_ping = false,
        ping_mode = 'number',
        notif_position = 'left',
        hide_on_minimize = false,
        toggle_notifications = true,
        background_enabled = false,
        background_asset = '',
        background_transparency = 0.5,
        texture_enabled = true,
    }
end

local Config = {}

function Config:load()
    local data = nil
    if hasFileSystem then
        local ok, result = pcall(function()
            if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
            if not isfile(CONFIG_FILE) then return nil end
            return HttpService:JSONDecode(readfile(CONFIG_FILE))
        end)
        if ok then
            data = result
        else
            warn('[Fallen] config load failed: ' .. tostring(result))
        end
    end

    local flags, keybinds = {}, {}
    local interface = defaultInterface()

    if type(data) == 'table' then
        if type(data._flags) == 'table' then
            for key, value in pairs(data._flags) do
                flags[key] = value
            end
        end
        if type(data._keybinds) == 'table' then
            for key, value in pairs(data._keybinds) do
                if type(value) == 'string' then
                    keybinds[key] = value
                end
            end
        end
        if type(data._interface) == 'table' then
            for key, value in pairs(data._interface) do
                interface[key] = value
            end
        end
    end

    interface.show_keybinds = interface.show_keybinds == true
    interface.show_fps = interface.show_fps == true
    interface.show_ping = interface.show_ping == true
    interface.hide_on_minimize = interface.hide_on_minimize == true
    interface.toggle_notifications = interface.toggle_notifications ~= false
    interface.background_enabled = interface.background_enabled == true
    interface.texture_enabled = interface.texture_enabled ~= false
    if type(interface.background_asset) ~= 'string' then
        interface.background_asset = ''
    end
    if type(interface.background_transparency) ~= 'number' then
        interface.background_transparency = 0.5
    end
    interface.background_transparency = math.clamp(interface.background_transparency, 0, 1)
    if interface.ping_mode ~= 'number' and interface.ping_mode ~= 'graph' then
        interface.ping_mode = 'number'
    end
    if interface.notif_position ~= 'left' and interface.notif_position ~= 'right' and interface.notif_position ~= 'center' then
        interface.notif_position = 'left'
    end

    return { _flags = flags, _keybinds = keybinds, _interface = interface }
end

function Config:save()
    if not hasFileSystem then return end
    local ok, result = pcall(function()
        if not isfolder(CONFIG_FOLDER) then makefolder(CONFIG_FOLDER) end
        writefile(CONFIG_FILE, HttpService:JSONEncode({
            _flags = Library._flags,
            _keybinds = Library._keybinds,
            _interface = Library._interface,
        }))
    end)
    if not ok then
        warn('[Fallen] config save failed: ' .. tostring(result))
    end
end

do
    local loaded = Config:load()
    Library._flags = loaded._flags
    Library._keybinds = loaded._keybinds
    Library._interface = loaded._interface
end

local KEY_ALIASES = {
    LeftShift = 'L-Shift',
    RightShift = 'R-Shift',
    LeftControl = 'L-Ctrl',
    RightControl = 'R-Ctrl',
    LeftAlt = 'L-Alt',
    RightAlt = 'R-Alt',
    MouseButton1 = 'MB1',
    MouseButton2 = 'MB2',
    MouseButton3 = 'MB3',
    Return = 'Enter',
}

local function formatKeybind(keyName)
    if not keyName or keyName == '' then
        return 'None'
    end
    return KEY_ALIASES[keyName] or keyName
end

local function inputName(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        return 'MouseButton1'
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        return 'MouseButton2'
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        return 'MouseButton3'
    end
    return nil
end

local setNotifPosition
local refreshKeybindOverlay
local setKeybindOverlay
local setOverlayFps
local setOverlayPing
local setPingMode

function Library:RegisterKeybind(title, defaultKey, callback)
    for _, existing in ipairs(Library._keybind_registry) do
        if existing.Title == title then
            return existing
        end
    end
    local saved = Library._keybinds[title]
    local entry = {
        Title = title,
        Key = (type(saved) == 'string' and saved) or defaultKey or nil,
        Callback = callback,
        OnChanged = nil,
        OnChoosingEnd = nil,
    }
    table.insert(Library._keybind_registry, entry)
    refreshKeybindOverlay()
    return entry
end

function Library:SetKeybind(entry, keyName)
    entry.Key = keyName
    if keyName then
        Library._keybinds[entry.Title] = keyName
    else
        Library._keybinds[entry.Title] = nil
    end
    Config:save()
    if entry.OnChanged then
        entry.OnChanged(keyName)
    end
    refreshKeybindOverlay()
end

Connections['keybind_input'] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    local name = inputName(input)
    if not name then return end

    if Library._choosing then
        if gameProcessed then return end
        if name == 'MouseButton1' then return end
        local entry = Library._choosing
        Library._choosing = nil
        if name == 'Escape' then
            if entry.OnChoosingEnd then entry.OnChoosingEnd() end
        elseif name == 'Backspace' then
            Library:SetKeybind(entry, nil)
        else
            Library:SetKeybind(entry, name)
        end
        return
    end

    if gameProcessed then return end

    for _, entry in ipairs(Library._keybind_registry) do
        if entry.Key == name and entry.Callback then
            task.spawn(entry.Callback, name)
        end
    end
end)

local Notif = {
    gui = nil,
    container = nil,
    layout = nil,
    order = 0,
    maxVisible = 4,
}

setNotifPosition = function(position)
    if position ~= 'left' and position ~= 'right' and position ~= 'center' then
        position = 'left'
    end
    local changed = Library._interface.notif_position ~= position
    Library._interface.notif_position = position
    if changed then Config:save() end
    local container = Notif.container
    if not container then return end
    if position == 'right' then
        container.AnchorPoint = Vector2.new(1, 1)
        container.Position = UDim2.new(1, -22, 1, -22)
        Notif.layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    elseif position == 'center' then
        container.AnchorPoint = Vector2.new(0.5, 1)
        container.Position = UDim2.new(0.5, 0, 1, -22)
        Notif.layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    else
        container.AnchorPoint = Vector2.new(0, 1)
        container.Position = UDim2.new(0, 22, 1, -22)
        Notif.layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    end
end

local function ensureNotifGui()
    if Notif.gui then return end
    local gui = Instance.new('ScreenGui')
    gui.Name = 'FallenNotifications'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 101
    gui.Parent = GuiRoot
    Notif.gui = gui

    local container = Instance.new('Frame')
    container.Name = 'Notifications'
    container.Size = UDim2.new(0, 300, 0, 0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1
    container.BorderSizePixel = 0
    container.ClipsDescendants = false
    container.Parent = gui
    Notif.container = container

    local layout = Instance.new('UIListLayout')
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)
    layout.Parent = container
    Notif.layout = layout

    setNotifPosition(Library._interface.notif_position)
end

function Library:Notify(settings)
    if type(settings) ~= 'table' then
        settings = (type(self) == 'table' and self ~= Library) and self or {}
    end
    ensureNotifGui()

    local position = Library._interface.notif_position
    local duration = math.max(tonumber(settings.duration) or 5, 1)

    local visible = {}
    for _, child in ipairs(Notif.container:GetChildren()) do
        if child.Name == 'Notification' then
            table.insert(visible, child)
        end
    end
    while #visible >= Notif.maxVisible do
        visible[1]:Destroy()
        table.remove(visible, 1)
    end

    Notif.order += 1

    local notification = Instance.new('Frame')
    notification.Name = 'Notification'
    notification.Size = UDim2.new(1, 0, 0, 62)
    notification.BackgroundTransparency = 1
    notification.BorderSizePixel = 0
    notification.LayoutOrder = Notif.order
    notification.Parent = Notif.container

    local inner = Instance.new('Frame')
    inner.Name = 'Inner'
    inner.Size = UDim2.new(1, 0, 1, 0)
    inner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    inner.BorderSizePixel = 0
    inner.Parent = notification
    addCorner(inner, 8)
    addStroke(inner, 0.72)
    addDarkGradient(inner, 92)

    addText(inner, {
        Text = tostring(settings.title or 'Notification'),
        Font = FONT_NOTIF,
        Size = 16,
        Size2 = UDim2.new(1, -28, 0, 15),
        Position = UDim2.new(0, 14, 0, 12),
        Truncate = true,
    })
    addText(inner, {
        Text = tostring(settings.text or ''),
        Font = FONT_NOTIF,
        Size = 13,
        Color = COLOR_MUTED,
        Size2 = UDim2.new(1, -28, 0, 13),
        Position = UDim2.new(0, 14, 0, 33),
        Truncate = true,
    })

    local startPos
    if position == 'right' then
        startPos = UDim2.new(0, 330, 0, 0)
    elseif position == 'center' then
        startPos = UDim2.new(0, 0, 0, 90)
    else
        startPos = UDim2.new(0, -330, 0, 0)
    end
    inner.Position = startPos

    TweenService:Create(inner, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 0, 0, 0),
    }):Play()

    task.delay(duration, function()
        if not notification.Parent then return end
        local outTween = TweenService:Create(inner, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            Position = startPos,
        })
        outTween:Play()
        outTween.Completed:Once(function()
            notification:Destroy()
        end)
    end)
end

Library.SendNotification = Library.Notify

local Overlay = {
    gui = nil,
    fpsPanel = nil,
    fpsValue = nil,
    pingPanel = nil,
    pingNumber = nil,
    pingNumberLabel = nil,
    pingGraph = nil,
    pingGraphValue = nil,
    bars = {},
    samples = {},
    maxSamples = 24,
    fps = 0,
    ping = 0,
}

local function pingColorFor(ping)
    if ping <= 80 then return Color3.fromRGB(126, 255, 126) end
    if ping <= 150 then return Color3.fromRGB(255, 220, 100) end
    return Color3.fromRGB(255, 100, 100)
end

local function updatePingDisplay()
    if not Overlay.gui or not Overlay.pingPanel or not Overlay.pingPanel.Visible then return end
    local ping = Overlay.ping
    if Library._interface.ping_mode == 'graph' then
        if Overlay.pingGraphValue then
            Overlay.pingGraphValue.Text = ping .. ' ms'
            Overlay.pingGraphValue.TextColor3 = pingColorFor(ping)
        end
        table.insert(Overlay.samples, ping)
        if #Overlay.samples > Overlay.maxSamples then
            table.remove(Overlay.samples, 1)
        end
        local maxPing = 120
        for _, sample in ipairs(Overlay.samples) do
            if sample > maxPing then maxPing = sample end
        end
        for index, bar in ipairs(Overlay.bars) do
            local sample = Overlay.samples[index] or 0
            local ratio = math.clamp(sample / maxPing, 0, 1)
            bar.Size = UDim2.new(0, 7, 0, 3 + math.floor(ratio * 31 + 0.5))
        end
    else
        if Overlay.pingNumberLabel then
            Overlay.pingNumberLabel.Text = ping .. ' ms'
            Overlay.pingNumberLabel.TextColor3 = pingColorFor(ping)
        end
    end
end

local function startPerfLoop()
    if Connections['perf_loop'] then return end
    local frames, fpsElapsed, pingElapsed = 0, 0, 0
    Connections['perf_loop'] = RunService.RenderStepped:Connect(function(dt)
        local showFps = Library._interface.show_fps
        local showPing = Library._interface.show_ping
        if not showFps and not showPing then return end

        frames += 1
        fpsElapsed += dt
        pingElapsed += dt

        if fpsElapsed >= 0.5 then
            if showFps and Overlay.fpsValue then
                Overlay.fps = math.max(1, math.round(frames / fpsElapsed))
                Overlay.fpsValue.Text = tostring(Overlay.fps)
                if Overlay.fps >= 60 then
                    Overlay.fpsValue.TextColor3 = Color3.fromRGB(126, 255, 126)
                elseif Overlay.fps >= 30 then
                    Overlay.fpsValue.TextColor3 = Color3.fromRGB(255, 220, 100)
                else
                    Overlay.fpsValue.TextColor3 = Color3.fromRGB(255, 100, 100)
                end
            end
            frames = 0
            fpsElapsed = 0
        end

        if pingElapsed >= 0.5 then
            if showPing then
                Overlay.ping = math.max(0, math.round((LocalPlayer and LocalPlayer:GetNetworkPing() or 0) * 1000))
                updatePingDisplay()
            end
            pingElapsed = 0
        end
    end)
end

local function ensureOverlayGui()
    if Overlay.gui then return end
    local gui = Instance.new('ScreenGui')
    gui.Name = 'FallenOverlays'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 99
    gui.Parent = GuiRoot
    Overlay.gui = gui

    local fpsPanel = Instance.new('Frame')
    fpsPanel.Name = 'FpsPanel'
    fpsPanel.Position = UDim2.new(1, -124, 0, 16)
    fpsPanel.Size = UDim2.new(0, 108, 0, 38)
    fpsPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    fpsPanel.BorderSizePixel = 0
    fpsPanel.Active = true
    fpsPanel.Visible = false
    fpsPanel.Parent = gui
    addCorner(fpsPanel, 10)
    addStroke(fpsPanel, 0.86)
    addDarkGradient(fpsPanel, 130)
    makeDraggable(fpsPanel)
    watchResize(fpsPanel)

    local fpsValue = addText(fpsPanel, {
        Text = '0',
        Font = FONT_HEAVY,
        Size = 22,
        Size2 = UDim2.new(0, 56, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
    })
    addText(fpsPanel, {
        Text = 'FPS',
        Size = 11,
        Color = Color3.fromRGB(178, 178, 185),
        Size2 = UDim2.new(0, 32, 1, 0),
        Position = UDim2.new(1, -44, 0, 0),
        XAlign = Enum.TextXAlignment.Right,
    })

    local pingPanel = Instance.new('Frame')
    pingPanel.Name = 'PingPanel'
    pingPanel.Position = UDim2.new(1, -124, 0, 62)
    pingPanel.Size = UDim2.new(0, 108, 0, 38)
    pingPanel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    pingPanel.BorderSizePixel = 0
    pingPanel.Active = true
    pingPanel.Visible = false
    pingPanel.Parent = gui
    addCorner(pingPanel, 10)
    addStroke(pingPanel, 0.86)
    addDarkGradient(pingPanel, 130)
    makeDraggable(pingPanel)
    watchResize(pingPanel)

    local pingNumber = Instance.new('Frame')
    pingNumber.Name = 'Number'
    pingNumber.Size = UDim2.new(1, 0, 1, 0)
    pingNumber.BackgroundTransparency = 1
    pingNumber.BorderSizePixel = 0
    pingNumber.Parent = pingPanel

    local pingNumberLabel = addText(pingNumber, {
        Text = '0 ms',
        Size = 15,
        Size2 = UDim2.new(0, 64, 1, 0),
        Position = UDim2.new(0, 12, 0, 0),
    })
    addText(pingNumber, {
        Text = 'PING',
        Size = 11,
        Color = Color3.fromRGB(178, 178, 185),
        Size2 = UDim2.new(0, 30, 1, 0),
        Position = UDim2.new(1, -42, 0, 0),
        XAlign = Enum.TextXAlignment.Right,
    })

    local pingGraph = Instance.new('Frame')
    pingGraph.Name = 'Graph'
    pingGraph.Size = UDim2.new(1, 0, 1, 0)
    pingGraph.BackgroundTransparency = 1
    pingGraph.BorderSizePixel = 0
    pingGraph.Visible = false
    pingGraph.Parent = pingPanel

    local pingGraphValue = addText(pingGraph, {
        Text = '0 ms',
        Size = 15,
        Size2 = UDim2.new(0, 84, 0, 21),
        Position = UDim2.new(1, -95, 0, 4),
        XAlign = Enum.TextXAlignment.Right,
    })

    local graphDivider = Instance.new('Frame')
    graphDivider.Size = UDim2.new(1, -20, 0, 1)
    graphDivider.Position = UDim2.new(0, 9, 0, 27)
    graphDivider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    graphDivider.BackgroundTransparency = 0.92
    graphDivider.BorderSizePixel = 0
    graphDivider.Parent = pingGraph

    local graphArea = Instance.new('Frame')
    graphArea.Position = UDim2.new(0, 9, 0, 32)
    graphArea.Size = UDim2.new(1, -18, 0, 38)
    graphArea.BackgroundTransparency = 1
    graphArea.BorderSizePixel = 0
    graphArea.ClipsDescendants = true
    graphArea.Parent = pingGraph

    local bars = {}
    for index = 1, Overlay.maxSamples do
        local bar = Instance.new('Frame')
        bar.AnchorPoint = Vector2.new(0, 1)
        bar.Position = UDim2.new(0, (index - 1) * 7, 1, -4)
        bar.Size = UDim2.new(0, 7, 0, 5)
        bar.BackgroundColor3 = COLOR_PING
        bar.BorderSizePixel = 0
        bar.Parent = graphArea

        local barGradient = Instance.new('UIGradient')
        barGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(205, 237, 255)),
            ColorSequenceKeypoint.new(0.30, Color3.fromRGB(151, 216, 255)),
            ColorSequenceKeypoint.new(0.72, Color3.fromRGB(92, 181, 242)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(48, 122, 190)),
        })
        barGradient.Rotation = 90
        barGradient.Parent = bar

        bars[index] = bar
    end

    Overlay.fpsPanel = fpsPanel
    Overlay.fpsValue = fpsValue
    Overlay.pingPanel = pingPanel
    Overlay.pingNumber = pingNumber
    Overlay.pingNumberLabel = pingNumberLabel
    Overlay.pingGraph = pingGraph
    Overlay.pingGraphValue = pingGraphValue
    Overlay.bars = bars
end

setPingMode = function(mode)
    if mode ~= 'number' and mode ~= 'graph' then mode = 'number' end
    local changed = Library._interface.ping_mode ~= mode
    Library._interface.ping_mode = mode
    if changed then Config:save() end
    if not Overlay.pingPanel then return end
    local isGraph = mode == 'graph'
    Overlay.pingNumber.Visible = not isGraph
    Overlay.pingGraph.Visible = isGraph
    Overlay.pingPanel.Size = isGraph and UDim2.new(0, 190, 0, 76) or UDim2.new(0, 108, 0, 38)
    Overlay.pingPanel.Position = clampFrame(Overlay.pingPanel, Overlay.pingPanel.Position)
    table.clear(Overlay.samples)
    updatePingDisplay()
end

setOverlayFps = function(enabled)
    Library._interface.show_fps = enabled == true
    Config:save()
    if Library._interface.show_fps then
        ensureOverlayGui()
        Overlay.fpsPanel.Visible = true
        startPerfLoop()
    elseif Overlay.fpsPanel then
        Overlay.fpsPanel.Visible = false
    end
end

setOverlayPing = function(enabled)
    Library._interface.show_ping = enabled == true
    Config:save()
    if Library._interface.show_ping then
        ensureOverlayGui()
        setPingMode(Library._interface.ping_mode)
        Overlay.pingPanel.Visible = true
        startPerfLoop()
    elseif Overlay.pingPanel then
        Overlay.pingPanel.Visible = false
    end
end

local KeybindOverlay = {
    gui = nil,
    panel = nil,
    list = nil,
    enabled = false,
}

local function buildKeybindOverlay()
    local gui = Instance.new('ScreenGui')
    gui.Name = 'FallenKeybinds'
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 98
    gui.Parent = GuiRoot
    KeybindOverlay.gui = gui

    local panel = Instance.new('Frame')
    panel.Name = 'KeybindPanel'
    panel.Position = UDim2.new(0, 16, 0, 16)
    panel.Size = UDim2.new(0, 208, 0, 42)
    panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    panel.BackgroundTransparency = 0.05
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Parent = gui
    addCorner(panel, 10)
    addStroke(panel, 0.7)
    addDarkGradient(panel, 60)
    makeDraggable(panel)
    watchResize(panel)

    addText(panel, {
        Text = 'Keybinds',
        Font = FONT_HEAVY,
        Size = 12,
        Size2 = UDim2.new(1, -20, 0, 14),
        Position = UDim2.new(0, 12, 0, 9),
    })

    local list = Instance.new('ScrollingFrame')
    list.Name = 'List'
    list.Position = UDim2.new(0, 6, 0, 28)
    list.Size = UDim2.new(1, -12, 0, 24)
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
    list.ScrollBarImageTransparency = 0.6
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = panel
    KeybindOverlay.list = list

    local layout = Instance.new('UIListLayout')
    layout.Padding = UDim.new(0, 2)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = list
end

refreshKeybindOverlay = function()
    if not KeybindOverlay.gui or not KeybindOverlay.list then return end
    if not KeybindOverlay.gui.Enabled then return end

    for _, child in ipairs(KeybindOverlay.list:GetChildren()) do
        if child:IsA('GuiObject') then
            child:Destroy()
        end
    end

    local bound = {}
    for _, entry in ipairs(Library._keybind_registry) do
        if entry.Key and entry.Key ~= '' then
            table.insert(bound, entry)
        end
    end

    local rowCount = math.max(#bound, 1)
    if #bound == 0 then
        local row = Instance.new('Frame')
        row.Size = UDim2.new(1, 0, 0, 22)
        row.BackgroundTransparency = 1
        row.BorderSizePixel = 0
        row.LayoutOrder = 1
        row.Parent = KeybindOverlay.list
        addText(row, {
            Text = 'No keybinds set',
            Size = 11,
            Color = COLOR_MUTED,
            Size2 = UDim2.new(1, 0, 1, 0),
            Position = UDim2.new(0, 10, 0, 0),
        })
    else
        for index, entry in ipairs(bound) do
            local row = Instance.new('Frame')
            row.Size = UDim2.new(1, 0, 0, 22)
            row.BackgroundTransparency = 1
            row.BorderSizePixel = 0
            row.LayoutOrder = index
            row.Parent = KeybindOverlay.list

            addText(row, {
                Text = entry.Title,
                Size = 12,
                Size2 = UDim2.new(1, -88, 1, 0),
                Position = UDim2.new(0, 10, 0, 0),
                Truncate = true,
            })
            addText(row, {
                Text = formatKeybind(entry.Key),
                Size = 12,
                Color = COLOR_PING,
                Size2 = UDim2.new(0, 72, 1, 0),
                Position = UDim2.new(1, -82, 0, 0),
                XAlign = Enum.TextXAlignment.Right,
                Truncate = true,
            })
        end
    end

    local listHeight = math.min(rowCount * 24, 240)
    KeybindOverlay.list.Size = UDim2.new(1, -12, 0, listHeight)
    KeybindOverlay.panel.Size = UDim2.new(0, 208, 0, 28 + listHeight + 8)
    KeybindOverlay.panel.Position = clampFrame(KeybindOverlay.panel, KeybindOverlay.panel.Position)
end

setKeybindOverlay = function(enabled)
    KeybindOverlay.enabled = enabled == true
    local changed = Library._interface.show_keybinds ~= KeybindOverlay.enabled
    Library._interface.show_keybinds = KeybindOverlay.enabled
    if changed then Config:save() end
    if KeybindOverlay.enabled then
        if not KeybindOverlay.gui then
            buildKeybindOverlay()
        end
        KeybindOverlay.gui.Enabled = true
        refreshKeybindOverlay()
    elseif KeybindOverlay.gui then
        KeybindOverlay.gui.Enabled = false
    end
end

local function newModule(parent, height)
    local module = Instance.new('Frame')
    module.Name = 'Module'
    module.Size = UDim2.new(0, 241, 0, height)
    module.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    module.BorderSizePixel = 0
    module.ClipsDescendants = true
    module.Parent = parent
    addCorner(module, 9)
    addStroke(module, 0.72)
    addDarkGradient(module, 92)
    return module
end

local function flagStorage(settings)
    if settings.Interface then
        return Library._interface, settings.Interface
    end
    if settings.Flag then
        return Library._flags, settings.Flag
    end
    return nil, nil
end

local function buildToggle(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local title = tostring(settings.Title or 'Toggle')
    local module = newModule(parent, 46)

    addText(module, {
        Text = title,
        Size = 13,
        Size2 = UDim2.new(1, -104, 0, 14),
        Position = UDim2.new(0, 12, 0, 16),
        Truncate = true,
    })

    local switch = Instance.new('Frame')
    switch.AnchorPoint = Vector2.new(1, 0.5)
    switch.Position = UDim2.new(1, -12, 0.5, 0)
    switch.Size = UDim2.new(0, 38, 0, 18)
    switch.BackgroundColor3 = Color3.fromRGB(70, 70, 78)
    switch.BorderSizePixel = 0
    switch.Parent = module
    addCorner(switch, 9)

    local knob = Instance.new('Frame')
    knob.AnchorPoint = Vector2.new(0, 0.5)
    knob.Position = UDim2.new(0, 3, 0.5, 0)
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.BackgroundColor3 = Color3.fromRGB(235, 235, 238)
    knob.BorderSizePixel = 0
    knob.Parent = switch
    addCorner(knob, 6)

    local controller = { Value = false }
    local storage, storeKey = flagStorage(settings)

    local function notifyState(value)
        if Library._interface.toggle_notifications == false then return end
        Library:Notify({
            Title = title,
            Text = value and 'Enabled' or 'Disabled',
            Duration = 2,
        })
    end

    local function apply(value)
        controller.Value = value
        TweenService:Create(module, TWEEN_FAST, {
            BackgroundColor3 = value and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(112, 112, 122),
        }):Play()
        TweenService:Create(switch, TWEEN_FAST, {
            BackgroundColor3 = value and Color3.fromRGB(228, 228, 234) or Color3.fromRGB(70, 70, 78),
        }):Play()
        TweenService:Create(knob, TWEEN_FAST, {
            Position = value and UDim2.new(1, -15, 0.5, 0) or UDim2.new(0, 3, 0.5, 0),
        }):Play()
        if storage and storeKey then
            storage[storeKey] = value
        end
    end

    local initial = settings.Default == true
    if storage and storeKey and storage[storeKey] ~= nil and type(storage[storeKey]) == 'boolean' then
        initial = storage[storeKey]
    end
    apply(initial)
    if settings.Callback then
        task.spawn(settings.Callback, initial)
    end

    module.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            apply(not controller.Value)
            Config:save()
            if settings.Callback then
                task.spawn(settings.Callback, controller.Value)
            end
            notifyState(controller.Value)
        end
    end)

    function controller:Set(value)
        apply(value == true)
        Config:save()
        if settings.Callback then
            task.spawn(settings.Callback, controller.Value)
        end
        notifyState(controller.Value)
    end

    return controller
end

local function buildSlider(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local module = newModule(parent, 64)

    local minValue = tonumber(settings.Min) or 0
    local maxValue = tonumber(settings.Max) or 100
    if maxValue <= minValue then
        maxValue = minValue + 1
    end
    local step = tonumber(settings.Step)
    if not step or step <= 0 then
        step = (maxValue - minValue) / 100
    end
    local precision = tonumber(settings.Precision)
    if not precision then
        precision = (step >= 1) and 0 or math.clamp(math.ceil(-math.log10(step)), 0, 4)
    end

    addText(module, {
        Text = tostring(settings.Title or 'Slider'),
        Size = 13,
        Size2 = UDim2.new(1, -96, 0, 14),
        Position = UDim2.new(0, 12, 0, 9),
        Truncate = true,
    })

    local valueLabel = addText(module, {
        Text = '',
        Size = 13,
        Color = COLOR_MUTED,
        Size2 = UDim2.new(0, 76, 0, 14),
        Position = UDim2.new(1, -88, 0, 9),
        XAlign = Enum.TextXAlignment.Right,
        Truncate = true,
    })

    local track = Instance.new('Frame')
    track.Position = UDim2.new(0, 12, 0, 38)
    track.Size = UDim2.new(1, -24, 0, 6)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
    track.BorderSizePixel = 0
    track.Parent = module
    addCorner(track, 3)

    local fill = Instance.new('Frame')
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(235, 235, 238)
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(fill, 3)

    local handle = Instance.new('Frame')
    handle.AnchorPoint = Vector2.new(0.5, 0.5)
    handle.Position = UDim2.new(0, 0, 0.5, 0)
    handle.Size = UDim2.new(0, 14, 0, 14)
    handle.BackgroundColor3 = Color3.fromRGB(245, 245, 248)
    handle.BorderSizePixel = 0
    handle.ZIndex = 2
    handle.Parent = track
    addCorner(handle, 7)

    local hitbox = Instance.new('TextButton')
    hitbox.Position = UDim2.new(0, 4, 0, 28)
    hitbox.Size = UDim2.new(1, -8, 0, 26)
    hitbox.BackgroundTransparency = 1
    hitbox.BorderSizePixel = 0
    hitbox.AutoButtonColor = false
    hitbox.Text = ''
    hitbox.TextSize = 13
    hitbox.FontFace = FONT
    hitbox.TextColor3 = Color3.fromRGB(0, 0, 0)
    hitbox.Parent = module

    local controller = { Value = minValue }
    local storage, storeKey = flagStorage(settings)

    local function toValue(alpha)
        alpha = math.clamp(alpha, 0, 1)
        local raw = minValue + (maxValue - minValue) * alpha
        raw = math.round(raw / step) * step
        if raw < minValue then raw = minValue end
        if raw > maxValue then raw = maxValue end
        return tonumber(string.format('%.' .. precision .. 'f', raw))
    end

    local function render()
        local alpha = math.clamp((controller.Value - minValue) / (maxValue - minValue), 0, 1)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        handle.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = string.format('%.' .. precision .. 'f', controller.Value)
    end

    local function setFromX(x)
        local alpha = (x - track.AbsolutePosition.X) / track.AbsoluteSize.X
        local value = toValue(alpha)
        if value ~= controller.Value then
            controller.Value = value
            if storage and storeKey then
                storage[storeKey] = value
            end
            render()
            if settings.Callback then
                settings.Callback(value)
            end
        end
    end

    local initial = tonumber(settings.Default)
    if not initial then initial = minValue end
    if storage and storeKey and type(storage[storeKey]) == 'number' then
        initial = math.clamp(storage[storeKey], minValue, maxValue)
    end
    controller.Value = initial
    if storage and storeKey then
        storage[storeKey] = initial
    end
    render()
    if settings.Callback then
        task.spawn(settings.Callback, initial)
    end

    local dragging = false
    hitbox.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    Config:save()
                end
            end)
        end
    end)

    Connections['slider_' .. nextUid()] = UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            setFromX(input.Position.X)
        end
    end)

    function controller:Set(value)
        value = tonumber(value)
        if not value then return end
        controller.Value = math.clamp(value, minValue, maxValue)
        if storage and storeKey then
            storage[storeKey] = controller.Value
        end
        render()
        Config:save()
        if settings.Callback then
            task.spawn(settings.Callback, controller.Value)
        end
    end

    return controller
end

local function buildDropdown(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local options = {}
    for _, option in ipairs(settings.Options or {}) do
        table.insert(options, tostring(option))
    end

    local module = newModule(parent, 46)

    addText(module, {
        Text = tostring(settings.Title or 'Dropdown'),
        Size = 13,
        Size2 = UDim2.new(1, -152, 0, 14),
        Position = UDim2.new(0, 12, 0, 16),
        Truncate = true,
    })

    local valueButton = Instance.new('TextButton')
    valueButton.AnchorPoint = Vector2.new(1, 0)
    valueButton.Position = UDim2.new(1, -12, 0, 11)
    valueButton.Size = UDim2.new(0, 132, 0, 24)
    valueButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    valueButton.BorderSizePixel = 0
    valueButton.AutoButtonColor = false
    valueButton.FontFace = FONT
    valueButton.TextColor3 = COLOR_TEXT
    valueButton.TextSize = 12
    valueButton.TextXAlignment = Enum.TextXAlignment.Left
    valueButton.TextTruncate = Enum.TextTruncate.AtEnd
    valueButton.Text = ''
    valueButton.Parent = module
    addCorner(valueButton, 6)

    local valuePadding = Instance.new('UIPadding')
    valuePadding.PaddingLeft = UDim.new(0, 8)
    valuePadding.PaddingRight = UDim.new(0, 18)
    valuePadding.Parent = valueButton

    local chevron = addText(valueButton, {
        Text = 'v',
        Size = 10,
        Color = COLOR_MUTED,
        Size2 = UDim2.new(0, 12, 1, 0),
        Position = UDim2.new(1, -14, 0, 0),
        XAlign = Enum.TextXAlignment.Right,
    })

    local list = Instance.new('ScrollingFrame')
    list.Position = UDim2.new(0, 10, 0, 41)
    list.Size = UDim2.new(1, -20, 0, 0)
    list.BackgroundColor3 = Color3.fromRGB(30, 30, 34)
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = module
    addCorner(list, 6)

    local listLayout = Instance.new('UIListLayout')
    listLayout.Padding = UDim.new(0, 2)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = list

    local controller = { Value = '', Open = false }
    local storage, storeKey = flagStorage(settings)

    local closedHeight = 46
    local openHeight = closedHeight + math.min(math.max(#options, 1), 5) * 26 + 9

    local function rebuildRows()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA('TextButton') then
                child:Destroy()
            end
        end
        for index, option in ipairs(options) do
            local row = Instance.new('TextButton')
            row.Size = UDim2.new(1, 0, 0, 24)
            row.BackgroundColor3 = (option == controller.Value) and Color3.fromRGB(72, 72, 80) or Color3.fromRGB(38, 38, 44)
            row.BackgroundTransparency = 0.15
            row.BorderSizePixel = 0
            row.AutoButtonColor = false
            row.FontFace = FONT
            row.Text = option
            row.TextColor3 = (option == controller.Value) and COLOR_TEXT or COLOR_MUTED
            row.TextSize = 12
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.LayoutOrder = index
            row.Parent = list
            addCorner(row, 5)

            local rowPadding = Instance.new('UIPadding')
            rowPadding.PaddingLeft = UDim.new(0, 10)
            rowPadding.Parent = row

            row.MouseButton1Click:Connect(function()
                controller:Set(option)
                if controller.Open then
                    controller.Open = false
                    chevron.Text = 'v'
                    TweenService:Create(module, TWEEN_FAST, {
                        Size = UDim2.new(0, 241, 0, closedHeight),
                    }):Play()
                end
            end)
        end
    end

    function controller:Set(value)
        if table.find(options, value) then
            controller.Value = value
            if storage and storeKey then
                storage[storeKey] = value
            end
            valueButton.Text = value
            rebuildRows()
            Config:save()
            if settings.Callback then
                task.spawn(settings.Callback, value)
            end
        end
    end

    local initial = tostring(settings.Default or '')
    if storage and storeKey and type(storage[storeKey]) == 'string' and table.find(options, storage[storeKey]) then
        initial = storage[storeKey]
    end
    if initial == '' and options[1] then
        initial = options[1]
    end
    controller.Value = initial
    if storage and storeKey and initial ~= '' then
        storage[storeKey] = initial
    end
    valueButton.Text = initial
    rebuildRows()
    if settings.Callback and initial ~= '' then
        task.spawn(settings.Callback, initial)
    end

    valueButton.MouseButton1Click:Connect(function()
        controller.Open = not controller.Open
        chevron.Text = controller.Open and '^' or 'v'
        TweenService:Create(module, TWEEN_FAST, {
            Size = UDim2.new(0, 241, 0, controller.Open and openHeight or closedHeight),
        }):Play()
    end)

    return controller
end

local function buildKeybind(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local module = newModule(parent, 46)

    addText(module, {
        Text = tostring(settings.Title or 'Keybind'),
        Size = 13,
        Size2 = UDim2.new(1, -160, 0, 14),
        Position = UDim2.new(0, 12, 0, 16),
        Truncate = true,
    })

    local chip = Instance.new('TextButton')
    chip.AnchorPoint = Vector2.new(1, 0)
    chip.Position = UDim2.new(1, -12, 0, 11)
    chip.Size = UDim2.new(0, 140, 0, 24)
    chip.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    chip.BorderSizePixel = 0
    chip.AutoButtonColor = false
    chip.FontFace = FONT
    chip.TextColor3 = COLOR_TEXT
    chip.TextSize = 12
    chip.TextTruncate = Enum.TextTruncate.AtEnd
    chip.Text = ''
    chip.Parent = module
    addCorner(chip, 6)

    local entry = Library:RegisterKeybind(tostring(settings.Title or 'Keybind'), settings.Default, settings.Callback)

    local function updateChip()
        if Library._choosing == entry then
            chip.Text = '[...]'
            chip.TextColor3 = COLOR_PING
        else
            chip.Text = formatKeybind(entry.Key)
            chip.TextColor3 = COLOR_TEXT
        end
    end

    entry.OnChanged = updateChip
    entry.OnChoosingEnd = updateChip
    updateChip()

    chip.MouseButton1Click:Connect(function()
        if Library._choosing == entry then
            Library._choosing = nil
            updateChip()
            return
        end
        if Library._choosing and Library._choosing.OnChoosingEnd then
            Library._choosing.OnChoosingEnd()
        end
        Library._choosing = entry
        updateChip()
    end)

    return entry
end

local function buildButton(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local module = newModule(parent, 42)

    addText(module, {
        Text = tostring(settings.Title or 'Button'),
        Size = 13,
        Size2 = UDim2.new(1, -16, 1, 0),
        XAlign = Enum.TextXAlignment.Center,
    })

    module.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local flash = TweenService:Create(module, TweenInfo.new(0.1), { BackgroundTransparency = 0.35 })
            flash:Play()
            flash.Completed:Once(function()
                TweenService:Create(module, TweenInfo.new(0.2), { BackgroundTransparency = 0 }):Play()
            end)
            if settings.Callback then
                task.spawn(settings.Callback)
            end
        end
    end)

    return module
end

local function buildTextBox(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local module = newModule(parent, 64)

    addText(module, {
        Text = tostring(settings.Title or 'Input'),
        Size = 13,
        Size2 = UDim2.new(1, -16, 0, 14),
        Position = UDim2.new(0, 12, 0, 9),
        Truncate = true,
    })

    local box = Instance.new('TextBox')
    box.Position = UDim2.new(0, 12, 0, 32)
    box.Size = UDim2.new(1, -24, 0, 24)
    box.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    box.BorderSizePixel = 0
    box.FontFace = FONT
    box.TextColor3 = COLOR_TEXT
    box.PlaceholderColor3 = COLOR_MUTED
    box.PlaceholderText = tostring(settings.Placeholder or '')
    box.TextSize = 12
    box.Text = ''
    box.TextXAlignment = Enum.TextXAlignment.Left
    box.ClearTextOnFocus = false
    box.Parent = module
    addCorner(box, 6)

    local boxPadding = Instance.new('UIPadding')
    boxPadding.PaddingLeft = UDim.new(0, 8)
    boxPadding.PaddingRight = UDim.new(0, 8)
    boxPadding.Parent = box

    local storage, storeKey = flagStorage(settings)

    if storage and storeKey and type(storage[storeKey]) == 'string' then
        box.Text = storage[storeKey]
    elseif type(settings.Default) == 'string' then
        box.Text = settings.Default
    end

    box.FocusLost:Connect(function()
        if storage and storeKey then
            storage[storeKey] = box.Text
        end
        Config:save()
        if settings.Callback then
            task.spawn(settings.Callback, box.Text)
        end
    end)

    return box
end

local function buildParagraph(parent, settings)
    if type(settings) ~= 'table' then settings = {} end
    local module = newModule(parent, 0)
    module.AutomaticSize = Enum.AutomaticSize.Y
    module.ClipsDescendants = false

    local holder = Instance.new('Frame')
    holder.Position = UDim2.new(0, 10, 0, 9)
    holder.Size = UDim2.new(1, -20, 0, 0)
    holder.AutomaticSize = Enum.AutomaticSize.Y
    holder.BackgroundTransparency = 1
    holder.BorderSizePixel = 0
    holder.Parent = module

    local layout = Instance.new('UIListLayout')
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = holder

    local titleText = tostring(settings.Title or '')
    local bodyText = tostring(settings.Text or '')

    local title = addText(holder, {
        Text = titleText,
        Size = 13,
        Size2 = UDim2.new(1, 0, 0, 14),
        LayoutOrder = 1,
    })
    if titleText == '' then title.Visible = false end

    local body = addText(holder, {
        Text = bodyText,
        Size = 12,
        Color = COLOR_MUTED,
        Size2 = UDim2.new(1, 0, 0, 0),
        LayoutOrder = 2,
        Wrapped = true,
    })
    body.AutomaticSize = Enum.AutomaticSize.Y
    body.TextYAlignment = Enum.TextYAlignment.Top
    if bodyText == '' then body.Visible = false end

    return module
end

local function buildCustomize(window)
    local tab = window:CreateTab('Customize')
    local overlays = tab:CreateSection('left')
    local windowSection = tab:CreateSection('right')

    overlays:Toggle({
        Title = 'Show Keybinds',
        Interface = 'show_keybinds',
        Default = false,
        Callback = function(value)
            setKeybindOverlay(value)
        end,
    })
    overlays:Toggle({
        Title = 'Show FPS',
        Interface = 'show_fps',
        Default = false,
        Callback = function(value)
            setOverlayFps(value)
        end,
    })
    overlays:Toggle({
        Title = 'Show Ping',
        Interface = 'show_ping',
        Default = false,
        Callback = function(value)
            setOverlayPing(value)
        end,
    })
    overlays:Dropdown({
        Title = 'Ping Display',
        Interface = 'ping_mode',
        Options = { 'number', 'graph' },
        Default = 'number',
        Callback = function(value)
            setPingMode(value)
        end,
    })

    overlays:Toggle({
        Title = 'Show Background',
        Interface = 'background_enabled',
        Default = false,
        Callback = function(value)
            local bg = window._background
            if bg then
                bg.Visible = value and bg.Image ~= ''
            end
        end,
    })
    overlays:Slider({
        Title = 'Background Transparency',
        Interface = 'background_transparency',
        Min = 0,
        Max = 1,
        Default = 0.5,
        Step = 0.05,
        Callback = function(value)
            if window._background then
                window._background.ImageTransparency = value
            end
        end,
    })
    overlays:TextBox({
        Title = 'Background Asset',
        Interface = 'background_asset',
        Placeholder = 'rbxassetid://...',
        Callback = function(text)
            window:SetBackground(text)
        end,
    })
    overlays:Toggle({
        Title = 'Background Texture',
        Interface = 'texture_enabled',
        Default = true,
        Callback = function(value)
            if window._texture then
                window._texture.Visible = value
            end
        end,
    })

    windowSection:Keybind({
        Title = 'UI Toggle',
        Default = 'RightShift',
        Callback = function()
            window:Toggle()
        end,
    })
    windowSection:Toggle({
        Title = 'Hide When Minimized',
        Interface = 'hide_on_minimize',
        Default = false,
        Callback = function(value)
            if not value and window._minimized and not window._gui.Enabled then
                window:Minimize(false)
            end
        end,
    })
    windowSection:Toggle({
        Title = 'Toggle Notifications',
        Interface = 'toggle_notifications',
        Default = true,
    })
    windowSection:Dropdown({
        Title = 'Notification Position',
        Interface = 'notif_position',
        Options = { 'left', 'right', 'center' },
        Default = 'left',
        Callback = function(value)
            setNotifPosition(value)
        end,
    })
    windowSection:Paragraph({
        Title = 'Customization',
        Text = 'Toggles notify on every state change, switch them off with Toggle Notifications if that gets loud. Set a Background Asset to enable the window background and fade it with the slider. Keybind list shows every bound function. Drag any panel, it stays on screen.',
    })
end

function Library.new(options)
    if Library._window then
        return Library._window
    end
    options = (type(options) == 'table') and options or {}

    local self = setmetatable({}, Library)
    self._minimized = false
    self._dragging = false
    self._tabCount = 0

    local gui = Instance.new('ScreenGui')
    gui.Name = 'Fallen'
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 100
    gui.Parent = GuiRoot
    self._gui = gui

    local container = Instance.new('Frame')
    container.Name = 'Container'
    container.AnchorPoint = Vector2.new(0.5, 0.5)
    container.Position = UDim2.new(0.5, 0, 0.5, 0)
    container.Size = UDim2.new(0, 0, 0, 0)
    container.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    container.BorderSizePixel = 0
    container.ClipsDescendants = true
    container.Active = true
    container.Parent = gui
    self._container = container

    local containerGradient = Instance.new('UIGradient')
    containerGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(145, 145, 145)),
        ColorSequenceKeypoint.new(0.11, Color3.fromRGB(0, 0, 0)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0)),
    })
    containerGradient.Rotation = 90
    containerGradient.Parent = container

    addCorner(container, 10)
    addStroke(container, 0.58, Color3.fromRGB(68, 68, 68))

    local background = Instance.new('ImageLabel')
    background.Name = 'Background'
    background.Size = UDim2.new(1, 0, 1, 0)
    background.BackgroundTransparency = 1
    background.BorderSizePixel = 0
    background.Image = ''
    background.ImageTransparency = 0.5
    background.ScaleType = Enum.ScaleType.Crop
    background.ZIndex = 0
    background.Visible = false
    background.Parent = container
    addCorner(background, 10)

    local texture = Instance.new('ImageLabel')
    texture.Name = 'Texture'
    texture.Size = UDim2.new(1, 0, 1, 0)
    texture.BackgroundTransparency = 1
    texture.BorderSizePixel = 0
    texture.Image = 'rbxassetid://9968344227'
    texture.ImageColor3 = Color3.fromRGB(0, 0, 0)
    texture.ImageTransparency = 0.88
    texture.ScaleType = Enum.ScaleType.Tile
    texture.TileSize = UDim2.new(0, 128, 0, 128)
    texture.ZIndex = 0
    texture.Parent = container

    background.Image = tostring(Library._interface.background_asset or '')
    background.ImageTransparency = math.clamp(tonumber(Library._interface.background_transparency) or 0.5, 0, 1)
    background.Visible = Library._interface.background_enabled == true and background.Image ~= ''
    texture.Visible = Library._interface.texture_enabled ~= false
    self._background = background
    self._texture = texture

    local shadowHolder = Instance.new('Frame')
    shadowHolder.Name = 'ShadowHolder'
    shadowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowHolder.Position = container.Position
    shadowHolder.Size = container.Size
    shadowHolder.BackgroundTransparency = 1
    shadowHolder.BorderSizePixel = 0
    shadowHolder.Visible = false
    shadowHolder.ZIndex = 0
    shadowHolder.Parent = gui

    local shadowImage = Instance.new('ImageLabel')
    shadowImage.AnchorPoint = Vector2.new(0.5, 0.5)
    shadowImage.Position = UDim2.new(0.5, 0, 0.5, 2)
    shadowImage.Size = UDim2.new(1, 58, 1, 58)
    shadowImage.BackgroundTransparency = 1
    shadowImage.BorderSizePixel = 0
    shadowImage.Image = 'rbxassetid://6014261993'
    shadowImage.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadowImage.ImageTransparency = 0.43
    shadowImage.ScaleType = Enum.ScaleType.Slice
    shadowImage.SliceCenter = Rect.new(49, 49, 450, 450)
    shadowImage.Parent = shadowHolder

    Connections['shadow_position'] = container:GetPropertyChangedSignal('Position'):Connect(function()
        shadowHolder.Position = container.Position
    end)
    Connections['shadow_size'] = container:GetPropertyChangedSignal('Size'):Connect(function()
        shadowHolder.Size = container.Size
    end)

    local handler = Instance.new('Frame')
    handler.Name = 'Handler'
    handler.BackgroundTransparency = 1
    handler.BorderSizePixel = 0
    handler.Size = UDim2.new(0, 752, 0, 479)
    handler.Parent = container

    local header = Instance.new('Frame')
    header.Name = 'Header'
    header.BackgroundTransparency = 1
    header.BorderSizePixel = 0
    header.Size = UDim2.new(1, 0, 0, 52)
    header.Active = true
    header.Parent = handler

    local nameX = 18
    if type(options.Logo) == 'string' and options.Logo ~= '' then
        local logo = Instance.new('ImageLabel')
        logo.Name = 'Logo'
        logo.AnchorPoint = Vector2.new(0, 0.5)
        logo.Position = UDim2.new(0, 18, 0, 26)
        logo.Size = UDim2.new(0, 24, 0, 24)
        logo.BackgroundTransparency = 1
        logo.BorderSizePixel = 0
        logo.Image = options.Logo
        logo.ScaleType = Enum.ScaleType.Fit
        logo.Parent = handler
        nameX = 48
    end

    local nameLabel = addText(handler, {
        Text = tostring(options.Name or 'Fallen'),
        Font = FONT_HEAVY,
        Size = 16,
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, nameX, 0, 26),
        Size2 = UDim2.new(0, 220, 0, 19),
        Truncate = true,
    })

    local BAR_WIDTH = 140

    local minimizeButton = Instance.new('TextButton')
    minimizeButton.Name = 'Minimize'
    minimizeButton.AnchorPoint = Vector2.new(1, 0.5)
    minimizeButton.Position = UDim2.new(1, -14, 0, 26)
    minimizeButton.Size = UDim2.new(0, 26, 0, 26)
    minimizeButton.BackgroundTransparency = 1
    minimizeButton.BorderSizePixel = 0
    minimizeButton.AutoButtonColor = false
    minimizeButton.FontFace = FONT_HEAVY
    minimizeButton.Text = '-'
    minimizeButton.TextSize = 20
    minimizeButton.TextColor3 = Color3.fromRGB(188, 188, 188)
    minimizeButton.Parent = handler

    local restoreButton = Instance.new('TextButton')
    restoreButton.Name = 'Restore'
    restoreButton.AnchorPoint = Vector2.new(0, 0.5)
    restoreButton.Position = UDim2.new(0, 106, 0, 26)
    restoreButton.Size = UDim2.new(0, 26, 0, 26)
    restoreButton.BackgroundTransparency = 1
    restoreButton.BorderSizePixel = 0
    restoreButton.AutoButtonColor = false
    restoreButton.FontFace = FONT_HEAVY
    restoreButton.Text = '+'
    restoreButton.TextSize = 20
    restoreButton.TextColor3 = Color3.fromRGB(188, 188, 188)
    restoreButton.Visible = false
    restoreButton.Parent = handler

    local tabsFrame = Instance.new('ScrollingFrame')
    tabsFrame.Name = 'Tabs'
    tabsFrame.Position = UDim2.new(0, 18, 0, 67)
    tabsFrame.Size = UDim2.new(0, 129, 0, 401)
    tabsFrame.BackgroundTransparency = 1
    tabsFrame.BorderSizePixel = 0
    tabsFrame.ScrollBarThickness = 0
    tabsFrame.ScrollBarImageTransparency = 1
    tabsFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    tabsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabsFrame.Selectable = false
    tabsFrame.Parent = handler

    local tabsLayout = Instance.new('UIListLayout')
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabsLayout.Parent = tabsFrame

    local pin = Instance.new('Frame')
    pin.Name = 'Pin'
    pin.Position = UDim2.new(0, 18, 0, 79)
    pin.Size = UDim2.new(0, 2, 0, 16)
    pin.BackgroundColor3 = Color3.fromRGB(224, 224, 224)
    pin.BorderSizePixel = 0
    pin.Parent = handler
    addCorner(pin, UDim.new(1, 0))

    local divider = Instance.new('Frame')
    divider.Name = 'Divider'
    divider.Position = UDim2.new(0, 164, 0, 75)
    divider.Size = UDim2.new(0, 1, 0, 330)
    divider.BackgroundColor3 = Color3.fromRGB(68, 68, 68)
    divider.BackgroundTransparency = 0.65
    divider.BorderSizePixel = 0
    divider.Parent = handler

    local sectionsFolder = Instance.new('Folder')
    sectionsFolder.Name = 'Sections'
    sectionsFolder.Parent = handler

    local function selectTab(button, leftSection, rightSection)
        for _, object in ipairs(tabsFrame:GetChildren()) do
            if object.Name == 'Tab' then
                local isActive = (object == button)
                local label = object:FindFirstChildOfClass('TextLabel')
                local icon = object:FindFirstChild('Icon')
                local labelGradient = label and label:FindFirstChildOfClass('UIGradient')

                if isActive then
                    if object.BackgroundTransparency ~= 0.5 then
                        TweenService:Create(pin, TWEEN_SMOOTH, {
                            Position = UDim2.new(0, 18, 0, 79 + object.LayoutOrder * 42),
                        }):Play()
                        TweenService:Create(object, TWEEN_SMOOTH, { BackgroundTransparency = 0.5 }):Play()
                        if label then
                            TweenService:Create(label, TWEEN_SMOOTH, { TextColor3 = COLOR_TEXT }):Play()
                        end
                        if labelGradient then
                            TweenService:Create(labelGradient, TWEEN_SMOOTH, { Offset = Vector2.new(1, 0) }):Play()
                        end
                        if icon then
                            TweenService:Create(icon, TWEEN_SMOOTH, { ImageColor3 = COLOR_TEXT }):Play()
                        end
                    end
                else
                    if object.BackgroundTransparency ~= 1 then
                        TweenService:Create(object, TWEEN_SMOOTH, { BackgroundTransparency = 1 }):Play()
                        if label then
                            TweenService:Create(label, TWEEN_SMOOTH, { TextColor3 = Color3.fromRGB(138, 138, 138) }):Play()
                        end
                        if labelGradient then
                            TweenService:Create(labelGradient, TWEEN_SMOOTH, { Offset = Vector2.new(0, 0) }):Play()
                        end
                        if icon then
                            TweenService:Create(icon, TWEEN_SMOOTH, { ImageColor3 = Color3.fromRGB(138, 138, 138) }):Play()
                        end
                    end
                end
            end
        end

        for _, object in ipairs(sectionsFolder:GetChildren()) do
            if object:IsA('ScrollingFrame') then
                object.Visible = (object == leftSection or object == rightSection)
            end
        end
    end

    function self:CreateTab(title, icon)
        local tabTitle = tostring(title or 'Tab')
        local order = self._tabCount
        self._tabCount += 1

        local button = Instance.new('TextButton')
        button.Name = 'Tab'
        button.Size = UDim2.new(0, 129, 0, 38)
        button.BackgroundTransparency = 1
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        button.BorderSizePixel = 0
        button.AutoButtonColor = false
        button.Text = ''
        button.TextSize = 13
        button.FontFace = FONT
        button.TextColor3 = Color3.fromRGB(0, 0, 0)
        button.LayoutOrder = order
        button.Parent = tabsFrame
        addCorner(button, 5)

        local textX = 14
        if type(icon) == 'string' and icon ~= '' then
            local iconLabel = Instance.new('ImageLabel')
            iconLabel.Name = 'Icon'
            iconLabel.AnchorPoint = Vector2.new(0, 0.5)
            iconLabel.Position = UDim2.new(0, 15, 0.5, 0)
            iconLabel.Size = UDim2.new(0, 16, 0, 16)
            iconLabel.BackgroundTransparency = 1
            iconLabel.BorderSizePixel = 0
            iconLabel.Image = icon
            iconLabel.ImageColor3 = Color3.fromRGB(138, 138, 138)
            iconLabel.ScaleType = Enum.ScaleType.Fit
            iconLabel.Parent = button
            textX = 37
        end

        local label = addText(button, {
            Text = tabTitle,
            Size = 13,
            Color = Color3.fromRGB(138, 138, 138),
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, textX, 0.5, 0),
            Size2 = UDim2.new(0, 129 - textX - 6, 0, 16),
            Truncate = true,
        })

        local labelGradient = Instance.new('UIGradient')
        labelGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.70, Color3.fromRGB(155, 155, 155)),
            ColorSequenceKeypoint.new(1.00, Color3.fromRGB(58, 58, 58)),
        })
        labelGradient.Parent = label

        local leftSection = Instance.new('ScrollingFrame')
        leftSection.Name = 'LeftSection'
        leftSection.Position = UDim2.new(0, 203, 0, 67)
        leftSection.Size = UDim2.new(0, 243, 0, 395)
        leftSection.BackgroundTransparency = 1
        leftSection.BorderSizePixel = 0
        leftSection.ScrollBarThickness = 0
        leftSection.ScrollBarImageTransparency = 1
        leftSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
        leftSection.CanvasSize = UDim2.new(0, 0, 0, 0)
        leftSection.Selectable = false
        leftSection.Visible = false
        leftSection.Parent = sectionsFolder

        local leftLayout = Instance.new('UIListLayout')
        leftLayout.Padding = UDim.new(0, 11)
        leftLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        leftLayout.SortOrder = Enum.SortOrder.LayoutOrder
        leftLayout.Parent = leftSection

        local rightSection = Instance.new('ScrollingFrame')
        rightSection.Name = 'RightSection'
        rightSection.Position = UDim2.new(0, 474, 0, 67)
        rightSection.Size = UDim2.new(0, 243, 0, 395)
        rightSection.BackgroundTransparency = 1
        rightSection.BorderSizePixel = 0
        rightSection.ScrollBarThickness = 0
        rightSection.ScrollBarImageTransparency = 1
        rightSection.AutomaticCanvasSize = Enum.AutomaticSize.Y
        rightSection.CanvasSize = UDim2.new(0, 0, 0, 0)
        rightSection.Selectable = false
        rightSection.Visible = false
        rightSection.Parent = sectionsFolder

        local rightLayout = Instance.new('UIListLayout')
        rightLayout.Padding = UDim.new(0, 11)
        rightLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        rightLayout.SortOrder = Enum.SortOrder.LayoutOrder
        rightLayout.Parent = rightSection

        local tab = {}

        button.MouseButton1Click:Connect(function()
            selectTab(button, leftSection, rightSection)
        end)

        if order == 0 then
            task.defer(function()
                selectTab(button, leftSection, rightSection)
            end)
        end

        function tab:CreateSection(side)
            local parent = (side == 'right') and rightSection or leftSection
            local section = {}
            function section:Toggle(sectionSettings) return buildToggle(parent, sectionSettings) end
            function section:Slider(sectionSettings) return buildSlider(parent, sectionSettings) end
            function section:Dropdown(sectionSettings) return buildDropdown(parent, sectionSettings) end
            function section:Keybind(sectionSettings) return buildKeybind(parent, sectionSettings) end
            function section:Button(sectionSettings) return buildButton(parent, sectionSettings) end
            function section:TextBox(sectionSettings) return buildTextBox(parent, sectionSettings) end
            function section:Paragraph(sectionSettings) return buildParagraph(parent, sectionSettings) end
            return section
        end

        return tab
    end

    function self:SetBackground(assetId)
        local id = tostring(assetId or '')
        Library._interface.background_asset = id
        Library._interface.background_enabled = id ~= ''
        background.Image = id
        background.Visible = id ~= ''
        Config:save()
    end

    local function applyMinimizeLayout(minimized)
        if minimized then
            nameLabel.Size = UDim2.new(0, BAR_WIDTH - nameX - 36, 0, 19)
        else
            nameLabel.Size = UDim2.new(0, 220, 0, 19)
        end
    end

    function self:Minimize(state)
        state = state == true
        if self._minimized == state then return end
        self._minimized = state

        if state then
            minimizeButton.Visible = false
            restoreButton.Visible = true
            applyMinimizeLayout(true)
            if Library._interface.hide_on_minimize then
                gui.Enabled = false
                shadowHolder.Visible = false
            else
                shadowHolder.Visible = false
                TweenService:Create(container, TWEEN_SMOOTH, {
                    Size = UDim2.new(0, BAR_WIDTH, 0, 52),
                }):Play()
            end
        else
            minimizeButton.Visible = true
            restoreButton.Visible = false
            applyMinimizeLayout(false)
            if not gui.Enabled then
                gui.Enabled = true
            end
            shadowHolder.Visible = true
            TweenService:Create(container, TWEEN_SMOOTH, {
                Size = UDim2.new(0, 752, 0, 479),
            }):Play()
        end
    end

    function self:Toggle()
        if self._minimized then
            self:Minimize(false)
        else
            self:Minimize(true)
        end
    end

    minimizeButton.MouseButton1Click:Connect(function()
        self:Minimize(true)
    end)
    restoreButton.MouseButton1Click:Connect(function()
        self:Minimize(false)
    end)

    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self._dragging = true
            self._dragStart = input.Position
            self._dragOrigin = container.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    self._dragging = false
                end
            end)
        end
    end)

    Connections['window_drag'] = UserInputService.InputChanged:Connect(function(input)
        if not self._dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - self._dragStart
            local target = UDim2.new(
                self._dragOrigin.X.Scale, self._dragOrigin.X.Offset + delta.X,
                self._dragOrigin.Y.Scale, self._dragOrigin.Y.Offset + delta.Y
            )
            container.Position = clampFrame(container, target)
        end
    end)

    if UserInputService.TouchEnabled then
        local uiScale = Instance.new('UIScale')
        uiScale.Parent = container

        local shadowScale = Instance.new('UIScale')
        shadowScale.Parent = shadowHolder

        local function updateScale()
            local camera = workspace.CurrentCamera
            if not camera then return end
            local scale = math.clamp(camera.ViewportSize.X / 1400, 0.55, 1)
            uiScale.Scale = scale
            shadowScale.Scale = scale
        end
        updateScale()

        local camera = workspace.CurrentCamera
        if camera then
            Connections['window_scale'] = camera:GetPropertyChangedSignal('ViewportSize'):Connect(updateScale)
        end
    end

    local function fullCleanup()
        if Notif.gui then
            Notif.gui:Destroy()
            Notif.gui = nil
            Notif.container = nil
            Notif.layout = nil
        end
        if Overlay.gui then
            Overlay.gui:Destroy()
            Overlay.gui = nil
            Overlay.fpsPanel = nil
            Overlay.fpsValue = nil
            Overlay.pingPanel = nil
            Overlay.pingNumber = nil
            Overlay.pingNumberLabel = nil
            Overlay.pingGraph = nil
            Overlay.pingGraphValue = nil
            Overlay.bars = {}
            table.clear(Overlay.samples)
        end
        if KeybindOverlay.gui then
            KeybindOverlay.gui:Destroy()
            KeybindOverlay.gui = nil
            KeybindOverlay.panel = nil
            KeybindOverlay.list = nil
        end
        if gui then
            gui:Destroy()
        end
    end

    Connections['ui_cleanup'] = gui.Destroying:Connect(function()
        Connections:disconnect_all()
        Library._window = nil
        pcall(function()
            if getgenv and getgenv()._Fallen_Cleanup then
                getgenv()._Fallen_Cleanup = nil
            end
        end)
    end)

    pcall(function()
        if getgenv then
            getgenv()._Fallen_Cleanup = fullCleanup
        end
    end)

    function self:Destroy()
        fullCleanup()
    end

    Library._window = self

    task.defer(function()
        if self._gui and self._gui.Parent then
            buildCustomize(self)
        end
    end)

    shadowHolder.Visible = true
    TweenService:Create(container, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 752, 0, 479),
    }):Play()

    return self
end

return Library

--[[
    usage:

    local Library = loadstring(game:HttpGet('your_url'))()
    local Window = Library.new({ Name = 'Fallen' })

    local Main = Window:CreateTab('Main')
    local Left = Main:CreateSection('left')

    Left:Toggle({ Title = 'Fly', Flag = 'fly_enabled', Default = false, Callback = function(v) print(v) end })
    Left:Slider({ Title = 'Speed', Flag = 'speed', Min = 0, Max = 100, Default = 50, Step = 1, Callback = function(v) print(v) end })

    -- background from code (also settable in the Customize tab):
    Window:SetBackground('rbxassetid://123456789')

    Library:Notify({ Title = 'Loaded', Text = 'Fallen is ready', Duration = 4 })

    Customize tab (added automatically, sits after your tabs):
      Show Keybinds, Show FPS, Show Ping, Ping Display,
      Show Background, Background Transparency, Background Asset, Background Texture,
      UI Toggle keybind, Hide When Minimized, Toggle Notifications, Notification Position.
]]

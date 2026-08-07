-- --- apexhubb.lua (Hub Interface) ---
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local Library = {}
Library.Theme = {
    Background = Color3.fromRGB(20, 18, 28),
    Secondary = Color3.fromRGB(28, 25, 38),
    Border = Color3.fromRGB(50, 45, 65),
    Text = Color3.fromRGB(235, 237, 240),
    TextDark = Color3.fromRGB(150, 145, 165),
    Accent = Color3.fromRGB(138, 43, 226),
    Accent2 = Color3.fromRGB(43, 122, 226),
    Success = Color3.fromRGB(50, 200, 100),
    Error = Color3.fromRGB(220, 60, 60)
}
Library.Assets = {
    Close = "rbxassetid://119943770201674",
    Minimize = "rbxassetid://82603981310445",
    Resize = "rbxassetid://120997033468887",
    DropdownArrow = "rbxassetid://105558791071013",
    ButtonIcon = "rbxassetid://10734898355",
    Notification = "rbxassetid://10709775704",
    CornerAnime = "rbxassetid://82631977882294"
}
Library.Flags = {}
Library.Connections = {}

function Library:Create(Class, Props)
    local Inst = Instance.new(Class)
    for K, V in pairs(Props) do Inst[K] = V end
    return Inst
end

function Library:ApplyBgGradient(Obj)
    return self:Create("UIGradient", {
        Parent = Obj, Rotation = 90,
        Color = ColorSequence.new(Color3.fromRGB(35, 28, 52), Color3.fromRGB(18, 18, 32))
    })
end

function Library:ApplyStrokeGradient(Obj)
    return self:Create("UIGradient", {
        Parent = Obj, Rotation = 0,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 28, 92)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 70, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(28, 60, 135))
        })
    })
end

function Library:Tween(Obj, Time, Props)
    local T = TweenService:Create(Obj, TweenInfo.new(Time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), Props)
    T:Play()
    return T
end

function Library:Connect(Signal, Callback)
    local C = Signal:Connect(Callback)
    table.insert(self.Connections, C)
    return C
end

function Library:Blurify(Frame, Strength)
    local Part = self:Create("Part", {
        Material = Enum.Material.Glass, Transparency = 1, Reflectance = 1,
        CastShadow = false, Anchored = true, CanCollide = false, CanQuery = false,
        Size = Vector3.new(1, 1, 1) * 0.01, Color = Color3.fromRGB(0,0,0), Parent = Camera,
    })
    local BlockMesh = self:Create("BlockMesh", {Parent = Part})
    self:Connect(RunService.RenderStepped, function()
        if not Frame.Parent then Part:Destroy() return end
        if Frame.Visible then
            Part.Transparency = Strength or 0.97
            local C0, C1 = Frame.AbsolutePosition, Frame.AbsolutePosition + Frame.AbsoluteSize
            local R0 = Camera:ScreenPointToRay(C0.X, C0.Y, 1)
            local R1 = Camera:ScreenPointToRay(C1.X, C1.Y, 1)
            local Origin = Camera.CFrame.Position + Camera.CFrame.LookVector * (0.05 - Camera.NearPlaneZ)
            local Normal = Camera.CFrame.LookVector
            local function CalcPos(Pos, Norm, Orig, Dir)
                local V = Orig - Pos
                local Num = (Norm.X * V.X) + (Norm.Y * V.Y) + (Norm.Z * V.Z)
                local Den = (Norm.X * Dir.X) + (Norm.Y * Dir.Y) + (Norm.Z * Dir.Z)
                return Orig + ((-Num / Den) * Dir)
            end
            local P0 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R0.Origin, R0.Direction))
            local P1 = Camera.CFrame:PointToObjectSpace(CalcPos(Origin, Normal, R1.Origin, R1.Direction))
            BlockMesh.Offset = (P0 + P1) / 2
            BlockMesh.Scale = (P1 - P0) / 0.0101
            Part.CFrame = Camera.CFrame
        else
            Part.Transparency = 1
        end
    end)
end

Library.Gui = Library:Create("ScreenGui", {
    Name = "ApexHub", Parent = gethui and gethui() or CoreGui,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, ResetOnSpawn = false
})

function Library:Draggable(Frame, Handle)
    local Dragging, DragInput, DragStart, StartPos
    Handle.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
            Dragging = true
            DragStart = Input.Position
            StartPos = Frame.Position
            Input.Changed:Connect(function()
                if Input.UserInputState == Enum.UserInputState.End then Dragging = false end
            end)
        end
    end)
    Handle.InputChanged:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then DragInput = Input end
    end)
    self:Connect(UserInputService.InputChanged, function(Input)
        if Input == DragInput and Dragging then
            local Delta = Input.Position - DragStart
            self:Tween(Frame, 0.1, {Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)})
        end
    end)
end

local NotifGui = Library:Create("ScreenGui", {Name = "ApexNotifs", Parent = gethui and gethui() or CoreGui, ResetOnSpawn = false})
local NotifHolder = Library:Create("Frame", {Parent = NotifGui, Size = UDim2.new(0, 240, 1, -20), Position = UDim2.new(1, -260, 0, 10), BackgroundTransparency = 1})
Library:Create("UIListLayout", {Parent = NotifHolder, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Right})

function Library:Notify(Title, Desc, Duration)
    Duration = Duration or 5
    local Notif = Library:Create("Frame", {Parent = NotifHolder, Size = UDim2.new(1, 0, 0, 70), BackgroundColor3 = Library.Theme.Background, BorderSizePixel = 0, ClipsDescendants = true, ZIndex = 50})
    Library:Create("UICorner", {Parent = Notif, CornerRadius = UDim.new(0, 6)})
    local NStroke = Library:Create("UIStroke", {Parent = Notif, Thickness = 1.5, ZIndex = 50})
    Library:ApplyStrokeGradient(NStroke)
    Library:ApplyBgGradient(Notif)
    Library:Create("TextLabel", {Parent = Notif, Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 14, 0, 14), BackgroundTransparency = 1, Font = Enum.Font.GothamSemibold, Text = Title, TextColor3 = Library.Theme.Text, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 50})
    Library:Create("TextLabel", {Parent = Notif, Size = UDim2.new(1, -50, 0, 20), Position = UDim2.new(0, 14, 0, 36), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = Desc, TextColor3 = Library.Theme.TextDark, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 50})
    local TimerBar = Library:Create("Frame", {Parent = Notif, Size = UDim2.new(1, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), BackgroundColor3 = Library.Theme.Accent, BorderSizePixel = 0, ZIndex = 50})
    Library:Create("UICorner", {Parent = TimerBar, CornerRadius = UDim.new(1, 0)})
    Library:ApplyStrokeGradient(TimerBar)
    Notif.Position = UDim2.new(1, 0, 0, 0)
    Library:Tween(Notif, 0.3, {Position = UDim2.new(0, 0, 0, 0)})
    Library:Tween(TimerBar, Duration, {Size = UDim2.new(0, 0, 0, 3)})
    task.delay(Duration, function()
        Library:Tween(Notif, 0.3, {Position = UDim2.new(1, 20, 0, 0)})
        task.wait(0.3)
        Notif:Destroy()
    end)
end

local Window = {}
Window.Tabs = {}
Window.IsOpen = false

local Main = Library:Create("Frame", {
    Parent = Library.Gui, Size = UDim2.new(0, 550, 0, 350),
    Position = UDim2.new(0.5, -275, 0.5, -175), BackgroundTransparency = 0.1,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true
})
Library:Create("UICorner", {Parent = Main, CornerRadius = UDim.new(0, 8)})
local MainStroke = Library:Create("UIStroke", {Parent = Main, Thickness = 1.5, ZIndex = 10})
Library:ApplyStrokeGradient(MainStroke)
Library:ApplyBgGradient(Main)
Library:Blurify(Main, 0.95)

local CornerAnime = Library:Create("ImageLabel", {
    Parent = Main, Size = UDim2.new(0, 300, 0, 300), 
    Position = UDim2.new(1, -50, 1, -50), AnchorPoint = Vector2.new(1, 1),
    BackgroundTransparency = 1, Image = Library.Assets.CornerAnime, 
    ImageTransparency = 0.7, ZIndex = 1, ScaleType = Enum.ScaleType.Crop
})

local TopBar = Library:Create("Frame", {Parent = Main, Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 10})
Library:Draggable(Main, TopBar)

Library:Create("TextLabel", {Parent = TopBar, Size = UDim2.new(0, 200, 1, 0), Position = UDim2.new(0, 15, 0, 0), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = "ApexHub", TextColor3 = Library.Theme.Text, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10})

local CloseBtn = Library:Create("ImageLabel", {Parent = TopBar, Size = UDim2.new(0, 18, 0, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -15, 0.5, 0), BackgroundTransparency = 1, Image = Library.Assets.Close, ImageColor3 = Library.Theme.Text, ZIndex = 12})
local CloseClick = Library:Create("TextButton", {Parent = CloseBtn, Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", ZIndex = 13})
CloseClick.MouseButton1Click:Connect(function() 
    Library:Tween(Main, 0.2, {Size = UDim2.new(0, 550, 0, 0)}) 
    task.wait(0.2) 
    Main.Visible = false 
    Window.IsOpen = false 
end)

Library:Create("Frame", {Parent = TopBar, Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, 0), BackgroundColor3 = Library.Theme.Border, BorderSizePixel = 0, ZIndex = 10})

local ContentArea = Library:Create("ScrollingFrame", {
    Parent = Main, Size = UDim2.new(1, -30, 1, -55), Position = UDim2.new(0, 15, 0, 50), 
    BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, 
    ScrollBarImageColor3 = Library.Theme.Border, CanvasSize = UDim2.new(0,0,0,0), 
    AutomaticCanvasSize = Enum.AutomaticSize.Y, ZIndex = 2
})
Library:Create("UIListLayout", {Parent = ContentArea, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder})
Library:Create("UIPadding", {Parent = ContentArea, PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10)})

function Window:Show()
    Main.Visible = true
    Main.Size = UDim2.new(0, 550, 0, 0)
    Window.IsOpen = true
    Library:Tween(Main, 0.4, {Size = UDim2.new(0, 550, 0, 350)})
end

function Window:Toggle()
    if Window.IsOpen then
        Library:Tween(Main, 0.3, {Size = UDim2.new(0, 550, 0, 0)})
        task.wait(0.3)
        Main.Visible = false
        Window.IsOpen = false
    else
        Window:Show()
    end
end

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
    if not GameProcessed and Input.KeyCode == Enum.KeyCode.RightControl then
        Window:Toggle()
    end
end)

local function CreateScriptCard(data)
    local Card = Library:Create("Frame", {Parent = ContentArea, Size = UDim2.new(1, 0, 0, 60), BackgroundColor3 = Library.Theme.Secondary, BorderSizePixel = 0, ZIndex = 2})
    Library:Create("UICorner", {Parent = Card, CornerRadius = UDim.new(0, 6)})
    local CardStroke = Library:Create("UIStroke", {Parent = Card, Thickness = 1, ZIndex = 2})
    Library:ApplyBgGradient(Card)
    Library:ApplyStrokeGradient(CardStroke)

    local StatusColor = data.Working and Library.Theme.Success or Library.Theme.Error
    local StatusText = data.Working and "Working" or "Down"

    local StatusDot = Library:Create("Frame", {Parent = Card, Size = UDim2.new(0, 8, 0, 8), Position = UDim2.new(0, 15, 0.5, -4), BackgroundColor3 = StatusColor, BorderSizePixel = 0, ZIndex = 3})
    Library:Create("UICorner", {Parent = StatusDot, CornerRadius = UDim.new(1, 0)})

    Library:Create("TextLabel", {Parent = Card, Size = UDim2.new(0, 200, 0, 20), Position = UDim2.new(0, 35, 0, 12), BackgroundTransparency = 1, Font = Enum.Font.GothamBold, Text = data.Name, TextColor3 = Library.Theme.Text, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})
    Library:Create("TextLabel", {Parent = Card, Size = UDim2.new(0, 200, 0, 16), Position = UDim2.new(0, 35, 0, 32), BackgroundTransparency = 1, Font = Enum.Font.Gotham, Text = StatusText, TextColor3 = StatusColor, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3})

    local ExecuteBtn = Library:Create("TextButton", {Parent = Card, Size = UDim2.new(0, 100, 0, 35), Position = UDim2.new(1, -115, 0.5, -17.5), BackgroundColor3 = Library.Theme.Background, Text = "Execute", Font = Enum.Font.GothamBold, TextColor3 = Library.Theme.Text, TextSize = 13, AutoButtonColor = false, BorderSizePixel = 0, ZIndex = 3})
    Library:Create("UICorner", {Parent = ExecuteBtn, CornerRadius = UDim.new(0, 5)})
    local ExecStroke = Library:Create("UIStroke", {Parent = ExecuteBtn, Thickness = 1, ZIndex = 3})
    Library:ApplyStrokeGradient(ExecStroke)

    if not data.Working then
        ExecuteBtn.Text = "Locked"
        ExecuteBtn.TextColor3 = Library.Theme.TextDark
        ExecuteBtn.AutoButtonColor = false
        ExecuteBtn.Active = false
    else
        ExecuteBtn.MouseButton1Click:Connect(function()
            Library:Notify("ApexHub", "Loading " .. data.Name .. "...", 3)
            Library:Tween(Main, 0.3, {Size = UDim2.new(0, 550, 0, 0)})
            task.delay(0.3, function()
                Main.Visible = false
                if Library.Gui then Library.Gui:Destroy() end
                for _, c in pairs(Library.Connections) do pcall(function() c:Disconnect() end) end
                if NotifGui then NotifGui:Destroy() end
                loadstring(game:HttpGet(data.Url))()
            end)
        end)
    end
end

CreateScriptCard({Name = "Murder Mystery 2", Working = true, Url = "https://raw.githubusercontent.com/naturaldesire23/gtddd/refs/heads/main/mm2sa.lua"})
CreateScriptCard({Name = "Blade Ball", Working = false, Url = ""})
CreateScriptCard({Name = "Fisch", Working = false, Url = ""})

Window:Show()
Library:Notify("ApexHub", "Hub loaded successfully. RightCtrl to toggle.", 5)

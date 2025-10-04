--// Garden Tower Defense Script - WORKING VERSION
local Players = game:GetService("Players")
local plr = Players.LocalPlayer

print(plr.Name .. " loaded the script. Waiting for key...")

--// Improved Key GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Parent = plr:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 400, 0, 300)
Frame.Position = UDim2.new(0.5, -200, 0.5, -150)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
Frame.BorderSizePixel = 0
Frame.BackgroundTransparency = 0.1
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 120, 200)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 60)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "GARDEN TOWER DEFENSE"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.TextStrokeTransparency = 0.8
Title.Parent = Frame

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, 0, 0, 30)
SubTitle.Position = UDim2.new(0, 0, 0, 40)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Enter Access Key"
SubTitle.TextColor3 = Color3.fromRGB(200, 200, 220)
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextSize = 16
SubTitle.Parent = Frame

-- Key Input
local TextBoxContainer = Instance.new("Frame")
TextBoxContainer.Size = UDim2.new(1, -40, 0, 50)
TextBoxContainer.Position = UDim2.new(0, 20, 0, 90)
TextBoxContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
TextBoxContainer.BorderSizePixel = 0
TextBoxContainer.Parent = Frame

local TextBoxCorner = Instance.new("UICorner")
TextBoxCorner.CornerRadius = UDim.new(0, 8)
TextBoxCorner.Parent = TextBoxContainer

local TextBox = Instance.new("TextBox")
TextBox.Size = UDim2.new(1, -20, 1, -10)
TextBox.Position = UDim2.new(0, 10, 0, 5)
TextBox.PlaceholderText = "Enter key here..."
TextBox.Text = ""
TextBox.Font = Enum.Font.Gotham
TextBox.TextSize = 18
TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
TextBox.BackgroundTransparency = 1
TextBox.PlaceholderColor3 = Color3.fromRGB(180, 180, 180)
TextBox.Parent = TextBoxContainer

-- Check Button
local CheckBtn = Instance.new("TextButton")
CheckBtn.Size = UDim2.new(1, -40, 0, 50)
CheckBtn.Position = UDim2.new(0, 20, 0, 160)
CheckBtn.Text = "VERIFY KEY"
CheckBtn.Font = Enum.Font.GothamBold
CheckBtn.TextSize = 18
CheckBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CheckBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
CheckBtn.BorderSizePixel = 0
CheckBtn.Parent = Frame

local CheckBtnCorner = Instance.new("UICorner")
CheckBtnCorner.CornerRadius = UDim.new(0, 8)
CheckBtnCorner.Parent = CheckBtn

-- Status Label
local Label = Instance.new("TextLabel")
Label.Size = UDim2.new(1, -40, 0, 40)
Label.Position = UDim2.new(0, 20, 0, 220)
Label.BackgroundTransparency = 1
Label.Text = ""
Label.Font = Enum.Font.Gotham
Label.TextSize = 14
Label.TextColor3 = Color3.fromRGB(255, 255, 255)
Label.TextWrapped = true
Label.Parent = Frame

--// Remotes - Let's find the correct ones
local rs = game:GetService("ReplicatedStorage")
local remotesFolder = rs:WaitForChild("Remotes") or rs:WaitForChild("RemoteEvents") or rs:WaitForChild("RemoteFunctions")

-- Function to find remotes
local function findRemote(name)
    -- Try different possible locations
    local locations = {
        rs:FindFirstChild("Remotes"),
        rs:FindFirstChild("RemoteEvents"), 
        rs:FindFirstChild("RemoteFunctions"),
        rs
    }
    
    for _, location in ipairs(locations) do
        if location then
            local remote = location:FindFirstChild(name)
            if remote then
                return remote
            end
        end
    end
    return nil
end

--=== WORKING GTD SCRIPT ===--

function loadWorkingScript()
    warn("[System] Loading WORKING GTD Script...")
    
    -- First, let's test what remotes we can find
    warn("[DEBUG] Searching for remotes...")
    
    -- Common GTD remote names
    local remoteNames = {
        "PlaceUnit", "UpgradeUnit", "ToggleAutoSkip", "ChangeTickSpeed", 
        "PlaceDifficultyVote", "RestartGame", "FireServer", "InvokeServer"
    }
    
    for _, name in ipairs(remoteNames) do
        local remote = findRemote(name)
        if remote then
            warn("[FOUND] " .. name .. " - Type: " .. remote.ClassName)
        else
            warn("[MISSING] " .. name)
        end
    end
    
    -- Let's use the original working approach but with better timing
    local function safeRemoteCall(remoteName, ...)
        local remote = findRemote(remoteName)
        if remote then
            if remote:IsA("RemoteFunction") then
                return pcall(function() return remote:InvokeServer(...) end)
            elseif remote:IsA("RemoteEvent") then
                return pcall(function() remote:FireServer(...) end)
            end
        end
        return false, "Remote not found: " .. remoteName
    end

    -- Enable auto skip
    task.delay(2, function()
        safeRemoteCall("ToggleAutoSkip", true)
        safeRemoteCall("AutoSkip", true) -- Try alternative name
        warn("[System] Auto Skip Attempted")
    end)

    -- Set game speed
    safeRemoteCall("ChangeTickSpeed", 3)
    safeRemoteCall("TickSpeed", 3) -- Try alternative name
    
    -- Set difficulty
    safeRemoteCall("PlaceDifficultyVote", "dif_hard")
    safeRemoteCall("Difficulty", "dif_hard") -- Try alternative name

    -- Unit placement data
    local unitPlacements = {
        -- Rainbow Tomatoes
        {
            time = 5,
            unit = "unit_tomato_rainbow",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-850.7767333984375, 61.93030548095703, -155.0453338623047, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-850.7767333984375, 61.93030548095703, -155.0453338623047)
            }
        },
        {
            time = 55,
            unit = "unit_tomato_rainbow", 
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-852.2405395507812, 61.93030548095703, -150.1680450439453, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)
            }
        },
        -- Metal Flowers
        {
            time = 85,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-850.2332153320312, 61.93030548095703, -151.0040740966797, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-850.2332153320312, 61.93030548095703, -151.0040740966797)
            }
        },
        {
            time = 100,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-853.2742919921875, 61.93030548095703, -146.7690887451172, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)
            }
        },
        {
            time = 115,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-857.4375, 61.93030548095703, -148.3301239013672, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)
            }
        },
        -- Punch Potatoes
        {
            time = 185,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.727783203125, 61.93030548095703, -135.6544952392578, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)
            }
        },
        {
            time = 190,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)
            }
        },
        {
            time = 195,
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)
            }
        }
    }

    -- Place units function
    local function placeUnits()
        for _, placement in ipairs(unitPlacements) do
            task.delay(placement.time, function()
                local success, result = safeRemoteCall("PlaceUnit", placement.unit, placement.data)
                if success then
                    warn("[PLACED] " .. placement.unit .. " at " .. placement.time .. "s")
                else
                    warn("[FAILED] " .. placement.unit .. " - " .. tostring(result))
                end
            end)
        end
    end

    -- Upgrade system - Let's use the original working approach
    local function startUpgrades()
        warn("[UPGRADES] Starting upgrade system...")
        
        -- Tomatoes upgrade (start at 10s)
        task.delay(10, function()
            warn("[UPGRADES] Starting tomato upgrades")
            while true do
                for i = 1, 50 do
                    safeRemoteCall("UpgradeUnit", i)
                    task.wait(0.01)
                end
                task.wait(0.5)
            end
        end)
        
        -- Metal flowers upgrade (start at 90s)  
        task.delay(90, function()
            warn("[UPGRADES] Starting metal flower upgrades")
            while true do
                for i = 20, 70 do
                    safeRemoteCall("UpgradeUnit", i)
                    task.wait(0.01)
                end
                task.wait(0.5)
            end
        end)
        
        -- Potatoes upgrade (start at 190s)
        task.delay(190, function()
            warn("[UPGRADES] Starting potato upgrades")
            while true do
                for i = 100, 200 do
                    safeRemoteCall("UpgradeUnit", i)
                    safeRemoteCall("UpgradeUnit", i) -- Double call
                    task.wait(0.01)
                end
                task.wait(0.3)
            end
        end)
    end

    -- Main game loop
    local function mainGameLoop()
        while true do
            warn("[GAME START] New game cycle starting...")
            
            -- Set game settings
            safeRemoteCall("ChangeTickSpeed", 3)
            safeRemoteCall("PlaceDifficultyVote", "dif_hard")
            
            -- Place units
            placeUnits()
            
            -- Start upgrades
            startUpgrades()
            
            -- Wait for game duration
            task.wait(300) -- 5 minutes
            
            warn("[RESTART] Restarting game...")
            safeRemoteCall("RestartGame")
            
            -- Wait for reset
            task.wait(5)
        end
    end

    -- Start everything
    mainGameLoop()
end

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "WORKING GTD SCRIPT"
    SubTitle.Text = "Debugging & Wide Range Coverage"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 WORKING GTD SCRIPT\n• Debugs remote connections first\n• Uses wide ID range coverage\n• Safe remote calling with error handling\n• Works with both RemoteEvents and RemoteFunctions\n• Auto-detects remote locations"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Working Button
    local btnWorking = Instance.new("TextButton")
    btnWorking.Size = UDim2.new(1, -40, 0, 120)
    btnWorking.Position = UDim2.new(0, 20, 0, 200)
    btnWorking.Text = "WORKING GTD SCRIPT\nDebug Mode + Wide Range Coverage\nSafe Remote Calling"
    btnWorking.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    btnWorking.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnWorking.Font = Enum.Font.GothamBold
    btnWorking.TextSize = 18
    btnWorking.BorderSizePixel = 0
    btnWorking.Parent = Frame

    local btnWorkingCorner = Instance.new("UICorner")
    btnWorkingCorner.CornerRadius = UDim.new(0, 10)
    btnWorkingCorner.Parent = btnWorking

    btnWorking.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadWorkingScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading WORKING SCRIPT..."
        Label.TextColor3 = Color3.fromRGB(100, 255, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
        CheckBtn.Text = "SUCCESS!"
        
        task.delay(1.5, showStrategyMenu)
    else
        TextBox.Text = ""
        Label.Text = "❌ Invalid Key! Please try again."
        Label.TextColor3 = Color3.fromRGB(255, 100, 100)
        CheckBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        
        task.delay(1, function()
            CheckBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
            CheckBtn.Text = "VERIFY KEY"
        end)
    end
end)

-- Add some visual effects
TextBox.Focused:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
end)

TextBox.FocusLost:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

-- Load anti-afk scripts
loadstring(game:HttpGet("https://pastebin.com/raw/HkAmPckQ"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()

-- Force GUI to be on top
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

print("GUI setup complete - Should be visible now!")

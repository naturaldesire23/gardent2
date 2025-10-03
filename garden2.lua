--// Garden Tower Defense Script - RELATIVE TIMING SYSTEM
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

--// Remotes
local rs = game:GetService("ReplicatedStorage")
local remotes = rs:WaitForChild("RemoteFunctions")

-- Auto Skip (enable once at start)
task.delay(2, function()
    pcall(function()
        remotes.ToggleAutoSkip:InvokeServer(true)
        warn("[System] Auto Skip Enabled")
    end)
end)

--=== RELATIVE TIMING SYSTEM ===--

function loadRelativeTimingSystem()
    warn("[System] Loaded RELATIVE TIMING SYSTEM")
    
    -- Create upgrade manager
    local UpgradeManager = {}
    UpgradeManager.Active = true
    UpgradeManager.CurrentPhase = "waiting"
    UpgradeManager.GameStartTime = 0

    -- Function to upgrade units
    local function upgradeUnit(unitId)
        pcall(function()
            remotes.UpgradeUnit:InvokeServer(unitId)
        end)
    end

    -- Start permanent upgrade loops
    local function startPermanentUpgradeLoops()
        warn("[PERMANENT] Starting permanent upgrade loops...")
        
        -- Tomato upgrade loop
        task.spawn(function()
            while UpgradeManager.Active do
                if UpgradeManager.CurrentPhase == "tomatoes" then
                    for id = 1, 50 do
                        upgradeUnit(id)
                        upgradeUnit(id) -- Double call
                    end
                end
                task.wait(0.01)
            end
        end)
        
        -- Metal Flower upgrade loop
        task.spawn(function()
            while UpgradeManager.Active do
                if UpgradeManager.CurrentPhase == "metal_flowers" then
                    for id = 20, 80 do
                        upgradeUnit(id)
                        upgradeUnit(id) -- Double call
                    end
                end
                task.wait(0.01)
            end
        end)
        
        -- Potato upgrade loop
        task.spawn(function()
            while UpgradeManager.Active do
                if UpgradeManager.CurrentPhase == "potatoes" then
                    for id = 230, 280 do
                        upgradeUnit(id)
                        upgradeUnit(id) -- Double call
                        upgradeUnit(id) -- Triple call
                    end
                end
                task.wait(0.001) -- Faster for potatoes
            end
        end)
    end

    -- Start the permanent loops
    startPermanentUpgradeLoops()

    -- Function to place units
    local function placeUnit(unitName, data)
        local success = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success then
            warn("[Placing] " .. unitName .. " at " .. os.clock())
            return true
        else
            warn("[Placing] " .. unitName .. " - Failed")
            return false
        end
    end

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

    -- Main game loop
    local function startGameLoop()
        while UpgradeManager.Active do
            warn("[GAME START] Beginning new game cycle...")
            
            -- Reset game settings
            UpgradeManager.GameStartTime = os.clock()
            UpgradeManager.CurrentPhase = "waiting"
            
            remotes.ChangeTickSpeed:InvokeServer(3)
            remotes.PlaceDifficultyVote:InvokeServer("dif_hard")
            
            -- Schedule unit placements
            for _, placement in ipairs(unitPlacements) do
                local placementTime = placement.time
                task.delay(placementTime, function()
                    if UpgradeManager.Active then
                        placeUnit(placement.unit, placement.data)
                    end
                end)
            end
            
            -- Schedule phase changes
            -- Phase 1: Tomato upgrades (6s)
            task.delay(6, function()
                if UpgradeManager.Active then
                    warn("[PHASE 1] Starting TOMATO upgrades!")
                    UpgradeManager.CurrentPhase = "tomatoes"
                end
            end)

            -- Phase 2: Metal Flower upgrades (86s)  
            task.delay(86, function()
                if UpgradeManager.Active then
                    warn("[PHASE 2] Starting METAL FLOWER upgrades!")
                    UpgradeManager.CurrentPhase = "metal_flowers"
                end
            end)

            -- Phase 3: Potato upgrades (186s)
            task.delay(186, function()
                if UpgradeManager.Active then
                    warn("[PHASE 3] Starting POTATO upgrades - MAXIMUM SPEED!")
                    UpgradeManager.CurrentPhase = "potatoes"
                end
            end)

            -- Wait for game to complete (300 seconds = 5 minutes)
            local gameDuration = 300
            warn("[GAME] Waiting " .. gameDuration .. " seconds for game completion...")
            task.wait(gameDuration)
            
            -- Restart game
            if UpgradeManager.Active then
                warn("[RESTART] Restarting game...")
                UpgradeManager.CurrentPhase = "waiting"
                
                remotes.RestartGame:InvokeServer()
                
                -- Wait for game to fully reset
                warn("[RESTART] Waiting 5 seconds for game reset...")
                task.wait(5)
            end
        end
    end

    -- Start the main game loop
    startGameLoop()
end

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "RELATIVE TIMING SYSTEM"
    SubTitle.Text = "No timing issues between games"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "⏱️ RELATIVE TIMING SYSTEM\n• Uses task.wait() instead of absolute time\n• No timing drift between games\n• Perfect 5-minute cycles\n• Upgrades work every game\n• No 10-second delays"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(100, 255, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Relative Timing Button
    local btnRelative = Instance.new("TextButton")
    btnRelative.Size = UDim2.new(1, -40, 0, 120)
    btnRelative.Position = UDim2.new(0, 20, 0, 200)
    btnRelative.Text = "RELATIVE TIMING SYSTEM\nNo Timing Issues\nPerfect 5-Minute Cycles"
    btnRelative.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
    btnRelative.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnRelative.Font = Enum.Font.GothamBold
    btnRelative.TextSize = 18
    btnRelative.BorderSizePixel = 0
    btnRelative.Parent = Frame

    local btnRelativeCorner = Instance.new("UICorner")
    btnRelativeCorner.CornerRadius = UDim.new(0, 10)
    btnRelativeCorner.Parent = btnRelative

    btnRelative.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadRelativeTimingSystem()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading RELATIVE TIMING..."
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

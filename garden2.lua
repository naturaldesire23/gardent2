--// Garden Tower Defense Script - Golem Priority Upgrade Strategy
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

--=== GOLEM PRIORITY UPGRADE STRATEGY ===--

function loadGolemPriorityScript()
    warn("[System] Loaded Golem Priority Upgrade Strategy")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_hard"
    
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
        -- Golem Dragons
        {
            time = 185,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.727783203125, 61.93030548095703, -135.6544952392578, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)
            }
        },
        {
            time = 215,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)
            }
        },
        {
            time = 230,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)
            }
        }
    }

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

    local function upgradeUnit(unitId)
        pcall(function()
            remotes.UpgradeUnit:InvokeServer(unitId)
        end)
    end

    -- Variables to control upgrade loops
    local upgradeTomatoesActive = true
    local upgradeMetalFlowersActive = true
    local upgradeGolemsActive = false

    -- UPGRADE FUNCTIONS
    local function upgradeTomatoes()
        warn("[UPGRADE] Starting TOMATO upgrades (1-50)")
        
        while upgradeTomatoesActive do
            for id = 1, 50 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
            end
            task.wait(0.01)
        end
        warn("[UPGRADE] Tomato upgrades STOPPED")
    end

    local function upgradeMetalFlowers()
        warn("[UPGRADE] Starting METAL FLOWER upgrades (20-80)")
        
        while upgradeMetalFlowersActive do
            for id = 20, 80 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
                upgradeUnit(id) -- Triple call
            end
            task.wait(0.01)
        end
        warn("[UPGRADE] Metal Flower upgrades STOPPED")
    end

    local function upgradeGolems()
        warn("[UPGRADE] Starting GOLEM upgrades (250-480) - PRIORITY")
        
        while upgradeGolemsActive do
            for id = 250, 480 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
                upgradeUnit(id) -- Triple call
                upgradeUnit(id) -- QUADRUPLE call
            end
            -- NO DELAY - MAXIMUM SPEED
        end
    end

    local function stopAllUpgradesExceptGolems()
        warn("[PRIORITY] Stopping tomato and metal flower upgrades...")
        upgradeTomatoesActive = false
        upgradeMetalFlowersActive = false
        
        -- Wait a moment for other loops to stop
        task.wait(0.1)
        
        -- Start golem upgrades
        upgradeGolemsActive = true
        warn("[PRIORITY] Starting GOLEM PRIORITY upgrades!")
        upgradeGolems()
    end

    local function startGame()
        warn("[Game Start] Choosing Hard difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Reset upgrade states
        upgradeTomatoesActive = true
        upgradeMetalFlowersActive = true
        upgradeGolemsActive = false
        
        -- Place all units at their times
        for _, placement in ipairs(unitPlacements) do
            task.delay(placement.time, function()
                placeUnit(placement.unit, placement.data)
            end)
        end
        
        -- Start TOMATO upgrades at 6 seconds
        task.delay(6, function()
            warn("[Starting] Beginning TOMATO upgrades!")
            upgradeTomatoes()
        end)
        
        -- Start METAL FLOWER upgrades at 86 seconds
        task.delay(86, function()
            warn("[Starting] Beginning METAL FLOWER upgrades!")
            upgradeMetalFlowers()
        end)
        
        -- STOP other upgrades and START GOLEM upgrades at 186 seconds
        task.delay(186, function()
            warn("[PRIORITY] First golem placed - SWITCHING TO GOLEM PRIORITY!")
            stopAllUpgradesExceptGolems()
        end)
        
        -- Auto-restart at 300 seconds (5 minutes)
        task.delay(300, function()
            warn("[Restart] Game ended, restarting in 2 seconds...")
            task.wait(2)
            remotes.RestartGame:InvokeServer()
            warn("[Restart] Game restarted, starting new cycle...")
            task.wait(1)
            startGame()
        end)
    end

    -- Start the first game
    startGame()
end

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "GOLEM PRIORITY STRATEGY"
    SubTitle.Text = "3x Speed - Golems Only After Placement"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 GOLEM PRIORITY STRATEGY\n• Tomatoes: IDs 1-50 (early game)\n• Metal Flowers: IDs 20-80 (mid game)\n• Golems: IDs 250-480 (LATE GAME PRIORITY)\n• After 1st golem: ONLY GOLEMS upgrade\n• No interference - Maximum focus"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Golem Priority Button
    local btnGolem = Instance.new("TextButton")
    btnGolem.Size = UDim2.new(1, -40, 0, 120)
    btnGolem.Position = UDim2.new(0, 20, 0, 200)
    btnGolem.Text = "GOLEM PRIORITY\nStops Tomatoes/Metal After Golems\nGolems Get 100% Focus"
    btnGolem.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btnGolem.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnGolem.Font = Enum.Font.GothamBold
    btnGolem.TextSize = 18
    btnGolem.BorderSizePixel = 0
    btnGolem.Parent = Frame

    local btnGolemCorner = Instance.new("UICorner")
    btnGolemCorner.CornerRadius = UDim.new(0, 10)
    btnGolemCorner.Parent = btnGolem

    btnGolem.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadGolemPriorityScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading GOLEM PRIORITY..."
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

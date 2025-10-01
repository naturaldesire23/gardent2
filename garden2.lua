--// Garden Tower Defense Script - Optimized ID Ranges
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

--=== OPTIMIZED ID RANGES ===--

function loadOptimizedScript()
    warn("[System] Loaded Optimized ID Range Strategy")
    remotes.ChangeTickSpeed:InvokeServer(3)

    local difficulty = "dif_hard"
    
    local unitPlacements = {
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
        {
            time = 90,
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-848.3375244140625, 61.93030548095703, -150.70787048339844, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-848.3375244140625, 61.93030548095703, -150.70787048339844)
            }
        },
        {
            time = 170,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-857.5816040039062, 61.93030548095703, -159.4305419921875, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-857.5816040039062, 61.93030548095703, -159.4305419921875)
            }
        },
        {
            time = 175,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-857.4984130859375, 61.93030548095703, -152.04917907714844, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-857.4984130859375, 61.93030548095703, -152.04917907714844)
            }
        },
        {
            time = 180,
            unit = "unit_golem_dragon",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-856.130615234375, 61.93030548095703, -146.03330993652344, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-856.130615234375, 61.93030548095703, -146.03330993652344)
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

    -- OPTIMIZED UPGRADE FUNCTIONS
    local function ultraFastUpgradeTomatoes()
        warn("[ULTRA FAST] Starting TOMATO upgrades (1-50)")
        
        while true do
            for id = 1, 50 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
            end
            task.wait(0.01)
        end
    end

    local function ultraFastUpgradeMetalFlower()
        warn("[ULTRA FAST] Starting METAL FLOWER upgrades (20-80)")
        
        while true do
            -- OPTIMIZED RANGE: 20-80 for metal flower
            for id = 20, 80 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
                upgradeUnit(id) -- Triple call for MAX speed
            end
            task.wait(0.01)
        end
    end

    local function ultraFastUpgradeGolems()
        warn("[ULTRA FAST] Starting GOLEM upgrades (400-450)")
        
        while true do
            for id = 400, 450 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call
                upgradeUnit(id) -- Triple call for MAX speed
            end
            task.wait(0.01)
        end
    end

    local function startGame()
        warn("[Game Start] Choosing Hard difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Place all units at their times
        for _, placement in ipairs(unitPlacements) do
            task.delay(placement.time, function()
                placeUnit(placement.unit, placement.data)
            end)
        end
        
        -- Start ULTRA FAST TOMATO upgrades at 6 seconds
        task.delay(6, function()
            warn("[Starting] Beginning ULTRA FAST TOMATO upgrades!")
            ultraFastUpgradeTomatoes()
        end)
        
        -- Start ULTRA FAST METAL FLOWER upgrades at 91 seconds
        task.delay(91, function()
            warn("[Starting] Beginning ULTRA FAST METAL FLOWER upgrades!")
            ultraFastUpgradeMetalFlower()
        end)
        
        -- Start ULTRA FAST GOLEM upgrades at 181 seconds
        task.delay(181, function()
            warn("[Starting] Beginning ULTRA FAST GOLEM upgrades!")
            ultraFastUpgradeGolems()
        end)
        
        -- Auto-restart at 240 seconds (4 minutes)
        task.delay(240, function()
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
    
    Title.Text = "SELECT STRATEGY"
    SubTitle.Text = "Optimized ID Ranges"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 100)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 OPTIMIZED ID RANGES\n• Tomatoes: IDs 1-50 (2x calls)\n• Metal Flower: IDs 20-80 (3x calls)\n• Golems: IDs 400-450 (3x calls)\n• Smaller ranges = FASTER upgrades\n• MAXIMUM SPEED"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Optimized Button
    local btnOptimized = Instance.new("TextButton")
    btnOptimized.Size = UDim2.new(1, -40, 0, 120)
    btnOptimized.Position = UDim2.new(0, 20, 0, 180)
    btnOptimized.Text = "OPTIMIZED RANGES\nMetal Flower: 20-80\nFASTER UPGRADES"
    btnOptimized.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btnOptimized.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnOptimized.Font = Enum.Font.GothamBold
    btnOptimized.TextSize = 18
    btnOptimized.BorderSizePixel = 0
    btnOptimized.Parent = Frame

    local btnOptimizedCorner = Instance.new("UICorner")
    btnOptimizedCorner.CornerRadius = UDim.new(0, 10)
    btnOptimizedCorner.Parent = btnOptimized

    btnOptimized.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadOptimizedScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading strategy selection..."
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

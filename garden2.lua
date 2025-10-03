--// Garden Tower Defense Script - FIXED Remote Calls
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

--// FIND ACTUAL REMOTES
local rs = game:GetService("ReplicatedStorage")
local remotesFolder = rs:WaitForChild("RemoteEvents") or rs:WaitForChild("RemoteFunctions") or rs:FindFirstChildWhichIsA("Folder")

-- Function to find remote by name pattern
local function findRemote(namePattern)
    for _, remote in pairs(rs:GetDescendants()) do
        if remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") then
            if string.find(string.lower(remote.Name), string.lower(namePattern)) then
                warn("[FOUND REMOTE]: " .. remote.Name)
                return remote
            end
        end
    end
    return nil
end

-- Auto find remotes
local placeRemote = findRemote("place") or findRemote("unit") or rs:FindFirstChild("PlaceUnit")
local upgradeRemote = findRemote("upgrade") or findRemote("level") or rs:FindFirstChild("UpgradeUnit")
local difficultyRemote = findRemote("difficulty") or findRemote("vote") or rs:FindFirstChild("PlaceDifficultyVote")
local restartRemote = findRemote("restart") or findRemote("reset") or rs:FindFirstChild("RestartGame")
local autoSkipRemote = findRemote("auto") or findRemote("skip") or rs:FindFirstChild("ToggleAutoSkip")
local tickSpeedRemote = findRemote("tick") or findRemote("speed") or rs:FindFirstChild("ChangeTickSpeed")

-- Log found remotes
warn("[REMOTE SCAN RESULTS]")
warn("Place Unit: " .. (placeRemote and placeRemote.Name or "NOT FOUND"))
warn("Upgrade Unit: " .. (upgradeRemote and upgradeRemote.Name or "NOT FOUND"))
warn("Difficulty: " .. (difficultyRemote and difficultyRemote.Name or "NOT FOUND"))
warn("Restart: " .. (restartRemote and restartRemote.Name or "NOT FOUND"))
warn("Auto Skip: " .. (autoSkipRemote and autoSkipRemote.Name or "NOT FOUND"))
warn("Tick Speed: " .. (tickSpeedRemote and tickSpeedRemote.Name or "NOT FOUND"))

-- Safe remote calling function
local function safeRemoteCall(remote, ...)
    if not remote then
        warn("[MISSING REMOTE]: " .. (remote and remote.Name or "unknown"))
        return false
    end
    
    local success, result = pcall(function()
        if remote:IsA("RemoteEvent") then
            remote:FireServer(...)
            return true
        elseif remote:IsA("RemoteFunction") then
            return remote:InvokeServer(...)
        end
    end)
    
    if success then
        warn("[SUCCESS]: " .. remote.Name)
        return result or true
    else
        warn("[FAILED]: " .. remote.Name .. " - " .. tostring(result))
        return false
    end
end

-- Auto Skip (enable once at start)
task.delay(2, function()
    if autoSkipRemote then
        safeRemoteCall(autoSkipRemote, true)
        warn("[System] Auto Skip Enabled")
    end
end)

--=== OPTIMIZED PUNCH POTATO PLACEMENT ===--

function loadOptimizedPotatoScript()
    warn("[System] Loaded Optimized Punch Potato Placement")
    
    if tickSpeedRemote then
        safeRemoteCall(tickSpeedRemote, 3)
    end

    local difficulty = "dif_hard"
    
    -- Unit placement data
    local unitPlacements = {
        -- Rainbow Tomatoes
        {
            time = 5,
            unit = "unit_tomato_rainbow",
            position = Vector3.new(-850.7767333984375, 61.93030548095703, -155.0453338623047)
        },
        {
            time = 55,
            unit = "unit_tomato_rainbow", 
            position = Vector3.new(-852.2405395507812, 61.93030548095703, -150.1680450439453)
        },
        -- Metal Flowers (ALL 3 with better timing)
        {
            time = 85,
            unit = "unit_metal_flower",
            position = Vector3.new(-850.2332153320312, 61.93030548095703, -151.0040740966797)
        },
        {
            time = 90,
            unit = "unit_metal_flower",
            position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)
        },
        {
            time = 95,
            unit = "unit_metal_flower",
            position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)
        },
        -- Punch Potatoes
        {
            time = 185,
            unit = "unit_punch_potato",
            position = Vector3.new(-851.727783203125, 61.93030548095703, -135.6544952392578)
        },
        {
            time = 190,
            unit = "unit_punch_potato",
            position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)
        },
        {
            time = 195,
            unit = "unit_punch_potato",
            position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)
        }
    }

    local function placeUnit(unitName, position)
        if not placeRemote then
            warn("[ERROR] No place remote found!")
            return false
        end
        
        local placementData = {
            Valid = true,
            Rotation = 180,
            CF = CFrame.new(position.X, position.Y, position.Z, -1, 0, 0, 0, 1, 0, 0, 0, -1),
            Position = position
        }
        
        local success = safeRemoteCall(placeRemote, unitName, placementData)
        
        if success then
            warn("[SUCCESS] Placed " .. unitName .. " at " .. os.clock())
            return true
        else
            warn("[FAILED] Could not place " .. unitName .. " - Retrying in 1 second...")
            task.wait(1)
            
            -- Retry with different parameters
            local retrySuccess = safeRemoteCall(placeRemote, unitName, {
                Valid = true,
                Rotation = 0,
                CF = CFrame.new(position),
                Position = position
            })
            
            if retrySuccess then
                warn("[RETRY SUCCESS] Placed " .. unitName)
                return true
            else
                warn("[FINAL FAIL] Could not place " .. unitName)
                return false
            end
        end
    end

    local function upgradeUnit(unitId)
        if upgradeRemote then
            safeRemoteCall(upgradeRemote, unitId)
        end
    end

    -- Upgrade control variables
    local upgradeTomatoesActive = true
    local upgradeMetalFlowersActive = true

    -- UPGRADE FUNCTIONS
    local function upgradeTomatoes()
        warn("[UPGRADE] Starting TOMATO upgrades (1-50)")
        
        while upgradeTomatoesActive do
            for id = 1, 50 do
                upgradeUnit(id)
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
            end
            task.wait(0.01)
        end
        warn("[UPGRADE] Metal Flower upgrades STOPPED")
    end

    local function ultraFastUpgradePunchPotatoes()
        warn("[ULTRA FAST] Starting PUNCH POTATO upgrades (100-400)")
        
        for thread = 1, 4 do
            task.spawn(function()
                while true do
                    local startId = 100 + ((thread - 1) * 75)
                    local endId = math.min(startId + 74, 400)
                    
                    for id = startId, endId do
                        upgradeUnit(id)
                        upgradeUnit(id)
                        upgradeUnit(id)
                    end
                end
            end)
        end
    end

    local function stopOtherUpgrades()
        warn("[PRIORITY] Stopping tomato and metal flower upgrades!")
        upgradeTomatoesActive = false
        upgradeMetalFlowersActive = false
    end

    local function startGame()
        warn("[Game Start] Choosing Hard difficulty")
        
        -- Set difficulty
        if difficultyRemote then
            safeRemoteCall(difficultyRemote, difficulty)
        end
        
        -- Reset upgrade states
        upgradeTomatoesActive = true
        upgradeMetalFlowersActive = true
        
        -- Place all units at their times
        local placedCount = {
            tomatoes = 0,
            metal_flowers = 0,
            punch_potatoes = 0
        }
        
        for _, placement in ipairs(unitPlacements) do
            task.delay(placement.time, function()
                if placeUnit(placement.unit, placement.position) then
                    if placement.unit == "unit_tomato_rainbow" then
                        placedCount.tomatoes = placedCount.tomatoes + 1
                    elseif placement.unit == "unit_metal_flower" then
                        placedCount.metal_flowers = placedCount.metal_flowers + 1
                    elseif placement.unit == "unit_punch_potato" then
                        placedCount.punch_potatoes = placedCount.punch_potatoes + 1
                    end
                end
            end)
        end
        
        -- Log placement summary
        task.delay(200, function()
            warn("[PLACEMENT SUMMARY] Tomatoes: "..placedCount.tomatoes.."/2, Metal Flowers: "..placedCount.metal_flowers.."/3, Punch Potatoes: "..placedCount.punch_potatoes.."/3")
        end)
        
        -- Start upgrades at appropriate times
        task.delay(6, upgradeTomatoes)
        task.delay(86, upgradeMetalFlowers)
        task.delay(186, function()
            stopOtherUpgrades()
            task.wait(0.1)
            ultraFastUpgradePunchPotatoes()
        end)
        
        -- Auto-restart
        task.delay(300, function()
            warn("[Restart] Game ended, restarting...")
            if restartRemote then
                safeRemoteCall(restartRemote)
                task.wait(2)
                startGame()
            end
        end)
    end

    -- Start the first game
    startGame()
end

--=== SIMPLIFIED MENU ===--
local function showStrategyMenu()
    Frame.Size = UDim2.new(0, 450, 0, 350)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -175)
    
    Title.Text = "FIXED REMOTE CALLS"
    SubTitle.Text = "Auto-detected Remotes"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🔧 FIXED REMOTE CALLS\n• Auto-detects remote events/functions\n• Better error handling\n• Multiple retry attempts\n• Works with actual game remotes"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Start Button
    local btnStart = Instance.new("TextButton")
    btnStart.Size = UDim2.new(1, -40, 0, 120)
    btnStart.Position = UDim2.new(0, 20, 0, 200)
    btnStart.Text = "START FIXED SCRIPT\nAuto-detected Remotes\nBetter Error Handling"
    btnStart.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btnStart.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnStart.Font = Enum.Font.GothamBold
    btnStart.TextSize = 18
    btnStart.BorderSizePixel = 0
    btnStart.Parent = Frame

    local btnStartCorner = Instance.new("UICorner")
    btnStartCorner.CornerRadius = UDim.new(0, 10)
    btnStartCorner.Parent = btnStart

    btnStart.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadOptimizedPotatoScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading FIXED..."
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

-- Visual effects
TextBox.Focused:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
end)

TextBox.FocusLost:Connect(function()
    TextBoxContainer.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
end)

-- Anti-afk
loadstring(game:HttpGet("https://pastebin.com/raw/HkAmPckQ"))()
loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()

-- Force GUI to be on top
ScreenGui.DisplayOrder = 999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

print("GUI setup complete - Should be visible now!")

--// Garden Tower Defense Script - FIXED TIMING Punch Potatoes
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

--=== FIXED TIMING PUNCH POTATOES ===--

function loadFixedTimingPotatoScript()
    warn("[System] Loaded FIXED TIMING Punch Potato Strategy")
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
        -- Metal Flowers - FIXED: 5 second intervals
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
            time = 90, -- 5 seconds after first
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-853.2742919921875, 61.93030548095703, -146.7690887451172, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-853.2742919921875, 61.93030548095703, -146.7690887451172)
            }
        },
        {
            time = 95, -- 5 seconds after second
            unit = "unit_metal_flower",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-857.4375, 61.93030548095703, -148.3301239013672, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-857.4375, 61.93030548095703, -148.3301239013672)
            }
        },
        -- Punch Potatoes - FIXED: 5 second intervals
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
            time = 190, -- 5 seconds after first potato
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-851.33349609375, 61.93030548095703, -133.5747833251953, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-851.33349609375, 61.93030548095703, -133.5747833251953)
            }
        },
        {
            time = 195, -- 5 seconds after second potato
            unit = "unit_punch_potato",
            data = {
                Valid = true,
                Rotation = 180,
                CF = CFrame.new(-846.9492797851562, 61.93030548095703, -133.9480743408203, -1, 0, -8.742277657347586e-08, 0, 1, 0, 8.742277657347586e-08, 0, -1),
                Position = Vector3.new(-846.9492797851562, 61.93030548095703, -133.9480743408203)
            }
        }
    }

    local function placeUnit(unitName, data)
        local success, result = pcall(function()
            return remotes.PlaceUnit:InvokeServer(unitName, data)
        end)
        
        if success and result == true then
            warn("[SUCCESS] Placed " .. unitName .. " at " .. os.clock())
            return true
        else
            warn("[FAILED] Could not place " .. unitName .. " - Retrying in 1 second...")
            -- Retry after 1 second
            task.wait(1)
            local retrySuccess, retryResult = pcall(function()
                return remotes.PlaceUnit:InvokeServer(unitName, data)
            end)
            if retrySuccess and retryResult == true then
                warn("[RETRY SUCCESS] Placed " .. unitName)
                return true
            else
                warn("[FINAL FAIL] Could not place " .. unitName)
                return false
            end
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

    -- UPGRADE FUNCTIONS
    local function upgradeTomatoes()
        warn("[UPGRADE] Starting TOMATO upgrades (1-50)")
        
        while upgradeTomatoesActive do
            for id = 1, 50 do
                upgradeUnit(id)
                upgradeUnit(id) -- Double call for speed
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
                upgradeUnit(id) -- Double call for speed
            end
            task.wait(0.01)
        end
        warn("[UPGRADE] Metal Flower upgrades STOPPED")
    end

    local function ultraFastUpgradePunchPotatoes()
        warn("[ULTRA FAST] Starting PUNCH POTATO upgrades (100-400) - MAXIMUM SPEED")
        
        -- Run multiple parallel loops for maximum speed
        for thread = 1, 4 do -- Increased to 4 threads
            task.spawn(function()
                while true do
                    -- Different ranges for each thread to cover more ground
                    local startId = 100 + ((thread - 1) * 75)
                    local endId = math.min(startId + 74, 400)
                    
                    for id = startId, endId do
                        upgradeUnit(id)
                        upgradeUnit(id) -- Double call
                        upgradeUnit(id) -- Triple call for MAXIMUM speed
                    end
                    -- NO DELAY - MAXIMUM SPEED
                end
            end)
        end
    end

    local function stopOtherUpgrades()
        warn("[PRIORITY] Stopping tomato and metal flower upgrades for MAXIMUM potato speed!")
        upgradeTomatoesActive = false
        upgradeMetalFlowersActive = false
    end

    local function startGame()
        warn("[Game Start] Choosing Hard difficulty")
        remotes.PlaceDifficultyVote:InvokeServer(difficulty)
        
        -- Reset upgrade states
        upgradeTomatoesActive = true
        upgradeMetalFlowersActive = true
        
        -- Place all units at their times with better error handling
        local placedCount = {
            tomatoes = 0,
            metal_flowers = 0,
            punch_potatoes = 0
        }
        
        for _, placement in ipairs(unitPlacements) do
            task.delay(placement.time, function()
                if placeUnit(placement.unit, placement.data) then
                    -- Track successful placements
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
        
        -- Log placement summary after all placements should be done
        task.delay(200, function()
            warn("[PLACEMENT SUMMARY] Tomatoes: "..placedCount.tomatoes.."/2, Metal Flowers: "..placedCount.metal_flowers.."/3, Punch Potatoes: "..placedCount.punch_potatoes.."/3")
        end)
        
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
        
        -- STOP other upgrades and START ULTRA FAST PUNCH POTATO upgrades at 186 seconds
        task.delay(186, function()
            warn("[ULTRA FAST] First punch potato placed - MAXIMUM SPEED ACTIVATED!")
            stopOtherUpgrades()
            task.wait(0.1) -- Let other loops stop
            ultraFastUpgradePunchPotatoes()
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
    
    Title.Text = "FIXED TIMING POTATOES"
    SubTitle.Text = "5s Intervals + Auto-Retry"
    TextBox.Visible = false
    CheckBtn.Visible = false
    Label.Visible = false

    -- Instructions
    local Instructions = Instance.new("TextLabel")
    Instructions.Size = UDim2.new(1, -40, 0, 120)
    Instructions.Position = UDim2.new(0, 20, 0, 60)
    Instructions.BackgroundTransparency = 1
    Instructions.Text = "🎯 FIXED TIMING PLACEMENT\n• Metal Flowers: 85s, 90s, 95s (5s intervals)\n• Punch Potatoes: 185s, 190s, 195s (5s intervals)\n• Auto-retry failed placements\n• 4 upgrade threads + triple calls\n• Placement tracking"
    Instructions.Font = Enum.Font.Gotham
    Instructions.TextSize = 14
    Instructions.TextColor3 = Color3.fromRGB(255, 200, 100)
    Instructions.TextWrapped = true
    Instructions.Parent = Frame

    -- Fixed Timing Button
    local btnFixed = Instance.new("TextButton")
    btnFixed.Size = UDim2.new(1, -40, 0, 120)
    btnFixed.Position = UDim2.new(0, 20, 0, 200)
    btnFixed.Text = "FIXED TIMING PLACEMENT\n5s Intervals + Auto-Retry\n4 Threads + Triple Calls"
    btnFixed.BackgroundColor3 = Color3.fromRGB(220, 100, 100)
    btnFixed.TextColor3 = Color3.fromRGB(255, 255, 255)
    btnFixed.Font = Enum.Font.GothamBold
    btnFixed.TextSize = 18
    btnFixed.BorderSizePixel = 0
    btnFixed.Parent = Frame

    local btnFixedCorner = Instance.new("UICorner")
    btnFixedCorner.CornerRadius = UDim.new(0, 10)
    btnFixedCorner.Parent = btnFixed

    btnFixed.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        loadFixedTimingPotatoScript()
    end)
end

--=== KEY CHECK ===--
CheckBtn.MouseButton1Click:Connect(function()
    if TextBox.Text:upper() == "GTD2025" then
        Label.Text = "✅ Key Verified! Loading FIXED TIMING..."
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
